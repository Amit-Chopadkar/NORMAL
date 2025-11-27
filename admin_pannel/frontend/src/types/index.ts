/**
 * TypeScript type definitions for frontend
 */

export interface User {
    id: string;
    name: string;
    phone: string;
    email: string;
    role: 'user' | 'admin';
    medicalConditions?: string;
    allergies?: string;
    emergencyContacts?: EmergencyContact[];
    createdAt: string;
    updatedAt?: string;
}

export interface EmergencyContact {
    name: string;
    relation: string;
    phone: string;
}

export interface SosEvent {
    id: string;
    userId: string;
    latitude: number;
    longitude: number;
    accuracyMeters?: number;
    message?: string;
    status: 'pending' | 'acknowledged' | 'resolved';
    createdAt: string;
    acknowledgedAt?: string;
    resolvedAt?: string;
    user?: {
        name: string;
        phone: string;
        email: string;
        medicalConditions?: string;
        allergies?: string;
        emergencyContacts?: EmergencyContact[];
    };
}

export interface LoginCredentials {
    email: string;
    password: string;
}

export interface LoginResponse {
    success: boolean;
    data: {
        token: string;
        user: {
            id: string;
            name: string;
            email: string;
            role: string;
        };
    };
}

export interface Incident {
    id: string;
    title: string;
    description: string;
    category: string;
    severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
    status: string;
    location: {
        latitude: number;
        longitude: number;
        address?: string | null;
        userId?: string | null;
    };
    createdAt: string;
    user?: {
        id: string;
        name: string;
        phone: string;
        email: string;
    } | null;
}

export interface ApiResponse<T = any> {
    success: boolean;
    data?: T;
    error?: string;
    message?: string;
}
