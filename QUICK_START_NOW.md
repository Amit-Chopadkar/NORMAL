# 🚀 Quick Start - Run Now!

## ✅ Configuration Complete!

- **PC IP Address**: `10.38.111.74`
- **Backend Port**: `5000`
- **Admin Panel**: `http://localhost:5000`
- **API URL**: `http://10.38.111.74:5000/api`

## Step 1: Start Backend Server

The server should be starting now. If not, run:

```bash
cd backend
npm start
```

You should see:
```
Server running on port 5000
✅ Admin Panel: http://localhost:5000
✅ Admin Panel (Network): http://10.38.111.74:5000
✅ API Base URL: http://10.38.111.74:5000/api
```

## Step 2: Open Admin Panel (PC)

1. Open your web browser
2. Go to: **http://localhost:5000**
3. You'll see the login screen

**Note**: If you don't have a user yet, you'll need to register one first through the Flutter app.

## Step 3: Run Flutter App (Mobile)

### Important: Same WiFi Network!

Make sure your mobile device and PC are on the **same WiFi network**.

### Run the App:

```bash
flutter run
```

The app is already configured to connect to: `http://10.38.111.74:5000/api`

### First Time Setup:

1. **Register a new user** in the Flutter app
2. This will create an account and get a JWT token
3. You can then use the same credentials to login to the admin panel

## Step 4: Test Everything

### In Flutter App:
1. ✅ Register/Login
2. ✅ Navigate around (location updates sent automatically)
3. ✅ Press SOS button
4. ✅ Check admin panel for real-time updates

### In Admin Panel:
1. ✅ Login with the same credentials
2. ✅ See user location on map
3. ✅ View alerts in real-time
4. ✅ Check communication log

## Troubleshooting

### Server Won't Start

**MongoDB Not Running?**
- Option 1: Start MongoDB locally: `mongod`
- Option 2: Use MongoDB Atlas (cloud):
  1. Get free account: https://www.mongodb.com/cloud/atlas
  2. Create cluster
  3. Get connection string
  4. Update `backend/.env`: `MONGO_URI=mongodb+srv://...`

### Can't Access from Mobile

1. **Check Firewall**:
   ```powershell
   # Run as Administrator
   New-NetFirewallRule -DisplayName "TourGuard Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
   ```

2. **Verify Same WiFi**:
   - Mobile and PC must be on same network
   - Check PC IP: `ipconfig` (should be 10.38.111.74)

3. **Test Connection**:
   - Open mobile browser: `http://10.38.111.74:5000/health`
   - Should see: `{"success":true,"message":"Server is running"}`

### Admin Panel Shows "No active incident"

- This is normal when no alerts are active
- Register/login in Flutter app first
- Send an SOS alert to see it appear

## Current Status

✅ Backend configured for network access
✅ Flutter app configured to use PC IP
✅ Server should be starting...
✅ Ready to test!

## Next Actions

1. ✅ Wait for server to start (check terminal)
2. ✅ Open admin panel: http://localhost:5000
3. ✅ Run Flutter app on mobile
4. ✅ Register user in app
5. ✅ Login to admin panel with same credentials
6. ✅ Test location updates and alerts!

---

**🎉 Everything is configured! Just start the server and run the app!**



