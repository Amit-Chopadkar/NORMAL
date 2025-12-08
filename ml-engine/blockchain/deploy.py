"""
Deploy TourGuard Identity Contract to Ethereum Network

Usage:
    python -m blockchain.deploy

Environment Variables:
    ETH_RPC_URL: RPC endpoint (default: http://127.0.0.1:8545)
    ETH_PRIVATE_KEY: Private key for deployment
    ETH_CHAIN_ID: Chain ID (default: 1337 for Ganache)
"""

import json
import os
import sys
from pathlib import Path

try:
    from solcx import compile_standard, install_solc
    from web3 import Web3
    from eth_account import Account
except ImportError:
    print("Required packages not installed. Run:")
    print("  pip install py-solc-x web3 eth-account")
    sys.exit(1)


def deploy_contract():
    """Deploy the TourGuardIdentity contract."""
    
    # Configuration
    rpc_url = os.getenv("ETH_RPC_URL", "http://127.0.0.1:8545")
    private_key = os.getenv("ETH_PRIVATE_KEY", None)
    chain_id = int(os.getenv("ETH_CHAIN_ID", "1337"))
    
    print("=" * 60)
    print("TourGuard Identity Contract Deployment")
    print("=" * 60)
    print(f"Network: {rpc_url}")
    print(f"Chain ID: {chain_id}")
    
    # Connect to network
    w3 = Web3(Web3.HTTPProvider(rpc_url))
    
    if not w3.is_connected():
        print(f"\n❌ Failed to connect to {rpc_url}")
        print("Make sure Ganache or your Ethereum node is running.")
        sys.exit(1)
    
    print(f"✅ Connected to network")
    
    # Determine deployer account
    use_unlocked = False
    deployer_address = None
    
    if private_key:
        # Try to use provided private key
        account = Account.from_key(private_key)
        deployer_address = account.address
        balance = w3.eth.get_balance(deployer_address)
        
        if balance == 0:
            print(f"Private key account {deployer_address} has no ETH, trying Ganache accounts...")
            use_unlocked = True
        else:
            print(f"Deployer: {deployer_address}")
            print(f"Balance: {w3.from_wei(balance, 'ether')} ETH")
    else:
        use_unlocked = True
    
    if use_unlocked:
        # Use Ganache's unlocked accounts
        accounts = w3.eth.accounts
        if not accounts:
            print("\n❌ No unlocked accounts available")
            sys.exit(1)
        
        deployer_address = accounts[0]
        balance = w3.eth.get_balance(deployer_address)
        print(f"Using Ganache unlocked account: {deployer_address}")
        print(f"Balance: {w3.from_wei(balance, 'ether')} ETH")
        
        if balance == 0:
            print("\n❌ Account has no ETH for gas")
            sys.exit(1)
    
    # Read contract source
    contract_path = Path(__file__).parent / "TourGuardIdentity.sol"
    
    if not contract_path.exists():
        print(f"\n❌ Contract file not found: {contract_path}")
        sys.exit(1)
    
    with open(contract_path, "r") as f:
        contract_source = f.read()
    
    print("\n📝 Compiling contract...")
    
    # Install solc if needed
    try:
        install_solc("0.8.19")
    except Exception:
        pass  # Already installed
    
    # Compile contract
    compiled = compile_standard(
        {
            "language": "Solidity",
            "sources": {
                "TourGuardIdentity.sol": {"content": contract_source}
            },
            "settings": {
                "outputSelection": {
                    "*": {
                        "*": ["abi", "metadata", "evm.bytecode"]
                    }
                },
                "optimizer": {
                    "enabled": True,
                    "runs": 200
                }
            }
        },
        solc_version="0.8.19"
    )
    
    # Extract ABI and bytecode
    contract_data = compiled["contracts"]["TourGuardIdentity.sol"]["TourGuardIdentity"]
    abi = contract_data["abi"]
    bytecode = contract_data["evm"]["bytecode"]["object"]
    
    print("✅ Contract compiled successfully")
    
    # Create contract instance
    Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
    
    # Build deployment transaction
    print("\n🚀 Deploying contract...")
    
    nonce = w3.eth.get_transaction_count(deployer_address)
    
    tx = Contract.constructor().build_transaction({
        "chainId": chain_id,
        "gasPrice": w3.to_wei("20", "gwei"),
        "gas": 3000000,
        "nonce": nonce,
        "from": deployer_address,
    })
    
    if use_unlocked:
        # Send transaction directly with unlocked account (Ganache)
        tx_hash = w3.eth.send_transaction(tx)
    else:
        # Sign and send with private key
        signed_tx = w3.eth.account.sign_transaction(tx, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    
    print(f"Transaction hash: {tx_hash.hex()}")
    print("Waiting for confirmation...")
    
    # Wait for receipt
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
    
    if receipt.status == 1:
        contract_address = receipt.contractAddress
        
        print("\n" + "=" * 60)
        print("✅ CONTRACT DEPLOYED SUCCESSFULLY!")
        print("=" * 60)
        print(f"Contract Address: {contract_address}")
        print(f"Block Number: {receipt.blockNumber}")
        print(f"Gas Used: {receipt.gasUsed}")
        print(f"Transaction Hash: {tx_hash.hex()}")
        
        # Save deployment info
        deployment_info = {
            "contract_address": contract_address,
            "deployer": deployer_address,
            "network": rpc_url,
            "chain_id": chain_id,
            "block_number": receipt.blockNumber,
            "tx_hash": tx_hash.hex(),
            "gas_used": receipt.gasUsed
        }
        
        info_path = Path(__file__).parent / "deployment_info.json"
        with open(info_path, "w") as f:
            json.dump(deployment_info, f, indent=2)
        
        print(f"\nDeployment info saved to: {info_path}")
        
        # Print environment variable
        print("\n" + "-" * 60)
        print("Add this to your environment:")
        print(f"  export ETH_CONTRACT_ADDRESS={contract_address}")
        print("-" * 60)
        
        # Save ABI
        abi_path = Path(__file__).parent / "TourGuardIdentity.abi.json"
        with open(abi_path, "w") as f:
            json.dump(abi, f, indent=2)
        print(f"ABI saved to: {abi_path}")
        
        return contract_address
        
    else:
        print("\n❌ Deployment failed!")
        print(f"Receipt: {receipt}")
        sys.exit(1)


if __name__ == "__main__":
    deploy_contract()
