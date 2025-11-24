const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const Alert = require('../models/Alert');
const jwt = require('jsonwebtoken');
const { successResponse, errorResponse, validationError } = require('../utils/response');

/**
 * Generate JWT Token
 */
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: '30d', // Token expires in 30 days
  });
};

/**
 * @route   POST /api/user/register
 * @desc    Register a new user
 * @access  Public
 */
exports.register = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    // Validation
    if (!name || !email || !phone || !password) {
      return validationError(res, {
        message: 'Please provide all required fields: name, email, phone, password',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { phone }],
    });

    if (existingUser) {
      return errorResponse(
        res,
        400,
        'User already exists with this email or phone number'
      );
    }

    // Create new user
    const user = new User({
      name,
      email,
      phone,
      password,
    });

    await user.save();

    // Add activity log
    await ActivityLog.create({
      userId: user._id,
      action: 'opened_app',
    });

    // Generate token
    const token = generateToken(user._id);

    // Return user data (without password)
    const userData = {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      token,
    };

    return successResponse(res, 201, 'User registered successfully', userData);
  } catch (error) {
    console.error('Register error:', error);
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map((err) => err.message);
      return validationError(res, errors);
    }
    return errorResponse(res, 500, 'Server error during registration', error.message);
  }
};

/**
 * @route   POST /api/user/login
 * @desc    Login user
 * @access  Public
 */
exports.login = async (req, res) => {
  try {
    const { email, phone, password } = req.body;

    // Validation - require either email or phone
    if (!password || (!email && !phone)) {
      return validationError(res, {
        message: 'Please provide email or phone and password',
      });
    }

    // Find user by email or phone
    const user = await User.findOne({
      $or: email ? [{ email }] : [{ phone }],
    }).select('+password'); // Include password for comparison

    if (!user) {
      return errorResponse(res, 401, 'Invalid credentials');
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);

    if (!isPasswordValid) {
      return errorResponse(res, 401, 'Invalid credentials');
    }

    // Add activity log
    await ActivityLog.create({
      userId: user._id,
      action: 'login',
    });

    // Generate token
    const token = generateToken(user._id);

    // Return user data (without password)
    const userData = {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      token,
    };

    return successResponse(res, 200, 'Login successful', userData);
  } catch (error) {
    console.error('Login error:', error);
    return errorResponse(res, 500, 'Server error during login', error.message);
  }
};

/**
 * @route   POST /api/user/update-location
 * @desc    Update user's last known location
 * @access  Private
 */
exports.updateLocation = async (req, res) => {
  try {
    const { lat, lng } = req.body;
    const userId = req.userId;

    // Validation
    if (lat === undefined || lng === undefined) {
      return validationError(res, {
        message: 'Latitude and longitude are required',
      });
    }

    if (typeof lat !== 'number' || typeof lng !== 'number') {
      return validationError(res, {
        message: 'Latitude and longitude must be numbers',
      });
    }

    // Update user location
    const user = await User.findByIdAndUpdate(
      userId,
      {
        lastLocation: {
          lat,
          lng,
          timestamp: new Date(),
        },
      },
      { new: true }
    );

    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    // Create activity log
    await ActivityLog.create({
      userId,
      action: 'location_update',
      metadata: { lat, lng },
    });

    // Emit location update via Socket.IO to admin clients
    if (req.io) {
      const userData = await User.findById(userId).select('name email phone');
      req.io.to('admin').emit('live-location', {
        userId: userId.toString(),
        name: userData.name,
        email: userData.email,
        phone: userData.phone,
        location: user.lastLocation,
      });
    }

    return successResponse(res, 200, 'Location updated successfully', {
      location: user.lastLocation,
    });
  } catch (error) {
    console.error('Update location error:', error);
    return errorResponse(res, 500, 'Server error updating location', error.message);
  }
};

/**
 * @route   POST /api/user/activity
 * @desc    Log user activity
 * @access  Private
 */
exports.logActivity = async (req, res) => {
  try {
    const { action, metadata } = req.body;
    const userId = req.userId;

    // Validation
    if (!action) {
      return validationError(res, {
        message: 'Action is required',
      });
    }

    // Create activity log
    const activityLog = await ActivityLog.create({
      userId,
      action,
      metadata: metadata || {},
    });

    // Also add to user's activityLogs array
    await User.findByIdAndUpdate(userId, {
      $push: {
        activityLogs: {
          action,
          timestamp: new Date(),
        },
      },
    });

    return successResponse(res, 201, 'Activity logged successfully', {
      activityLog,
    });
  } catch (error) {
    console.error('Log activity error:', error);
    return errorResponse(res, 500, 'Server error logging activity', error.message);
  }
};

/**
 * @route   POST /api/user/alert
 * @desc    Create an alert (panic, SOS, danger zone entry)
 * @access  Private
 */
exports.createAlert = async (req, res) => {
  try {
    const { alertType, lat, lng, message } = req.body;
    const userId = req.userId;

    // Validation
    if (!alertType || !lat || !lng) {
      return validationError(res, {
        message: 'Alert type, latitude, and longitude are required',
      });
    }

    if (!['panic', 'sos', 'danger_zone_entry'].includes(alertType)) {
      return validationError(res, {
        message: 'Invalid alert type. Must be: panic, sos, or danger_zone_entry',
      });
    }

    // Create alert
    const alert = await Alert.create({
      userId,
      location: { lat, lng },
      alertType,
      message: message || '',
    });

    // Create activity log
    await ActivityLog.create({
      userId,
      action: alertType === 'panic' ? 'panic_button' : 'sos_alert',
      metadata: { alertId: alert._id, alertType },
    });

    // Emit alert via Socket.IO to admin clients
    if (req.io) {
      const userData = await User.findById(userId).select('name email phone');
      req.io.to('admin').emit('new-alert', {
        alert: {
          _id: alert._id,
          userId: userId.toString(),
          user: {
            name: userData.name,
            email: userData.email,
            phone: userData.phone,
          },
          location: alert.location,
          alertType: alert.alertType,
          message: alert.message,
          status: alert.status,
          timestamp: alert.timestamp,
        },
      });
    }

    return successResponse(res, 201, 'Alert created successfully', {
      alert,
    });
  } catch (error) {
    console.error('Create alert error:', error);
    return errorResponse(res, 500, 'Server error creating alert', error.message);
  }
};

