# Blockchain module for TourGuard ML Engine
# Provides Ethereum-based permissioned blockchain for identity management

from .ethereum_service import EthereumService, BlockchainConfig

__all__ = ["EthereumService", "BlockchainConfig"]
