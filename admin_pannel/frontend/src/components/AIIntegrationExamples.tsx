import React from 'react';
import { DistressScoreCard } from './DistressScoreCard';
import { InvestigationReportViewer } from './InvestigationReportViewer';
import { AIHealthStatus } from './AIHealthStatus';

/**
 * Example: How to integrate AI components into your admin dashboard
 * 
 * You can use these components in your incident details page,
 * tourist monitoring page, or create a dedicated AI insights page.
 */

// Example 1: Incident Details Page
export const IncidentDetailsWithAI: React.FC<{ incidentId: string }> = ({ incidentId }) => {
  // Fetch incident data (example)
  const incident = {
    touristId: 'tourist-123',
    tripId: 'trip-456',
    currentLocation: {
      lat: '25.2841',
      lng: '91.5801',
      timestamp: new Date().toISOString(),
      speed_mps: '0.5',
      battery_pct: '25',
      accuracy_m: '85',
    },
    recentAlerts: [
      { type: 'danger_zone', message: 'Entered high-risk area' },
      { type: 'long_inactivity', message: 'No movement for 20 minutes' }
    ]
  };

  return (
    <div className="incident-details-page">
      <h1>Incident Details</h1>

      {/* Show AI Health Status in header */}
      <AIHealthStatus />

      {/* Show real-time distress assessment */}
      <section className="ai-section">
        <DistressScoreCard
          touristId={incident.touristId}
          tripId={incident.tripId}
          currentObservation={incident.currentLocation}
          recentAlerts={incident.recentAlerts}
          autoAssess={true}
        />
      </section>

      {/* Investigation report (on-demand) */}
      <section className="ai-section">
        <InvestigationReportViewer
          touristId={incident.touristId}
          tripId={incident.tripId}
          incidentType="missing_person"
        />
      </section>

      {/* Your existing incident details components... */}
    </div>
  );
};

// Example 2: Tourist Monitoring Dashboard
export const TouristMonitoringWithAI: React.FC = () => {
  const activeTourists = [
    { id: 'tourist-1', tripId: 'trip-1', name: 'John Doe' },
    { id: 'tourist-2', tripId: 'trip-2', name: 'Jane Smith' },
  ];

  return (
    <div className="monitoring-dashboard">
      <div className="dashboard-header">
        <h1>Tourist Monitoring</h1>
        <AIHealthStatus />
      </div>

      <div className="tourists-grid">
        {activeTourists.map(tourist => (
          <div key={tourist.id} className="tourist-card">
            <h3>{tourist.name}</h3>
            
            {/* Mini distress score */}
            <DistressScoreCard
              touristId={tourist.id}
              tripId={tourist.tripId}
              currentObservation={{
                // Fetch from real-time data
                lat: '25.28',
                lng: '91.58',
                timestamp: new Date().toISOString(),
                speed_mps: '1.5',
                battery_pct: '65',
                accuracy_m: '15',
              }}
              autoAssess={true}
            />
          </div>
        ))}
      </div>
    </div>
  );
};

// Example 3: Add to existing Dashboard component
export const IntegrateIntoExistingDashboard = () => {
  /**
   * To add AI features to your existing dashboard:
   * 
   * 1. Import the components:
   *    import { AIHealthStatus } from './components/AIHealthStatus';
   *    import { DistressScoreCard } from './components/DistressScoreCard';
   * 
   * 2. Add AI Health Status to your header/navbar:
   *    <AIHealthStatus />
   * 
   * 3. When viewing tourist/incident details, show distress assessment:
   *    <DistressScoreCard 
   *      touristId={selectedTourist.id}
   *      tripId={selectedTourist.tripId}
   *      currentObservation={latestObservation}
   *      recentAlerts={alerts}
   *    />
   * 
   * 4. Add "Generate Investigation Report" button in incident actions:
   *    <InvestigationReportViewer 
   *      touristId={incident.touristId}
   *      tripId={incident.tripId}
   *    />
   */

  return (
    <div>
      <p>See code comments above for integration instructions</p>
    </div>
  );
};

export default IncidentDetailsWithAI;
