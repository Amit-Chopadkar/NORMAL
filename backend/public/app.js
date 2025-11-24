// Configuration
const API_BASE_URL = window.location.origin;
const SOCKET_URL = window.location.origin;

// State
let socket;
let map;
let currentIncident = null;
let markers = {};
let authToken = localStorage.getItem('adminToken');
let currentUser = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    if (!authToken) {
        showLoginModal();
    } else {
        initializeApp();
    }
});

// Login
function showLoginModal() {
    document.getElementById('loginModal').classList.add('show');
}

function hideLoginModal() {
    document.getElementById('loginModal').classList.remove('show');
}

document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    const errorDiv = document.getElementById('loginError');

    try {
        const response = await fetch(`${API_BASE_URL}/api/user/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (data.success) {
            authToken = data.data.token;
            localStorage.setItem('adminToken', authToken);
            hideLoginModal();
            initializeApp();
        } else {
            errorDiv.textContent = data.message || 'Login failed';
            errorDiv.classList.add('show');
        }
    } catch (error) {
        errorDiv.textContent = 'Connection error. Please try again.';
        errorDiv.classList.add('show');
    }
});

// Initialize App
async function initializeApp() {
    initializeMap();
    initializeSocket();
    loadUsers();
    loadAlerts();
    loadResources();
    setupEventListeners();
    startPolling();
}

// Initialize Google Maps
function initializeMap() {
    map = new google.maps.Map(document.getElementById('map'), {
        zoom: 12,
        center: { lat: 28.6139, lng: 77.2090 }, // Default to Delhi
        mapTypeId: 'roadmap'
    });
}

// Initialize Socket.IO
function initializeSocket() {
    socket = io(SOCKET_URL);

    socket.on('connect', () => {
        console.log('Connected to server');
        socket.emit('join-admin');
        addLogEntry('[System] Connected to server');
    });

    socket.on('live-location', (data) => {
        updateUserLocation(data);
        addLogEntry(`[${formatTime(new Date())}] Location update from ${data.name || data.userId}`);
    });

    socket.on('new-alert', (data) => {
        handleNewAlert(data.alert);
        addLogEntry(`[${formatTime(new Date())}] SOS activated by ${data.alert.user?.name || 'User'}`);
    });

    socket.on('disconnect', () => {
        addLogEntry('[System] Disconnected from server');
    });
}

// Load Users
async function loadUsers() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/users`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        const data = await response.json();
        if (data.success) {
            // Store users for reference
            window.users = data.data.users;
        }
    } catch (error) {
        console.error('Error loading users:', error);
    }
}

// Load Alerts
async function loadAlerts() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/alerts?status=pending`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        const data = await response.json();
        if (data.success && data.data.alerts.length > 0) {
            // Show most recent alert
            const latestAlert = data.data.alerts[0];
            handleNewAlert(latestAlert);
        }
    } catch (error) {
        console.error('Error loading alerts:', error);
    }
}

// Load Live Locations
async function loadLiveLocations() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/live-locations`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        const data = await response.json();
        if (data.success) {
            data.data.locations.forEach(location => {
                updateUserLocation(location);
            });
        }
    } catch (error) {
        console.error('Error loading live locations:', error);
    }
}

// Update User Location on Map
function updateUserLocation(data) {
    const userId = data.userId || data.user?.id;
    const location = data.location || data;
    
    if (!location.lat || !location.lng) return;

    // Update or create marker
    if (markers[userId]) {
        markers[userId].setPosition({ lat: location.lat, lng: location.lng });
    } else {
        markers[userId] = new google.maps.Marker({
            position: { lat: location.lat, lng: location.lng },
            map: map,
            title: data.name || 'User',
            icon: {
                url: 'http://maps.google.com/mapfiles/ms/icons/red-dot.png'
            }
        });

        // Add circle for radius
        new google.maps.Circle({
            strokeColor: '#28a745',
            strokeOpacity: 0.8,
            strokeWeight: 2,
            fillColor: '#28a745',
            fillOpacity: 0.2,
            map: map,
            center: { lat: location.lat, lng: location.lng },
            radius: 500 // 500 meters
        });
    }

    // Center map on location
    map.setCenter({ lat: location.lat, lng: location.lng });
}

// Handle New Alert
async function handleNewAlert(alert) {
    currentIncident = alert;
    
    // Update map
    if (alert.location) {
        updateUserLocation({
            userId: alert.userId?._id || alert.userId,
            location: alert.location,
            name: alert.userId?.name || alert.user?.name
        });
    }

    // Load user details
    if (alert.userId?._id || alert.userId) {
        await loadUserDetails(alert.userId?._id || alert.userId);
    }

    // Update UI
    updateEmergencyBanner();
    addLogEntry(`[${formatTime(new Date(alert.timestamp))}] Alert: ${alert.alertType.toUpperCase()} - ${alert.message || 'No message'}`);
}

