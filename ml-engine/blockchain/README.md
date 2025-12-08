# Ethereum Blockchain Integration for TourGuard

This module provides Ethereum-based permissioned blockchain functionality for storing user identity hash IDs.

## Features

- Store registration hash on blockchain after user sign-up
- Store login hash on blockchain after user login
- Verify hash existence on blockchain
- Query user records and global statistics
- Permissioned access control (only authorized nodes can write)

## Quick Start

### 1. Install Dependencies

```bash
cd ml-engine
pip install -r requirements.txt
```

### 2. Start Ganache (Local Ethereum)

**Option A: Ganache GUI**
Download from https://trufflesuite.com/ganache/ and start it.

**Option B: Ganache CLI**
```bash
npm install -g ganache
ganache
```

Default RPC: `http://127.0.0.1:8545`

### 3. Deploy the Smart Contract

```bash
cd ml-engine
python -m blockchain.deploy
```

This will:
- Compile `TourGuardIdentity.sol`
- Deploy to the network
- Save the contract address to `blockchain/deployment_info.json`

### 4. Configure Environment

Create `.env` file from the example:
```bash
cp .env.example .env
```

Update `ETH_CONTRACT_ADDRESS` with the deployed contract address.

### 5. Start the ML Engine

```bash
uvicorn app.main:app --reload --port 8082
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/blockchain/health` | Check blockchain connection |
| POST | `/blockchain/register` | Store registration hash |
| POST | `/blockchain/login` | Store login hash |
| GET | `/blockchain/verify/{hash}` | Verify hash exists |
| GET | `/blockchain/user/{id}/records` | Get user's records |
| GET | `/blockchain/stats` | Get global statistics |

## Example Usage

### Store Registration Hash
```bash
curl -X POST http://localhost:8082/blockchain/register \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "email": "user@example.com",
    "phone": "+919876543210",
    "name": "John Doe"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Registration recorded on blockchain",
  "hash_id": "0x1234...abcd",
  "tx_hash": "0xabcd...1234",
  "block_number": 42
}
```

### Verify Hash
```bash
curl http://localhost:8082/blockchain/verify/0x1234...abcd
```

**Response:**
```json
{
  "exists": true,
  "hash_id": "0x1234...abcd",
  "message": "Hash verified"
}
```

## Network Configuration

### Ganache (Development)
```env
ETH_RPC_URL=http://127.0.0.1:8545
ETH_CHAIN_ID=1337
ETH_IS_POA=false
```

### Polygon Mumbai (Testnet)
```env
ETH_RPC_URL=https://rpc-mumbai.maticvigil.com
ETH_CHAIN_ID=80001
ETH_IS_POA=true
```

### Polygon Mainnet (Production)
```env
ETH_RPC_URL=https://polygon-rpc.com
ETH_CHAIN_ID=137
ETH_IS_POA=true
```

## Smart Contract

The `TourGuardIdentity.sol` contract provides:

- **Permissioned Access**: Only authorized nodes can write
- **Hash Storage**: Stores registration and login hashes
- **Verification**: Check if a hash exists
- **User Records**: Query user's activity history
- **Statistics**: Global registration/login counts

## Flutter Integration

The Flutter app automatically calls the blockchain API:

1. **On Sign Up**: Stores registration hash
2. **On Login**: Stores login hash
3. **Hash stored in Firestore**: `blockchainHashId` field

## Troubleshooting

### "Contract not deployed"
Run `python -m blockchain.deploy` and set `ETH_CONTRACT_ADDRESS`.

### "Not connected to blockchain"
Check that Ganache is running and `ETH_RPC_URL` is correct.

### "Insufficient funds"
Ensure the account has ETH for gas. Ganache provides 100 ETH by default.
