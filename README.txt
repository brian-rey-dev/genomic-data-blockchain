# Problem: "Genetic Data Storage & Access Control"

In the biotech world, managing and securing genetic data is a major concern. For this challenge, you're going to create a smart contract that allows researchers to store and access genetic data in a decentralized, secure way. But there’s a twist:

---

**Problem Statement:**

Design a Solidity contract that allows **researchers** to upload genetic sequences associated with unique IDs (like patient IDs) to a decentralized registry. Only **authorized researchers** can upload and retrieve data, while the **patients** (or their representatives) should have control over who can access or view their genetic information. Here's the breakdown:

- **Researchers** can:
  - Request to be authorized to access genetic data.
  - Upload genetic data (as a string) associated with unique patient IDs once authorized.
  - Retrieve genetic data only if they are authorized by the respective patient.

- **Patients** (or their representatives) can:
  - Approve or reject researcher access requests.
  - View the history of access requests and approvals.

**Constraints and Considerations:**
1. **Data Size**: Genetic sequences can be large. You need to think about how to handle this efficiently on the blockchain (hint: you probably don’t want to store the full sequence on-chain but only references).
   
2. **Access Control**: Only patients or their representatives can approve or deny access to their data. How would you structure permissions? How do you ensure researchers don't see data they aren’t allowed to?

3. **Security**: What happens if a patient accidentally approves access to the wrong researcher? How will you design a revocation system?

4. **Edge Cases**:
   - What happens if a researcher is no longer authorized but tries to upload or retrieve data?
   - How do you handle duplicate data submissions?
   - How will you manage large data associated with patients efficiently (hint: off-chain storage, IPFS)?
   
5. **Gas Costs**: Think about optimizing the contract to reduce unnecessary gas costs, especially in terms of managing access lists, approvals, and data pointers.

6. **Upgradeable**: As a bonus, consider how you could make this contract upgradeable in the future, as the way genetic data is managed may evolve over time.

---

### Hints to Guide Your Thinking:
- **Mappings & Structs**: Think about how mappings could be used to manage researcher access and patient data.
- **Modifiers**: You'll want to enforce access control. Modifiers might help ensure only certain users (researchers, patients) can call specific functions.
- **Events**: Consider using events to track when access is requested, granted, or revoked.
- **Storage Optimization**: Use external storage mechanisms for genetic data, such as IPFS or a decentralized file storage solution, and store only references in the contract.
- **Calldata vs. Storage**: Think about when you need to pass data around efficiently and avoid unnecessarily large variables in storage.

### Extra Challenges:
- **Time-based Access**: What if access should expire after a certain period? How would you implement a system where access permissions automatically revoke after a time limit?
  
- **Emergency Revoke**: What if a patient wants to revoke access for all researchers immediately? How would you design that functionality?