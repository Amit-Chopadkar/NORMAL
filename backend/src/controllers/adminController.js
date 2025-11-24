const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const Alert = require('../models/Alert');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * @route   GET /api/admin/users
 * @desc    Get all users
 * @access  Private (Admin)
 */
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find()
      .select('-password')
      .sort({ createdAt: -1 });

    return successResponse(res, 200, 'Users retrieved successfully', {
      users,
      count: users.length,
    });
  } catch (error) {
    console.error('Get all users error:', error);
    return errorResponse(res, 500, 'Server error retrieving users', error.message);
  }
};

/**
 * @route   GET /api/admin/user/:id
 * @desc    Get user by ID
 * @access  Private (Admin)
 */
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id).select('-password');

    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    return successResponse(res, 200, 'User retrieved successfully', { user });
  } catch (error) {
    console.error('Get user by ID error:', error);
    if (error.name === 'CastError') {
      return errorResponse(res, 400, 'Invalid user ID');
    }
    return errorResponse(res, 500, 'Server error retrieving user', error.message);
  }
};

/**
 * @route   GET /api/admin/user/:id/activity
 * @desc    Get user activity history
 * @access  Private (Admin)
 */
exports.getUserActivity = async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 100, page = 1 } = req.query;

    // Validate user exists
    const user = await User.findById(id);
    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get activity logs
    const activityLogs = await ActivityLog.find({ userId: id })
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip(skip);

    // Get total count
    const totalCount = await ActivityLog.countDocuments({ userId: id });

    return successResponse(res, 200, 'User activity retrieved successfully', {
      activityLogs,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('Get user activity error:', error);
    if (error.name === 'CastError') {
      return errorResponse(res, 400, 'Invalid user ID');
    }
    return errorResponse(res, 500, 'Server error retrieving user activity', error.message);
  }
};

/**
 * @route   GET /api/admin/live-locations
 * @desc    Get all users' live locations
 * @access  Private (Admin)
 */
exports.getLiveLocations = async (req, res) => {
  try {
    const users = await User.find({
      'lastLocation.lat': { $ne: null },
      'lastLocation.lng': { $ne: null },
    })
      .select('name email phone lastLocation')
      .sort({ 'lastLocation.timestamp': -1 });

    const locations = users.map((user) => ({
      userId: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      location: user.lastLocation,
    }));

    return successResponse(res, 200, 'Live locations retrieved successfully', {
      locations,
      count: locations.length,
    });
  } catch (error) {
    console.error('Get live locations error:', error);
    return errorResponse(res, 500, 'Server error retrieving live locations', error.message);
  }
};



