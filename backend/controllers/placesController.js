const placesService = require('../services/placesService');

async function getNearbyPlaces(req, res) {
  try {
    const { lat, lng, radius, type } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitude and longitude are required' });
    }

    const places = await placesService.fetchNearbyPlaces(
      parseFloat(lat),
      parseFloat(lng),
      parseInt(radius) || 5000,
      type
    );

    res.json({
      status: 'success',
      count: places.length,
      data: places
    });
  } catch (error) {
    console.error('Controller Error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch places',
      details: error.message
    });
  }
}

module.exports = {
  getNearbyPlaces
};
