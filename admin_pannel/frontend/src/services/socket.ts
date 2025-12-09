/**
 * Socket.IO client for real-time SOS updates
 */

import { io, Socket } from 'socket.io-client';
import { SosEvent } from '../types';

const SOCKET_URL = 'http://localhost:5002';
const SOCKET_NAMESPACE = '/admin';

let socket: Socket | null = null;

const getAuthToken = () => localStorage.getItem('token');

export const initializeSocket = (): Socket | null => {
    const token = getAuthToken();

    if (!token) {
        console.warn('Socket initialization skipped: missing auth token');
        return null;
    }

    if (!socket) {
        socket = io(`${SOCKET_URL}${SOCKET_NAMESPACE}`, {
            transports: ['websocket'],
            reconnection: true,
            reconnectionAttempts: 5,
            reconnectionDelay: 1000,
            auth: { token },
            withCredentials: true,
        });

        socket.on('connect', () => {
            console.log('✓ Socket.IO connected');
        });

        socket.on('disconnect', () => {
            console.log('✗ Socket.IO disconnected');
        });

        socket.on('connect_error', (error) => {
            console.error('Socket.IO connection error:', error);
            if ((error as Error)?.message === 'Unauthorized') {
                localStorage.removeItem('token');
                localStorage.removeItem('user');
                window.location.href = '/login';
            }
        });
    }

    return socket;
};

export const disconnectSocket = () => {
    if (socket) {
        socket.disconnect();
        socket = null;
    }
};

export const onSosNew = (callback: (event: SosEvent) => void) => {
    if (socket) {
        socket.on('sos:new', callback);
    }
};

export const onSosUpdate = (callback: (event: SosEvent) => void) => {
    if (socket) {
        socket.on('sos:update', callback);
    }
};

export const offSosNew = () => {
    if (socket) {
        socket.off('sos:new');
    }
};

export const offSosUpdate = () => {
    if (socket) {
        socket.off('sos:update');
    }
};

export default {
    initializeSocket,
    disconnectSocket,
    onSosNew,
    onSosUpdate,
    offSosNew,
    offSosUpdate,
};
