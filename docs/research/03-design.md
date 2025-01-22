Below is **Topic #3** in our series: **Design Approaches and Architectural Considerations**. Here, we explore common architectural patterns for k-of-n multisig wallets, comparing them with respect to the requirements we outlined in Topic #2, and examining how each approach mitigates (or introduces) the adversarial threats from Topic #1.

---

## 3. Design Approaches and Architectural Considerations

### 3.1 High-Level Architectural Patterns

#### 3.1.1 Minimal On-Chain Logic with Off-Chain Aggregation

**Concept**  
- Every new transaction is prepared off-chain (i.e., the parameters are decided, hashed, and signed by at least \(k\) signers).
- One actor (doesn’t have to be a signer) assembles these signatures and submits them to the multisig contract, which verifies each signature and then executes the transaction if the threshold is met.
- The contract keeps only minimal state:
  1. A list/bitmap/set of authorized signer addresses.
  2. An integer threshold \(k\).
  3. A nonce to prevent replay.

**Pros**  
1. **Simplicity**: The on-chain contract stays small. This is easier to audit and reason about.  
2. **Low Storage**: There is no on-chain record of partial approvals; only the final “execute” function call needs to store or process the signatures.  
3. **Flexibility**: Signers can coordinate off-chain in any manner they like, using standard libraries or custom cryptographic solutions.

**Cons**  
1. **Higher Gas for Bulk Signatures**: If \(n\) is large, verifying many ECDSA signatures on-chain can be expensive.  
2. **No On-Chain History of Partial Approvals**: The contract does not track partial signatures, so signers must coordinate off-chain.  
3. **Potential Aggregation Vulnerability**: Whoever submits the transaction can (theoretically) reorder or omit certain signatures, though as long as it meets the threshold, this is typically not an issue.

**Security Considerations**  
- Must ensure proper nonce handling and signature domain separation to prevent replay.  
- Must prevent duplicate counting of the same signer’s signature.  
- Must robustly enforce that only signers recognized by the contract are counted.

---

#### 3.1.2 On-Chain Proposal/Approval Flow (Queued Proposals)

**Concept**  
- The contract maintains a **proposal** registry. A transaction proposal has an ID, which references:
  1. The target contract and data to be executed.
  2. The number of approvals it has so far.
  3. Which signers have already approved.
- Each signer can call `approveProposal(proposalId)` on-chain. This function records that the given signer approves.
- Once a proposal accumulates \(\ge k\) unique approvals, an on-chain function can be called to finalize/execute it.

**Pros**  
1. **Transparency**: All partial approvals are visible on-chain, so there’s no off-chain aggregator that can tamper with the list of signatures.  
2. **Async Signing**: Signers can approve at different times, removing the need for off-chain coordination in real time.  
3. **Stronger Auditability**: Anyone can see exactly who approved what proposal and when.

**Cons**  
1. **More Complex State**: Storing proposals, tracking signers who approved each, and eventually removing or archiving proposals can complicate the contract.  
2. **Higher Overall Gas Usage**: Each partial signature approval is an on-chain transaction.  
3. **State Clutter**: Over time, the contract might accumulate many “dead” proposals.

**Security Considerations**  
- Must handle concurrency and nonces for each proposal.  
- Potential for replay if proposals are not properly invalidated once executed (i.e., proposals should be single-use).  
- Must ensure signers cannot trivially re-approve a maliciously modified proposal ID or content.

---

#### 3.1.3 Threshold Cryptography (e.g., BLS, Schnorr)

**Concept**  
- Instead of having each signer produce a separate ECDSA signature, signers coordinate off-chain using a threshold scheme (e.g., BLS threshold signatures, FROST for Schnorr, etc.).
- The final on-chain submission is a single aggregated signature.  
- The contract needs only to verify one signature that mathematically proves that at least \(k\) signers participated.

