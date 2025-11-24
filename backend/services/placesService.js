const axios = require('axios');
const NodeCache = require('node-cache');

// Cache for 1 hour (3600 seconds)
const placesCache = new NodeCache({ stdTTL: 3600 });

const GOOGLE_PLACES_API_KEY =
  process.env.GOOGLE_PLACES_API_KEY || 'AIzaSyDtbyiNsjhAWH-7NJPT0xu_FJKRIi9YPzU';
const BASE_URL = 'https://places.googleapis.com/v1/places:searchNearby';

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
 * Fetch nearby places based on latitude and longitude using Google Places API (New)
 * @param {number} lat Latitude
 * @param {number} lng Longitude
 * @param {number} radius Radius in meters (default 50000 - 50 km)
 * @param {string} type Place type (optional)
 * @returns {Promise<Array>} List of places
 */
async function fetchNearbyPlaces(lat, lng, radius = 50000, type = '') {
  const cacheKey = `places_v2_${lat.toFixed(3)}_${lng.toFixed(3)}_${radius}_${type}`;
  
  // Check cache first
  const cachedData = placesCache.get(cacheKey);
  if (cachedData) {
    console.log('Serving from cache');
    return cachedData;
  }

  // If no API key, return mock data
  if (!GOOGLE_PLACES_API_KEY || GOOGLE_PLACES_API_KEY === 'AIzaSyDtbyiNsjhAWH-7NJPT0xu_FJKRIi9YPzU') {
    console.log('No valid API key found, returning mock data');
    if (type && type !== 'all') {
      return MOCK_PLACES.filter(place => place.types.includes(type));
    }
    return MOCK_PLACES;
  }

  try {
    console.log(`Fetching from Google Places API (New): ${lat}, ${lng}`);

    // Construct Request Body
    const requestBody = {
      locationRestriction: {
        circle: {
          center: {
            latitude: lat,
            longitude: lng
          },
          radius: radius
        }
      }
    };

    // Add type filtering if provided
    if (type && type !== 'all') {
      // Map common legacy types to new API types if necessary, or pass directly
      // The new API uses specific type strings (e.g., "restaurant", "tourist_attraction")
      requestBody.includedTypes = [type];
    }

    // Make POST request
    const response = await axios.post(BASE_URL, requestBody, {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_PLACES_API_KEY,
        // Request specific fields to optimize response and cost
        'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.photos,places.types,places.regularOpeningHours'
      }
    });

    // Check if places are returned
    if (!response.data.places) {
      console.log('No places found');
      return [];
    }

    // Map response to match the existing frontend structure
    const places = response.data.places.map(place => ({
      place_id: place.id,
      name: place.displayName ? place.displayName.text : 'Unknown',
      rating: place.rating || 0,
      user_ratings_total: place.userRatingCount || 0,
      vicinity: place.formattedAddress || '', // New API uses formattedAddress
      geometry: {
        location: {
          lat: place.location.latitude,
          lng: place.location.longitude
        }
      },
      // Construct photo URLs for the new API
      photos: place.photos ? place.photos.map(photo => 
        `https://places.googleapis.com/v1/${photo.name}/media?maxHeightPx=400&maxWidthPx=400&key=${GOOGLE_PLACES_API_KEY}`
      ) : [],
      types: place.types || [],
      opening_hours: {
        open_now: place.regularOpeningHours ? place.regularOpeningHours.openNow : null
      }
    }));

    // Sort by rating (descending)
    places.sort((a, b) => b.rating - a.rating);

    // Cache the result
    placesCache.set(cacheKey, places);

    return places;
  } catch (error) {
    // Enhanced error logging
    if (error.response) {
      console.error('API Error Data:', JSON.stringify(error.response.data, null, 2));
      console.error('API Error Status:', error.response.status);
    } else {
      console.error('Error fetching places:', error.message);
    }
    throw error;
  }
}

module.exports = {
  fetchNearbyPlaces
};