// Load User Details
async function loadUserDetails(userId) {
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/user/${userId}`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        const data = await response.json();
        if (data.success) {
            currentUser = data.data.user;
            displayUserInfo(currentUser);
        }
    } catch (error) {
        console.error('Error loading user details:', error);
    }
}

// Display User Information
function displayUserInfo(user) {
    const userInfoDiv = document.getElementById('userInfo');
    const initials = user.name.split(' ').map(n => n[0]).join('').toUpperCase();
    
    userInfoDiv.innerHTML = `
        <div class="user-details">
            <div class="user-avatar">${initials}</div>
            <div class="user-data">
                <div class="user-name">${user.name}</div>
                <div class="user-field"><strong>ID:</strong> ${user._id.slice(-4)}</div>
                <div class="user-field"><strong>Email:</strong> ${user.email}</div>
                <div class="user-field"><strong>Phone:</strong> ${user.phone}</div>
                <div class="user-field"><strong>Registered:</strong> ${formatDate(user.createdAt)}</div>
            </div>
        </div>
        <div class="emergency-contacts">
            <h3>EMERGENCY CONTACTS</h3>
            <div class="contact-item">
                <div class="contact-info">
                    <div class="contact-name">Emergency Contact</div>
                    <div class="contact-phone">${user.phone}</div>
                </div>
                <button class="call-btn" onclick="callNumber('${user.phone}')">CALL NOW</button>
            </div>
        </div>
    `;
}

// Load Resources (Nearby Help)
function loadResources() {
    const resources = [
        { name: 'Police Station', icon: '🚔', distance: '0.5 km', action: 'DISPATCH NOW' },
        { name: 'Central Precinct', icon: '🛡️', distance: '0.8 km', action: 'CONTACT' },
        { name: 'City General Hospital', icon: '🏥', distance: '1.2 km', action: 'CONTACT' },
        { name: 'Fire Station', icon: '🚒', distance: '0.5 km', action: 'CONTACT' },
        { name: 'Volunteer First Aid', icon: '➕', distance: 'Local Team', action: 'DISPATCH' }
    ];

    const resourcesList = document.getElementById('resourcesList');
    resourcesList.innerHTML = resources.map(resource => `
        <div class="resource-item">
            <span class="resource-icon">${resource.icon}</span>
            <div class="resource-info">
                <span class="resource-name">${resource.name}</span>
                <span class="resource-distance">${resource.distance}</span>
            </div>
            <button class="resource-btn" onclick="dispatchResource('${resource.name}')">${resource.action}</button>
        </div>
    `).join('');
}

// Setup Event Listeners
function setupEventListeners() {
    document.getElementById('broadcastBtn').addEventListener('click', () => {
        if (currentIncident) {
            broadcastAlert();
        } else {
            alert('No active incident to broadcast');
        }
    });

    document.getElementById('manualDispatchBtn').addEventListener('click', () => {
        alert('Manual dispatch feature - to be implemented');
    });

    document.getElementById('resolveBtn').addEventListener('click', async () => {
        if (currentIncident) {
            await resolveIncident();
        } else {
            alert('No active incident to resolve');
        }
    });
}

// Broadcast Alert
function broadcastAlert() {
    addLogEntry(`[${formatTime(new Date())}] Broadcast alert sent to all emergency services`);
    alert('Alert broadcasted to all emergency services');
}

// Resolve Incident
async function resolveIncident() {
    if (!currentIncident) return;

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/alert/${currentIncident._id}/status`, {
            method: 'PATCH',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ status: 'resolved' })
        });

        const data = await response.json();
        if (data.success) {
            addLogEntry(`[${formatTime(new Date())}] Incident resolved`);
            currentIncident = null;
            document.getElementById('userInfo').innerHTML = '<div class="user-placeholder"><p>No active incident. Waiting for alerts...</p></div>';
            updateEmergencyBanner();
        }
    } catch (error) {
        console.error('Error resolving incident:', error);
    }
}

// Call Number
function callNumber(phone) {
    window.location.href = `tel:${phone}`;
}

// Dispatch Resource
function dispatchResource(resourceName) {
    addLogEntry(`[${formatTime(new Date())}] Dispatched: ${resourceName}`);
    alert(`${resourceName} has been dispatched`);
}

// Add Log Entry
function addLogEntry(message) {
    const logContainer = document.getElementById('communicationLog');
    const entry = document.createElement('div');
    entry.className = 'log-entry';
    entry.textContent = message;
    logContainer.insertBefore(entry, logContainer.firstChild);
    
    // Keep only last 50 entries
    while (logContainer.children.length > 50) {
        logContainer.removeChild(logContainer.lastChild);
    }
}

// Update Emergency Banner
function updateEmergencyBanner() {
    const banner = document.querySelector('.emergency-banner');
    if (currentIncident) {
        banner.textContent = `EMERGENCY SOS - ${currentIncident.alertType.toUpperCase()}`;
        banner.style.animation = 'pulse 2s infinite';
    } else {
        banner.textContent = 'EMERGENCY SOS';
        banner.style.animation = 'none';
    }
}

// Polling for updates
function startPolling() {
    setInterval(() => {
        loadLiveLocations();
        loadAlerts();
    }, 10000); // Every 10 seconds
}

// Utility Functions
function formatTime(date) {
    return new Date(date).toLocaleTimeString('en-US', { hour12: false });
}

function formatDate(date) {
    return new Date(date).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

// Add pulse animation
const style = document.createElement('style');
style.textContent = `
    @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.7; }
    }
`;
document.head.appendChild(style);



