Below is **Topic #4** in our series: **Key Components and Implementation Details**. We’ll now translate the architectural concepts from Topic #3 into practical, on-chain structures and function flows. While we reference an EVM/Solidity context for concreteness, the same fundamental ideas can be ported to other blockchains (CosmWasm, Solana, etc.) with equivalent logic.

---

## 4. Key Components and Implementation Details

We’ll break the discussion into five main parts:

1. **Data Structures**  
2. **Initialization**  
3. **Core Execution Flow**  
4. **Signer Update Flow**  
5. **Security-Specific Implementation Concerns**

---

### 4.1 Data Structures

A typical EVM-based k-of-n multisig might store:

1. **Signers**:  
   - `mapping(address => bool) public isSigner;`  
     \- Allows constant-time membership checks.  
   - An array `signersList` if we need to iterate over signers or quickly fetch the entire set.

2. **Threshold**:  
   - `uint256 public threshold;`  
     \- The number \(k\) of signatures required.

3. **Nonce**:  
   - `uint256 public nonce;`  
     \- Monotonically incremented for each executed transaction or signer update (depending on the design).

4. **(Optional) Governance Nonce**:  
   - If you separate “transaction execution” from “governance actions” (like changing signers), you might store a different nonce for each.  
   - Alternatively, a single global nonce can be used for both, as long as each transaction or update references the correct nonce.

5. **(Optional) Proposal/Approval Mapping** (for on-chain proposals approach):  
   - If you choose the on-chain queue style, you’ll store per-proposal data:
     ```solidity
     struct Proposal {
         address target;
         uint256 value;
         bytes data;
         uint256 approvalsCount;
         mapping(address => bool) hasApproved;
         bool executed;
     }
     mapping(uint256 => Proposal) public proposals;
     ```
   - This adds complexity but increases on-chain transparency.

---

### 4.2 Initialization

In Solidity, the constructor (or initialization function, if using proxies) sets up initial signers, threshold, and nonce. For example:

```solidity
constructor(address[] memory _initialSigners, uint256 _threshold) {
    require(_threshold <= _initialSigners.length && _threshold > 0, "Invalid threshold");

    for (uint256 i = 0; i < _initialSigners.length; i++) {
        address signer = _initialSigners[i];
        require(signer != address(0), "Zero address not allowed");
        require(!isSigner[signer], "Duplicate signer");

        isSigner[signer] = true;
        // Optionally store them in an array for easy iteration
        // signersList.push(signer);
    }

    threshold = _threshold;
    nonce = 0;
}
```

**Key Points**  
- Enforce `0 < threshold <= n` from the start.  
- Reject duplicates or zero addresses.  
- Initialize `nonce = 0`.

---

### 4.3 Core Execution Flow

Let’s assume a **minimal on-chain logic** approach with off-chain aggregation of signatures. A typical function might be:

```solidity
function executeTransaction(
    address _to,
    uint256 _value,
    bytes calldata _data,
    uint256 _nonce,
    bytes[] calldata _signatures
) external returns (bytes memory) {
    // 1. Check nonce
    require(_nonce == nonce, "Invalid nonce");

    // 2. Build the message hash
    //    Typically a hash of (this contract address, chainID, _to, _value, _data, _nonce).
    //    For EVM, consider EIP-712 or a simpler keccak256 scheme.
    bytes32 messageHash = getMessageHash(_to, _value, _data, _nonce);

    // 3. Verify signatures
    uint256 validSignaturesCount = 0;
    address[] memory encounteredSigners = new address[](_signatures.length);

    for (uint256 i = 0; i < _signatures.length; i++) {
        address recovered = recoverSigner(messageHash, _signatures[i]);
        // a) Check membership
        if (!isSigner[recovered]) {
            continue;  // not a valid signer
        }
        // b) Check for duplicate signers
        bool alreadyCounted = false;
        for (uint256 j = 0; j < validSignaturesCount; j++) {
            if (encounteredSigners[j] == recovered) {
                alreadyCounted = true;
                break;
            }
        }
        if (!alreadyCounted) {
            encounteredSigners[validSignaturesCount] = recovered;
            validSignaturesCount++;
        }
    }

    require(validSignaturesCount >= threshold, "Not enough valid signatures");

    // 4. Update nonce
    nonce++;

    // 5. Execute the call
    (bool success, bytes memory returnData) = _to.call{value: _value}(_data);
    require(success, "Target call failed");

    return returnData;
}
```

#### Key Subroutines

1. **Message Hash Construction**  
   ```solidity
   function getMessageHash(
       address _to,
       uint256 _value,
       bytes memory _data,
       uint256 _nonce
   ) public view returns (bytes32) {
       // Could also incorporate chainId, contract address to avoid cross-replay
       return keccak256(
           abi.encodePacked(
               address(this),
               block.chainid,
               _to,
               _value,
               _data,
               _nonce
           )
       );
   }
   ```
   - Alternatively, use EIP-712 structured data.

2. **Signature Recovery**  
   ```solidity
   function recoverSigner(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
       // 1. We might prepend "\x19Ethereum Signed Message:\n32" if using personal_sign style
       // 2. Use ecrecover to get the address
       bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_messageHash);
       return ECDSA.recover(ethSignedMessageHash, _signature);
   }
   ```
   - Or directly recover from the raw message hash if using EIP-712 domain separation.

---

### 4.4 Signer Update Flow

In the same pattern, we allow signers to update the signer set and threshold:

