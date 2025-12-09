#!/bin/bash

# TourGuard System Startup Script
# Opens a new Terminal window for each service.

echo "🚀 Starting TourGuard System..."

# Function to run command in new terminal tab/window
run_in_new_terminal() {
    local title="$1"
    local cmd="$2"
    
    # Use osascript to tell Terminal to do script
    # We must escape double quotes in the cmd for AppleScript
    local escaped_cmd=${cmd//\"/\\\"}
    
    osascript -e "tell application \"Terminal\" to do script \"$escaped_cmd\""
    echo "Started: $title"
}

# 1. Start Ganache (Blockchain)
run_in_new_terminal "Blockchain (Ganache)" "cd \"$PWD\" && npx ganache --port 8545 --quiet"
echo "⏳ Waiting 5s for Blockchain..."
sleep 5

# 2. Deploy Smart Contract (One-time, but running here to ensure it's up to date)
# Note: This runs in the main terminal, not a new one, as it exits quickly.
echo "📝 Deploying Smart Contract..."
cd ml-engine && python3 -m blockchain.deploy && cd ..

# 3. Start ML Engine
run_in_new_terminal "ML Engine" "cd \"$PWD/ml-engine\" && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

# 4. Start Main Backend
run_in_new_terminal "Main Backend" "cd \"$PWD/tourguard-backend Final\" && npm run start:dev"

# 5. Start Admin Backend (Port 5002)
run_in_new_terminal "Admin Backend" "cd \"$PWD/admin_pannel/backend\" && PORT=5002 ML_ENGINE_URL=http://localhost:8000 npm run dev"

# 6. Start Admin Frontend
run_in_new_terminal "Admin Frontend" "cd \"$PWD/admin_pannel/frontend\" && npm run dev"

echo "✅ All services initiated in separate terminals."
echo "------------------------------------------------"
echo "📱 Main Backend:    http://localhost:3000"
echo "🧠 ML Engine:       http://localhost:8000"
echo "🛡️ Admin Backend:   http://localhost:5002"
echo "💻 Admin Frontend:  Check terminal (likely 3001 or 3004)"
echo "------------------------------------------------"
