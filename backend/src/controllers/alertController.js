const Alert = require('../models/Alert');
const User = require('../models/User');
const { successResponse, errorResponse } = require('../utils/response');

/**
 * @route   GET /api/admin/alerts
 * @desc    Get all alerts
 * @access  Private (Admin)
 */
exports.getAllAlerts = async (req, res) => {
  try {
    const { status, alertType, limit = 100, page = 1 } = req.query;

    // Build query
    const query = {};
    if (status) {
      query.status = status;
    }
    if (alertType) {
      query.alertType = alertType;
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get alerts with user information
    const alerts = await Alert.find(query)
      .populate('userId', 'name email phone')
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .skip(skip);

    // Get total count
    const totalCount = await Alert.countDocuments(query);

    return successResponse(res, 200, 'Alerts retrieved successfully', {
      alerts,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('Get all alerts error:', error);
    return errorResponse(res, 500, 'Server error retrieving alerts', error.message);
  }
};

/**
 * @route   PATCH /api/admin/alert/:id/status
 * @desc    Update alert status
 * @access  Private (Admin)
 */
exports.updateAlertStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['pending', 'viewed', 'resolved'].includes(status)) {
      return errorResponse(res, 400, 'Valid status is required (pending, viewed, resolved)');
    }

    const alert = await Alert.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    ).populate('userId', 'name email phone');

    if (!alert) {
      return errorResponse(res, 404, 'Alert not found');
    }

    return successResponse(res, 200, 'Alert status updated successfully', { alert });
  } catch (error) {
    console.error('Update alert status error:', error);
    if (error.name === 'CastError') {
      return errorResponse(res, 400, 'Invalid alert ID');
    }
    return errorResponse(res, 500, 'Server error updating alert status', error.message);
  }
};



