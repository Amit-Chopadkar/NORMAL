-- =============================================
-- SMART TOURIST SAFETY MONITORING SYSTEM (TOURGUARD)
-- Enterprise PostgreSQL Database Schema - FINAL VERSION
-- =============================================

CREATE DATABASE smart_tourist_safety;
\c smart_tourist_safety;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =============================================
-- 1. CORE USER AUTHENTICATION & PROFILES
-- =============================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_country_code VARCHAR(5) DEFAULT '+91',
    phone_number VARCHAR(15) NOT NULL,
    password_hash TEXT NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('TOURIST', 'ADMIN', 'RESPONDER', 'OPERATOR')),
    
    -- Profile Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    nationality VARCHAR(3), -- ISO 3166-1 alpha-3
    profile_image_url TEXT,
    preferred_language VARCHAR(10) DEFAULT 'en', -- Added for multi-language support
    
    -- Status & Timestamps
    account_status VARCHAR(20) DEFAULT 'PENDING_VERIFICATION' 
        CHECK (account_status IN ('PENDING_VERIFICATION', 'ACTIVE', 'SUSPENDED', 'DELETED')),
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    kyc_status VARCHAR(20) DEFAULT 'PENDING' 
        CHECK (kyc_status IN ('PENDING', 'IN_PROGRESS', 'VERIFIED', 'REJECTED', 'EXPIRED')),
    
    -- Security
    mfa_enabled BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- =============================================
-- 2. TOURIST-SPECIFIC PROFILE DATA
-- =============================================

CREATE TABLE tourist_profiles (
    tourist_profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Travel Information
    arrival_date DATE NOT NULL,
    departure_date DATE NOT NULL,
    purpose_of_visit VARCHAR(50) CHECK (purpose_of_visit IN ('TOURISM', 'BUSINESS', 'MEDICAL', 'EDUCATION', 'OTHER')),
    visa_number VARCHAR(100),
    visa_expiry_date DATE,
    
    -- Accommodation Details
    accommodation_type VARCHAR(50),
    accommodation_name VARCHAR(255),
    accommodation_address TEXT,
    accommodation_phone VARCHAR(20),
    
    -- Emergency Information
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(50),
    emergency_contact_email VARCHAR(255),
    
    -- Medical Information
    blood_group VARCHAR(5),
    known_allergies TEXT[],
    medical_conditions TEXT[],
    current_medications TEXT[],
    insurance_provider VARCHAR(255),
    insurance_policy_number VARCHAR(100),
    
    -- Preferences
    preferred_language VARCHAR(10) DEFAULT 'en',
    alert_preferences JSONB DEFAULT '{
        "push_notifications": true,
        "sms_alerts": true,
        "email_alerts": false,
        "high_risk_only": false
    }',
    family_sharing_enabled BOOLEAN DEFAULT FALSE, -- Added for family monitoring
    
    -- Device Information
    device_id VARCHAR(255),
    device_type VARCHAR(50),
    device_os VARCHAR(50),
    app_version VARCHAR(20),
    
    -- AI Safety Scoring
    safety_risk_score INTEGER DEFAULT 50 CHECK (safety_risk_score BETWEEN 0 AND 100),
    risk_level VARCHAR(10) DEFAULT 'LOW' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    behavior_patterns JSONB,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- =============================================
-- 3. EMERGENCY CONTACTS SYSTEM
-- =============================================

CREATE TABLE emergency_contacts (
    contact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    contact_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100),
    phone_country_code VARCHAR(5) DEFAULT '+91',
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    notification_preferences JSONB DEFAULT '{"push": true, "sms": true, "email": false}',
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, phone_number)
);

-- =============================================
-- 4. FAMILY MONITORING SYSTEM
-- =============================================

CREATE TABLE family_monitoring (
    monitor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tourist_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    family_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    access_level VARCHAR(50) DEFAULT 'LOCATION_ONLY' 
        CHECK (access_level IN ('LOCATION_ONLY', 'FULL_ACCESS')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(tourist_user_id, family_user_id)
);

-- =============================================
-- 5. AADHAAR VERIFICATION SYSTEM (Indian Tourists)
-- =============================================

CREATE TABLE aadhaar_verifications (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Aadhaar Details (Masked for Privacy)
    aadhaar_masked_number VARCHAR(12) NOT NULL, -- Store only last 4 digits: XXXX-XXXX-1234
    aadhaar_reference_hash TEXT NOT NULL, -- Hash of full Aadhaar for deduplication
    
    -- DigiLocker Integration
    digilocker_reference_id VARCHAR(255),
    digilocker_document_uri TEXT,
    digilocker_issued_at TIMESTAMP WITH TIME ZONE,
    digilocker_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- UIDAI OTP Verification
    uidai_otp_transaction_id VARCHAR(255),
    uidai_otp_mobile_last_4 VARCHAR(4),
    uidai_verification_timestamp TIMESTAMP WITH TIME ZONE,
    uidai_kyc_status VARCHAR(50),
    
    -- Verification Evidence
    aadhaar_name_match_score INTEGER,
    aadhaar_dob_match BOOLEAN,
    aadhaar_gender_match BOOLEAN,
    verification_confidence_score INTEGER,
    
    -- Digital Certificate
    digital_certificate_reference TEXT,
    certificate_issued_at TIMESTAMP WITH TIME ZONE,
    certificate_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    verification_status VARCHAR(20) DEFAULT 'INITIATED' 
        CHECK (verification_status IN ('INITIATED', 'OTP_SENT', 'OTP_VERIFIED', 'DIGILOCKER_VERIFIED', 'COMPLETED', 'FAILED')),
    rejection_reason TEXT,
    
    -- Audit Trail
    otp_attempts_count INTEGER DEFAULT 0,
    last_otp_sent_at TIMESTAMP WITH TIME ZONE,
    verified_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id),
    UNIQUE(aadhaar_reference_hash)
);

-- =============================================
-- 6. PASSPORT VERIFICATION SYSTEM (Foreign Tourists)
-- =============================================

