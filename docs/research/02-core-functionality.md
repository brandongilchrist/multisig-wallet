Below is our **Topic #2** in the walkthrough: **Core Functionalities and Requirements**. We’ll dive deeply into the essential building blocks (transaction execution, signer management, threshold logic) and how these requirements shape the final contract. We’ll also highlight how these functionalities might be extended or adapted in a cross-chain context.

---

## 2. Core Functionalities and Requirements

### 2.1 Basic Multisig Mechanism

At its core, a **multisig** (multi-signature) contract enforces that a subset \(k\) out of \(n\) designated signers must approve any state-changing action. For a typical on-chain environment:

1. **Threshold \(k\)**: The number of signatures required.  
2. **Signer Set \(\{S_1, S_2, \dots, S_n\}\)**: The addresses (or public keys, depending on the chain) that are authorized to sign.  
3. **Nonce**: A monotonically increasing counter used to avoid replay attacks.

**Minimum Requirement**: The contract must not allow execution (of some payload) unless \(\ge k\) valid signatures from unique signers are supplied.

#### Why a Threshold?
- **Security**: No single signer alone should be able to unilaterally move assets or alter the contract’s state.  
- **Redundancy**: The design tolerates losing or compromising a fraction of private keys, as long as at most \(k-1\) are compromised.  
- **Governance**: It embodies a form of consensus—decisions get executed only if they meet the required level of trust.

---

### 2.2 Transaction Execution

A key feature for a multisig is the ability to execute **arbitrary** actions on other contracts:

1. **Target Contract**: The address of the contract (or EOA) to be called.  
2. **Call Data**: Encoded function name and parameters for the target (e.g., `abi.encodeWithSignature(...)` in Solidity).  
3. **Value**: The amount of native token (e.g., Ether in Ethereum) to send with the call, if applicable.  
4. **Nonce**: An on-chain nonce that must match the expected value in the contract’s state.

**Execution Flow**:
1. Gather signatures off-chain from at least \(k\) signers over a **message** (consisting of `target`, `value`, `callData`, `nonce`, and potentially the chain ID and the contract address).  
2. Anyone can submit these signatures on-chain via `executeTransaction(...)`.  
3. The contract verifies that:
   - The nonce is correct.  
   - Each signature is valid (correct signer, no duplication).  
   - The total count of unique valid signers \(\ge k\).  
4. If all checks pass, the contract executes the function call (`(bool success, ) = target.call{value: _value}(_data)`).  
5. The contract increments its nonce to prevent replay of the same signatures in the future.

**Core Requirement**: The user can call **any** method on **any** contract, as long as the threshold of signatures is met.

---

### 2.3 Signer Set Updates

Multisig is not just about day-to-day transaction approvals—it also needs an upgrade path for:

- **Replacing / Adding Signers**: If a signer loses their key or if the organization wants new signers.  
- **Removing Signers**: If a signer becomes untrusted or leaves the organization.  
- **Updating Threshold**: If the security or operational needs change (e.g., from 3-of-5 to 4-of-7).

**Update Flow**:
1. The new signer set (and new threshold, if needed) is proposed off-chain.  
2. The existing \(n\) signers produce signatures approving the update. At least \(k\) of them must sign for it to pass.  
3. A transaction is submitted on-chain (e.g., `updateSigners(...)`), verifying the signatures just like a normal transaction.  
4. If successful, the contract updates its internal records (`signers`, `threshold`, etc.).  
5. The nonce is incremented (or a separate nonce for “governance” updates, depending on the design).

**Core Requirement**: The same threshold logic and off-chain signing method used for executing normal transactions must also be used for updating signers, ensuring no single party can unilaterally alter the signer set.

---

### 2.4 Additional Security Requirements

Beyond these two primary actions (execute transactions and update signers), the following are critical for a robust multisig solution:

1. **Replay Protection**  
   - **Global Nonce**: Ensures each transaction can only be executed once.  
   - **Chain ID & Contract Address**: Embedded into the message hash so signatures can’t be replayed across chains or different contracts.

2. **Uniqueness of Signatures**  
   - Each signer’s address can only be counted once per transaction.  
   - Malleable signatures (if any) must not break the threshold count (e.g., the same signer producing multiple slightly different signatures).

3. **Boundary Checks on Threshold**  
   - \(k\) must never be 0 or more than the current number of signers.  
   - New signers must be validated (e.g., no duplicates, and addresses are formatted correctly).

