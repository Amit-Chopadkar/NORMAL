import { io } from 'socket.io-client';
import axios from 'axios';

const BACKEND_URL = 'http://localhost:5000';
const socket = io(BACKEND_URL);

console.log('🔌 Connecting to Admin Backend...');

socket.on('connect', () => {
    console.log('✅ Connected to Socket.IO');

    // Simulate logic
    sendTestLog();
});

socket.on('ai:log', (data) => {
    console.log('🎉 RECEIVED AI LOG VIA SOCKET!');
    console.log('Data:', data);

    if (data.prompt === 'Test Prompt' && data.response === 'Test Response') {
        console.log('✅ VERIFICATION PASSED: Data matches.');
        process.exit(0);
    } else {
        console.error('❌ VERIFICATION FAILED: Data mismatch.');
        process.exit(1);
    }
});

async function sendTestLog() {
    console.log('📤 Sending test log to /api/ai/log...');
    try {
        await axios.post(`${BACKEND_URL}/api/ai/log`, {
            timestamp: new Date().toISOString(),
            model: 'test-model',
            prompt: 'Test Prompt',
            response: 'Test Response',
            system_prompt: 'You are a test.'
        });
        console.log('✅ Log posted successfully.');
    } catch (error: any) {
        console.error('❌ Failed to post log:', error.message);
        process.exit(1);
    }
}

// Timeout
setTimeout(() => {
    console.error('❌ TIMEOUT: Did not receive socket event in time.');
    process.exit(1);
}, 5000);
