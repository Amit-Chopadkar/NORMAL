# Quick Start Guide

Get your TourGuard backend up and running in 5 minutes!

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or Atlas)
- npm or yarn

## Step 1: Install Dependencies

```bash
cd backend
npm install
```

## Step 2: Configure Environment

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set:
   ```env
   MONGO_URI=mongodb://localhost:27017/tourguard
   JWT_SECRET=your-secret-key-here
   PORT=5000
   ```

   **For MongoDB Atlas:**
   ```env
   MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/tourguard
   ```

   **Generate JWT Secret:**
   ```bash
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
   ```

## Step 3: Start MongoDB

**Local MongoDB:**
```bash
mongod
```

**Or use MongoDB Atlas (cloud) - no local setup needed!**

## Step 4: Run the Server

**Development (with auto-reload):**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

## Step 5: Test the API

**Health Check:**
```bash
curl http://localhost:5000/health
```

**Register a User:**
```bash
curl -X POST http://localhost:5000/api/user/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "+1234567890",
    "password": "password123"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:5000/api/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Save the `token` from the response for authenticated requests!

## Next Steps

- Read `README.md` for full API documentation
- Check `API_TESTING.md` for example requests
- Connect your Android app to the API
- Set up Socket.IO client for real-time features

## Troubleshooting

**MongoDB Connection Error:**
- Ensure MongoDB is running
- Check `MONGO_URI` in `.env`
- For Atlas: Check network access and credentials

**Port Already in Use:**
- Change `PORT` in `.env`
- Or kill the process using port 5000

**Module Not Found:**
- Run `npm install` again
- Delete `node_modules` and `package-lock.json`, then `npm install`

## Support

For detailed API documentation, see `README.md` and `API_TESTING.md`.



