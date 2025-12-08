from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple, List, Dict, Any

# Load environment variables from .env file
from dotenv import load_dotenv
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

from web3 import Web3
from eth_account import Account
from eth_account.signers.local import LocalAccount

# Handle different web3.py versions for PoA middleware
try:
    from web3.middleware import ExtraDataToPOAMiddleware as poa_middleware
except ImportError:
    try:
        from web3.middleware import geth_poa_middleware as poa_middleware
    except ImportError:
        poa_middleware = None


# Contract ABI - Simplified for key functions
CONTRACT_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [
            {"internalType": "string", "name": "userId", "type": "string"},
            {"internalType": "bytes32", "name": "hashId", "type": "bytes32"}
        ],
        "name": "storeRegistrationHash",
        "outputs": [{"internalType": "bool", "name": "success", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "string", "name": "userId", "type": "string"},
            {"internalType": "bytes32", "name": "hashId", "type": "bytes32"}
        ],
        "name": "storeLoginHash",
        "outputs": [{"internalType": "bool", "name": "success", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "bytes32", "name": "hashId", "type": "bytes32"}],
        "name": "verifyHash",
        "outputs": [{"internalType": "bool", "name": "exists", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "userId", "type": "string"}],
        "name": "getUserRecordCount",
        "outputs": [{"internalType": "uint256", "name": "count", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "string", "name": "userId", "type": "string"},
            {"internalType": "uint256", "name": "index", "type": "uint256"}
        ],
        "name": "getUserRecord",
        "outputs": [
            {"internalType": "bytes32", "name": "hashId", "type": "bytes32"},
            {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
            {"internalType": "string", "name": "eventType", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "userId", "type": "string"}],
        "name": "getUserSummary",
        "outputs": [
            {"internalType": "uint256", "name": "registrationCount", "type": "uint256"},
            {"internalType": "uint256", "name": "loginCount", "type": "uint256"},
            {"internalType": "uint256", "name": "firstActivity", "type": "uint256"},
            {"internalType": "uint256", "name": "lastActivity", "type": "uint256"},
            {"internalType": "bool", "name": "isRegistered", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getGlobalStats",
        "outputs": [
            {"internalType": "uint256", "name": "_totalUsers", "type": "uint256"},
            {"internalType": "uint256", "name": "_totalRegistrations", "type": "uint256"},
            {"internalType": "uint256", "name": "_totalLogins", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "node", "type": "address"},
            {"internalType": "bool", "name": "authorized", "type": "bool"}
        ],
        "name": "setAuthorizedNode",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True, "internalType": "bytes32", "name": "userIdHash", "type": "bytes32"},
            {"indexed": False, "internalType": "bytes32", "name": "hashId", "type": "bytes32"},
            {"indexed": False, "internalType": "uint256", "name": "timestamp", "type": "uint256"},
            {"indexed": False, "internalType": "string", "name": "userId", "type": "string"}
        ],
        "name": "RegistrationRecorded",
        "type": "event"
    },
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True, "internalType": "bytes32", "name": "userIdHash", "type": "bytes32"},
            {"indexed": False, "internalType": "bytes32", "name": "hashId", "type": "bytes32"},
            {"indexed": False, "internalType": "uint256", "name": "timestamp", "type": "uint256"},
            {"indexed": False, "internalType": "string", "name": "userId", "type": "string"}
        ],
        "name": "LoginRecorded",
        "type": "event"
    }
]


@dataclass
class BlockchainConfig:
    """Configuration for Ethereum blockchain connection."""
    
    # Network settings
    rpc_url: str = os.getenv("ETH_RPC_URL", "http://127.0.0.1:8545")
    chain_id: int = int(os.getenv("ETH_CHAIN_ID", "1337"))
    
    # Account settings
    private_key: str = os.getenv(
        "ETH_PRIVATE_KEY",
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # Ganache default
    )
    
    # Contract settings
    contract_address: Optional[str] = os.getenv("ETH_CONTRACT_ADDRESS")
    
    # Network type (for middleware)
    is_poa: bool = os.getenv("ETH_IS_POA", "false").lower() == "true"
    
    # Gas settings
    gas_limit: int = int(os.getenv("ETH_GAS_LIMIT", "3000000"))
    gas_price_gwei: int = int(os.getenv("ETH_GAS_PRICE_GWEI", "20"))


