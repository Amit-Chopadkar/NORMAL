import express, { Request, Response } from 'express';
import db from '../database/db';

const router = express.Router();

// Helper function to parse location JSON
function parseLocation(locationStr: string | null): any {
  if (!locationStr) return null;
  try {
    return JSON.parse(locationStr);
  } catch {
    return null;
  }
}

// Helper function to map incident to frontend format
async function mapIncidentToFrontend(incident: any): Promise<any> {
  const location = parseLocation(incident.location);
  const userId = location?.userId || null;

  // Get user data if userId exists
  let user = null;
  if (userId) {
    user = await db.getUserById(userId);
  }

  // Parse description
  let description = incident.description || '';
  let status = 'reported';
  let category = null;
  
  try {
    if (typeof incident.description === 'string') {
      const parsed = JSON.parse(incident.description);
      if (parsed.status) status = parsed.status;
      if (parsed.originalMessage) description = parsed.originalMessage;
      if (parsed.category) category = parsed.category;
    }
  } catch {
    // Description is plain text
  }

  return {
    id: incident.id,
    title: incident.title,
    description: description,
    category: category || (incident.title === 'SOS Alert' ? 'SOS' : 'Incident'),
    severity: incident.severity || 'MEDIUM',
    status: status,
    location: {
      latitude: location?.latitude || 0,
      longitude: location?.longitude || 0,
      address: location?.address || null,
      userId: userId,
    },
    createdAt: incident.createdAt || incident.created_at,
    user: user
      ? {
          id: user.id,
          name: user.name || user.email || 'Unknown',
          phone: user.phone || '',
          email: user.email || '',
        }
      : null,
  };
}

// Get all incidents (including SOS and regular incidents)
router.get('/api/incidents', async (req: Request, res: Response) => {
  try {
    const { type, status, since } = req.query;

    // Get all incidents
    let incidents = await db.getAllIncidents();

    // Filter by type if provided (sos or regular)
    if (type === 'sos') {
      incidents = incidents.filter((inc) => inc.title === 'SOS Alert');
    } else if (type === 'regular') {
      incidents = incidents.filter((inc) => inc.title !== 'SOS Alert');
    }

    // Filter by status if provided
    if (status) {
      incidents = incidents.filter((inc) => {
        try {
          const desc = typeof inc.description === 'string' 
            ? JSON.parse(inc.description) 
            : inc.description;
          const incidentStatus = desc?.status || 'reported';
          return incidentStatus === status;
        } catch {
          return status === 'reported';
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

    // Map incidents to frontend format
    const formattedIncidents = await Promise.all(
      incidents.map((inc) => mapIncidentToFrontend(inc))
    );

    res.json({
      success: true,
      data: formattedIncidents,
    });
  } catch (error: any) {
    console.error('Error fetching incidents:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

// Get incident by ID
router.get('/api/incidents/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const incident = await db.getIncidentById(id);

    if (!incident) {
      return res.status(404).json({
        success: false,
        error: 'Incident not found',
      });
    }

    const formattedIncident = await mapIncidentToFrontend(incident);

    res.json({
      success: true,
      data: formattedIncident,
    });
  } catch (error: any) {
    console.error('Error fetching incident:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

export default router;

