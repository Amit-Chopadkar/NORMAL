"""
Blockchain API Routes for TourGuard
Provides REST endpoints for blockchain identity operations.
"""

from __future__ import annotations

import sys
from pathlib import Path
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field

# Add parent directory to path to import blockchain module
sys.path.insert(0, str(Path(__file__).parent.parent))
from blockchain.ethereum_service import (
    get_ethereum_service,
    TransactionResult,
    VerificationResult,
)


router = APIRouter(prefix="/blockchain", tags=["Blockchain"])


# ============ Request/Response Models ============

class RegistrationRequest(BaseModel):
    """Request body for registration hash storage."""
    user_id: str = Field(..., description="Unique user identifier (Firebase UID)")
    email: str = Field(..., description="User's email address")
    phone: str = Field(..., description="User's phone number")
    name: str = Field(..., description="User's full name")


class LoginRequest(BaseModel):
    """Request body for login hash storage."""
    user_id: str = Field(..., description="Unique user identifier")
    device_id: str = Field(default="unknown", description="Device identifier")


class BlockchainResponse(BaseModel):
    """Response for blockchain operations."""
    success: bool
    message: str
    hash_id: Optional[str] = None
    tx_hash: Optional[str] = None
    block_number: Optional[int] = None
    gas_used: Optional[int] = None
    error: Optional[str] = None


class VerifyResponse(BaseModel):
    """Response for hash verification."""
    exists: bool
    hash_id: str
    message: str
    error: Optional[str] = None


class UserRecordsResponse(BaseModel):
    """Response for user records query."""
    user_id: str
    record_count: int
    records: list
    summary: Optional[dict] = None


class GlobalStatsResponse(BaseModel):
    """Response for global blockchain statistics."""
    connected: bool
    contract_deployed: bool
    total_users: int = 0
    total_registrations: int = 0
    total_logins: int = 0
    network_url: Optional[str] = None
    account_address: Optional[str] = None


# ============ Endpoints ============

@router.get("/health")
async def blockchain_health():
    """Check blockchain connection status."""
    service = get_ethereum_service()
    
    return {
        "status": "connected" if service.is_connected else "disconnected",
        "network": service.config.rpc_url,
        "chain_id": service.config.chain_id,
        "account": service.account_address,
        "contract_deployed": service.config.contract_address is not None
    }


@router.post("/register", response_model=BlockchainResponse)
async def store_registration(request: RegistrationRequest, req: Request):
    """
    Store user registration hash on blockchain.
    
    This creates an immutable record of user registration with:
    - User ID
    - Email (hashed)
    - Phone (hashed)
    - Name (hashed)
    - Timestamp
    
    Returns the blockchain transaction details and hash ID.
    """
    service = get_ethereum_service()
    
    if not service.is_connected:
        raise HTTPException(
            status_code=503,
            detail="Blockchain service not available"
        )
    
    # Store registration
    result = await service.store_registration(
        user_id=request.user_id,
        email=request.email,
        phone=request.phone,
        name=request.name
    )
    
    if result.success:
        return BlockchainResponse(
            success=True,
            message="Registration recorded on blockchain",
            hash_id=result.hash_id,
            tx_hash=result.tx_hash,
            block_number=result.block_number,
            gas_used=result.gas_used
        )
    else:
        return BlockchainResponse(
            success=False,
            message="Failed to record registration",
            error=result.error
        )


@router.post("/login", response_model=BlockchainResponse)
async def store_login(request: LoginRequest, req: Request):
    """
    Store user login hash on blockchain.
    
    This creates an immutable record of user login with:
    - User ID
    - Device ID
    - IP Address
    - Timestamp
    
    Returns the blockchain transaction details and hash ID.
    """
    service = get_ethereum_service()
    
    if not service.is_connected:
        raise HTTPException(
            status_code=503,
            detail="Blockchain service not available"
        )
    
    # Get client IP
    client_ip = req.client.host if req.client else "unknown"
    
    # Store login
    result = await service.store_login(
        user_id=request.user_id,
        device_id=request.device_id,
        ip_address=client_ip
    )
    
    if result.success:
        return BlockchainResponse(
            success=True,
            message="Login recorded on blockchain",
            hash_id=result.hash_id,
            tx_hash=result.tx_hash,
            block_number=result.block_number,
            gas_used=result.gas_used
        )
    else:
        return BlockchainResponse(
            success=False,
            message="Failed to record login",
            error=result.error
        )