@dataclass
class TransactionResult:
    """Result of a blockchain transaction."""
    success: bool
    tx_hash: Optional[str]
    block_number: Optional[int]
    hash_id: Optional[str]
    gas_used: Optional[int]
    error: Optional[str] = None


@dataclass
class VerificationResult:
    """Result of hash verification."""
    exists: bool
    hash_id: str
    user_id: Optional[str] = None
    error: Optional[str] = None


class EthereumService:
    """Service for interacting with Ethereum blockchain."""
    
    def __init__(self, config: Optional[BlockchainConfig] = None):
        self.config = config or BlockchainConfig()
        self._web3: Optional[Web3] = None
        self._account: Optional[LocalAccount] = None
        self._contract = None
        self._connected = False
        self._use_unlocked = False
        self._unlocked_address: Optional[str] = None
    
    def connect(self) -> bool:
        """Establish connection to Ethereum node."""
        try:
            self._web3 = Web3(Web3.HTTPProvider(self.config.rpc_url))
            
            # Add PoA middleware if needed (for networks like Polygon)
            if self.config.is_poa and poa_middleware is not None:
                self._web3.middleware_onion.inject(poa_middleware, layer=0)
            
            if not self._web3.is_connected():
                print(f"[Blockchain] Failed to connect to {self.config.rpc_url}")
                return False
            
            # Try to load account from private key
            if self.config.private_key:
                try:
                    self._account = Account.from_key(self.config.private_key)
                    balance = self._web3.eth.get_balance(self._account.address)
                    
                    if balance == 0:
                        print(f"[Blockchain] Private key account has no ETH, trying Ganache accounts...")
                        self._use_unlocked = True
                    else:
                        print(f"[Blockchain] Account: {self._account.address}")
                        print(f"[Blockchain] Balance: {self._web3.from_wei(balance, 'ether')} ETH")
                except Exception as e:
                    print(f"[Blockchain] Private key error: {e}, trying Ganache accounts...")
                    self._use_unlocked = True
            else:
                self._use_unlocked = True
            
            # Use Ganache unlocked accounts if needed
            if self._use_unlocked:
                accounts = self._web3.eth.accounts
                if accounts:
                    self._unlocked_address = accounts[0]
                    balance = self._web3.eth.get_balance(self._unlocked_address)
                    print(f"[Blockchain] Using unlocked account: {self._unlocked_address}")
                    print(f"[Blockchain] Balance: {self._web3.from_wei(balance, 'ether')} ETH")
                else:
                    print("[Blockchain] No unlocked accounts available")
                    return False
            
            # Load contract if address is configured
            if self.config.contract_address:
                self._contract = self._web3.eth.contract(
                    address=Web3.to_checksum_address(self.config.contract_address),
                    abi=CONTRACT_ABI
                )
            
            self._connected = True
            print(f"[Blockchain] Connected to {self.config.rpc_url}")
            
            return True
            
        except Exception as e:
            print(f"[Blockchain] Connection error: {e}")
            return False
    
    @property
    def is_connected(self) -> bool:
        """Check if connected to blockchain."""
        return self._connected and self._web3 is not None and self._web3.is_connected()
    
    @property
    def account_address(self) -> Optional[str]:
        """Get the current account address."""
        return self._account.address if self._account else None
    
    def generate_registration_hash(
        self,
        user_id: str,
        email: str,
        phone: str,
        name: str,
        timestamp: Optional[datetime] = None
    ) -> str:
        """
        Generate a SHA256 hash for user registration.
        
        Args:
            user_id: Unique user identifier
            email: User's email
            phone: User's phone number
            name: User's name
            timestamp: Registration timestamp (defaults to now)
        
        Returns:
            Hexadecimal hash string (with 0x prefix)
        """
        ts = timestamp or datetime.utcnow()
        data = f"{user_id}|{email}|{phone}|{name}|{ts.isoformat()}|REGISTER"
        hash_bytes = hashlib.sha256(data.encode()).digest()
        return "0x" + hash_bytes.hex()
    
    def generate_login_hash(
        self,
        user_id: str,
        device_id: str,
        ip_address: str,
        timestamp: Optional[datetime] = None
    ) -> str:
        """
        Generate a SHA256 hash for user login.
        
        Args:
            user_id: Unique user identifier
            device_id: Device identifier
            ip_address: Client IP address
            timestamp: Login timestamp (defaults to now)
        
        Returns:
            Hexadecimal hash string (with 0x prefix)
        """
        ts = timestamp or datetime.utcnow()
        data = f"{user_id}|{device_id}|{ip_address}|{ts.isoformat()}|LOGIN"
        hash_bytes = hashlib.sha256(data.encode()).digest()
        return "0x" + hash_bytes.hex()
    
    async def store_registration(
        self,
        user_id: str,
        email: str,
        phone: str,
        name: str
    ) -> TransactionResult:
        """
        Store registration hash on blockchain.
        
        Args:
            user_id: Unique user identifier
            email: User's email
            phone: User's phone number
            name: User's name
        
        Returns:
            TransactionResult with transaction details
        """
        if not self.is_connected:
            return TransactionResult(
                success=False,
                tx_hash=None,
                block_number=None,
                hash_id=None,
                gas_used=None,
                error="Not connected to blockchain"
            )
        
        if not self._contract:
            return TransactionResult(
                success=False,
                tx_hash=None,
                block_number=None,
                hash_id=None,
                gas_used=None,
                error="Contract not deployed"
            )
        
        try:
            # Generate hash
            hash_id = self.generate_registration_hash(user_id, email, phone, name)
            hash_bytes = bytes.fromhex(hash_id[2:])  # Remove 0x prefix
            
            # Determine sender address
            sender_address = self._unlocked_address if self._use_unlocked else self._account.address
            
            # Build transaction
            nonce = self._web3.eth.get_transaction_count(sender_address)
            
            tx = self._contract.functions.storeRegistrationHash(
                user_id,
                hash_bytes
            ).build_transaction({
                'chainId': self.config.chain_id,
                'gas': self.config.gas_limit,
                'gasPrice': self._web3.to_wei(self.config.gas_price_gwei, 'gwei'),
                'nonce': nonce,
                'from': sender_address,
            })
            
            if self._use_unlocked:
                # Send transaction directly with unlocked account (Ganache)
                tx_hash = self._web3.eth.send_transaction(tx)
            else:
                # Sign and send transaction with private key
                signed_tx = self._web3.eth.account.sign_transaction(tx, self.config.private_key)
                tx_hash = self._web3.eth.send_raw_transaction(signed_tx.raw_transaction)
            
            # Wait for receipt
            receipt = self._web3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
            
            return TransactionResult(
                success=receipt.status == 1,
                tx_hash=tx_hash.hex(),
                block_number=receipt.blockNumber,
                hash_id=hash_id,
                gas_used=receipt.gasUsed
            )
            
        except Exception as e:
            print(f"[Blockchain] Registration error: {e}")
            return TransactionResult(
                success=False,
                tx_hash=None,
                block_number=None,
                hash_id=None,
                gas_used=None,
                error=str(e)
            )
    
    async def store_login(
        self,
        user_id: str,
        device_id: str,
        ip_address: str
    ) -> TransactionResult:
        """
        Store login hash on blockchain.
        
        Args:
            user_id: Unique user identifier
            device_id: Device identifier
            ip_address: Client IP address
        
        Returns:
            TransactionResult with transaction details
        """
        if not self.is_connected:
            return TransactionResult(
                success=False,
                tx_hash=None,
                block_number=None,
                hash_id=None,
                gas_used=None,
                error="Not connected to blockchain"
            )
        
        if not self._contract:
            return TransactionResult(
                success=False,
                tx_hash=None,
                block_number=None,
                hash_id=None,
                gas_used=None,
                error="Contract not deployed"
            )
        
        try:
            # Generate hash
            hash_id = self.generate_login_hash(user_id, device_id, ip_address)
            hash_bytes = bytes.fromhex(hash_id[2:])  # Remove 0x prefix
            
            # Determine sender address
            sender_address = self._unlocked_address if self._use_unlocked else self._account.address
            
            # Build transaction
            nonce = self._web3.eth.get_transaction_count(sender_address)
            
            tx = self._contract.functions.storeLoginHash(
                user_id,
                hash_bytes
            ).build_transaction({
                'chainId': self.config.chain_id,
                'gas': self.config.gas_limit,
                'gasPrice': self._web3.to_wei(self.config.gas_price_gwei, 'gwei'),
                'nonce': nonce,
                'from': sender_address,
            })
            
            if self._use_unlocked:
                # Send transaction directly with unlocked account (Ganache)
                tx_hash = self._web3.eth.send_transaction(tx)
            else:
                # Sign and send transaction with private key
                signed_tx = self._web3.eth.account.sign_transaction(tx, self.config.private_key)
                tx_hash = self._web3.eth.send_raw_transaction(signed_tx.raw_transaction)
            
            # Wait for receipt
            receipt = self._web3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)
            
            return TransactionResult(
                success=receipt.status == 1,
                tx_hash=tx_hash.hex(),
                block_number=receipt.blockNumber,
                hash_id=hash_id,
                gas_used=receipt.gasUsed
            )
            
        except Exception as e:
            print(f"[Blockchain] Login error: {e}")
            return TransactionResult(
                success=False,
                tx_hash=None,
                block_number=None,
                hash_id=None,
                gas_used=None,
                error=str(e)
            )
    
    def verify_hash(self, hash_id: str) -> VerificationResult:
        """
        Verify if a hash exists on the blockchain.
        
        Args:
            hash_id: The hash to verify (with 0x prefix)
        
        Returns:
            VerificationResult indicating if hash exists
        """
        if not self.is_connected:
            return VerificationResult(
                exists=False,
                hash_id=hash_id,
                error="Not connected to blockchain"
            )
        
        if not self._contract:
            return VerificationResult(
                exists=False,
                hash_id=hash_id,
                error="Contract not deployed"
            )
        
        try:
            hash_bytes = bytes.fromhex(hash_id[2:]) if hash_id.startswith("0x") else bytes.fromhex(hash_id)
            exists = self._contract.functions.verifyHash(hash_bytes).call()
            
            return VerificationResult(
                exists=exists,
                hash_id=hash_id
            )
            
        except Exception as e:
            print(f"[Blockchain] Verification error: {e}")
            return VerificationResult(
                exists=False,
                hash_id=hash_id,
                error=str(e)
            )
    
    def get_user_records(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Get all records for a user.
        
        Args:
            user_id: Unique user identifier
        
        Returns:
            List of user records
        """
        if not self.is_connected or not self._contract:
            return []
        
        try:
            count = self._contract.functions.getUserRecordCount(user_id).call()
            records = []
            
            for i in range(count):
                hash_id, timestamp, event_type = self._contract.functions.getUserRecord(
                    user_id, i
                ).call()
                
                records.append({
                    "hash_id": "0x" + hash_id.hex(),
                    "timestamp": timestamp,
                    "event_type": event_type,
                    "datetime": datetime.utcfromtimestamp(timestamp).isoformat()
                })
            
            return records
            
        except Exception as e:
            print(f"[Blockchain] Get records error: {e}")
            return []
    
    def get_user_summary(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get summary statistics for a user.
        
        Args:
            user_id: Unique user identifier
        
        Returns:
            User summary or None
        """
        if not self.is_connected or not self._contract:
            return None
        
        try:
            result = self._contract.functions.getUserSummary(user_id).call()
            
            return {
                "registration_count": result[0],
                "login_count": result[1],
                "first_activity": result[2],
                "last_activity": result[3],
                "is_registered": result[4],
                "first_activity_datetime": datetime.utcfromtimestamp(result[2]).isoformat() if result[2] > 0 else None,
                "last_activity_datetime": datetime.utcfromtimestamp(result[3]).isoformat() if result[3] > 0 else None
            }
            
        except Exception as e:
            print(f"[Blockchain] Get summary error: {e}")
            return None
    
    def get_global_stats(self) -> Optional[Dict[str, int]]:
        """
        Get global blockchain statistics.
        
        Returns:
            Dictionary with total users, registrations, and logins
        """
        if not self.is_connected or not self._contract:
            return None
        
        try:
            result = self._contract.functions.getGlobalStats().call()
            
            return {
                "total_users": result[0],
                "total_registrations": result[1],
                "total_logins": result[2]
            }
            
        except Exception as e:
            print(f"[Blockchain] Get stats error: {e}")
            return None


# Singleton instance
_ethereum_service: Optional[EthereumService] = None


def get_ethereum_service() -> EthereumService:
    """Get or create the Ethereum service singleton."""
    global _ethereum_service
    if _ethereum_service is None:
        _ethereum_service = EthereumService()
        _ethereum_service.connect()
    return _ethereum_service
