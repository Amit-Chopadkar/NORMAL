export declare class MiscController {
    getSafetyScore(): {
        score: number;
        level: string;
        factors: {
            locationAwareness: number;
            incidentReports: number;
            emergencyPreparedness: number;
            communityEngagement: number;
        };
        tips: string[];
    };
    getProfile(): {
        id: string;
        name: string;
        email: string;
        phone: string;
        memberSince: string;
        tripsCompleted: number;
        incidentsReported: number;
        safetyScore: number;
    };
    getPlaces(): {
        id: string;
        name: string;
        category: string;
        safetyLevel: string;
        rating: number;
        location: {
            lat: number;
            lng: number;
        };
        description: string;
    }[];
}