**Pros**  
1. **Significant Gas Savings**: Only one signature verification step on-chain.  
2. **Cleaner On-Chain Logic**: The contract sees a single proof, and either it’s valid (k-of-n) or it’s not.  
3. **Improved Privacy**: On-chain, you do not necessarily learn which subset of signers approved, only that at least \(k\) did.

**Cons**  
1. **Complex Off-Chain Setup**: Threshold cryptography requires more sophisticated key generation, multi-party computations, and protocols that are not as widely adopted in typical Ethereum stacks.  
2. **Library Support**: Solid BLS or Schnorr threshold libraries must be available on your target chain.  
3. **Upgradability**: Changing signer sets or re-sharing keys can be more complicated when dealing with advanced cryptography.

**Security Considerations**  
- Must ensure secure multi-party key generation.  
- If the threshold cryptography library has undiscovered vulnerabilities, that can be catastrophic.  
- Harder to debug or audit, given the specialized cryptographic code.

---

### 3.2 Decision Criteria for Approach Selection

1. **Complexity vs. Security**:  
   - Minimal on-chain logic is easiest to review, but might lead to higher gas costs or weaker on-chain traceability.  
   - On-chain proposals are more intuitive from an auditing perspective but increase contract surface area.

2. **Size of Signer Set**:  
   - For small \(n\) (e.g., 5 or 7), verifying multiple ECDSA signatures on-chain is not prohibitive.  
   - For larger \(n\) (20, 50, 100+), the gas cost for verifying each signature might push one toward threshold cryptography.

3. **Frequency of Transactions**:  
   - If the multisig rarely executes transactions, a simpler approach (like minimal on-chain logic) may suffice.  
   - If transactions happen often, repeated signature verifications can be expensive, nudging us toward more sophisticated solutions.

4. **User Experience**:  
   - Off-chain coordination might be simpler for technical teams already comfortable with bundling signatures.  
   - If signers are less technical, an on-chain proposal system might be more user-friendly (each signer just “logs on” and clicks “approve”).

5. **Cross-Chain Requirements**:  
   - If we need signatures to be recognized on multiple chains, or if signers operate in different ecosystems, there might be specialized bridging or aggregator logic.  
   - Some bridging solutions (e.g., Axelar) already incorporate threshold cryptography at the protocol level, so it might be redundant or beneficial to align with that approach.

---

### 3.3 Architectural Patterns for Updating Signers

Regardless of which high-level approach is taken for transaction execution, there is also a question of **how** to manage signers. Typically, we see two patterns:

1. **Same Flow as Transaction Execution**  
   - The same function (or a parallel function) that executes transactions is used to update signers.  
   - It requires a k-of-n signature over the new signer set + new threshold.  

2. **Separate “Governance” Module**  
   - The contract might have separate states/logic for normal “transaction execution” vs. “governance updates.”  
   - Each has its own nonce or ID to track proposals.  
   - This can be beneficial if updates are rare or require more signers than normal transactions (e.g., a 4-of-5 for normal transactions but 5-of-5 for changing signers).

