# 🚀 START HERE - Run Admin Panel (PC) + Flutter App (Mobile)

## ✅ Everything is Configured!

- **PC IP Address**: `10.38.111.74`
- **Backend Port**: `5000`
- **Flutter app** is configured to connect to your PC

## 📋 Step-by-Step Instructions

### Step 1: Setup MongoDB (Choose One)

#### Option A: MongoDB Atlas (Cloud - Easiest) ⭐ Recommended

1. Go to: https://www.mongodb.com/cloud/atlas/register
2. Create free account
3. Create a free cluster
4. Click "Connect" → "Connect your application"
5. Copy the connection string (looks like: `mongodb+srv://username:password@cluster.mongodb.net/...`)
6. Update `backend/.env`:
   ```env
   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/tourguard
   JWT_SECRET=your-secret-key-here
   PORT=5000
   ```

#### Option B: Local MongoDB

1. Install MongoDB: https://www.mongodb.com/try/download/community
2. Start MongoDB: `mongod`
3. Your `.env` should have: `MONGO_URI=mongodb://localhost:27017/tourguard`

### Step 2: Setup Firewall (Allow Port 5000)

**Run PowerShell as Administrator**, then:

```powershell
.\setup_firewall.ps1
```

Or manually:
```powershell
New-NetFirewallRule -DisplayName "TourGuard Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

### Step 3: Start Backend Server

**Option A: Use the batch file**
```bash
start_backend.bat
```

**Option B: Manual start**
```bash
cd backend
npm start
```

**You should see:**
```
Server running on port 5000
✅ Admin Panel: http://localhost:5000
✅ Admin Panel (Network): http://10.38.111.74:5000
✅ API Base URL: http://10.38.111.74:5000/api
```

### Step 4: Open Admin Panel (PC Browser)

1. Open Chrome/Firefox/Edge
2. Go to: **http://localhost:5000**
3. You'll see the login screen
4. **Note**: You need to register a user first (via Flutter app)

### Step 5: Run Flutter App (Mobile Device)

#### Important Prerequisites:
- ✅ Mobile device and PC on **same WiFi network**
- ✅ Firewall allows port 5000
- ✅ Backend server is running

#### Run the App:

```bash
flutter run
```

#### First Time:
1. **Register a new user** in the Flutter app
   - Name, Email, Phone, Password
2. This creates account and stores JWT token
3. **Use same credentials** to login to admin panel

### Step 6: Test Everything!

#### In Flutter App:
1. ✅ Register/Login
2. ✅ Navigate around (location updates sent automatically)
3. ✅ Press SOS button
4. ✅ Check admin panel for real-time updates

#### In Admin Panel:
1. ✅ Login with same credentials
2. ✅ See user location on map (updates in real-time)
3. ✅ View alerts when user sends SOS
4. ✅ Check communication log for all events

## 🔧 Troubleshooting

### Server Won't Start

**Error: "MongoDB connection failed"**
- ✅ Check MongoDB is running (local) or connection string is correct (Atlas)
- ✅ Verify `MONGO_URI` in `backend/.env`

**Error: "Port 5000 already in use"**
- ✅ Change PORT in `.env` to another port (e.g., 5001)
- ✅ Update Flutter app IP: `http://10.38.111.74:5001/api`

### Can't Access from Mobile

**Test connection from mobile browser:**
- Open: `http://10.38.111.74:5000/health`
- Should see: `{"success":true,"message":"Server is running"}`

**If it doesn't work:**
1. ✅ Check firewall (run `setup_firewall.ps1` as Admin)
2. ✅ Verify same WiFi network
3. ✅ Check PC IP hasn't changed: `ipconfig`
4. ✅ Update IP in `lib/services/backend_service.dart` if changed

### Admin Panel Shows "No active incident"

- ✅ This is normal - no alerts active yet
- ✅ Register/login in Flutter app first
- ✅ Send an SOS alert to see it appear

### Location Updates Not Showing

- ✅ Check user is authenticated in Flutter app
- ✅ Verify location permissions granted
- ✅ Check backend logs for errors
- ✅ Check browser console in admin panel

## 📱 Quick Reference

| Item | URL/Value |
|------|-----------|
| PC IP | `10.38.111.74` |
| Admin Panel (PC) | `http://localhost:5000` |
| Admin Panel (Network) | `http://10.38.111.74:5000` |
| API Base URL | `http://10.38.111.74:5000/api` |
| Health Check | `http://10.38.111.74:5000/health` |

## 🎯 Current Status

✅ Backend configured for network access  
✅ Flutter app configured to use PC IP  
✅ Server ready to start  
✅ Firewall script created  
✅ Helper scripts created  

## 🚀 Next Actions

1. ✅ Setup MongoDB (Atlas or local)
2. ✅ Run firewall script (as Admin)
3. ✅ Start backend server (`start_backend.bat`)
4. ✅ Open admin panel: http://localhost:5000
5. ✅ Run Flutter app on mobile
6. ✅ Register user in app
7. ✅ Login to admin panel
8. ✅ Test location updates and alerts!

---

## 📞 Need Help?

- Check `RUN_INSTRUCTIONS.md` for detailed steps
- Check `backend/README.md` for API docs
- Check `backend/INTEGRATION_GUIDE.md` for integration details

**🎉 You're all set! Start the server and run the app!**
