# 🚀 Run Instructions: Admin Panel (PC) + Flutter App (Mobile)

## Your PC IP Address: `10.38.111.74`

## Step 1: Start Backend Server (PC)

### Option A: If MongoDB is installed locally

1. Make sure MongoDB is running:
   ```bash
   # Check if MongoDB is running
   # If not, start it:
   mongod
   ```

2. Start the backend:
   ```bash
   cd backend
   npm install  # Only needed first time
   npm start
   ```

### Option B: Use MongoDB Atlas (Cloud - Recommended)

1. Get a free MongoDB Atlas account: https://www.mongodb.com/cloud/atlas
2. Create a cluster and get connection string
3. Update `backend/.env`:
   ```env
   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/tourguard
   JWT_SECRET=your-secret-key-here
   PORT=5000
   ```

4. Start the backend:
   ```bash
   cd backend
   npm start
   ```

### Verify Server is Running

You should see:
```
Server running on port 5000
✅ Admin Panel: http://localhost:5000
✅ Admin Panel (Network): http://10.38.111.74:5000
✅ API Base URL: http://10.38.111.74:5000/api
```

## Step 2: Open Admin Panel (PC Browser)

1. Open your web browser (Chrome, Firefox, Edge)
2. Navigate to: **http://localhost:5000**
3. You should see the login screen
4. Login with any registered user credentials

## Step 3: Run Flutter App (Mobile Device)

### Prerequisites

1. **Connect mobile device to same WiFi network as your PC**
2. **Ensure firewall allows connections on port 5000**

### Windows Firewall Setup

1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Click "Change Settings" → "Allow another app"
4. Add Node.js or allow port 5000

Or run this in PowerShell (as Administrator):
```powershell
New-NetFirewallRule -DisplayName "TourGuard Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

### Run Flutter App

1. Connect your mobile device via USB or use WiFi debugging
2. Make sure device and PC are on the same WiFi network
3. Run the app:
   ```bash
   flutter run
   ```

4. The app is configured to connect to: `http://10.38.111.74:5000/api`

## Step 4: Test the Connection

### In Flutter App:
1. Register/Login a user
2. Navigate around - location updates are sent automatically
3. Press SOS button - alert should appear in admin panel

### In Admin Panel:
1. You should see user location on the map
2. When user sends SOS, alert appears immediately
3. User information displays in left panel
4. Communication log shows all events

## Troubleshooting

### Admin Panel Not Loading

- ✅ Check backend is running: `http://localhost:5000/health`
- ✅ Check browser console for errors
- ✅ Verify MongoDB connection

### Flutter App Can't Connect

1. **Check IP Address**:
   - Verify PC IP is still `10.38.111.74`
   - Run: `ipconfig` to check current IP
   - Update `lib/services/backend_service.dart` if IP changed

2. **Check Network**:
   - Ensure mobile and PC are on same WiFi
   - Try pinging PC from mobile: `ping 10.38.111.74`

3. **Check Firewall**:
   - Windows Firewall may be blocking port 5000
   - Allow Node.js through firewall

4. **Test Connection**:
   - Open browser on mobile: `http://10.38.111.74:5000/health`
   - Should return: `{"success":true,"message":"Server is running"}`

### Location Updates Not Appearing

- ✅ Check user is authenticated in Flutter app
- ✅ Check backend logs for errors
- ✅ Verify location permissions granted
- ✅ Check admin panel console for Socket.IO connection

### Alerts Not Showing

- ✅ Verify user is logged in
- ✅ Check backend logs
- ✅ Check browser console in admin panel
- ✅ Verify Socket.IO connection

## Quick Test Commands

### Test Backend from Mobile Browser
Open on mobile: `http://10.38.111.74:5000/health`

### Test API from Mobile Browser
Open on mobile: `http://10.38.111.74:5000/api/admin/users` (requires auth)

### Check Server Status
```bash
curl http://localhost:5000/health
```

## Network Configuration

- **PC IP**: 10.38.111.74
- **Port**: 5000
- **Protocol**: HTTP (use HTTPS in production)
- **Admin Panel**: http://localhost:5000 (PC) or http://10.38.111.74:5000 (any device)
- **API Base**: http://10.38.111.74:5000/api

## Next Steps

1. ✅ Start backend server
2. ✅ Open admin panel in browser
3. ✅ Run Flutter app on mobile
4. ✅ Test location updates
5. ✅ Test SOS alerts
6. ✅ Verify real-time updates in admin panel

---

**🎉 You're all set! Both admin panel and mobile app should now be connected!**



