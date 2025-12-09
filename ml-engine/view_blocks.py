#!/usr/bin/env python3
"""
TourGuard Blockchain Block Viewer
Displays detailed blockchain information including blocks, transactions, and TourGuard statistics.
"""

from web3 import Web3
from datetime import datetime
import sys
from pathlib import Path

# Add parent directory to path for blockchain module
sys.path.insert(0, str(Path(__file__).parent))

try:
    from blockchain.ethereum_service import get_ethereum_service
    USE_SERVICE = True
except ImportError:
    USE_SERVICE = False


def format_timestamp(timestamp):
    """Convert Unix timestamp to readable format."""
    return datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')


def print_separator(char="=", length=80):
    """Print a separator line."""
    print(char * length)


def display_block_details(w3, block_num):
    """Display detailed information about a specific block."""
    block = w3.eth.get_block(block_num, full_transactions=True)
    
    print(f"\n{'='*80}")
    print(f"BLOCK #{block_num}")
    print(f"{'='*80}")
    print(f"Hash:          {block.hash.hex()}")
    print(f"Parent Hash:   {block.parentHash.hex()}")
    print(f"Timestamp:     {format_timestamp(block.timestamp)}")
    print(f"Miner:         {block.miner}")
    print(f"Gas Limit:     {block.gasLimit:,}")
    print(f"Gas Used:      {block.gasUsed:,} ({block.gasUsed/block.gasLimit*100:.1f}%)")
    print(f"Transactions:  {len(block.transactions)}")
    
    # Display transaction details
    if len(block.transactions) > 0:
        print(f"\n{'-'*80}")
        print("TRANSACTIONS:")
        print(f"{'-'*80}")
        
        for i, tx in enumerate(block.transactions, 1):
            print(f"\n  Transaction #{i}")
            print(f"  Hash:      {tx.hash.hex()}")
            print(f"  From:      {tx['from']}")
            print(f"  To:        {tx.to if tx.to else '(Contract Creation)'}")
            print(f"  Value:     {w3.from_wei(tx.value, 'ether')} ETH")
            print(f"  Gas:       {tx.gas:,}")
            print(f"  Gas Price: {w3.from_wei(tx.gasPrice, 'gwei')} Gwei")
            
            # Get receipt for status and gas used
            try:
                receipt = w3.eth.get_transaction_receipt(tx.hash)
                status_icon = "✓" if receipt.status == 1 else "✗"
                print(f"  Status:    {status_icon} {'Success' if receipt.status == 1 else 'Failed'}")
                print(f"  Gas Used:  {receipt.gasUsed:,}")
                
                if receipt.contractAddress:
                    print(f"  Contract:  {receipt.contractAddress}")
                
                if receipt.logs:
                    print(f"  Events:    {len(receipt.logs)} event(s) emitted")
                    for j, log in enumerate(receipt.logs[:3], 1):  # Show first 3 events
                        print(f"    Event {j}: {len(log.topics)} topic(s)")
            except Exception as e:
                print(f"  Receipt:   Error - {str(e)}")


def main():
    """Main function."""
    # Connect to blockchain
    w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
    
    if not w3.is_connected():
        print("\n❌ Not connected to blockchain")
        print("   Make sure Ganache is running on http://127.0.0.1:8545")
        return
    
    print_separator()
    print("TOURGUARD BLOCKCHAIN EXPLORER")
    print_separator()
    
    # Network info
    latest_block = w3.eth.block_number
    print(f"\n✓ Connected to blockchain")
    print(f"  Chain ID:      {w3.eth.chain_id}")
    print(f"  Latest Block:  #{latest_block}")
    print(f"  Total Blocks:  {latest_block + 1}")
    
    # Account balances
    print(f"\n{'='*80}")
    print("ACCOUNTS")
    print(f"{'='*80}")
    accounts = w3.eth.accounts
    for i, acc in enumerate(accounts[:5], 1):
        balance = w3.from_wei(w3.eth.get_balance(acc), 'ether')
        print(f"{i}. {acc}: {balance:.6f} ETH")
    
    # Display all blocks
    print(f"\n{'='*80}")
    print("BLOCKCHAIN BLOCKS")
    print(f"{'='*80}")
    
    for block_num in range(latest_block + 1):
        display_block_details(w3, block_num)
    
    # TourGuard statistics (if service is available)
    if USE_SERVICE:
        try:
            service = get_ethereum_service()
            if service.is_connected:
                stats = service.get_global_stats()
                
                print(f"\n{'='*80}")
                print("TOURGUARD STATISTICS")
                print(f"{'='*80}")
                print(f"\nContract:      {service.config.contract_address or 'Not deployed'}")
                print(f"Total Users:   {stats.get('total_users', 0)}")
                print(f"Registrations: {stats.get('total_registrations', 0)}")
                print(f"Logins:        {stats.get('total_logins', 0)}")
        except Exception as e:
            print(f"\n⚠ Could not fetch TourGuard stats: {str(e)}")
    
    print(f"\n{'='*80}")
    print("API Endpoints:")
    print(f"{'='*80}")
    print("  Health:   http://localhost:8000/blockchain/health")
    print("  Stats:    http://localhost:8000/blockchain/stats")
    print("  User:     http://localhost:8000/blockchain/user/{USER_ID}/records")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()
