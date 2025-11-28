import express, { Request, Response } from 'express';

const router = express.Router();

// Mock zones data (matching Wear OS fallback zones)
const ZONES = [
    {
        id: '1',
        name: 'Remote Forest',
        type: 'danger',
        riskLevel: 'high',
        lat: 20.0112,
        lng: 73.7909,
        radius: 2000,
        color: '#ef4444',
    },
    {
        id: '2',
        name: 'Market Area',
        type: 'caution',
        riskLevel: 'medium',
        lat: 20.0150,
        lng: 73.7950,
        radius: 800,
        color: '#eab308',
    },
    {
        id: '3',
        name: 'Industrial Zone',
        type: 'danger',
        riskLevel: 'high',
        lat: 20.0050,
        lng: 73.7850,
        radius: 1500,
        color: '#ef4444',
    },
    {
        id: '4',
        name: 'Tourist Zone',
        type: 'safe',
        riskLevel: 'low',
        lat: 20.0098,
        lng: 73.7954,
        radius: 500,
        color: '#22c55e',
    },
];

// Get nearby zones
router.get('/api/zones', (req: Request, res: Response) => {
    try {
        const { lat, lng } = req.query;

        // In a real app, we would filter by distance here
        // For now, return all zones

        res.json({
            success: true,
            data: ZONES,
        });
    } catch (error) {
        console.error('Error fetching zones:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error',
        });
    }
});

export default router;
