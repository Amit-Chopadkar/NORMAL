import { Router } from 'express';

const router = Router();

const ML_ENGINE_URL = process.env.ML_ENGINE_URL || 'http://172.17.5.58:8082';

// Get investigation report for a specific tourist
router.post('/api/ai/investigation/report', async (req, res) => {
    try {
        const { touristId, tripId, incidentType = 'anomaly', hoursOfHistory = 24 } = req.body;

        if (!touristId || !tripId) {
            return res.status(400).json({
                error: 'Missing required fields: touristId and tripId are required'
            });
        }

        const response = await fetch(`${ML_ENGINE_URL}/investigation/analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                tourist_id: touristId,
                trip_id: tripId,
                incident_type: incidentType,
                hours_of_history: hoursOfHistory
            })
        });

        if (!response.ok) {
            throw new Error(`ML Engine responded with status: ${response.status}`);
        }

        const report = await response.json();
        res.json(report);

    } catch (error: any) {
        console.error('Error generating investigation report:', error);
        res.status(500).json({
            error: 'Failed to generate investigation report',
            message: error.message
        });
    }
});

// Assess distress level for a tourist
router.post('/api/ai/distress/assess', async (req, res) => {
    try {
        const { touristId, tripId, currentObservation, recentAlerts = [] } = req.body;

        if (!touristId || !tripId || !currentObservation) {
            return res.status(400).json({
                error: 'Missing required fields: touristId, tripId, and currentObservation are required'
            });
        }

        const response = await fetch(`${ML_ENGINE_URL}/anomaly/assess-distress`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                tourist_id: touristId,
                trip_id: tripId,
                current_observation: currentObservation,
                recent_alerts: recentAlerts
            })
        });

        if (!response.ok) {
            throw new Error(`ML Engine responded with status: ${response.status}`);
        }

        const assessment = await response.json();
        res.json(assessment);

    } catch (error: any) {
        console.error('Error assessing distress:', error);
        res.status(500).json({
            error: 'Failed to assess distress level',
            message: error.message
        });
    }
});

// Get behavioral patterns for a tourist
router.get('/api/ai/patterns/:touristId/:tripId', async (req, res) => {
    try {
        const { touristId, tripId } = req.params;

        const response = await fetch(
            `${ML_ENGINE_URL}/observations/${touristId}/${tripId}/patterns`
        );

        if (!response.ok) {
            throw new Error(`ML Engine responded with status: ${response.status}`);
        }

        const patterns = await response.json();
        res.json(patterns);

    } catch (error: any) {
        console.error('Error fetching behavioral patterns:', error);
        res.status(500).json({
            error: 'Failed to fetch behavioral patterns',
            message: error.message
        });
    }
});

// Explain a specific anomaly
router.post('/api/ai/anomaly/explain', async (req, res) => {
    try {
        const { anomalyType, anomalyData, observation, context = {} } = req.body;

        if (!anomalyType || !anomalyData) {
            return res.status(400).json({
                error: 'Missing required fields: anomalyType and anomalyData are required'
            });
        }

        const response = await fetch(`${ML_ENGINE_URL}/anomaly/explain`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                anomaly_type: anomalyType,
                anomaly_data: anomalyData,
                observation,
                context
            })
        });

        if (!response.ok) {
            throw new Error(`ML Engine responded with status: ${response.status}`);
        }

        const explanation = await response.json();
        res.json(explanation);

    } catch (error: any) {
        console.error('Error explaining anomaly:', error);
        res.status(500).json({
            error: 'Failed to explain anomaly',
            message: error.message
        });
    }
});

// Get ML Engine health status
router.get('/api/ai/health', async (req, res) => {
    try {
        const [mlHealth, llmHealth] = await Promise.all([
            fetch(`${ML_ENGINE_URL}/health`).then((r: Response) => r.json()),
            fetch(`${ML_ENGINE_URL}/llm/health`).then((r: Response) => r.json())
        ]);

        res.json({
            ml_engine: mlHealth,
            llm_service: llmHealth,
            timestamp: new Date().toISOString()
        });

    } catch (error: any) {
        console.error('Error checking AI health:', error);
        res.status(500).json({
            error: 'Failed to check AI service health',
            message: error.message
        });
    }
});

export default router;