```solidity
function updateSigners(
    address[] calldata _newSigners,
    uint256 _newThreshold,
    uint256 _nonce,
    bytes[] calldata _signatures
) external {
    require(_nonce == nonce, "Invalid nonce");
    require(_newThreshold <= _newSigners.length && _newThreshold > 0, "Invalid threshold");

    bytes32 updateHash = getSignerUpdateHash(_newSigners, _newThreshold, _nonce);
    
    // Verify signatures
    uint256 validSignaturesCount = 0;
    address[] memory encounteredSigners = new address[](_signatures.length);

    for (uint256 i = 0; i < _signatures.length; i++) {
        address recovered = recoverSigner(updateHash, _signatures[i]);
        if (!isSigner[recovered]) {
            continue;
        }
        // Check duplicates
        bool alreadyCounted = false;
        for (uint256 j = 0; j < validSignaturesCount; j++) {
            if (encounteredSigners[j] == recovered) {
                alreadyCounted = true;
                break;
            }
        }
        if (!alreadyCounted) {
            encounteredSigners[validSignaturesCount] = recovered;
            validSignaturesCount++;
        }
    }

    require(validSignaturesCount >= threshold, "Not enough valid signatures");

    // If signatures valid, update signers
    // 1) Reset current signers
    // 2) Set new ones
    // 3) Update threshold
    // 4) Increment nonce

    // For each old signer, set isSigner[...] = false;
    // Then for each address in _newSigners:
    //    isSigner[newAddress] = true;

    // Or just remove/overwrite in a single pass
    _setNewSigners(_newSigners, _newThreshold);

    nonce++;
}

function getSignerUpdateHash(
    address[] calldata _newSigners,
    uint256 _newThreshold,
    uint256 _nonce
) public view returns (bytes32) {
    return keccak256(
        abi.encodePacked(
            address(this),
            block.chainid,
            "SIGNER_UPDATE",
            _newSigners,
            _newThreshold,
            _nonce
        )
    );
}

function _setNewSigners(address[] calldata newSigners, uint256 newThreshold) internal {
    // For example, if we keep track of signers in a dynamic array or mapping:
    // 1) Clear old signers
    // 2) Add new signers
    // 3) Update threshold

    // Pseudocode:
    // For each old signer in signersList:
    //     isSigner[oldSigner] = false;
    // Delete signersList;

    // For each s in newSigners:
    //     isSigner[s] = true;
    //     signersList.push(s);

    threshold = newThreshold;
}
```

**Important**: The message to be signed for signer updates includes a unique label (like `"SIGNER_UPDATE"`) or a function selector to differentiate it from transaction execution. This prevents an attacker from reusing a valid “executeTransaction” signature to update signers or vice versa.

---

### 4.5 Security-Specific Implementation Concerns

#### 4.5.1 Replay Protection

- We rely on `require(_nonce == nonce)` to prevent replays of the same message.  
- Each call increments `nonce` by 1.  

**Edge Case**: If multiple transactions are broadcast simultaneously for the same nonce, only one can succeed. The rest will revert with “Invalid nonce.”

#### 4.5.2 Cross-Chain Domain Separation

- Notice how `block.chainid` and `address(this)` are included in the message.  
- This means the same exact signature cannot be replayed on a different chain ID or a cloned contract.

#### 4.5.3 Duplicate Signatures

- We explicitly track which signers have been counted in `encounteredSigners`.  
- An attacker cannot supply multiple identical signatures from the same signer to inflate the count.

#### 4.5.4 Handling Malleable Signatures

- In EVM, using `ecrecover` typically requires the `(r, s, v)` format. The widely used `ECDSA` library from OpenZeppelin checks `s` is in the lower half of the secp256k1 curve to avoid malleability.  
- Or we compare addresses after recovery to ensure uniqueness. If the signature is valid but malleated, it will still map to the same signer. We only count that signer once.

#### 4.5.5 Re-entrancy

- The `executeTransaction(...)` function calls an external contract (`_to`).  
- To avoid re-entrancy, we typically structure code so that all state changes (nonce increments, checks) happen **before** the external call.  
- Use the **Checks-Effects-Interactions** pattern or standard re-entrancy guards if needed. In many multisig designs, the function updates `nonce` (and any other relevant state) before calling out, so the external contract can’t re-enter with the same nonce.

#### 4.5.6 Gas Efficiency

- Each signature check calls `ecrecover` or `ECDSA.recover()`. For large \(n\), consider:
  - A batch signature verification library.  
  - BLS threshold signature approach.  
  - A smaller set of signers or using a sub-DAO or sub-multisig pattern.  
- For small \(n\) (e.g., 5 or 7 signers), the overhead is typically acceptable.

#### 4.5.7 Event Emissions

It’s common to emit events so off-chain tools can track the multisig’s activity:

```solidity
event TransactionExecuted(address indexed by, address indexed to, uint256 value, bytes data);
event SignersUpdated(address[] newSigners, uint256 newThreshold);

...
emit TransactionExecuted(msg.sender, _to, _value, _data);
...
emit SignersUpdated(_newSigners, _newThreshold);
```

Events improve auditability and help third-party indexers detect or react to changes.

---

## Conclusion for Topic #4

The **key components** of a minimal k-of-n multisig revolve around:

1. **Data Structures**: Storing signers, threshold, and a nonce.  
2. **Transaction Execution Logic**: Verifying \(k\)-of-n signatures over a structured message, incrementing the nonce, and performing the external call.  
3. **Signer Update Logic**: Using the same signature verification flow to replace or add new signers, with careful domain separation in the message hashing.  
4. **Security Best Practices**: Include chain ID and contract address in the message hash, handle re-entrancy by updating state first, and ensure robust checking of signatures.

These **implementation details** form the backbone of most EVM-based multisig wallets. Next, we will talk in more depth about overall **Security by Design and Risk Mitigations** (Topic #5), covering how these details align with or counter specific advanced attacks from Topic #1.