// AI Service for Admin Panel
// Connects to ML Engine via admin backend

const API_BASE = import.meta.env.VITE_API_BASE || 'http://172.17.5.58:5000';

export interface DistressAssessment {
    distress_score: number;
    risk_level: 'low' | 'medium' | 'high';
    warning_signals: string[];
    assessment_text: string;
    recommended_actions: string[];
    priority: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
}

export interface InvestigationReport {
    full_report: string;
    sections: Record<string, string>;
    tourist_id: string;
    trip_id: string;
    incident_type: string;
    generated_at: string;
}

export interface BehavioralPatterns {
    tourist_id: string;
    trip_id: string;
    baseline: Record<string, string>;
    recent_patterns: Array<Record<string, string>>;
    anomalies_detected: string[];
    risk_assessment: 'low' | 'medium' | 'high';
}

export interface AIHealth {
    ml_engine: { status: string };
    llm_service: {
        status: string;
        model: string;
        ollama_available: boolean;
    };
    timestamp: string;
}

class AIService {
    /**
     * Generate investigation report for a tourist
     */
    async generateInvestigationReport(
        touristId: string,
        tripId: string,
        incidentType: string = 'anomaly',
        hoursOfHistory: number = 24
    ): Promise<InvestigationReport> {
        const response = await fetch(`${API_BASE}/api/ai/investigation/report`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                touristId,
                tripId,
                incidentType,
                hoursOfHistory,
            }),
        });

        if (!response.ok) {
            throw new Error(`Failed to generate report: ${response.statusText}`);
        }

        return response.json();
    }

    /**
     * Assess distress level for a tourist
     */
    async assessDistress(
        touristId: string,
        tripId: string,
        currentObservation: Record<string, string>,
        recentAlerts: any[] = []
    ): Promise<DistressAssessment> {
        const response = await fetch(`${API_BASE}/api/ai/distress/assess`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                touristId,
                tripId,
                currentObservation,
                recentAlerts,
            }),
        });

        if (!response.ok) {
            throw new Error(`Failed to assess distress: ${response.statusText}`);
        }

        return response.json();
    }

    /**
     * Get behavioral patterns for a tourist
     */
    async getBehavioralPatterns(
        touristId: string,
        tripId: string
    ): Promise<BehavioralPatterns> {
        const response = await fetch(
            `${API_BASE}/api/ai/patterns/${touristId}/${tripId}`
        );

        if (!response.ok) {
            throw new Error(`Failed to fetch patterns: ${response.statusText}`);
        }

        return response.json();
    }

    /**
     * Explain a specific anomaly
     */
    async explainAnomaly(
        anomalyType: string,
        anomalyData: Record<string, string>,
        observation?: Record<string, string>,
        context?: Record<string, string>
    ): Promise<any> {
        const response = await fetch(`${API_BASE}/api/ai/anomaly/explain`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                anomalyType,
                anomalyData,
                observation,
                context,
            }),
        });

        if (!response.ok) {
            throw new Error(`Failed to explain anomaly: ${response.statusText}`);
        }

        return response.json();
    }

    /**
     * Check AI services health
     */
    async checkHealth(): Promise<AIHealth> {
        const response = await fetch(`${API_BASE}/api/ai/health`);

        if (!response.ok) {
            throw new Error(`Health check failed: ${response.statusText}`);
        }

        return response.json();
    }
}

export const aiService = new AIService();
export default aiService;
