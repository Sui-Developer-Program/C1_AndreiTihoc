# Gratuity Box Smart Contract

A Sui Move smart contract that enables direct "gratuity" payments. Funds are forwarded immediately to the owner's wallet while maintaining lightweight statistics on a shared object.

## 📋 Prerequisites

- Sui CLI - [Installation Guide](https://docs.sui.io/guides/developer/getting-started/sui-install)
- Testnet SUI tokens - [Get from Faucet](https://faucet.sui.io/)

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd tip_jar_contract
```

### 2. Build Contract
```bash
sui move build
```

### 3. Run Tests
```bash
sui move test
```

All tests should pass ✅

### 4. Deploy to Testnet
```bash
sui client publish --gas-budget 20000000
```

### 5. Save Important Information
After deployment, note down:
- **Package ID**: Required for frontend integration
- **GratuityVault Object ID**: The shared object ID from deployment
- **Owner Address**: Your wallet address that will receive tips

## 📦 Contract Features

- **Direct Transfers**: Gratuities go immediately to owner
- **Statistics Tracking**: Total, count, and last tipper
- **Event Emission**: Creation and deposit events
- **Input Validation**: Ensures non-zero amounts
- **Owner Controls**: Reset counts admin utility
- **Shared Object**: Concurrent access for multiple users

## 🧪 Test Coverage

The contract includes comprehensive tests:
- Contract bootstrap (creation)
- Basic gratuity deposit
- Multiple user interactions
- Input validation (zero amount rejected)
- Event emission verification
- Statistical accuracy and snapshot
- Edge cases (large/minimal amounts)

## 🔧 Integration

After deployment, use the Package ID and GratuityVault Object ID in your frontend application to enable sending gratuities.

## 📚 Learn More

This contract demonstrates key Sui Move concepts:
- One-time witness pattern
- Shared objects
- Direct transfers
- Event emission
- Entry functions

---

Part of the Sui Development Workshop series