import React, { useState } from 'react';
import { aiService, InvestigationReport } from '../services/ai.service';
import '../styles/AIComponents.css';

interface InvestigationReportProps {
  touristId: string;
  tripId: string;
  incidentType?: string;
}

export const InvestigationReportViewer: React.FC<InvestigationReportProps> = ({
  touristId,
  tripId,
  incidentType = 'anomaly',
}) => {
  const [report, setReport] = useState<InvestigationReport | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});

  const generateReport = async () => {
    setLoading(true);
    setError(null);

    try {
      const result = await aiService.generateInvestigationReport(
        touristId,
        tripId,
        incidentType,
        24
      );
      setReport(result);
      // Auto-expand first section
      if (result.sections && Object.keys(result.sections).length > 0) {
        setExpanded({ [Object.keys(result.sections)[0]]: true });
      }
    } catch (err: any) {
      setError(err.message || 'Failed to generate report');
    } finally {
      setLoading(false);
    }
  };

  const toggleSection = (sectionName: string) => {
    setExpanded(prev => ({
      ...prev,
      [sectionName]: !prev[sectionName]
    }));
  };

  const downloadReport = () => {
    if (!report) return;

    const blob = new Blob([report.full_report], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `investigation_${touristId}_${tripId}_${report.generated_at}.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  if (loading) {
    return (
      <div className="investigation-report loading">
        <div className="spinner"></div>
        <p>Generating AI-powered investigation report...</p>
        <small>This may take 3-5 seconds</small>
      </div>
    );
  }

  if (error) {
    return (
      <div className="investigation-report error">
        <p className="error-message">⚠️ {error}</p>
        <button onClick={generateReport}>Retry</button>
      </div>
    );
  }

  if (!report) {
    return (
      <div className="investigation-report empty">
        <div className="empty-state">
          <h3>📄 Investigation Report</h3>
          <p>Generate a comprehensive AI-powered investigation report</p>
          <button onClick={generateReport} className="generate-btn">
            🤖 Generate Report
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="investigation-report">
      <div className="report-header">
        <div>
          <h2>🔍 Investigation Report</h2>
          <p className="report-meta">
            Case: {report.tourist_id} / {report.trip_id} | 
            Type: {report.incident_type} | 
            Generated: {new Date(report.generated_at).toLocaleString()}
          </p>
        </div>
        <div className="report-actions">
          <button onClick={downloadReport} className="download-btn">
            ⬇️ Download
          </button>
          <button onClick={generateReport} className="refresh-btn">
            🔄 Regenerate
          </button>
        </div>
      </div>

      <div className="report-sections">
        {Object.entries(report.sections).map(([sectionName, content]) => (
          <div key={sectionName} className="report-section">
            <div 
              className="section-header"
              onClick={() => toggleSection(sectionName)}
            >
              <h3>
                {expanded[sectionName] ? '▼' : '▶'} {sectionName}
              </h3>
            </div>
            {expanded[sectionName] && (
              <div className="section-content">
                <pre>{content}</pre>
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="full-report-section">
        <details>
          <summary>View Full Report (Markdown)</summary>
          <pre className="full-report-text">{report.full_report}</pre>
        </details>
      </div>
    </div>
  );
};

export default InvestigationReportViewer;
