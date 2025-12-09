import React, { useState, useEffect } from 'react';
import { aiService, AIHealth } from '../services/ai.service';
import '../styles/AIComponents.css';

interface FeatureStatus {
    name: string;
    description: string;
    available: boolean;
    requiresLLM: boolean;
}

export const AIFeaturesStatus: React.FC = () => {
    const [health, setHealth] = useState<AIHealth | null>(null);
    const [loading, setLoading] = useState(true);
    const [showInstallInstructions, setShowInstallInstructions] = useState(false);

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

    const mlOnline = health?.ml_engine.status === 'ok';
    const llmOnline = health?.llm_service.status === 'ok' && health?.llm_service.ollama_available;

    const features: FeatureStatus[] = [
        {
            name: 'Real-time Anomaly Detection',
            description: 'Isolation Forest ML model detects unusual tourist behavior patterns',
            available: mlOnline,
            requiresLLM: false,
        },
        {
            name: 'Behavioral Pattern Analysis',
            description: 'Analyzes movement patterns, speed changes, and location history',
            available: mlOnline,
            requiresLLM: false,
        },
        {
            name: 'Multi-signal Distress Scoring',
            description: 'Combines time, location, battery, GPS, and alerts into risk score (0-100)',
            available: mlOnline,
            requiresLLM: false,
        },
        {
            name: 'GPS Anomaly Detection',
            description: 'Detects location jumps, signal loss, and accuracy degradation',
            available: mlOnline,
            requiresLLM: false,
        },
        {
            name: 'Natural Language Explanations',
            description: 'AI-generated human-readable explanations of detected anomalies',
            available: llmOnline,
            requiresLLM: true,
        },
        {
            name: 'AI Investigation Reports',
            description: 'Comprehensive 24-hour analysis with timeline, scenarios, and recommendations',
            available: llmOnline,
            requiresLLM: true,
        },
        {
            name: 'Safety Advisories',
            description: 'Context-aware safety recommendations for locations and situations',
            available: llmOnline,
            requiresLLM: true,
        },
        {
            name: 'Conversational Assistant',
            description: 'Chat with AI about destinations, safety, and travel recommendations',
            available: llmOnline,
            requiresLLM: true,
        },
    ];

    const activeFeatures = features.filter(f => f.available);
    const unavailableFeatures = features.filter(f => !f.available);

    if (loading) {
        return (
            <div className="ai-features-status loading">
                <div className="spinner-small"></div>
                <span>Loading AI features...</span>
            </div>
        );
    }

    return (
        <div className="ai-features-status-panel">
            <div className="ai-features-header">
                <h3>🤖 AI Capabilities Status</h3>
                <div className="features-summary">
                    <span className="active-count">{activeFeatures.length} Active</span>
                    <span className="separator">•</span>
                    <span className="inactive-count">{unavailableFeatures.length} Requires LLM</span>
                </div>
            </div>

            <div className="features-grid">
                {/* Active Features */}
                <div 
                    className="features-section" 
                    style={unavailableFeatures.length === 0 ? { gridColumn: 'span 2' } : {}}
                >
                    <h4 className="section-title">✅ Active Features</h4>
                    <div 
                        className="features-list"
                        style={unavailableFeatures.length === 0 ? { 
                            display: 'grid', 
                            gridTemplateColumns: '1fr 1fr',
                            gap: '12px' 
                        } : {}}
                    >
                        {activeFeatures.map((feature, idx) => (
                            <div key={idx} className="feature-card active" title={feature.description}>
                                <div className="feature-icon">✅</div>
                                <div className="feature-content">
                                    <div className="feature-name">{feature.name}</div>
                                    <div className="feature-description">{feature.description}</div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Unavailable Features */}
                {unavailableFeatures.length > 0 && (
                    <div className="features-section">
                        <h4 className="section-title">❌ Requires Ollama LLM</h4>
                        <div className="features-list">
                            {unavailableFeatures.map((feature, idx) => (
                                <div key={idx} className="feature-card inactive" title={feature.description}>
                                    <div className="feature-icon">❌</div>
                                    <div className="feature-content">
                                        <div className="feature-name">{feature.name}</div>
                                        <div className="feature-description">{feature.description}</div>
                                    </div>
                                </div>
                            ))}
                        </div>

                        {/* Installation Instructions */}
                        <div className="install-instructions">
                            <button
                                className="toggle-instructions-btn"
                                onClick={() => setShowInstallInstructions(!showInstallInstructions)}
                            >
                                {showInstallInstructions ? '▼' : '▶'} How to Enable LLM Features
                            </button>

                            {showInstallInstructions && (
                                <div className="instructions-content">
                                    <h5>Install Ollama & Phi-3 Model:</h5>
                                    <div className="code-block">
                                        <code>
                                            # Install Ollama (macOS)<br />
                                            brew install ollama<br />
                                            <br />
                                            # Pull Phi-3 Mini model (~3.8GB)<br />
                                            ollama pull phi3:mini<br />
                                            <br />
                                            # Start Ollama service<br />
                                            ollama serve
                                        </code>
                                    </div>
                                    <p className="instructions-note">
                                        After installation, refresh this page. LLM features will activate automatically.
                                    </p>
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </div>

            {/* Status Footer */}
            <div className="ai-features-footer">
                <div className="status-indicator">
                    <span className={`status-dot ${mlOnline ? 'online' : 'offline'}`}></span>
                    <span>ML Engine: {mlOnline ? 'Online' : 'Offline'}</span>
                </div>
                <div className="status-indicator">
                    <span className={`status-dot ${llmOnline ? 'online' : 'offline'}`}></span>
                    <span>LLM Service: {llmOnline ? 'Online' : 'Offline'}</span>
                </div>
                <div className="last-check">
                    Last checked: {new Date().toLocaleTimeString()}
                </div>
            </div>
        </div>
    );
};

export default AIFeaturesStatus;
