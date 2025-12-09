/**
 * API client using Axios
 * Configured with JWT interceptor
 */

import axios from 'axios';
import { LoginCredentials, LoginResponse, SosEvent, User, Incident, ApiResponse } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_BASE || 'http://localhost:5001';

const apiClient = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Add JWT token to requests
apiClient.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Handle 401 errors (redirect to login)
apiClient.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

export const authApi = {
    login: async (credentials: LoginCredentials): Promise<LoginResponse> => {
        const response = await apiClient.post<LoginResponse>('/api/auth/login', credentials);
        return response.data;
    },
};

export const userApi = {
    getUserById: async (id: string): Promise<User> => {
        const response = await apiClient.get<ApiResponse<User>>(`/api/users/${id}`);
        return response.data.data!;
    },
};

export const sosApi = {
    listEvents: async (filters?: { status?: string; since?: string }): Promise<SosEvent[]> => {
        const params = new URLSearchParams();
        if (filters?.status) params.append('status', filters.status);
        if (filters?.since) params.append('since', filters.since);

        const response = await apiClient.get<ApiResponse<SosEvent[]>>(
            `/api/sos?${params.toString()}`
        );
        return response.data.data!;
    },

    getEventById: async (id: string): Promise<SosEvent> => {
        const response = await apiClient.get<ApiResponse<SosEvent>>(`/api/sos/${id}`);
        return response.data.data!;
    },

    createEvent: async (event: {
        userId: string;
        latitude: number;
        longitude: number;
        accuracy?: number;
        message?: string;
    }): Promise<SosEvent> => {
        const response = await apiClient.post<SosEvent>('/api/sos', {
            ...event,
            timestamp: new Date().toISOString(),
        });
        return response.data;
    },

    updateStatus: async (id: string, status: 'acknowledged' | 'resolved'): Promise<SosEvent> => {
        const response = await apiClient.patch<ApiResponse<SosEvent>>(`/api/sos/${id}`, { status });
        return response.data.data!;
    },
};

export const incidentsApi = {
    listIncidents: async (filters?: { type?: 'sos' | 'regular'; status?: string; since?: string }): Promise<Incident[]> => {
        const params = new URLSearchParams();
        if (filters?.type) params.append('type', filters.type);
        if (filters?.status) params.append('status', filters.status);
        if (filters?.since) params.append('since', filters.since);

        const response = await apiClient.get<ApiResponse<Incident[]>>(
            `/api/incidents?${params.toString()}`
        );
        return response.data.data!;
    },

    getIncidentById: async (id: string): Promise<Incident> => {
        const response = await apiClient.get<ApiResponse<Incident>>(`/api/incidents/${id}`);
        return response.data.data!;
    },
};

export default apiClient;
