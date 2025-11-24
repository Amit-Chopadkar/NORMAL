const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { errorResponse } = require('../utils/response');

/**
 * JWT Authentication Middleware
 * Verifies JWT token and attaches user to request object
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 401, 'No token provided. Access denied.');
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    if (!token) {
      return errorResponse(res, 401, 'No token provided. Access denied.');
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Get user from database
    const user = await User.findById(decoded.userId).select('-password');

    if (!user) {
      return errorResponse(res, 401, 'Invalid token. User not found.');
    }

    // Attach user to request
    req.user = user;
    req.userId = decoded.userId;

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return errorResponse(res, 401, 'Invalid token.');
    }
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 401, 'Token expired.');
    }
    return errorResponse(res, 500, 'Authentication error.', error.message);
  }
};

/**
 * Admin authentication middleware (if needed in future)
 * For now, all authenticated users can access admin endpoints
 * You can extend this to check for admin role
 */
const authenticateAdmin = async (req, res, next) => {
  // First authenticate as regular user
  await authenticate(req, res, () => {
    // Ensure authenticated user has admin role
    if (!req.user || req.user.role !== 'admin') {
      return errorResponse(res, 403, 'Admin access required.');
    }
    next();
  });
};

module.exports = {
  authenticate,
  authenticateAdmin,
};



