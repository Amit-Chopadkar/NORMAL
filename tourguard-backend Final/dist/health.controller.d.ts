import { Connection } from 'typeorm';
export declare class HealthController {
    private readonly connection;
    constructor(connection: Connection);
    check(): Promise<{
        status: string;
        timestamp: string;
        database: {
            connected: boolean;
            type: "mysql" | "mariadb" | "postgres" | "cockroachdb" | "sqlite" | "mssql" | "sap" | "oracle" | "cordova" | "nativescript" | "react-native" | "sqljs" | "mongodb" | "aurora-mysql" | "aurora-postgres" | "expo" | "better-sqlite3" | "capacitor" | "spanner";
            error?: undefined;
        };
        uptime: number;
    } | {
        status: string;
        timestamp: string;
        database: {
            connected: boolean;
            error: any;
            type?: undefined;
        };
        uptime?: undefined;
    }>;
    readiness(): Promise<{
        status: string;
        version: any;
    }>;
}
