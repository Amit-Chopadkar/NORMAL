export declare class ZonesController {
    getNearbyZones(lat: string, lng: string): {
        id: string;
        name: string;
        safetyLevel: string;
        lat: number;
        lng: number;
        radius: number;
    }[];
}
