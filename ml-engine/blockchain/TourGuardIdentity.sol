// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TourGuardIdentity
 * @dev Permissioned blockchain contract for storing tourist identity hash IDs
 * @notice This contract stores registration and login hashes for TourGuard users
 */
contract TourGuardIdentity {
    
    // ============ Structs ============
    
    struct IdentityRecord {
        bytes32 hashId;
        uint256 timestamp;
        string eventType;  // "REGISTER" or "LOGIN"
        string userId;
        bool exists;
    }
    
    struct UserSummary {
        uint256 registrationCount;
        uint256 loginCount;
        uint256 firstActivity;
        uint256 lastActivity;
        bool isRegistered;
    }
    
    // ============ State Variables ============
    
    address public admin;
    mapping(address => bool) public authorizedNodes;
    
    // User records: userId hash => array of identity records
    mapping(bytes32 => IdentityRecord[]) private userRecords;
    
    // User summaries: userId hash => summary
    mapping(bytes32 => UserSummary) public userSummaries;
    
    // Global hash registry to prevent duplicates
    mapping(bytes32 => bool) public hashExists;
    
    // Hash to user mapping for verification
    mapping(bytes32 => bytes32) public hashToUser;
    
    // Statistics
    uint256 public totalRegistrations;
    uint256 public totalLogins;
    uint256 public totalUsers;
    
    // ============ Events ============
    
    event RegistrationRecorded(
        bytes32 indexed userIdHash,
        bytes32 hashId,
        uint256 timestamp,
        string userId
    );
    
    event LoginRecorded(
        bytes32 indexed userIdHash,
        bytes32 hashId,
        uint256 timestamp,
        string userId
    );
    
    event NodeAuthorized(address indexed node, bool authorized);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    
    // ============ Modifiers ============
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "TourGuard: Only admin can call this");
        _;
    }
    
    modifier onlyAuthorized() {
        require(
            authorizedNodes[msg.sender] || msg.sender == admin,
            "TourGuard: Not authorized to submit records"
        );
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        admin = msg.sender;
        authorizedNodes[msg.sender] = true;
        emit NodeAuthorized(msg.sender, true);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @dev Authorize or revoke a node's permission to submit records
     * @param node Address of the node
     * @param authorized Whether to authorize or revoke
     */
    function setAuthorizedNode(address node, bool authorized) external onlyAdmin {
        authorizedNodes[node] = authorized;
        emit NodeAuthorized(node, authorized);
    }
    
    /**
     * @dev Transfer admin rights to a new address
     * @param newAdmin Address of the new admin
     */
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "TourGuard: Invalid admin address");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
        authorizedNodes[newAdmin] = true;
    }
    
    // ============ Core Functions ============
    
    /**
     * @dev Store a registration hash on the blockchain
     * @param userId The user's unique identifier (will be hashed internally)
     * @param hashId The SHA256 hash of registration data
     * @return success Whether the operation was successful
     */
    function storeRegistrationHash(
        string calldata userId,
        bytes32 hashId
    ) external onlyAuthorized returns (bool success) {
        require(hashId != bytes32(0), "TourGuard: Invalid hash");
        require(!hashExists[hashId], "TourGuard: Hash already exists");
        
        bytes32 userIdHash = keccak256(abi.encodePacked(userId));
        
        // Create identity record
        IdentityRecord memory record = IdentityRecord({
            hashId: hashId,
            timestamp: block.timestamp,
            eventType: "REGISTER",
            userId: userId,
            exists: true
        });
        
        // Store record
        userRecords[userIdHash].push(record);
        hashExists[hashId] = true;
        hashToUser[hashId] = userIdHash;
        
        // Update user summary
        UserSummary storage summary = userSummaries[userIdHash];
        if (!summary.isRegistered) {
            summary.isRegistered = true;
            summary.firstActivity = block.timestamp;
            totalUsers++;
        }
        summary.registrationCount++;
        summary.lastActivity = block.timestamp;
        
        totalRegistrations++;
        
        emit RegistrationRecorded(userIdHash, hashId, block.timestamp, userId);
        
        return true;
    }
    
    /**
     * @dev Store a login hash on the blockchain
     * @param userId The user's unique identifier
     * @param hashId The SHA256 hash of login data
     * @return success Whether the operation was successful
     */
    function storeLoginHash(
        string calldata userId,
        bytes32 hashId
    ) external onlyAuthorized returns (bool success) {
        require(hashId != bytes32(0), "TourGuard: Invalid hash");
        require(!hashExists[hashId], "TourGuard: Hash already exists");
        
        bytes32 userIdHash = keccak256(abi.encodePacked(userId));
        
        // Create identity record
        IdentityRecord memory record = IdentityRecord({
            hashId: hashId,
            timestamp: block.timestamp,
            eventType: "LOGIN",
            userId: userId,
            exists: true
        });
        
        // Store record
        userRecords[userIdHash].push(record);
        hashExists[hashId] = true;
        hashToUser[hashId] = userIdHash;
        
        // Update user summary
        UserSummary storage summary = userSummaries[userIdHash];
        if (!summary.isRegistered) {
            summary.isRegistered = true;
            summary.firstActivity = block.timestamp;
            totalUsers++;
        }
        summary.loginCount++;
        summary.lastActivity = block.timestamp;
        
        totalLogins++;
        
        emit LoginRecorded(userIdHash, hashId, block.timestamp, userId);
        
        return true;
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Verify if a hash exists on the blockchain
     * @param hashId The hash to verify
     * @return exists Whether the hash exists
     */
    function verifyHash(bytes32 hashId) external view returns (bool exists) {
        return hashExists[hashId];
    }
    
    /**
     * @dev Get the number of records for a user
     * @param userId The user's unique identifier
     * @return count Number of records
     */
    function getUserRecordCount(string calldata userId) external view returns (uint256 count) {
        bytes32 userIdHash = keccak256(abi.encodePacked(userId));
        return userRecords[userIdHash].length;
    }
    
    /**
     * @dev Get a specific record for a user
     * @param userId The user's unique identifier
     * @param index The index of the record
     * @return hashId The hash ID
     * @return timestamp When the record was created
     * @return eventType Type of event (REGISTER or LOGIN)
     */
    function getUserRecord(
        string calldata userId,
        uint256 index
    ) external view returns (
        bytes32 hashId,
        uint256 timestamp,
        string memory eventType
    ) {
        bytes32 userIdHash = keccak256(abi.encodePacked(userId));
        require(index < userRecords[userIdHash].length, "TourGuard: Invalid index");
        
        IdentityRecord memory record = userRecords[userIdHash][index];
        return (record.hashId, record.timestamp, record.eventType);
    }
    
    /**
     * @dev Get user summary statistics
     * @param userId The user's unique identifier
     * @return registrationCount Number of registrations
     * @return loginCount Number of logins
     * @return firstActivity First activity timestamp
     * @return lastActivity Last activity timestamp
     * @return isRegistered Whether user is registered
     */
    function getUserSummary(string calldata userId) external view returns (
        uint256 registrationCount,
        uint256 loginCount,
        uint256 firstActivity,
        uint256 lastActivity,
        bool isRegistered
    ) {
        bytes32 userIdHash = keccak256(abi.encodePacked(userId));
        UserSummary memory summary = userSummaries[userIdHash];
        return (
            summary.registrationCount,
            summary.loginCount,
            summary.firstActivity,
            summary.lastActivity,
            summary.isRegistered
        );
    }
    
    /**
     * @dev Get global statistics
     * @return _totalUsers Total number of users
     * @return _totalRegistrations Total number of registrations
     * @return _totalLogins Total number of logins
     */
    function getGlobalStats() external view returns (
        uint256 _totalUsers,
        uint256 _totalRegistrations,
        uint256 _totalLogins
    ) {
        return (totalUsers, totalRegistrations, totalLogins);
    }
}
