import React, { useState, useEffect } from 'react';
import { aiService, AIHealth } from '../services/ai.service';
import '../styles/AIComponents.css';

export const AIHealthStatus: React.FC = () => {
  const [health, setHealth] = useState<AIHealth | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkHealth();
    const interval = setInterval(checkHealth, 30000); // Check every 30s
    return () => clearInterval(interval);
  }, []);

  const checkHealth = async () => {
    try {
      const result = await aiService.checkHealth();
      setHealth(result);
    } catch (err) {
      console.error('Health check failed:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="ai-health-status loading">
        <div className="spinner-small"></div>
      </div>
    );
  }

  if (!health) {
    return (
      <div className="ai-health-status offline">
        <span className="status-dot offline"></span>
        <span>AI Services Offline</span>
      </div>
    );
  }

  const mlOnline = health.ml_engine.status === 'ok';
  const llmOnline = health.llm_service.status === 'ok' && health.llm_service.ollama_available;

  return (
    <div className="ai-health-status">
      <div className="health-item">
        <span className={`status-dot ${mlOnline ? 'online' : 'offline'}`}></span>
        <span className="health-label">ML Engine</span>
      </div>
      <div className="health-item">
        <span className={`status-dot ${llmOnline ? 'online' : 'warning'}`}></span>
        <span className="health-label">
          LLM ({health.llm_service.model})
          {!llmOnline && <small> - Degraded Mode</small>}
        </span>
      </div>
    </div>
  );
};

export default AIHealthStatus;