4. **Failure Modes**  
   - If \(\ge k\) signers do not agree, the transaction or signer update must fail cleanly.  
   - Avoid partial states or “limbo” states (atomicity of on-chain execution ensures that either the entire operation succeeds or is reverted).

5. **Cross-Chain / Cross-Contract Safety**  
   - If the contract is used in a cross-chain environment (e.g., Axelar, Cosmos, Solana bridging), the signature domain **must** include the correct chain ID or other unique identifier to prevent replay across chains.  
   - The contract might also consider a time-lock or other gating mechanism if cross-chain confirmations are needed.

---

### 2.5 Non-Functional Requirements

In addition to the “must-have” functionalities above, there are **non-functional requirements** that can drastically affect real-world usability and security:

1. **Gas Efficiency** (on EVM or similar blockchains)  
   - The cost of verifying multiple signatures can be high. Implementation details (e.g., using `ecrecover` vs. a precompile vs. BLS aggregation) can be critical.  

2. **Usability for Signers**  
   - Off-chain signing flows should be clear, ideally using standardized typed data (e.g., EIP-712).  
   - Key rotations or updates should not be overly complex.

3. **Scalability**  
   - If \(n\) is large, verifying all signatures on-chain becomes expensive. Solutions might explore threshold cryptography or rolling committees.

4. **Maintainability**  
   - The system should be designed so that updates to signers or threshold do not require a full contract migration, if possible.

5. **Auditability and Transparency**  
   - The contract’s code should be clear and easily audited.  
   - Every signer update or transaction execution is permanently recorded on-chain.

---

### 2.6 Typical Use Cases

Below are common scenarios that illustrate why these functionalities are essential:

1. **Project Treasury Management**  
   - A DeFi protocol or DAO wants to secure its treasury, requiring multiple core contributors to sign off on large transfers or contract interactions.

2. **Cross-Chain Governance**  
   - A multi-chain system that needs consistent control or upgrade keys across multiple blockchains. A single on-chain multisig can be used to manage bridging operations, but signers may be distributed globally, adding the requirement for strong cross-chain replay protections.

3. **Upgrade Keys for Smart Contracts**  
   - Some protocols have upgradeable contracts, with an admin key that can upgrade or pause the system. Instead of a single EOA holding that key, the admin key is replaced by a k-of-n multisig contract for shared governance.

4. **Decentralized Team Management**  
   - Multiple co-founders or partners hold shares of control. The contract enforces collaborative decision-making (e.g., no single co-founder can drain funds).

---

### 2.7 Cross-Chain Implications (Particularly for Axelar / Interop Labs)

Given the assignment’s context—**Axelar / Interop Labs**—the system must handle or be aware of cross-chain messaging and bridging:

1. **Message Format**: Signers might sign “execute transaction on chain A,” but the result is validated on chain B. Ensure domain separation (chain ID, contract address, and possibly a unique domain string) is always included in the message hash.  
2. **Trusted vs. Trustless Bridges**: If the bridging layer itself is trusted, the main threat is a compromise of that bridging system. If it’s trustless, the multisig might need an additional Oracle check.  
3. **Atomic Updates**: If the multisig signers are updated on chain A, do we also need a mechanism to update signers on chain B? This can be done by replicating updates or letting the new set sign a chain B update.  
4. **Time Delays**: Some cross-chain flows insert finality delays. The multisig design might incorporate waiting periods before finalizing an action that impacts multiple chains.

---

### 2.8 Summary of Core Requirements

1. **Multisig Execution**:  
   - Enforce \(k\)-of-\(n\) signature checks on any arbitrary transaction.  
   - Use secure replay protection (nonce, chain ID).  
   - Count only unique valid signers.

2. **Signer/Threshold Updates**:  
   - Same \(k\)-of-\(n\) logic to update the signing group.  
   - Bound checks on threshold vs. number of signers.

3. **Security Considerations**:  
   - Prevent replay, signature malleability, re-entrancy, and other classical attacks.  
   - Factor in cross-chain pitfalls (replay across chains, bridging illusions, etc.).

4. **Non-Functional**:  
   - Gas efficiency, usability, maintainability, auditability.

With these core functionalities and requirements established, we have a comprehensive framework that covers what the multisig **must** do, how it **must** behave, and the basic constraints it must respect.

---

### Next Topic

Moving forward, we will discuss **Design Approaches and Architectural Considerations** (Topic #3). We’ll dive into high-level strategies (e.g., minimal on-chain logic, queued proposals, threshold cryptography) and how they fulfill or refine the requirements we’ve just outlined. We’ll also tie back to the adversarial perspective: how each architectural choice mitigates or introduces different risks.