**Considerations**  
- The core principle is the same: we must ensure that at least \(k\) existing signers approve any change to the signer set.  
- We must ensure that the new threshold does not become invalid (e.g., larger than the number of signers, or zero).  
- We should be mindful of incremental updates that could let a malicious subset gradually replace enough signers to seize control (Topic #1 “Gradual Signer Replacement Attack”).

---

### 3.4 Data Structures for Signers

**Arrays vs. Mappings vs. Sets** (in EVM, for instance):

1. **Array**  
   - Pro: Easy to iterate over signers, straightforward to store.  
   - Con: Checking membership (to see if an address is an authorized signer) requires a loop or an auxiliary structure.

2. **Mapping (address => bool)**  
   - Pro: O(1) membership check.  
   - Con: Harder to iterate over all signers, you need to store an additional array or counters to keep track of the total count and enumerations.

3. **Mapping + Array**  
   - A hybrid approach: store signers in an array for iteration, and also store `(address => bool)` for membership checks. This is typical in Gnosis Safe–like designs.

For threshold cryptography, the *contract* might just need to store a single “public key” or “group public key,” so data structures become simpler on-chain, but the complexity moves off-chain.

---

### 3.5 Additional Architectural Enhancements

1. **Time Locks**  
   - Provide an optional waiting period after \(\ge k\) signatures are submitted before the transaction executes. Allows watchers to veto or withdraw (if that’s part of the design) in case of malicious proposals.

2. **Spending Limits**  
   - Some multisig designs (like Gnosis Safe) let you set daily/monthly spend limits that can be executed with fewer than \(k\) signers, but require full \(k\)-of-\(n\) for larger amounts.

3. **Meta-Transactions and Relayers**  
   - Signers might prefer not to pay gas. A relayer can collect the signatures off-chain and pay the gas to submit the final transaction.  

4. **Role-Based/Weighted Threshold**  
   - Instead of a simple “1 signer = 1 vote,” advanced designs weigh different signers differently. Or they introduce roles (e.g., “At least 2 dev signers and 1 legal signer”). This adds complexity and potential new bugs.

---

### 3.6 Cross-Chain Architectural Considerations

For protocols like **Axelar/Interop Labs** that handle cross-chain messaging, the architectural design might look different:

- **Signature Aggregation Off-Chain**: Axelar itself often uses a threshold scheme to sign cross-chain messages. You might integrate your multisig logic with their aggregator, so you only verify one Axelar “gateway signature” on your chain.  
- **Multi-Chain Deployment**: If you deploy the same multisig logic on multiple chains, you must ensure the signer set and threshold are kept in sync—or intentionally not, if each chain has different signer requirements.  
- **Bridged Governance**: If the “main” governance is on one chain, you might require cross-chain messages to update the signer set on another chain. This might require an additional bridging contract or protocol-level trust assumptions.

---

### 3.7 Matching the Architecture to the Threat Landscape

Recalling the advanced attacker perspective (Topic #1), each architectural approach offers different strengths and weaknesses:

- **Minimal On-Chain + Off-Chain Aggregation**:  
  - Attackers might try to reorder or maliciously combine signatures off-chain. However, if the final submission is correct (k valid signers, correct nonce), the contract is safe. It’s crucial to embed the chain ID and contract address in the message to prevent cross-chain or cross-contract replay.  

- **On-Chain Proposal System**:  
  - Attackers have fewer avenues to tamper with off-chain data because partial approvals are recorded on-chain as they happen. But new vectors may arise from concurrency or from malicious signers repeatedly approving/revoking proposals to spam the system.

- **Threshold Cryptography**:  
  - Attackers face a high cryptographic barrier if the library is solid, but if the threshold system is compromised off-chain (key generation or aggregator code), the chain sees only a single signature.  
  - In cross-chain contexts, bridging that aggregated signature might be simpler, but also centralizes risk in the single aggregator code.

In any case, the design must thoroughly handle nonce management, signer updates, domain separation, and boundary checks on the threshold.

---

### 3.8 Conclusion of Design Approaches

Each of these designs can fulfill the **core requirements**—they just do so with different tradeoffs in complexity, gas cost, and reliability. For most typical EVM-based use cases with moderate \(n\), a **minimal on-chain approach** or **on-chain proposal approach** with standard ECDSA checks is the simplest and most commonly used pattern (e.g., Gnosis Safe, which uses a queued proposal concept combined with an off-chain aggregator). For specialized high-performance or large \(n\) use cases, a **threshold cryptography** approach could be compelling.

---

## Next Topic

We’ll move on to **Topic #4: Key Components and Implementation Details**, where we’ll outline how these architectural choices translate into actual contract structures, data layouts, and function flows (including pseudo-code examples). We’ll also pay close attention to implementation-level security, such as how to properly compute and verify message hashes, how to track nonces, and how to store signers in the contract.