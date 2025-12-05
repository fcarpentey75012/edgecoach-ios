
import requests
import json
from datetime import date, timedelta

# Configuration
API_BASE_URL = "http://localhost:5002/api"
USER_ID = "6880a3a8a86549586b6db600"  # Same user ID as user provided

def test_legacy_plan():
    print("=" * 60)
    print("🧪 TEST: POST /api/plans/generate (Legacy)")
    print("=" * 60)

    today = date.today()
    season_start = today + timedelta(days=7)

    # Payload matching PlansService.GeneratePlanRequest
    payload = {
        "user_id": USER_ID,
        "sport": "triathlon",
        "experience_level": "intermediate", # intermediate in frontend -> intermediate
        "objectives": ["10k Paris", "Ironman 70.3 Carcans"], # simplistic list of strings
        "custom_objective": None,
        "duration_weeks": 12, # guess
        "start_date": season_start.isoformat(),
        "weekly_hours": 12,
        "constraints": "long vélo dimanche, sortie longue samedi",
        "unavailable_days": ["monday"],
        "language": "fr"
    }

    print(f"\n📤 Envoi de la requête...")
    print(f"   URL: {API_BASE_URL}/plans/generate")

    try:
        response = requests.post(
            f"{API_BASE_URL}/plans/generate",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=120
        )

        print(f"\n📥 Réponse reçue:")
        print(f"   Status: {response.status_code}")
        
        try:
             print(f"   Body: {json.dumps(response.json(), indent=2)}")
        except:
             print(f"   Body: {response.text}")

    except Exception as e:
        print(f"\n❌ Erreur: {e}")

if __name__ == "__main__":
    test_legacy_plan()
