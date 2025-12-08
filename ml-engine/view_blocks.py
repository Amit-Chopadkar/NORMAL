"""
View Blockchain Blocks and Transactions
"""
from web3 import Web3

# Connect to Ganache
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))

if not w3.is_connected():
    print("[X] Not connected to blockchain. Make sure Ganache is running.")
    exit(1)

print("=" * 60)
print("ETHEREUM BLOCKCHAIN EXPLORER")
print("=" * 60)

# Block info
latest_block = w3.eth.block_number
print(f"\n[*] Latest Block Number: {latest_block}")

# List blocks
print("\n=== BLOCKS ===")
for i in range(min(latest_block + 1, 10)):  # Show up to 10 blocks
    block = w3.eth.get_block(i)
    tx_count = len(block['transactions'])
    print(f"Block {i}: {tx_count} transaction(s) | Hash: {block['hash'].hex()[:16]}...")

# Accounts
print("\n=== ACCOUNTS ===")
accounts = w3.eth.accounts
for i, acc in enumerate(accounts[:5]):
    balance = w3.from_wei(w3.eth.get_balance(acc), 'ether')
    print(f"{i+1}. {acc}: {balance:.4f} ETH")

# Recent transactions
print("\n=== RECENT TRANSACTIONS ===")
for block_num in range(max(0, latest_block - 5), latest_block + 1):
    block = w3.eth.get_block(block_num, full_transactions=True)
    for tx in block['transactions']:
        print(f"Block {block_num} | TX: {tx['hash'].hex()[:16]}... | From: {tx['from'][:10]}...")

print("\n" + "=" * 60)
print("To see more details, use Ganache GUI or the API endpoints")
print("API: http://localhost:8082/blockchain/stats")
print("=" * 60)
