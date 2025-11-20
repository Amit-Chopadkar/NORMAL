const axios = require('axios');
const NodeCache = require('node-cache');

// Cache for 1 hour (3600 seconds)
const placesCache = new NodeCache({ stdTTL: 3600 });

const GOOGLE_PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY;
const BASE_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

// Mock data for fallback/testing when no API key is present
const MOCK_PLACES = [
  {
    place_id: 'mock1',
    name: 'Sula Vineyards (Mock)',
    rating: 4.5,
    user_ratings_total: 1250,
    vicinity: 'Gangapur-Savargaon Road, Nashik',
    geometry: { location: { lat: 20.0063, lng: 73.6868 } },
    photos: [{ photo_reference: 'mock_photo_ref_1' }],
    types: ['tourist_attraction', 'point_of_interest'],
    opening_hours: { open_now: true }
  },
  {
    place_id: 'mock2',
    name: 'Pandavleni Caves (Mock)',
    rating: 4.4,
    user_ratings_total: 3400,
    vicinity: 'Buddha Vihar, Pathardi Phata, Nashik',
    geometry: { location: { lat: 19.9416, lng: 73.7636 } },
    photos: [{ photo_reference: 'mock_photo_ref_2' }],
    types: ['tourist_attraction', 'point_of_interest'],
    opening_hours: { open_now: false }
  },
  {
    place_id: 'mock3',
    name: 'Sadhana Restaurant (Mock)',
    rating: 4.3,
    user_ratings_total: 5600,
    vicinity: 'Hardev Nagar, Nashik',
    geometry: { location: { lat: 19.9975, lng: 73.7898 } },
    photos: [{ photo_reference: 'mock_photo_ref_3' }],
    types: ['restaurant', 'food'],
    opening_hours: { open_now: true }
  },
  {
    place_id: 'mock4',
    name: 'Zonkers Adventure Park (Mock)',
    rating: 4.2,
    user_ratings_total: 890,
    vicinity: 'Gangapur Road, Nashik',
    geometry: { location: { lat: 20.0110, lng: 73.7900 } },
    photos: [{ photo_reference: 'mock_photo_ref_4' }],
    types: ['amusement_park', 'point_of_interest'],
    opening_hours: { open_now: true }
  },
  {
    place_id: 'mock5',
    name: 'Someshwar Waterfall (Mock)',
    rating: 4.6,
    user_ratings_total: 2100,
    vicinity: 'Gangapur Road, Nashik',
    geometry: { location: { lat: 20.0200, lng: 73.7700 } },
    photos: [{ photo_reference: 'mock_photo_ref_5' }],
    types: ['park', 'tourist_attraction'],
    opening_hours: { open_now: true }
  }
];

/**
 * Fetch nearby places based on latitude and longitude
 * @param {number} lat Latitude
 * @param {number} lng Longitude
 * @param {number} radius Radius in meters (default 5000)
 * @param {string} type Place type (optional)
 * @returns {Promise<Array>} List of places
 */
async function fetchNearbyPlaces(lat, lng, radius = 5000, type = '') {
  const cacheKey = `places_${lat.toFixed(3)}_${lng.toFixed(3)}_${radius}_${type}`;
  
  // Check cache first
  const cachedData = placesCache.get(cacheKey);
  if (cachedData) {
    console.log('Serving from cache');
    return cachedData;
  }

  // If no API key, return mock data
  if (!GOOGLE_PLACES_API_KEY || GOOGLE_PLACES_API_KEY === 'YOUR_API_KEY_HERE') {
    console.log('No valid API key found, returning mock data');
    if (type && type !== 'all') {
      return MOCK_PLACES.filter(place => place.types.includes(type));
    }
    return MOCK_PLACES;
  }

  try {
    const params = {
      location: `${lat},${lng}`,
      radius: radius,
      key: GOOGLE_PLACES_API_KEY,
    };
    
    if (type && type !== 'all') {
      params.type = type;
    }

    console.log(`Fetching from Google Places API: ${lat}, ${lng}`);
    const response = await axios.get(BASE_URL, { params });
    
    if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
      throw new Error(`API Error: ${response.data.status} - ${response.data.error_message || ''}`);
    }

    const places = response.data.results.map(place => ({
      place_id: place.place_id,
      name: place.name,
      rating: place.rating || 0,
      user_ratings_total: place.user_ratings_total || 0,
      vicinity: place.vicinity,
      geometry: place.geometry,
      photos: place.photos ? place.photos.map(p => 
        `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${p.photo_reference}&key=${GOOGLE_PLACES_API_KEY}`
      ) : [],
      types: place.types,
      opening_hours: place.opening_hours
    }));

    // Sort by rating (descending)
    places.sort((a, b) => b.rating - a.rating);

    // Cache the result
    placesCache.set(cacheKey, places);

    return places;
  } catch (error) {
    console.error('Error fetching places:', error.message);
    throw error;
  }
}

module.exports = {
  fetchNearbyPlaces
};
