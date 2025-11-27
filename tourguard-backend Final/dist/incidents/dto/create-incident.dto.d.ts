import { IncidentSeverity } from '../entities/incident.entity';
export declare class LocationDto {
    lat: number;
    lng: number;
}
export declare class CreateIncidentDto {
    title: string;
    description?: string;
    severity: IncidentSeverity;
    location?: LocationDto;
}
