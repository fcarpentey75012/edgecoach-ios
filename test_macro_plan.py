#!/usr/bin/env python3
"""
Script de test manuel pour l'endpoint POST /api/plans/macro.
"""

import requests
import json
from datetime import date, timedelta

# Configuration
API_BASE_URL = "http://localhost:5002/api"
USER_ID = "6880a3a8a86549586b6db600"  # Remplacer par un user_id valide

def test_post_macro_plan():
    """Test de génération d'un macro plan."""

    print("=" * 60)
    print("🧪 TEST: POST /api/plans/macro")
    print("=" * 60)

    # Calculer les dates
    today = date.today()
    season_start = today + timedelta(days=7)  # Dans 1 semaine

    payload = {
        "user_id": USER_ID,
        "athlete_profile": {
            "sport": "triathlon",
            "level": "advanced",
            "plan_config": {
                "start_date": season_start.isoformat(),
                "weekly_time_available": 12,
                "constraints": "long vélo dimanche, sortie longue samedi",
                "per_sport_sessions": {
                    "swimming": 3,
                    "cycling": 3,
                    "running": 3
                }
            },
            "soft_constraints": {
                "unavailable_days": ["monday"],
                "preferred_easy_days": ["tuesday", "friday"],
                "preferred_long_workout_days": ["saturday", "sunday"],
                "max_sessions_per_week": 8,
                "no_doubles": False
            }
        },
        "objectives": [
            {
                "name": "10k Paris",
                "target_date": "2026-02-01",
                "priority": "principal",
                "objective_type": "race",
                "sport": "running",
                "race_format": "10k",
                "distance_value": 10.0,
                "distance_unit": "km",
                "target_time": "42:00"
            }
        ],
        "options": {
            "use_coordinator": True,
            "language": "fr"
        }
    }

    print(f"\n📤 Envoi de la requête...")
    print(f"   URL: {API_BASE_URL}/plans/macro")
    print(f"   User ID: {USER_ID}")

    try:
        response = requests.post(
            f"{API_BASE_URL}/plans/macro",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )

        print(f"\n📥 Réponse reçue:")
        print(f"   Status: {response.status_code}")
        print(f"   Body: {response.text}")

    except Exception as e:
        print(f"\n❌ Erreur: {e}")

if __name__ == "__main__":
    test_post_macro_plan()
