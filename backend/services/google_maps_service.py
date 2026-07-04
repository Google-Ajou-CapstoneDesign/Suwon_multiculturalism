import os
import googlemaps

_client: googlemaps.Client | None = None


def get_client() -> googlemaps.Client:
    global _client
    if _client is None:
        api_key = os.getenv("GOOGLE_MAPS_API_KEY")
        if not api_key:
            raise RuntimeError("GOOGLE_MAPS_API_KEY environment variable is not set")
        _client = googlemaps.Client(key=api_key)
    return _client


def search_nearby(
    lat: float,
    lng: float,
    keyword: str,
    radius: int = 5000,
) -> list[dict]:
    client = get_client()
    result = client.places_nearby(
        location=(lat, lng),
        radius=radius,
        keyword=keyword,
        language="ko",
    )
    places = []
    for place in result.get("results", [])[:5]:
        loc = place["geometry"]["location"]
        places.append(
            {
                "name": place.get("name", ""),
                "lat": loc["lat"],
                "lng": loc["lng"],
                "address": place.get("vicinity", ""),
                "phone": place.get("formatted_phone_number", ""),
            }
        )
    return places
