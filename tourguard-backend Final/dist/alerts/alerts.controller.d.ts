export declare class AlertsController {
    getAlerts(): {
        id: string;
        type: string;
        title: string;
        message: string;
        severity: string;
        location: {
            lat: number;
            lng: number;
        };
        timestamp: string;
    }[];
}
