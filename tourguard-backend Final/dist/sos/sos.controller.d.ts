declare class EmergencyContactDto {
    name: string;
    phone: string;
}
declare class SendSOSDto {
    latitude: number;
    longitude: number;
    emergencyContacts: EmergencyContactDto[];
    userName?: string;
}
export declare class SosController {
    sendSOS(dto: SendSOSDto): Promise<{
        success: boolean;
        message: string;
        alertId: string;
        timestamp: string;
    }>;
}
export {};
