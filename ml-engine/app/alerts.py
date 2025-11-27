from __future__ import annotations

from typing import Dict, List

from .schemas import AlertPayload


class AlertDispatcher:
    """Stub dispatcher; extend with SMS/email/push providers."""

    def __init__(self) -> None:
        self._history: Dict[str, List[AlertPayload]] = {}

    def dispatch(self, alert: AlertPayload) -> None:
        key = alert.trip_id
        self._history.setdefault(key, []).append(alert)
        # Replace print statements with vendor integrations
        print(
            f"[ALERT] {alert.alert_type.upper()} for {alert.tourist_id}/{alert.trip_id}: "
            f"{alert.message} (severity={alert.severity})"
        )

    def history(self, trip_id: str) -> List[AlertPayload]:
        return self._history.get(trip_id, [])


dispatcher = AlertDispatcher()






