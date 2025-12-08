"""
TourGuard Blockchain Explorer
Shows blocks and hash IDs from user registrations/logins
"""
from web3 import Web3
import json
from pathlib import Path
from dotenv import load_dotenv
import os

# Load environment
load_dotenv(Path(__file__).parent / ".env")

# Connect to Ganache
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))

if not w3.is_connected():
    print("[X] Not connected to blockchain. Make sure Ganache is running.")
    exit(1)

# Load contract ABI
abi_path = Path(__file__).parent / "blockchain" / "TourGuardIdentity.abi.json"
if abi_path.exists():
    with open(abi_path) as f:
        abi = json.load(f)
else:
    print("[X] Contract ABI not found. Deploy the contract first.")
    exit(1)

# Get contract address
contract_address = os.getenv("ETH_CONTRACT_ADDRESS")
if not contract_address:
    print("[X] Contract address not set. Check .env file.")
    exit(1)

contract = w3.eth.contract(
    address=Web3.to_checksum_address(contract_address),
    abi=abi
)

print("=" * 70)
print("TOURGUARD BLOCKCHAIN EXPLORER")
print("=" * 70)
print(f"Contract: {contract_address}")
print(f"Network:  http://127.0.0.1:8545")

# Get blockchain stats
latest_block = w3.eth.block_number
print(f"\n[+] Total Blocks: {latest_block + 1}")

# Show all blocks with transactions
print("\n" + "-" * 70)
print("BLOCKS WITH REGISTRATION/LOGIN TRANSACTIONS")
print("-" * 70)

for block_num in range(latest_block + 1):
    block = w3.eth.get_block(block_num, full_transactions=True)
    
    if len(block['transactions']) > 0:
        print(f"\n[BLOCK {block_num}]")
        print(f"  Block Hash: {block['hash'].hex()}")
        print(f"  Timestamp:  {block['timestamp']}")
        
        for tx in block['transactions']:
            tx_hash = tx['hash'].hex()
            print(f"\n  [TX] {tx_hash}")
            print(f"       From: {tx['from']}")
            print(f"       To:   {tx['to']}")
            print(f"       Gas:  {tx['gas']}")
            
            # Get transaction receipt for logs
            receipt = w3.eth.get_transaction_receipt(tx['hash'])
            
            # Decode events
            for log in receipt['logs']:
                try:
                    # Check for RegistrationRecorded event
                    if log['topics'][0].hex() == w3.keccak(text="RegistrationRecorded(bytes32,bytes32,uint256,string)").hex():
                        hash_id = "0x" + log['data'][2:66]
                        print(f"       [EVENT] REGISTRATION")
                        print(f"       Hash ID: {hash_id}")
                    # Check for LoginRecorded event
                    elif log['topics'][0].hex() == w3.keccak(text="LoginRecorded(bytes32,bytes32,uint256,string)").hex():
                        hash_id = "0x" + log['data'][2:66]
                        print(f"       [EVENT] LOGIN")
                        print(f"       Hash ID: {hash_id}")
                except:
                    pass

print("\n" + "=" * 70)
print("HOW TO MATCH HASH IDs:")
print("=" * 70)
print("""
1. Register/Login in the TourGuard app
2. Check the console logs for:
   [Auth] Registration recorded on blockchain: 0x...
   
3. The hash_id in the logs should match the Hash ID in the blocks above

4. You can also check the user's profile in Firestore:
   - Field 'blockchainHashId' contains the same hash

5. Use the API to verify:
   GET http://localhost:8082/blockchain/user/{user_id}/records
""")
