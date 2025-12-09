import React, { useState } from 'react';
import { aiService, DistressAssessment } from '../services/ai.service';
import '../styles/AIComponents.css';

interface DistressScoreProps {
  touristId: string;
  tripId: string;
  currentObservation?: Record<string, string>;
  recentAlerts?: any[];
  autoAssess?: boolean;
}

export const DistressScoreCard: React.FC<DistressScoreProps> = ({
  touristId,
  tripId,
  currentObservation,
  recentAlerts = [],
  autoAssess = false,
}) => {
  const [assessment, setAssessment] = useState<DistressAssessment | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    if (autoAssess && currentObservation) {
      assessDistress();
    }
  }, [autoAssess, touristId, tripId]);

  const assessDistress = async () => {
    if (!currentObservation) {
      setError('Missing current observation data');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const result = await aiService.assessDistress(
        touristId,
        tripId,
        currentObservation,
        recentAlerts
      );
      setAssessment(result);
    } catch (err: any) {
      setError(err.message || 'Failed to assess distress');
    } finally {
      setLoading(false);
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'CRITICAL': return '#dc2626';
      case 'HIGH': return '#ea580c';
      case 'MEDIUM': return '#f59e0b';
      case 'LOW': return '#22c55e';
      default: return '#6b7280';
    }
  };

  const getScoreColor = (score: number) => {
    if (score >= 60) return '#dc2626';
    if (score >= 30) return '#f59e0b';
    return '#22c55e';
  };

  if (loading) {
    return (
      <div className="distress-card loading">
        <div className="spinner"></div>
        <p>Analyzing distress signals...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="distress-card error">
        <p className="error-message">⚠️ {error}</p>
        <button onClick={assessDistress}>Retry</button>
      </div>
    );
  }

  if (!assessment) {
    return (
      <div className="distress-card empty">
        <p>Click to assess distress level</p>
        <button onClick={assessDistress} disabled={!currentObservation}>
          Assess Distress
        </button>
      </div>
    );
  }

  return (
    <div className="distress-card">
      <div className="distress-header">
        <h3>🚨 Distress Assessment</h3>
        <span 
          className="priority-badge"
          style={{ backgroundColor: getPriorityColor(assessment.priority) }}
        >
          {assessment.priority}
        </span>
      </div>

      <div className="distress-score">
        <div className="score-circle" style={{ borderColor: getScoreColor(assessment.distress_score) }}>
          <span className="score-value">{Math.round(assessment.distress_score)}</span>
          <span className="score-label">/ 100</span>
        </div>
        <div className="risk-level">
          Risk Level: <strong>{assessment.risk_level.toUpperCase()}</strong>
        </div>
      </div>

      <div className="assessment-text">
        <p>{assessment.assessment_text}</p>
      </div>

      {assessment.warning_signals.length > 0 && (
        <div className="warning-signals">
          <h4>⚠️ Warning Signals</h4>
          <ul>
            {assessment.warning_signals.map((signal, idx) => (
              <li key={idx}>{signal}</li>
            ))}
          </ul>
        </div>
      )}

      {assessment.recommended_actions.length > 0 && (
        <div className="recommended-actions">
          <h4>📋 Recommended Actions</h4>
          <ol>
            {assessment.recommended_actions.map((action, idx) => (
              <li key={idx}>{action}</li>
            ))}
          </ol>
        </div>
      )}

      <button onClick={assessDistress} className="refresh-btn">
        🔄 Refresh Assessment
      </button>
    </div>
  );
};

export default DistressScoreCard;
