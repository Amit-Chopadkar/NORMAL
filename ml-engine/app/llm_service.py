"""
LLM Service Module for TourGuard ML Engine

Provides intelligent AI features using Ollama with Phi-3 Mini:
- Conversational travel assistant
- Safety advisory generation
- Itinerary suggestions
- Enhanced alert messaging
"""

from __future__ import annotations

import json
import logging
from datetime import datetime
from typing import Dict, List, Optional, Tuple

try:
    import ollama
    OLLAMA_AVAILABLE = True
except ImportError:
    OLLAMA_AVAILABLE = False
    logging.warning("Ollama package not installed. LLM features will be disabled.")

from .config import get_settings
from .schemas import RiskLevel

logger = logging.getLogger(__name__)
settings = get_settings()


class LLMService:
    """Service for interacting with Ollama LLM."""
    
    def __init__(self):
        self.enabled = settings.llm_enabled and OLLAMA_AVAILABLE
        self.model = settings.ollama_model
        self.host = settings.ollama_host
        self.timeout = settings.llm_timeout
        self.max_tokens = settings.llm_max_tokens
        self._cache: Dict[str, str] = {}
        
        if self.enabled:
            try:
                self._verify_connection()
                logger.info(f"LLM Service initialized with model: {self.model}")
            except Exception as e:
                logger.error(f"Failed to initialize LLM service: {e}")
                self.enabled = False
        else:
            logger.warning("LLM Service is disabled. Enable with ML_ENGINE_LLM_ENABLED=true")
    
    def _verify_connection(self) -> bool:
        """Verify Ollama is running and model is available."""
        try:
            # Try to list models to verify connection
            response = ollama.list()
            # Ollama API returns 'model' field, not 'name'
            models = [model.get('model') or model.get('name') for model in response.get('models', [])]
            
            if self.model not in models:
                logger.warning(f"Model {self.model} not found. Available models: {models}")
                logger.info(f"Pull the model with: ollama pull {self.model}")
                return False
            
            return True
        except Exception as e:
            logger.error(f"Ollama connection failed: {e}")
            raise
    
    def is_available(self) -> bool:
        """Check if LLM service is available."""
        return self.enabled
    
    def _generate(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        """Generate text using Ollama."""
        if not self.enabled:
            return "LLM service is currently unavailable."
        
        # Check cache
        cache_key = f"{system_prompt}::{prompt}"
        if cache_key in self._cache:
            logger.debug("Returning cached response")
            return self._cache[cache_key]
        
        try:
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})
            
            response = ollama.chat(
                model=self.model,
                messages=messages,
                options={
                    "num_predict": self.max_tokens,
                    "temperature": 0.7,
                }
            )
            
            result = response['message']['content'].strip()
            
            # Cache the response
            self._cache[cache_key] = result
            
            # Limit cache size
            if len(self._cache) > 100:
                # Remove oldest entry
                self._cache.pop(next(iter(self._cache)))
            
            return result
            
        except Exception as e:
            logger.error(f"LLM generation failed: {e}")
            return f"I'm having trouble processing your request right now. Please try again later."
    
    def chat_travel_assistant(
        self, 
        message: str, 
        location: Optional[Dict] = None,
        context: Optional[Dict] = None
    ) -> Tuple[str, List[str], Optional[float]]:
        """
        Handle conversational queries about travel, safety, and destinations.
        
        Returns:
            Tuple of (response_text, suggested_actions, safety_score)
        """
        system_prompt = """You are a knowledgeable travel assistant specializing in Meghalaya, India.
Your primary focus is tourist safety. Provide helpful, accurate information about:
- Popular destinations and hidden gems
- Safety considerations and precautions
- Local culture and customs
- Best times to visit
- Transportation options

Always prioritize safety in your recommendations. Be concise and practical.
If you don't know something, say so rather than guessing."""

        # Build context-aware prompt
        prompt_parts = [message]
        
        if location:
            loc_name = location.get('name', 'current location')
            prompt_parts.append(f"\n\nUser is at: {loc_name} ({location.get('lat')}, {location.get('lng')})")
        
        if context:
            if context.get('danger_zones_nearby'):
                prompt_parts.append(f"\nNearby danger zones: {context['danger_zones_nearby']}")
            if context.get('current_risk'):
                prompt_parts.append(f"\nCurrent area risk level: {context['current_risk']}")
        
        full_prompt = "".join(prompt_parts)
        response = self._generate(full_prompt, system_prompt)
        
        # Extract suggested actions (simple heuristic)
        suggested_actions = []
        if any(word in response.lower() for word in ['should', 'recommend', 'suggest', 'try']):
            # Simple extraction - look for action phrases
            lines = response.split('.')
            for line in lines:
                if any(word in line.lower() for word in ['should', 'recommend', 'suggest']):
                    action = line.strip()
                    if action and len(action) < 100:
                        suggested_actions.append(action)
        
        # Estimate safety score based on response content
        safety_score = None
        if any(word in response.lower() for word in ['danger', 'risk', 'unsafe', 'avoid', 'caution']):
            safety_score = 60.0
        elif any(word in response.lower() for word in ['safe', 'secure', 'recommended']):
            safety_score = 85.0
        
        return response, suggested_actions[:3], safety_score
    
    def generate_safety_advisory(
        self,
        location_name: str,
        risk_level: Optional[str] = None,
        time_of_day: Optional[str] = None,
        user_profile: Optional[Dict] = None
    ) -> Tuple[str, RiskLevel, List[str]]:
        """
        Generate contextual safety advisory for a location.
        
        Returns:
            Tuple of (advisory_text, risk_assessment, recommendations)
        """
        system_prompt = """You are a safety expert for tourist destinations in Meghalaya, India.
Generate concise, actionable safety advisories. Consider:
- Current risk level of the area
- Time of day (night travel is generally riskier)
- Traveler profile (solo vs group, local vs foreign)
- Specific local safety concerns

Format: Brief advisory followed by 2-4 specific recommendations.
Be reassuring but honest about risks."""

        prompt_parts = [f"Generate a safety advisory for: {location_name}"]
        
        if risk_level:
            prompt_parts.append(f"\nCurrent risk level: {risk_level}")
        if time_of_day:
            prompt_parts.append(f"\nTime of day: {time_of_day}")
        if user_profile:
            if user_profile.get('solo_traveler'):
                prompt_parts.append("\nTraveler: Solo tourist")
            if user_profile.get('foreign_traveler'):
                prompt_parts.append("\nTraveler: International visitor")
        
        prompt_parts.append("\n\nProvide: 1) Brief assessment 2) List of 3 recommendations starting each with '-'")
        
        full_prompt = "".join(prompt_parts)
        response = self._generate(full_prompt, system_prompt)
        
        # Extract recommendations (lines starting with -)
        recommendations = []
        for line in response.split('\n'):
            line = line.strip()
            if line.startswith('-') or line.startswith('•'):
                rec = line.lstrip('-•').strip()
                if rec:
                    recommendations.append(rec)
        
        # Determine risk assessment based on response
        response_lower = response.lower()
        if any(word in response_lower for word in ['high risk', 'dangerous', 'avoid', 'not recommended']):
            assessed_risk: RiskLevel = 'high'
        elif any(word in response_lower for word in ['moderate', 'caution', 'careful']):
            assessed_risk = 'medium'
        else:
            assessed_risk = 'low'
        
        # If we have explicit risk level, use it
        if risk_level and risk_level in ['low', 'medium', 'high']:
            assessed_risk = risk_level  # type: ignore
        
        return response, assessed_risk, recommendations[:4]
    
    def suggest_itinerary(
        self,
        destinations: List[str],
        duration_days: int,
        preferences: Optional[Dict] = None,
        safety_scores: Optional[Dict[str, float]] = None
    ) -> Tuple[str, List[Dict], float, List[str]]:
        """
        Generate safe itinerary suggestions.
        
        Returns:
            Tuple of (itinerary_text, daily_plan, overall_safety_score, safety_notes)
        """
        system_prompt = """You are an expert travel planner for Meghalaya, India.
Create safe, enjoyable itineraries that balance exploration with security.
Consider safety scores, travel distances, and realistic timing.
Format each day clearly with: Day X: Location - Activities."""

        dest_list = ", ".join(destinations)
        prompt_parts = [
            f"Create a {duration_days}-day itinerary for: {dest_list}"
        ]
        
        if preferences:
            if preferences.get('focus') == 'safety':
                prompt_parts.append("\nPriority: Maximum safety")
            if preferences.get('pace'):
                prompt_parts.append(f"\nPreferred pace: {preferences['pace']}")
        
        if safety_scores:
            prompt_parts.append("\n\nSafety scores (0-100):")
            for dest, score in safety_scores.items():
                prompt_parts.append(f"\n- {dest}: {score:.0f}/100")
        
        prompt_parts.append(f"\n\nCreate day-by-day plan for {duration_days} days. Include safety tips.")
        
        full_prompt = "".join(prompt_parts)
        response = self._generate(full_prompt, system_prompt)
        
        # Extract daily plan
        daily_plan = []
        lines = response.split('\n')
        current_day = None
        
        for line in lines:
            line = line.strip()
            if line.startswith('Day ') or line.startswith('**Day '):
                # Extract day info
                parts = line.split(':', 1)
                if len(parts) == 2:
                    day_num = parts[0].replace('*', '').strip()
                    day_content = parts[1].strip()
                    current_day = {
                        'day': day_num,
                        'content': day_content,
                        'activities': []
                    }
                    daily_plan.append(current_day)
            elif current_day and line and not line.startswith('#'):
                # Add to current day's activities
                if line.startswith('-') or line.startswith('•'):
                    activity = line.lstrip('-•').strip()
                    if activity:
                        current_day['activities'].append(activity)
        
        # Extract safety notes
        safety_notes = []
        for line in lines:
            line_lower = line.lower()
            if any(word in line_lower for word in ['safety', 'caution', 'avoid', 'careful', 'warning']):
                note = line.strip().lstrip('-•*#').strip()
                if note and len(note) > 10:
                    safety_notes.append(note)
        
        # Calculate overall safety score
        if safety_scores:
            overall_safety = sum(safety_scores.values()) / len(safety_scores)
        else:
            overall_safety = 75.0  # Default moderate-high safety
        
        return response, daily_plan, overall_safety, safety_notes[:5]
    
    def enhance_alert_message(
        self,
        alert_type: str,
        base_message: str,
        location: Optional[Dict] = None,
        metadata: Optional[Dict] = None
    ) -> str:
        """
        Enhance alert messages with contextual information and actionable advice.
        
        This is optional enhancement - base message is always shown.
        """
        if not self.enabled:
            return base_message
        
        system_prompt = """You are a safety assistant. Enhance alert messages with:
- Clear explanation of the situation
- Immediate actionable steps
- Reassurance where appropriate
Keep it brief (2-3 sentences) and practical."""

        prompt = f"""Alert type: {alert_type}
Base message: {base_message}

Enhance this alert with practical advice. Be concise and actionable."""

        if location:
            prompt += f"\nLocation: {location.get('name', 'Unknown')}"
        
        if metadata:
            prompt += f"\nContext: {json.dumps(metadata)}"
        
        try:
            enhanced = self._generate(prompt, system_prompt)
            # Return enhanced message if it's reasonable length
            if len(enhanced) < 300:
                return enhanced
            return base_message
        except:
            # Fall back to base message on any error
            return base_message
    
    def explain_anomaly(
        self,
        anomaly_type: str,
        anomaly_data: Dict,
        observation: Optional[Dict] = None,
        context: Optional[Dict] = None
    ) -> str:
        """
        Generate human-readable explanation for detected anomalies.
        
        Args:
            anomaly_type: Type of anomaly (location_jump, erratic_movement, etc.)
            anomaly_data: Anomaly detection details
            observation: Current observation data
            context: Additional context (location, time, etc.)
        
        Returns:
            Detailed explanation of the anomaly
        """
        if not self.enabled:
            return f"Anomaly detected: {anomaly_data.get('message', anomaly_type)}"
        
        system_prompt = """You are a safety analyst explaining detected anomalies in tourist behavior.
Provide clear, actionable explanations that help responders understand:
- What anomaly was detected
- Why it's concerning
- Possible causes (benign vs concerning)
- Recommended actions

Be concise but thorough. Prioritize safety."""

        prompt_parts = [
            f"Anomaly Type: {anomaly_type}",
            f"\nDetection: {anomaly_data.get('message', 'Unknown anomaly')}"
        ]
        
        if observation:
            prompt_parts.append(f"\n\nCurrent Status:")
            prompt_parts.append(f"- Location: ({observation.get('lat')}, {observation.get('lng')})")
            prompt_parts.append(f"- Time: {observation.get('timestamp')}")
            prompt_parts.append(f"- Speed: {observation.get('speed_mps', 0) * 3.6:.1f} km/h")
            if observation.get('battery_pct'):
                prompt_parts.append(f"- Battery: {observation['battery_pct']:.0f}%")
        
        if context:
            prompt_parts.append(f"\n\nContext:")
            for key, value in context.items():
                prompt_parts.append(f"- {key}: {value}")
        
        prompt_parts.append("\n\nProvide: 1) Explanation 2) Possible causes 3) Recommended immediate actions")
        
        full_prompt = "".join(prompt_parts)
        return self._generate(full_prompt, system_prompt)
    
    def assess_distress_probability(
        self,
        signals: List[str],
        distress_score: float,
        observation: Dict,
        history_summary: Optional[Dict] = None
    ) -> Tuple[str, List[str], str]:
        """
        Assess distress situation and provide detailed analysis.
        
        Args:
            signals: List of detected warning signals
            distress_score: Numerical distress score (0-100)
            observation: Current observation data
            history_summary: Summary of recent behavior
        
        Returns:
            Tuple of (assessment_text, recommended_actions, priority_level)
        """
        if not self.enabled:
            # Fallback assessment
            if distress_score >= 60:
                return (
                    f"HIGH DISTRESS PROBABILITY ({distress_score:.0f}%): Multiple warning signals detected. Immediate intervention recommended.",
                    ["Contact tourist immediately", "Alert emergency services", "Monitor situation closely"],
                    "CRITICAL"
                )
            elif distress_score >= 30:
                return (
                    f"MODERATE CONCERN ({distress_score:.0f}%): Some warning signals present. Monitor closely.",
                    ["Attempt contact with tourist", "Check for pattern continuation", "Prepare for escalation"],
                    "MEDIUM"
                )
            else:
                return (
                    f"LOW RISK ({distress_score:.0f}%): Minimal warning signals. Continue normal monitoring.",
                    ["Continue routine monitoring"],
                    "LOW"
                )
        
        system_prompt = """You are an emergency response analyst assessing tourist distress situations.
Analyze the warning signals and provide:
1. Clear risk assessment
2. Prioritized action recommendations
3. Context-aware reasoning

Be direct and actionable. In emergencies, clarity saves lives."""

        signal_list = "\n".join(f"- {s}" for s in signals)
        
        prompt = f"""DISTRESS ASSESSMENT REQUEST

Distress Score: {distress_score:.0f}/100

Warning Signals:
{signal_list}

Current Status:
- Location: ({observation.get('lat')}, {observation.get('lng')})
- Time: {observation.get('timestamp')}
- Battery: {observation.get('battery_pct', 'Unknown')}%
- GPS Accuracy: {observation.get('accuracy_m', 'Unknown')}m
"""
        
        if history_summary:
            prompt += f"\n\nRecent Behavior:\n"
            for key, value in history_summary.items():
                prompt += f"- {key}: {value}\n"
        
        prompt += """\n\nProvide:
1. Risk Assessment (CRITICAL/HIGH/MEDIUM/LOW)
2. Situation Analysis (2-3 sentences)
3. Immediate Actions (prioritized list of 3-5 actions)
4. Escalation Triggers (when to escalate further)

Format as clear sections."""
        
        response = self._generate(prompt, system_prompt)
        
        # Parse response for actions and priority
        actions = []
        priority = "MEDIUM"
        
        lines = response.split('\n')
        in_actions_section = False
        
        for line in lines:
            line = line.strip()
            
            # Detect priority from response
            if 'CRITICAL' in line.upper():
                priority = "CRITICAL"
            elif 'HIGH' in line.upper() and priority != "CRITICAL":
                priority = "HIGH"
            elif 'LOW' in line.upper() and priority not in ["CRITICAL", "HIGH"]:
                priority = "LOW"
            
            # Extract actions
            if 'immediate action' in line.lower() or 'recommended action' in line.lower():
                in_actions_section = True
                continue
            
            if in_actions_section:
                if line.startswith('-') or line.startswith('•') or any(line.startswith(f"{i}.") for i in range(1, 10)):
                    action = line.lstrip('-•0123456789. ').strip()
                    if action and len(action) > 5:
                        actions.append(action)
                elif line and not line[0].isdigit() and len(actions) > 0:
                    in_actions_section = False
        
        # Ensure we have at least some actions
        if not actions:
            if distress_score >= 60:
                actions = [
                    "Immediately contact tourist via all available channels",
                    "Dispatch emergency services to last known location",
                    "Alert tourist's emergency contacts",
                    "Prepare search and rescue if no response within 15 minutes"
                ]
            else:
                actions = [
                    "Attempt to contact tourist",
                    "Continue monitoring for pattern changes",
                    "Review recent behavior for additional context"
                ]
        
        return (response, actions[:5], priority)
    
    def generate_investigation_report(
        self,
        tourist_id: str,
        trip_id: str,
        observations: List[Dict],
        alerts: List[Dict],
        incident_type: str = "anomaly"
    ) -> Dict:
        """
        Generate comprehensive investigation report.
        
        Args:
            tourist_id: Tourist identifier
            trip_id: Trip identifier
            observations: List of observations (chronological)
            alerts: List of triggered alerts
            incident_type: Type of incident (missing_person, anomaly, etc.)
        
        Returns:
            Dict with report sections
        """
        if not self.enabled:
            return {
                'summary': f"Investigation report for {tourist_id} - {incident_type}",
                'timeline': [f"{o.get('timestamp')}: Location update" for o in observations[-10:]],
                'analysis': "LLM service unavailable. Manual analysis required.",
                'recommendations': ["Review observation data manually", "Contact local authorities"]
            }
        
        system_prompt = """You are a professional investigator analyzing tourist safety incidents.
Create detailed, factual investigation reports with:
- Timeline reconstruction
- Pattern analysis
- Scenario assessment (ranked by likelihood)
- Evidence-based recommendations

Be thorough, objective, and actionable."""

        # Prepare observation summary
        if observations:
            first_obs = observations[0]
            last_obs = observations[-1]
            duration = "Unknown"
            if 'timestamp' in first_obs and 'timestamp' in last_obs:
                # Calculate duration (simplified)
                duration = f"{len(observations)} observations"
            
            obs_summary = f"""
Observation Period: {first_obs.get('timestamp')} to {last_obs.get('timestamp')}
Total Observations: {len(observations)}
First Location: ({first_obs.get('lat')}, {first_obs.get('lng')})
Last Location: ({last_obs.get('lat')}, {last_obs.get('lng')})
"""
        else:
            obs_summary = "No observation data available"
        
        # Prepare alert summary
        alert_summary = "\n".join(
            f"- {a.get('timestamp')}: {a.get('alert_type')} - {a.get('message')}"
            for a in alerts
        ) if alerts else "No alerts triggered"
        
        prompt = f"""INVESTIGATION REPORT REQUEST

Case ID: {tourist_id} / {trip_id}
Incident Type: {incident_type}

OBSERVATION DATA:
{obs_summary}

ALERTS TRIGGERED:
{alert_summary}

Generate a comprehensive investigation report with the following sections:

1. EXECUTIVE SUMMARY (2-3 sentences)
2. TIMELINE RECONSTRUCTION (key events in chronological order)
3. BEHAVIORAL ANALYSIS (patterns, anomalies, deviations)
4. SCENARIO ASSESSMENT (3-4 scenarios ranked by probability with %)
5. RECOMMENDED ACTIONS (prioritized investigation steps)
6. EVIDENCE TO COLLECT (specific items needed)

Be specific, factual, and actionable."""
        
        response = self._generate(prompt, system_prompt)
        
        # Parse response into sections
        sections = {}
        current_section = None
        section_content = []
        
        for line in response.split('\n'):
            line = line.strip()
            
            # Detect section headers
            if any(header in line.upper() for header in [
                'EXECUTIVE SUMMARY', 'TIMELINE', 'BEHAVIORAL', 'SCENARIO',
                'RECOMMENDED', 'EVIDENCE', 'SUMMARY', 'ANALYSIS'
            ]):
                if current_section:
                    sections[current_section] = '\n'.join(section_content).strip()
                current_section = line.rstrip(':').strip()
                section_content = []
            elif current_section:
                if line:
                    section_content.append(line)
        
        # Add last section
        if current_section:
            sections[current_section] = '\n'.join(section_content).strip()
        
        return {
            'full_report': response,
            'sections': sections,
            'tourist_id': tourist_id,
            'trip_id': trip_id,
            'incident_type': incident_type,
            'generated_at': datetime.now().isoformat()
        }


# Singleton instance
_llm_service: Optional[LLMService] = None


def get_llm_service() -> LLMService:
    """Get or create LLM service singleton."""
    global _llm_service
    if _llm_service is None:
        _llm_service = LLMService()
    return _llm_service