@router.get("/verify/{hash_id}", response_model=VerifyResponse)
async def verify_hash(hash_id: str):
    """
    Verify if a hash exists on the blockchain.
    
    Args:
        hash_id: The hash to verify (with or without 0x prefix)
    
    Returns:
        Whether the hash exists on the blockchain.
    """
    service = get_ethereum_service()
    
    if not service.is_connected:
        raise HTTPException(
            status_code=503,
            detail="Blockchain service not available"
        )
    
    # Ensure hash has 0x prefix
    if not hash_id.startswith("0x"):
        hash_id = "0x" + hash_id
    
    result = service.verify_hash(hash_id)
    
    return VerifyResponse(
        exists=result.exists,
        hash_id=hash_id,
        message="Hash verified" if result.exists else "Hash not found",
        error=result.error
    )


@router.get("/user/{user_id}/records", response_model=UserRecordsResponse)
async def get_user_records(user_id: str):
    """
    Get all blockchain records for a user.
    
    Args:
        user_id: The user's unique identifier
    
    Returns:
        List of all registration and login records for the user.
    """
    service = get_ethereum_service()
    
    if not service.is_connected:
        raise HTTPException(
            status_code=503,
            detail="Blockchain service not available"
        )
    
    records = service.get_user_records(user_id)
    summary = service.get_user_summary(user_id)
    
    return UserRecordsResponse(
        user_id=user_id,
        record_count=len(records),
        records=records,
        summary=summary
    )


@router.get("/stats", response_model=GlobalStatsResponse)
async def get_global_stats():
    """
    Get global blockchain statistics.
    
    Returns:
        Total users, registrations, and logins recorded on blockchain.
    """
    service = get_ethereum_service()
    
    stats = service.get_global_stats() if service.is_connected else None
    
    return GlobalStatsResponse(
        connected=service.is_connected,
        contract_deployed=service.config.contract_address is not None,
        total_users=stats.get("total_users", 0) if stats else 0,
        total_registrations=stats.get("total_registrations", 0) if stats else 0,
        total_logins=stats.get("total_logins", 0) if stats else 0,
        network_url=service.config.rpc_url,
        account_address=service.account_address
    )


@router.post("/generate-hash/registration")
async def generate_registration_hash_only(request: RegistrationRequest):
    """
    Generate a registration hash without storing it on blockchain.
    Useful for testing or preview purposes.
    """
    service = get_ethereum_service()
    
    hash_id = service.generate_registration_hash(
        user_id=request.user_id,
        email=request.email,
        phone=request.phone,
        name=request.name
    )
    
    return {
        "hash_id": hash_id,
        "user_id": request.user_id,
        "generated_at": datetime.utcnow().isoformat(),
        "note": "This hash was not stored on blockchain"
    }


@router.post("/generate-hash/login")
async def generate_login_hash_only(request: LoginRequest, req: Request):
    """
    Generate a login hash without storing it on blockchain.
    Useful for testing or preview purposes.
    """
    service = get_ethereum_service()
    client_ip = req.client.host if req.client else "unknown"
    
    hash_id = service.generate_login_hash(
        user_id=request.user_id,
        device_id=request.device_id,
        ip_address=client_ip
    )
    
    return {
        "hash_id": hash_id,
        "user_id": request.user_id,
        "device_id": request.device_id,
        "generated_at": datetime.utcnow().isoformat(),
        "note": "This hash was not stored on blockchain"
    }