CREATE TABLE passport_verifications (
    verification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Passport Details
    passport_number VARCHAR(50) NOT NULL,
    passport_country VARCHAR(3) NOT NULL, -- ISO 3166-1 alpha-3
    nationality VARCHAR(3) NOT NULL,
    
    -- MRZ (Machine Readable Zone) Data
    mrz_line1 VARCHAR(50),
    mrz_line2 VARCHAR(50),
    mrz_hash TEXT,
    
    -- Personal Details from Passport
    passport_full_name VARCHAR(255),
    passport_date_of_birth DATE,
    passport_gender VARCHAR(10),
    passport_issue_date DATE,
    passport_expiry_date DATE,
    place_of_birth VARCHAR(100),
    issuing_authority VARCHAR(100),
    
    -- Visa Information
    visa_type VARCHAR(50),
    visa_issue_date DATE,
    visa_expiry_date DATE,
    visa_entries_allowed INTEGER,
    visa_conditions TEXT,
    
    -- Document Evidence
    passport_front_image_url TEXT,
    passport_back_image_url TEXT,
    visa_image_url TEXT,
    selfie_with_passport_url TEXT,
    
    -- Verification Results
    mrz_validation_status BOOLEAN,
    document_authenticity_score INTEGER,
    face_match_score INTEGER,
    data_consistency_check BOOLEAN,
    
    -- External Verification
    external_verification_service VARCHAR(100),
    external_reference_id VARCHAR(255),
    external_verification_data JSONB,
    
    -- Status
    verification_status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (verification_status IN ('PENDING', 'DOCUMENT_UPLOADED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED')),
    verification_notes TEXT,
    
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- =============================================
-- 7. BLOCKCHAIN DIGITAL IDENTITY (DID) SYSTEM
-- =============================================

CREATE TABLE digital_identities (
    did_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- DID Information
    did_identifier VARCHAR(255) NOT NULL UNIQUE, -- did:example:123456
    did_method VARCHAR(50) NOT NULL DEFAULT 'india-tourist', -- DID method namespace
    did_document JSONB NOT NULL, -- Complete DID Document
    
    -- Blockchain Details
    blockchain_name VARCHAR(50) NOT NULL, -- 'Ethereum', 'Polygon', 'Hyperledger'
    network_type VARCHAR(20) NOT NULL CHECK (network_type IN ('MAINNET', 'TESTNET', 'DEVNET')),
    contract_address TEXT,
    token_id VARCHAR(100),
    
    -- Transaction Information
    transaction_hash TEXT NOT NULL,
    block_number BIGINT,
    block_timestamp TIMESTAMP WITH TIME ZONE,
    gas_used BIGINT,
    transaction_status VARCHAR(20) DEFAULT 'PENDING' 
        CHECK (transaction_status IN ('PENDING', 'CONFIRMED', 'FAILED')),
    
    -- Verification & Status
    did_status VARCHAR(20) DEFAULT 'ACTIVE' 
        CHECK (did_status IN ('ACTIVE', 'SUSPENDED', 'REVOKED', 'EXPIRED')),
    verification_url TEXT,
    qr_code_url TEXT,
    
    -- Key Management
    public_key TEXT,
    private_key_encrypted TEXT, -- Encrypted with master key
    key_type VARCHAR(50) DEFAULT 'secp256k1',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    issued_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(user_id)
);

-- =============================================
-- 8. SAFETY SCORING ENGINE
-- =============================================

CREATE TABLE safety_data_sources (
    source_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_type VARCHAR(50) NOT NULL CHECK (source_type IN ('GOVERNMENT', 'POLICE', 'INCIDENT', 'CROWDSOURCE')),
    zone_id UUID REFERENCES geo_fence_zones(zone_id),
    data_points JSONB NOT NULL,
    confidence_score INTEGER CHECK (confidence_score BETWEEN 0 AND 100),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE safety_scores (
    score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_id UUID REFERENCES geo_fence_zones(zone_id),
    overall_score INTEGER CHECK (overall_score BETWEEN 0 AND 100),
    breakdown JSONB NOT NULL, -- {"government": 85, "police": 70, "incident": 60, "crowdsource": 90}
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 9. GEO-FENCE ZONE MANAGEMENT
-- =============================================

CREATE TABLE geo_fence_zones (
    zone_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Zone Information
    zone_name VARCHAR(255) NOT NULL,
    zone_description TEXT,
    zone_type VARCHAR(20) NOT NULL 
        CHECK (zone_type IN ('SAFE_ZONE', 'DANGER_ZONE', 'RESTRICTED_AREA', 'TOURIST_SPOT', 'EMERGENCY_SERVICE')),
    
    -- Geographic Boundaries
    boundary_geometry GEOMETRY(POLYGON, 4326) NOT NULL,
    center_point GEOMETRY(POINT, 4326),
    radius_meters DOUBLE PRECISION, -- For circular zones
    
    -- Safety Metrics
    safety_score INTEGER CHECK (safety_score BETWEEN 0 AND 100),
    risk_factors JSONB, -- {"crime_rate": 0.3, "accident_rate": 0.1, "lighting_quality": 0.8}
    historical_incident_count INTEGER DEFAULT 0,
    
    -- Contact Information
    local_police_station VARCHAR(255),
    police_contact VARCHAR(20),
    nearest_hospital VARCHAR(255),
    hospital_contact VARCHAR(20),
    tourist_helpline VARCHAR(20),
    
    -- Alert Settings
    alert_on_entry BOOLEAN DEFAULT FALSE,
    alert_on_exit BOOLEAN DEFAULT FALSE,
    alert_on_dwell BOOLEAN DEFAULT FALSE,
    max_dwell_time_minutes INTEGER,
    
    -- Time-based Restrictions
    time_restrictions JSONB, -- {"night_restricted": true, "start_time": "22:00", "end_time": "05:00"}
    
    -- Management
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(user_id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 10. REAL-TIME LOCATION TRACKING
-- =============================================

CREATE TABLE tourist_locations (
    location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- GPS Coordinates
    geom GEOMETRY(POINT, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    altitude DOUBLE PRECISION,
    
    -- Accuracy & Context
    accuracy_meters DOUBLE PRECISION,
    battery_level INTEGER,
    network_type VARCHAR(20),
    location_source VARCHAR(20) DEFAULT 'GPS' CHECK (location_source IN ('GPS', 'NETWORK', 'MANUAL')),
    
    -- Movement Analysis
    speed_kph DOUBLE PRECISION,
    heading_degrees DOUBLE PRECISION,
    activity_type VARCHAR(50), -- 'walking', 'driving', 'stationary'
    confidence_score DOUBLE PRECISION,
    
    -- Zone Context
    current_zone_id UUID REFERENCES geo_fence_zones(zone_id),
    zone_entered_at TIMESTAMP WITH TIME ZONE,
    
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 11. INCIDENT REPORTING SYSTEM
-- =============================================

CREATE TABLE incidents (
    incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Incident Information
    incident_type VARCHAR(50) NOT NULL 
        CHECK (incident_type IN (
            'SOS_EMERGENCY', 'THEFT', 'MEDICAL_EMERGENCY', 'HARASSMENT', 
            'ACCIDENT', 'LOST', 'NATURAL_DISASTER', 'AI_DETECTED_SAFETY_RISK',
            'GEOFENCE_BREACH', 'OTHER'
        )),
    severity_level VARCHAR(20) NOT NULL DEFAULT 'MEDIUM'
        CHECK (severity_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    
    -- Reporter Information
    reporter_user_id UUID REFERENCES users(user_id),
    reporter_type VARCHAR(20) DEFAULT 'TOURIST' 
        CHECK (reporter_type IN ('TOURIST', 'ADMIN', 'AI_SYSTEM', 'RESPONDER')),
    
    -- Victim Information (if different from reporter)
    victim_user_id UUID REFERENCES users(user_id),
    
    -- Location Details
    incident_location GEOMETRY(POINT, 4326),
    incident_address TEXT,
    landmark_description TEXT,
    zone_id UUID REFERENCES geo_fence_zones(zone_id),
    
    -- Incident Details
    title VARCHAR(255) NOT NULL,
    description TEXT,
    media_attachments TEXT[], -- URLs to images/videos
    family_notified BOOLEAN DEFAULT FALSE, -- Added for family monitoring
    
    -- AI Analysis
    ai_confidence_score DOUBLE PRECISION,
    ai_detected_patterns TEXT[],
    ai_risk_assessment JSONB,
    ai_recommended_actions TEXT[],
    
    -- Status & Timeline
    status VARCHAR(20) DEFAULT 'REPORTED'
        CHECK (status IN ('REPORTED', 'VERIFIED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'FALSE_ALARM')),
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    -- Response Metrics
    first_response_time_seconds INTEGER,
    total_resolution_time_seconds INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 12. RESPONDER MANAGEMENT
-- =============================================

CREATE TABLE responders (
    responder_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Responder Information
    responder_type VARCHAR(50) NOT NULL 
        CHECK (responder_type IN ('POLICE', 'MEDICAL', 'FIRE', 'TOURIST_POLICE', 'VOLUNTEER', 'SECURITY')),
    badge_number VARCHAR(100),
    department VARCHAR(255),
    rank VARCHAR(100),
    
    -- Contact Information
    official_phone VARCHAR(20),
    radio_frequency VARCHAR(50),
    emergency_contact VARCHAR(255),
    
    -- Location & Availability
    current_location GEOMETRY(POINT, 4326),
    base_station_location GEOMETRY(POINT, 4326),
    coverage_radius_meters DOUBLE PRECISION,
    
    -- Availability Status
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE'
        CHECK (availability_status IN ('AVAILABLE', 'BUSY', 'OFF_DUTY', 'ON_BREAK', 'UNAVAILABLE')),
    current_status_description TEXT,
    
    -- Capabilities & Resources
    capabilities TEXT[], -- ['first_aid', 'rescue', 'investigation', 'crowd_control']
    assigned_equipment JSONB,
    vehicle_info JSONB,
    
    -- Performance Metrics
    total_incidents_handled INTEGER DEFAULT 0,
    average_response_time_seconds INTEGER,
    success_rate DOUBLE PRECISION,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_active_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- =============================================
-- 13. INCIDENT RESPONSE ASSIGNMENTS
-- =============================================

CREATE TABLE incident_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id UUID NOT NULL REFERENCES incidents(incident_id) ON DELETE CASCADE,
    responder_id UUID NOT NULL REFERENCES responders(responder_id) ON DELETE CASCADE,
    
    -- Assignment Details
    assignment_type VARCHAR(20) DEFAULT 'PRIMARY' 
        CHECK (assignment_type IN ('PRIMARY', 'SUPPORT', 'BACKUP')),
    assigned_by UUID REFERENCES users(user_id),
    
    -- Status & Timeline
    assignment_status VARCHAR(20) DEFAULT 'ASSIGNED'
        CHECK (assignment_status IN ('ASSIGNED', 'ACKNOWLEDGED', 'EN_ROUTE', 'ON_SCENE', 'COMPLETED', 'CANCELLED')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    en_route_at TIMESTAMP WITH TIME ZONE,
    on_scene_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Response Metrics
    travel_time_seconds INTEGER,
    on_scene_time_seconds INTEGER,
    
    -- Notes & Feedback
    assignment_notes TEXT,
    responder_feedback TEXT,
    quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(incident_id, responder_id)
);

-- =============================================
-- 14. WEARABLE DEVICES INTEGRATION
-- =============================================

CREATE TABLE wearable_devices (
    device_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    device_type VARCHAR(50) NOT NULL 
        CHECK (device_type IN ('APPLE_WATCH', 'WEAR_OS', 'FITBIT', 'OTHER')),
    device_name VARCHAR(255),
    device_token TEXT,
    capabilities JSONB DEFAULT '{"panic_button": true, "heart_rate": false, "fall_detection": false}',
    battery_level INTEGER,
    last_sync TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 15. MULTI-LANGUAGE SUPPORT SYSTEM
-- =============================================

CREATE TABLE localized_content (
    content_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_key VARCHAR(255) NOT NULL UNIQUE,
    content_type VARCHAR(50) NOT NULL 
        CHECK (content_type IN ('ALERT', 'BUTTON', 'MENU', 'MESSAGE', 'TITLE', 'DESCRIPTION')),
    translations JSONB NOT NULL, -- {"en": "Emergency", "hi": "आपातकाल", "ta": "அவசர"}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 16. ALERTS & NOTIFICATIONS SYSTEM
-- =============================================

CREATE TABLE alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Alert Information
    alert_type VARCHAR(50) NOT NULL 
        CHECK (alert_type IN (
            'GEOFENCE_BREACH', 'SOS_TRIGGERED', 'HEALTH_EMERGENCY', 
            'WEATHER_ALERT', 'CRIME_ALERT', 'ITINERARY_DEVIATION',
            'AI_SAFETY_RISK', 'SYSTEM_ANNOUNCEMENT'
        )),
    severity VARCHAR(20) DEFAULT 'MEDIUM'
        CHECK (severity IN ('INFO', 'WARNING', 'ALERT', 'EMERGENCY')),
    
    -- Source Information
    triggered_by_user_id UUID REFERENCES users(user_id),
    triggered_by_system VARCHAR(100), -- 'AI_ENGINE', 'GEOFENCE_SYSTEM', 'MANUAL'
    source_incident_id UUID REFERENCES incidents(incident_id),
    source_zone_id UUID REFERENCES geo_fence_zones(zone_id),
    
    -- Alert Content
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    localized_messages JSONB, -- Multi-language support
    recommended_actions TEXT[],
    
    -- Geographic Context
    alert_location GEOMETRY(POINT, 4326),
    affected_radius_meters DOUBLE PRECISION,
    
    -- Delivery Management
    delivery_channels JSONB DEFAULT '{"push": true, "sms": true, "email": false}',
    target_audience JSONB, -- Specific user groups or all tourists
    
    -- Status & Expiry
    alert_status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (alert_status IN ('ACTIVE', 'ACKNOWLEDGED', 'EXPIRED', 'CANCELLED')),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 17. OTP MANAGEMENT SYSTEM
-- =============================================

CREATE TABLE otp_verifications (
    otp_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- OTP Details
    otp_type VARCHAR(20) NOT NULL CHECK (otp_type IN ('EMAIL_VERIFICATION', 'PHONE_VERIFICATION', 'AADHAAR_OTP', 'LOGIN_2FA', 'PASSWORD_RESET')),
    otp_code VARCHAR(10) NOT NULL,
    otp_hash TEXT NOT NULL, -- Hashed OTP for security
    
    -- Destination
    recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('EMAIL', 'PHONE', 'AADHAAR_MOBILE')),
    recipient_value VARCHAR(255) NOT NULL, -- email, phone number, etc.
    
    -- Validity & Usage
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    attempts_count INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    
    -- Context
    session_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    purpose_metadata JSONB, -- Additional context for the OTP
    
    -- Status
    status VARCHAR(20) DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'VERIFIED', 'EXPIRED', 'MAX_ATTEMPTS_EXCEEDED')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 18. JWT TOKEN MANAGEMENT
-- =============================================

CREATE TABLE jwt_tokens (
    token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Token Information
    token_hash TEXT NOT NULL UNIQUE, -- Hashed JWT for security
    token_type VARCHAR(20) DEFAULT 'ACCESS' CHECK (token_type IN ('ACCESS', 'REFRESH')),
    device_id VARCHAR(255),
    user_agent TEXT,
    ip_address INET,
    
    -- Validity
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    revocation_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 19. FAILED LOGIN ATTEMPTS LOG
-- =============================================

CREATE TABLE failed_login_attempts (
    attempt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Attempt Details
    email VARCHAR(255),
    phone_number VARCHAR(20),
    ip_address INET NOT NULL,
    user_agent TEXT,
    
    -- Context
    attempt_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    failure_reason VARCHAR(100),
    provided_password_hash TEXT, -- For security analysis (hashed)
    
    -- Geographic Context
    country_code VARCHAR(3),
    city VARCHAR(100),
    isp VARCHAR(255),
    
    -- Risk Assessment
    risk_score INTEGER DEFAULT 0,
    is_suspicious BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 20. AUDIT LOGS FOR SECURITY & COMPLIANCE
-- =============================================

CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Actor Information
    actor_type VARCHAR(20) NOT NULL CHECK (actor_type IN ('USER', 'ADMIN', 'SYSTEM', 'AI_ENGINE')),
    actor_id UUID, -- Reference to users table
    actor_name VARCHAR(255),
    
    -- Action Details
    action_type VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(100),
    resource_name VARCHAR(255),
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    location GEOMETRY(POINT, 4326),
    
    -- Changes
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    
    -- AI Context
    ai_confidence_score DOUBLE PRECISION,
    ai_reasoning TEXT,
    
    -- Status
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_status ON users(account_status);
CREATE INDEX idx_users_kyc_status ON users(kyc_status);
CREATE INDEX idx_users_language ON users(preferred_language);

-- Tourist profiles indexes
CREATE INDEX idx_tourist_profiles_user_id ON tourist_profiles(user_id);
CREATE INDEX idx_tourist_profiles_dates ON tourist_profiles(arrival_date, departure_date);
CREATE INDEX idx_tourist_profiles_risk ON tourist_profiles(risk_level, safety_risk_score);

-- Emergency contacts indexes
CREATE INDEX idx_emergency_contacts_user_id ON emergency_contacts(user_id);
CREATE INDEX idx_emergency_contacts_primary ON emergency_contacts(user_id, is_primary);

-- Family monitoring indexes
CREATE INDEX idx_family_monitoring_tourist ON family_monitoring(tourist_user_id);
CREATE INDEX idx_family_monitoring_family ON family_monitoring(family_user_id);

-- Aadhaar verification indexes
CREATE INDEX idx_aadhaar_user_id ON aadhaar_verifications(user_id);
CREATE INDEX idx_aadhaar_status ON aadhaar_verifications(verification_status);
CREATE INDEX idx_aadhaar_reference_hash ON aadhaar_verifications(aadhaar_reference_hash);

-- Passport verification indexes
CREATE INDEX idx_passport_user_id ON passport_verifications(user_id);
CREATE INDEX idx_passport_country ON passport_verifications(passport_country);
CREATE INDEX idx_passport_status ON passport_verifications(verification_status);

-- Digital identity indexes
CREATE INDEX idx_did_user_id ON digital_identities(user_id);
CREATE INDEX idx_did_identifier ON digital_identities(did_identifier);
CREATE INDEX idx_did_status ON digital_identities(did_status);
CREATE INDEX idx_did_transaction_hash ON digital_identities(transaction_hash);

-- Safety scoring indexes
CREATE INDEX idx_safety_scores_zone ON safety_scores(zone_id);
CREATE INDEX idx_safety_scores_calculated ON safety_scores(calculated_at);
CREATE INDEX idx_safety_data_sources_type ON safety_data_sources(source_type);

-- Geospatial indexes
CREATE INDEX idx_geo_zones_boundary ON geo_fence_zones USING GIST(boundary_geometry);
CREATE INDEX idx_tourist_locations_geom ON tourist_locations USING GIST(geom);
CREATE INDEX idx_tourist_locations_user_time ON tourist_locations(user_id, timestamp DESC);
CREATE INDEX idx_incidents_location ON incidents USING GIST(incident_location);
CREATE INDEX idx_responders_location ON responders USING GIST(current_location);

-- Incident indexes
CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_type ON incidents(incident_type);
CREATE INDEX idx_incidents_reporter ON incidents(reporter_user_id);
CREATE INDEX idx_incidents_timestamp ON incidents(reported_at DESC);

-- Responder indexes
CREATE INDEX idx_responders_status ON responders(availability_status);
CREATE INDEX idx_responders_type ON responders(responder_type);

-- Assignment indexes
CREATE INDEX idx_assignments_incident ON incident_assignments(incident_id);
CREATE INDEX idx_assignments_responder ON incident_assignments(responder_id);
CREATE INDEX idx_assignments_status ON incident_assignments(assignment_status);

-- Wearable devices indexes
CREATE INDEX idx_wearable_user_id ON wearable_devices(user_id);
CREATE INDEX idx_wearable_type ON wearable_devices(device_type);

-- Localized content indexes
CREATE INDEX idx_localized_key ON localized_content(content_key);
CREATE INDEX idx_localized_type ON localized_content(content_type);

-- Alert indexes
CREATE INDEX idx_alerts_type ON alerts(alert_type);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_status ON alerts(alert_status);
CREATE INDEX idx_alerts_created ON alerts(created_at DESC);

-- OTP indexes
CREATE INDEX idx_otp_user_id ON otp_verifications(user_id);
CREATE INDEX idx_otp_recipient ON otp_verifications(recipient_value, otp_type);
CREATE INDEX idx_otp_expires ON otp_verifications(expires_at) WHERE status = 'ACTIVE';

-- JWT token indexes
CREATE INDEX idx_jwt_user_id ON jwt_tokens(user_id);
CREATE INDEX idx_jwt_expires ON jwt_tokens(expires_at) WHERE is_active = true;

-- Failed login indexes
CREATE INDEX idx_failed_login_ip ON failed_login_attempts(ip_address, attempt_timestamp);
CREATE INDEX idx_failed_login_email ON failed_login_attempts(email, attempt_timestamp);

-- Audit log indexes
CREATE INDEX idx_audit_actor ON audit_logs(actor_type, actor_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX idx_audit_action ON audit_logs(action_type);

-- =============================================
-- STORED PROCEDURES & FUNCTIONS
-- =============================================

-- 1. OTP Verification Function
CREATE OR REPLACE FUNCTION verify_otp_code(
    p_otp_id UUID,
    p_otp_code VARCHAR(10),
    p_session_id VARCHAR(255) DEFAULT NULL
) RETURNS TABLE(
    is_valid BOOLEAN,
    user_id UUID,
    message TEXT
) AS $$
DECLARE
    v_otp_record otp_verifications%ROWTYPE;
    v_current_time TIMESTAMP := NOW();
BEGIN
    -- Get OTP record
    SELECT * INTO v_otp_record 
    FROM otp_verifications 
    WHERE otp_id = p_otp_id 
    AND status = 'ACTIVE';
    
    -- Check if OTP exists
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL, 'OTP not found or already used'::TEXT;
        RETURN;
    END IF;
    
    -- Check if OTP is expired
    IF v_otp_record.expires_at < v_current_time THEN
        UPDATE otp_verifications 
        SET status = 'EXPIRED' 
        WHERE otp_id = p_otp_id;
        
        RETURN QUERY SELECT FALSE, NULL, 'OTP has expired'::TEXT;
        RETURN;
    END IF;
    
    -- Check if max attempts exceeded
    IF v_otp_record.attempts_count >= v_otp_record.max_attempts THEN
        UPDATE otp_verifications 
        SET status = 'MAX_ATTEMPTS_EXCEEDED' 
        WHERE otp_id = p_otp_id;
        
        RETURN QUERY SELECT FALSE, NULL, 'Maximum verification attempts exceeded'::TEXT;
        RETURN;
    END IF;
    
    -- Increment attempts count
    UPDATE otp_verifications 
    SET attempts_count = attempts_count + 1 
    WHERE otp_id = p_otp_id;
    
    -- Verify OTP (compare hashed values)
    IF crypt(p_otp_code, v_otp_record.otp_hash) = v_otp_record.otp_hash THEN
        -- OTP is valid
        UPDATE otp_verifications 
        SET 
            status = 'VERIFIED',
            verified_at = v_current_time,
            session_id = COALESCE(p_session_id, session_id)
        WHERE otp_id = p_otp_id;
        
        RETURN QUERY SELECT TRUE, v_otp_record.user_id, 'OTP verified successfully'::TEXT;
    ELSE
        -- OTP is invalid
        RETURN QUERY SELECT FALSE, v_otp_record.user_id, 'Invalid OTP code'::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 2. Safety Score Calculation Function
CREATE OR REPLACE FUNCTION calculate_safety_score(
    p_zone_id UUID
) RETURNS TABLE(
    zone_id UUID,
    overall_score INTEGER,
    breakdown JSONB,
    message TEXT
) AS $$
DECLARE
    v_gov_score INTEGER;
    v_police_score INTEGER;
    v_incident_score INTEGER;
    v_crowd_score INTEGER;
    v_weighted_score INTEGER;
    v_data_count INTEGER;
BEGIN
    -- Calculate weighted average from different sources
    SELECT 
        AVG(CASE WHEN source_type = 'GOVERNMENT' THEN confidence_score END),
        AVG(CASE WHEN source_type = 'POLICE' THEN confidence_score END),
        AVG(CASE WHEN source_type = 'INCIDENT' THEN confidence_score END),
        AVG(CASE WHEN source_type = 'CROWDSOURCE' THEN confidence_score END),
        COUNT(*)
    INTO v_gov_score, v_police_score, v_incident_score, v_crowd_score, v_data_count
    FROM safety_data_sources
    WHERE zone_id = p_zone_id
    AND collected_at > NOW() - INTERVAL '7 days';
    
    -- If no data, return default score
    IF v_data_count = 0 THEN
        RETURN QUERY SELECT p_zone_id, 50, 
            '{"government": 50, "police": 50, "incident": 50, "crowdsource": 50}'::JSONB,
            'Insufficient data for accurate scoring'::TEXT;
        RETURN;
    END IF;
    
    -- Calculate weighted score (40% gov, 30% police, 20% incident, 10% crowd)
    v_weighted_score := 
        COALESCE(v_gov_score, 50) * 0.4 +
        COALESCE(v_police_score, 50) * 0.3 +
        COALESCE(v_incident_score, 50) * 0.2 +
        COALESCE(v_crowd_score, 50) * 0.1;
    
    -- Insert or update safety score
    INSERT INTO safety_scores (
        zone_id, overall_score, breakdown, expires_at
    ) VALUES (
        p_zone_id, 
        v_weighted_score::INTEGER,
        jsonb_build_object(
            'government', COALESCE(v_gov_score, 50),
            'police', COALESCE(v_police_score, 50),
            'incident', COALESCE(v_incident_score, 50),
            'crowdsource', COALESCE(v_crowd_score, 50)
        ),
        NOW() + INTERVAL '1 hour'
    )
    ON CONFLICT (zone_id) 
    DO UPDATE SET
        overall_score = EXCLUDED.overall_score,
        breakdown = EXCLUDED.breakdown,
        calculated_at = NOW(),
        expires_at = EXCLUDED.expires_at;
    
    RETURN QUERY SELECT p_zone_id, v_weighted_score::INTEGER,
        jsonb_build_object(
            'government', COALESCE(v_gov_score, 50),
            'police', COALESCE(v_police_score, 50),
            'incident', COALESCE(v_incident_score, 50),
            'crowdsource', COALESCE(v_crowd_score, 50)
        ),
        'Safety score calculated successfully'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 3. Emergency Alert Function
CREATE OR REPLACE FUNCTION trigger_emergency_alert(
    p_user_id UUID,
    p_incident_type VARCHAR(50),
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION
) RETURNS TABLE(
    alert_id UUID,
    contacts_notified INTEGER,
    message TEXT
) AS $$
DECLARE
    v_alert_id UUID;
    v_incident_id UUID;
    v_contacts_count INTEGER;
    v_geom GEOMETRY;
BEGIN
    -- Create geometry from coordinates
    v_geom := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326);
    
    -- Create incident record
    INSERT INTO incidents (
        incident_type, severity_level, reporter_user_id, victim_user_id,
        incident_location, title, description, status, family_notified
    ) VALUES (
        p_incident_type, 'CRITICAL', p_user_id, p_user_id,
        v_geom, 'Emergency Alert', 'User triggered emergency alert', 'REPORTED', TRUE
    )
    RETURNING incident_id INTO v_incident_id;
    
    -- Create emergency alert
    INSERT INTO alerts (
        alert_type, severity, triggered_by_user_id, source_incident_id,
        title, message, alert_location, delivery_channels, target_audience
    ) VALUES (
        'SOS_TRIGGERED', 'EMERGENCY', p_user_id, v_incident_id,
        'EMERGENCY ALERT', 'User has triggered emergency alert',
        v_geom, '{"push": true, "sms": true, "email": true}', 
        '{"emergency_contacts": true, "responders": true}'
    )
    RETURNING alert_id INTO v_alert_id;
    
    -- Count emergency contacts to notify
    SELECT COUNT(*) INTO v_contacts_count
    FROM emergency_contacts
    WHERE user_id = p_user_id AND is_active = true;
    
    RETURN QUERY SELECT v_alert_id, v_contacts_count, 
        'Emergency alert triggered successfully'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 4. Family Notification Function
CREATE OR REPLACE FUNCTION notify_family_members(
    p_tourist_user_id UUID,
    p_alert_type VARCHAR(50),
    p_message TEXT,
    p_location GEOMETRY
) RETURNS TABLE(
    members_notified INTEGER,
    message TEXT
) AS $$
DECLARE
    v_members_count INTEGER;
BEGIN
    -- Count family members to notify
    SELECT COUNT(*) INTO v_members_count
    FROM family_monitoring
    WHERE tourist_user_id = p_tourist_user_id AND is_active = true;
    
    -- Create alerts for family members
    INSERT INTO alerts (
        alert_type, severity, triggered_by_user_id,
        title, message, alert_location, 
        delivery_channels, target_audience
    )
    SELECT 
        p_alert_type,
        'WARNING',
        p_tourist_user_id,
        'Family Member Alert',
        p_message,
        p_location,
        '{"push": true, "sms": true}',
        jsonb_build_object('family_members', true)
    FROM family_monitoring
    WHERE tourist_user_id = p_tourist_user_id AND is_active = true;
    
    RETURN QUERY SELECT v_members_count, 
        'Family members notified successfully'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- TRIGGERS FOR AUTOMATED UPDATES
-- =============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tourist_profiles_updated_at BEFORE UPDATE ON tourist_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_aadhaar_verifications_updated_at BEFORE UPDATE ON aadhaar_verifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_passport_verifications_updated_at BEFORE UPDATE ON passport_verifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_digital_identities_updated_at BEFORE UPDATE ON digital_identities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_geo_fence_zones_updated_at BEFORE UPDATE ON geo_fence_zones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_responders_updated_at BEFORE UPDATE ON responders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_incident_assignments_updated_at BEFORE UPDATE ON incident_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alerts_updated_at BEFORE UPDATE ON alerts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_localized_content_updated_at BEFORE UPDATE ON localized_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SAMPLE DATA INSERTION
-- =============================================

-- Insert sample admin user
INSERT INTO users (
    email, phone_number, password_hash, user_type, 
    first_name, last_name, date_of_birth, gender, nationality,
    account_status, email_verified, phone_verified, kyc_status, preferred_language
) VALUES (
    'admin@tourguard.gov',
    '9876543210',
    crypt('Admin123!', gen_salt('bf')),
    'ADMIN',
    'System', 'Administrator', '1980-01-01', 'MALE', 'IND',
    'ACTIVE', true, true, 'VERIFIED', 'en'
);

-- Insert sample tourist user (Indian)
INSERT INTO users (
    email, phone_number, password_hash, user_type, 
    first_name, last_name, date_of_birth, gender, nationality,
    account_status, email_verified, phone_verified, kyc_status, preferred_language
) VALUES (
    'raj.sharma@example.com',
    '9876543211',
    crypt('Tourist123!', gen_salt('bf')),
    'TOURIST',
    'Raj', 'Sharma', '1990-05-15', 'MALE', 'IND',
    'ACTIVE', true, true, 'VERIFIED', 'hi'
);

-- Insert sample tourist user (Foreign)
INSERT INTO users (
    email, phone_number, password_hash, user_type, 
    first_name, last_name, date_of_birth, gender, nationality,
    account_status, email_verified, phone_verified, kyc_status, preferred_language
) VALUES (
    'john.smith@example.com',
    '+1-555-0123',
    crypt('Tourist123!', gen_salt('bf')),
    'TOURIST',
    'John', 'Smith', '1985-08-20', 'MALE', 'USA',
    'ACTIVE', true, true, 'VERIFIED', 'en'
);

-- Insert tourist profiles
INSERT INTO tourist_profiles (
    user_id, arrival_date, departure_date, purpose_of_visit,
    emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
    blood_group, preferred_language, device_id, family_sharing_enabled
) VALUES 
(
    (SELECT user_id FROM users WHERE email = 'raj.sharma@example.com'),
    '2024-01-15', '2024-01-30', 'TOURISM',
    'Priya Sharma', '9876543212', 'SISTER',
    'O+', 'hi', 'device_android_001', true
),
(
    (SELECT user_id FROM users WHERE email = 'john.smith@example.com'),
    '2024-01-10', '2024-02-10', 'TOURISM',
    'Sarah Smith', '+1-555-0124', 'WIFE',
    'A+', 'en', 'device_ios_001', false
);

-- Insert emergency contacts
INSERT INTO emergency_contacts (
    user_id, contact_name, relationship, phone_number, is_primary
) VALUES 
(
    (SELECT user_id FROM users WHERE email = 'raj.sharma@example.com'),
    'Priya Sharma', 'SISTER', '9876543212', true
),
(
    (SELECT user_id FROM users WHERE email = 'john.smith@example.com'),
    'Sarah Smith', 'WIFE', '+1-555-0124', true
);

-- Insert family monitoring
INSERT INTO family_monitoring (
    tourist_user_id, family_user_id, access_level
) VALUES (
    (SELECT user_id FROM users WHERE email = 'raj.sharma@example.com'),
    (SELECT user_id FROM users WHERE email = 'admin@tourguard.gov'),
    'FULL_ACCESS'
);

-- Insert sample Aadhaar verification
INSERT INTO aadhaar_verifications (
    user_id, aadhaar_masked_number, aadhaar_reference_hash,
    verification_status, uidai_kyc_status, verified_at
) VALUES (
    (SELECT user_id FROM users WHERE email = 'raj.sharma@example.com'),
    'XXXX-XXXX-1234',
    encode(digest('123412341234' || 'raj.sharma@example.com', 'sha256'), 'hex'),
    'COMPLETED', 'KYC_VERIFIED', NOW()
);

-- Insert sample passport verification
INSERT INTO passport_verifications (
    user_id, passport_number, passport_country, nationality,
    passport_full_name, passport_date_of_birth, passport_gender,
    passport_issue_date, passport_expiry_date,
    verification_status, verified_at
) VALUES (
    (SELECT user_id FROM users WHERE email = 'john.smith@example.com'),
    'A12345678', 'USA', 'USA',
    'JOHN SMITH', '1985-08-20', 'MALE',
    '2020-01-15', '2030-01-15',
    'VERIFIED', NOW()
);

-- Insert sample digital identities
INSERT INTO digital_identities (
    user_id, did_identifier, did_document, blockchain_name,
    network_type, transaction_hash, transaction_status, did_status
) VALUES 
(
    (SELECT user_id FROM users WHERE email = 'raj.sharma@example.com'),
    'did:india-tourist:rajsharma123',
    '{"@context": "https://www.w3.org/ns/did/v1", "id": "did:india-tourist:rajsharma123"}',
    'Polygon', 'TESTNET', '0xabc123def456', 'CONFIRMED', 'ACTIVE'
),
(
    (SELECT user_id FROM users WHERE email = 'john.smith@example.com'),
    'did:india-tourist:johnsmith456',
    '{"@context": "https://www.w3.org/ns/did/v1", "id": "did:india-tourist:johnsmith456"}',
    'Polygon', 'TESTNET', '0xdef456abc123', 'CONFIRMED', 'ACTIVE'
);

-- Insert sample geo-fence zones
INSERT INTO geo_fence_zones (
    zone_name, zone_description, zone_type,
    boundary_geometry, center_point, safety_score,
    local_police_station, police_contact, nearest_hospital, hospital_contact
) VALUES 
(
    'City Center Safe Zone',
    'Well-lit area with police patrols and tourist facilities',
    'SAFE_ZONE',
    ST_GeomFromText('POLYGON((77.2090 28.6139, 77.2090 28.6149, 77.2100 28.6149, 77.2100 28.6139, 77.2090 28.6139))', 4326),
    ST_GeomFromText('POINT(77.2095 28.6144)', 4326),
    85,
    'Central Police Station', '100', 'City General Hospital', '102'
),
(
    'Old Market Area - High Alert',
    'High crime rate area, limited lighting at night',
    'DANGER_ZONE',
    ST_GeomFromText('POLYGON((77.2110 28.6150, 77.2110 28.6160, 77.2120 28.6160, 77.2120 28.6150, 77.2110 28.6150))', 4326),
    ST_GeomFromText('POINT(77.2115 28.6155)', 4326),
    30,
    'Market Police Station', '101', 'Market Area Hospital', '103'
);

-- Insert safety data sources
INSERT INTO safety_data_sources (
    source_type, zone_id, data_points, confidence_score
) VALUES 
(
    'GOVERNMENT',
    (SELECT zone_id FROM geo_fence_zones WHERE zone_name = 'City Center Safe Zone'),
    '{"crime_rate": 0.05, "lighting_index": 0.9, "police_presence": 0.8}',
    85
),
(
    'POLICE',
    (SELECT zone_id FROM geo_fence_zones WHERE zone_name = 'Old Market Area - High Alert'),
    '{"recent_incidents": 12, "response_time": 15, "patrol_frequency": 0.3}',
    40
);

-- Insert safety scores
INSERT INTO safety_scores (
    zone_id, overall_score, breakdown
) VALUES 
(
    (SELECT zone_id FROM geo_fence_zones WHERE zone_name = 'City Center Safe Zone'),
    85,
    '{"government": 85, "police": 80, "incident": 75, "crowdsource": 90}'
),
(
    (SELECT zone_id FROM geo_fence_zones WHERE zone_name = 'Old Market Area - High Alert'),
    30,
    '{"government": 25, "police": 40, "incident": 20, "crowdsource": 35}'
);

-- Insert localized content
INSERT INTO localized_content (
    content_key, content_type, translations
) VALUES 
(
    'emergency_button',
    'BUTTON',
    '{"en": "Emergency", "hi": "आपातकाल", "ta": "அவசர", "te": "అత్యవసర", "bn": "জরুরী", "ml": "അടിയന്തര", "mr": "आणीबाणी"}'
),
(
    'safety_score',
    'TITLE',
    '{"en": "Safety Score", "hi": "सुरक्षा स्कोर", "ta": "பாதுகாப்பு மதிப்பெண்", "te": "భద్రత స్కోరు", "bn": "সুরক্ষা স্কোর", "ml": "സുരക്ഷാ സ്കോർ", "mr": "सुरक्षा स्कोअर"}'
);

-- Insert wearable device
INSERT INTO wearable_devices (
    user_id, device_type, device_name, capabilities
) VALUES (
    (SELECT user_id FROM users WHERE email = 'raj.sharma@example.com'),
    'APPLE_WATCH',
    'Raj''s Apple Watch',
    '{"panic_button": true, "heart_rate": true, "fall_detection": true}'
);

-- Insert sample responders
INSERT INTO responders (
    user_id, responder_type, badge_number, department,
    availability_status, capabilities, is_active
) VALUES 
(
    (SELECT user_id FROM users WHERE email = 'admin@tourguard.gov'),
    'POLICE', 'POL123', 'Tourist Police',
    'AVAILABLE', '{"first_aid", "investigation", "crowd_control"}', true
);

-- =============================================
-- DATABASE SECURITY & MAINTENANCE
-- =============================================

-- Create read-only user for analytics
CREATE USER analytics_user WITH PASSWORD 'secure_password_123';
GRANT CONNECT ON DATABASE smart_tourist_safety TO analytics_user;
GRANT USAGE ON SCHEMA public TO analytics_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;

-- Create application user
CREATE USER app_user WITH PASSWORD 'app_secure_password_456';
GRANT CONNECT ON DATABASE smart_tourist_safety TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Set up automated vacuum and analyze
ALTER SYSTEM SET autovacuum = on;
ALTER SYSTEM SET autovacuum_analyze_scale_factor = 0.1;
ALTER SYSTEM SET autovacuum_analyze_threshold = 50;

-- Enable query logging for performance monitoring
ALTER SYSTEM SET log_statement = 'none';
ALTER SYSTEM SET log_duration = off;
ALTER SYSTEM SET log_min_duration_statement = 1000;

SELECT pg_reload_conf();

-- Create maintenance function for cleaning old data
CREATE OR REPLACE FUNCTION perform_database_maintenance()
RETURNS VOID AS $$
BEGIN
    -- Clean expired OTPs older than 7 days
    DELETE FROM otp_verifications 
    WHERE expires_at < NOW() - INTERVAL '7 days';
    
    -- Clean old failed login attempts (older than 30 days)
    DELETE FROM failed_login_attempts 
    WHERE attempt_timestamp < NOW() - INTERVAL '30 days';
    
    -- Clean expired JWT tokens
    DELETE FROM jwt_tokens 
    WHERE expires_at < NOW() - INTERVAL '1 day';
    
    -- Archive old location data (keep only 30 days)
    DELETE FROM tourist_locations 
    WHERE timestamp < NOW() - INTERVAL '30 days';
    
    -- Clean expired safety scores
    DELETE FROM safety_scores 
    WHERE expires_at < NOW();
    
    RAISE NOTICE 'Database maintenance completed successfully';
END;
$$ LANGUAGE plpgsql;

-- Schedule maintenance (run this function daily via cron)
COMMENT ON FUNCTION perform_database_maintenance() IS 'Daily maintenance: clean expired OTPs, old locations, expired safety scores';

-- =============================================
-- FINAL DATABASE COMMENT
-- =============================================

COMMENT ON DATABASE smart_tourist_safety IS 
'TOURGUARD - Complete Tourist Safety Platform Database 
Features: Blockchain DID, Multi-language Support, Safety Scoring, 
Family Monitoring, Emergency Contacts, Wearable Integration, 
Real-time Location Tracking, AI-powered Safety Analytics';

-- =============================================
-- DATABASE IS READY FOR TOURGUARD DEPLOYMENT
-- =============================================