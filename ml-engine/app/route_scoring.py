"""Route safety scoring module for TourGuard ML Engine.

Calculates safety scores for route segments based on:
- Danger zone intersections
- Historical incident data
- Time-of-day factors
"""
from __future__ import annotations

from datetime import datetime
from typing import List, Tuple

from shapely.geometry import LineString, Point
from shapely import geometry

from .schemas import RoutePoint, DangerZone
from .detection import engine


def score_route_segment(
    lat1: float,
    lng1: float,
    lat2: float,
    lng2: float,
    timestamp: datetime | None = None,
) -> float:
    """Score a single route segment for safety.
    
    Args:
        lat1, lng1: Start point coordinates
        lat2, lng2: End point coordinates
        timestamp: Time of travel (for time-of-day adjustment)
        
    Returns:
        Safety score from 0 (very unsafe) to 100 (very safe)
    """
    base_score = 100.0
    
    # Create line segment
    segment = LineString([(lng1, lat1), (lng2, lat2)])
    
    # Check intersection with danger zones
    for polygon, name, risk_level, advisory in engine._danger_polygons:
        if segment.intersects(polygon):
            # Calculate penalty based on risk level
            if risk_level == "high":
                base_score -= 45
            elif risk_level == "medium":
                base_score -= 30
            else:  # low
                base_score -= 15
    
    # Apply time-of-day adjustment
    if timestamp:
        hour = timestamp.hour
        # Nighttime penalty (8 PM to 6 AM)
        if hour >= 20 or hour < 6:
            base_score *= 0.85  # 15% penalty for nighttime
    
    return max(0.0, min(100.0, base_score))


def get_route_safety_impact(
    route_points: List[RoutePoint],
    danger_zones: List[Tuple[geometry.Polygon, str, str, str]] | None = None,
) -> dict[str, any]:
    """Calculate overall safety impact of a route.
    
    Args:
        route_points: List of coordinates forming the route
        danger_zones: Optional list of danger zone polygons
        
    Returns:
        Dictionary with safety metrics including zones crossed
    """
    if danger_zones is None:
        danger_zones = engine._danger_polygons
    
    zones_crossed = []
    total_high_risk = 0
    total_medium_risk = 0
    total_low_risk = 0
    
    # Create route line
    if len(route_points) < 2:
        return {
            "zones_crossed": [],
            "high_risk_count": 0,
            "medium_risk_count": 0,
            "low_risk_count": 0,
            "total_zones": 0,
        }
    
    coords = [(p.lng, p.lat) for p in route_points]
    route_line = LineString(coords)
    
    # Check each danger zone
    seen_zones = set()
    for polygon, name, risk_level, advisory in danger_zones:
        if route_line.intersects(polygon) and name not in seen_zones:
            zones_crossed.append({
                "name": name,
                "risk_level": risk_level,
                "advisory": advisory,
            })
            seen_zones.add(name)
            
            if risk_level == "high":
                total_high_risk += 1
            elif risk_level == "medium":
                total_medium_risk += 1
            else:
                total_low_risk += 1
    
    return {
        "zones_crossed": zones_crossed,
        "high_risk_count": total_high_risk,
        "medium_risk_count": total_medium_risk,
        "low_risk_count": total_low_risk,
        "total_zones": len(zones_crossed),
    }


def calculate_time_adjusted_safety(
    base_score: float,
    hour_of_day: int,
) -> float:
    """Adjust safety score based on time of day.
    
    Args:
        base_score: Base safety score (0-100)
        hour_of_day: Hour in 24-hour format (0-23)
        
    Returns:
        Adjusted safety score
    """
    # Nighttime hours (8 PM to 6 AM) get penalty
    if hour_of_day >= 20 or hour_of_day < 6:
        return base_score * 0.85
    
    # Early morning (6 AM to 8 AM) slight penalty
    if 6 <= hour_of_day < 8:
        return base_score * 0.95
    
    # Late evening (6 PM to 8 PM) slight penalty
    if 18 <= hour_of_day < 20:
        return base_score * 0.95
    
    # Daytime hours - no adjustment
    return base_score


def calculate_overall_route_score(
    route_points: List[RoutePoint],
    timestamp: datetime | None = None,
) -> Tuple[float, dict[str, any]]:
    """Calculate comprehensive safety score for entire route.
    
    Args:
        route_points: List of coordinates forming the route
        timestamp: Time of travel
        
    Returns:
        Tuple of (overall_score, safety_metadata)
    """
    if len(route_points) < 2:
        return 100.0, {"zones_crossed": [], "segments_analyzed": 0}
    
    # Score each segment
    segment_scores = []
    for i in range(len(route_points) - 1):
        p1 = route_points[i]
        p2 = route_points[i + 1]
        score = score_route_segment(p1.lat, p1.lng, p2.lat, p2.lng, timestamp)
        segment_scores.append(score)
    
    # Calculate weighted average (favor worst segments)
    if segment_scores:
        # Use minimum score with 60% weight, average with 40% weight
        min_score = min(segment_scores)
        avg_score = sum(segment_scores) / len(segment_scores)
        overall_score = (min_score * 0.6) + (avg_score * 0.4)
    else:
        overall_score = 100.0
    
    # Get danger zone impact
    impact = get_route_safety_impact(route_points)
    
    # Apply time adjustment if provided
    if timestamp:
        overall_score = calculate_time_adjusted_safety(overall_score, timestamp.hour)
    
    metadata = {
        "zones_crossed": impact["zones_crossed"],
        "segments_analyzed": len(segment_scores),
        "min_segment_score": min(segment_scores) if segment_scores else 100.0,
        "avg_segment_score": sum(segment_scores) / len(segment_scores) if segment_scores else 100.0,
        "high_risk_zones": impact["high_risk_count"],
        "medium_risk_zones": impact["medium_risk_count"],
        "low_risk_zones": impact["low_risk_count"],
    }
    
    return overall_score, metadata
