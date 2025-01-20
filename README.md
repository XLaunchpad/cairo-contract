# XLaunchpad Contract

This repository contains the **XLaunchpad Contract**, a powerful StarkNet-based solution for launching and managing NFTs across Layer 1 (Ethereum) and Layer 2 (StarkNet) networks. The contract is equipped with features to deploy ERC-721 and ERC-1155 NFTs, facilitate cross-chain communication, and ensure upgradability.

---

## 📍 Contract Details

- **Network**: Sepolia Testnet (StarkNet)
- **Contract Address**: `0x903caa0048aa69211903a530960020f63742ed2489e4bcc9e0a5c38aa52fec`
- **Explorer Link**: [StarkScan - XLaunchpad Contract](https://sepolia.starkscan.co/contract/0x903caa0048aa69211903a530960020f63742ed2489e4bcc9e0a5c38aa52fec) or [Voyager](https://sepolia.voyager.online/contract/0x00903caa0048aa69211903a530960020f63742ed2489e4bcc9e0a5c38aa52fec)

---

## 🛠 Features

### 🚀 NFT Launchpad
- **Launch NFTs on StarkNet**:
  - Deploy ERC-721 and ERC-1155 NFTs with custom metadata (name, symbol, URI).
  - Owner-controlled contract ensures secure NFT creation.

### 🌉 Cross-Chain Compatibility
- **From Ethereum to StarkNet**:
  - Launch NFTs on StarkNet via L1-L2 messaging.
  - Automatically maps Ethereum NFT addresses to their StarkNet counterparts.
- **From StarkNet to Ethereum**:
  - Send messages back to Ethereum to synchronize NFT states.

### 🏗️ Modular Design
- Built with OpenZeppelin Contracts for StarkNet, ensuring robustness and compatibility.
- Fully **Upgradeable**: Future-proof with an upgrade mechanism for contract improvements.

### 🔒 Access Control
- **Owner Control**: Only the contract owner can update configurations or trigger upgrades.
- **L1 Address Validation**: Ensures cross-chain operations originate from the specified L1 address.

---

## 📚 Key Components

### Core Logic
- **NFT Deployment**:
  - Utilizes pre-defined class hashes for ERC-721 and ERC-1155 standards.
  - Ensures deployed NFTs inherit desired properties and behavior.
- **L1-L2 Mapping**:
  - Maintains a bidirectional mapping of Ethereum and StarkNet NFT addresses.
  - Enables seamless interoperability between layers.

### Contract Interfaces
- **IERC721xETHDispatcher** and **IERC1155xETHDispatcher**:
  - Interfaces for interacting with deployed ERC-721 and ERC-1155 contracts.
- **IUpgradeable**:
  - Provides an upgrade interface for owner-controlled class hash updates.

### Events
- **NFTLaunchedOnSN**:
  - Logs NFT deployments on StarkNet.
- **NFTLaunchedFromETH**:
  - Tracks NFTs launched from Ethereum with both L1 and L2 addresses.

---

## 🔗 Interaction Guide

### Deploying the Contract
1. **Prerequisites**:
   - Ensure a StarkNet wallet is funded with test tokens for deployment.
   - Use StarkNet-compatible tools (e.g., StarkNet CLI, StarkNet.js).

2. **Constructor Parameters**:
   - `owner`: The address of the contract owner.

### Launching NFTs
#### On StarkNet
- Call `launch_x_nft` with:
  - `name`: Name of the NFT.
  - `symbol`: Symbol of the NFT.
  - `uri`: Metadata URI.
  - `nft_type`: `ERC721` or `ERC1155`.

#### From Ethereum
- Use the `launch_x_nft_from_eth` L1 handler to:
  - Deploy NFTs on StarkNet.
  - Establish the L1-L2 mapping.

---

## ⚙️ Developer Notes

### Upgradeable Contract
- The contract leverages OpenZeppelin's `UpgradeableComponent` for upgradability.
- Use the `upgrade` function to apply a new class hash.

### Security
- **Access Control**:
  - Critical functions are restricted to the contract owner.
  - Cross-chain operations are validated against the configured L1 address.

- **Error Handling**:
  - Assertions ensure invalid operations (e.g., unauthorized calls) are rejected.

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE).

---

Feel free to contribute, raise issues, or suggest improvements! 🚀