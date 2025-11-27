import express, { Request, Response } from 'express';
import db from '../database/db';

const router = express.Router();

// Helper function to parse location JSON and extract data
function parseLocation(locationStr: string | null): any {
  if (!locationStr) return null;
  try {
    return JSON.parse(locationStr);
  } catch {
    return null;
  }
}

// Helper function to map incident to SOS event format
async function mapIncidentToSOSEvent(incident: any): Promise<any> {
  const location = parseLocation(incident.location);
  const userId = location?.userId || null;

  // Get user data if userId exists
  let user = null;
  if (userId) {
    user = await db.getUserById(userId);
  }

  // Parse description to extract status if stored there
  let status = 'pending';
  let acknowledgedAt: string | undefined;
  let resolvedAt: string | undefined;
  
  try {
    const desc = typeof incident.description === 'string' 
      ? JSON.parse(incident.description) 
      : incident.description;
    if (desc?.status) {
      status = desc.status;
    }
    if (desc?.acknowledgedAt) {
      acknowledgedAt = desc.acknowledgedAt;
    }
    if (desc?.resolvedAt) {
      resolvedAt = desc.resolvedAt;
    }
  } catch {
    // Description is plain text, use default status
  }

  // Extract message from description
  let message = 'SOS Alert';
  try {
    const desc = typeof incident.description === 'string' 
      ? JSON.parse(incident.description) 
      : incident.description;
    if (desc?.originalMessage) {
      message = desc.originalMessage;
    } else if (desc?.message) {
      message = desc.message;
    } else if (typeof incident.description === 'string' && !desc.status) {
      message = incident.description;
    }
  } catch {
    if (typeof incident.description === 'string') {
      message = incident.description;
    }
  }

  return {
    id: incident.id,
    userId: userId || 'unknown',
    latitude: location?.latitude || 0,
    longitude: location?.longitude || 0,
    accuracyMeters: location?.accuracy || undefined,
    message: message,
    status: status,
    createdAt: incident.createdAt || incident.created_at,
    acknowledgedAt: acknowledgedAt,
    resolvedAt: resolvedAt,
    user: user
      ? {
          name: user.name || user.email || 'Unknown',
          phone: user.phone || '',
          email: user.email || '',
        }
      : undefined,
  };
}

// Get all SOS events
router.get('/api/sos', async (req: Request, res: Response) => {
  try {
    const { status, since } = req.query;

    // Get all SOS incidents
    let incidents = await db.getSOSIncidents();

    // Filter by status if provided
    if (status) {
      incidents = incidents.filter((inc) => {
        try {
          const desc = typeof inc.description === 'string' 
            ? JSON.parse(inc.description) 
            : inc.description;
          const incidentStatus = desc?.status || 'pending';
          return incidentStatus === status;
        } catch {
          // If description is plain text, default to pending
          return status === 'pending';
        }
      });
    }

    // Filter by date if provided
    if (since) {
      const sinceDate = new Date(since as string);
      incidents = incidents.filter((inc) => {
        const createdAt = new Date(inc.createdAt || inc.created_at);
        return createdAt >= sinceDate;
      });
    }

    // Map incidents to SOS events
    const sosEvents = await Promise.all(
      incidents.map((inc) => mapIncidentToSOSEvent(inc))
    );

    res.json({
      success: true,
      data: sosEvents,
    });
  } catch (error: any) {
    console.error('Error fetching SOS events:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

// Get SOS event by ID
router.get('/api/sos/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const incident = await db.getIncidentById(id);

    if (!incident || incident.title !== 'SOS Alert') {
      return res.status(404).json({
        success: false,
        error: 'SOS event not found',
      });
    }

    const sosEvent = await mapIncidentToSOSEvent(incident);

    res.json({
      success: true,
      data: sosEvent,
    });
  } catch (error: any) {
    console.error('Error fetching SOS event:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

// Create SOS event (for testing)
router.post('/api/sos', async (req: Request, res: Response) => {
  try {
    const { userId, latitude, longitude, accuracy, message } = req.body;

    // This would create an incident in the database
    // For now, we'll just return a mock response
    // In production, you'd insert into the incidents table

    const sosEvent = {
      id: `sos-${Date.now()}`,
      userId: userId || 'unknown',
      latitude,
      longitude,
      accuracyMeters: accuracy,
      message: message || 'SOS Alert',
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    res.json({
      success: true,
      data: sosEvent,
    });
  } catch (error: any) {
    console.error('Error creating SOS event:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

// Update SOS event status
router.patch('/api/sos/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['pending', 'acknowledged', 'resolved'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be: pending, acknowledged, or resolved',
      });
    }

    const incident = await db.getIncidentById(id);
    if (!incident) {
      return res.status(404).json({
        success: false,
        error: 'SOS event not found',
      });
    }

    // Update status in description JSON
    const success = await db.updateIncidentStatus(id, status);
    if (!success) {
      return res.status(500).json({
        success: false,
        error: 'Failed to update status',
      });
    }

    // Get updated incident and return as SOS event
    const updatedIncident = await db.getIncidentById(id);
    const sosEvent = await mapIncidentToSOSEvent(updatedIncident!);

    res.json({
      success: true,
      data: sosEvent,
    });
  } catch (error: any) {
    console.error('Error updating SOS event:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

export default router;

