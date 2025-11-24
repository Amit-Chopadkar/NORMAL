const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate } = require('../middleware/auth');

/**
 * User Routes
 * All routes are prefixed with /api/user
 */

// Public routes
router.post('/register', userController.register);
router.post('/login', userController.login);

// Protected routes (require authentication)
router.post('/update-location', authenticate, userController.updateLocation);
router.post('/activity', authenticate, userController.logActivity);
router.post('/alert', authenticate, userController.createAlert);

module.exports = router;



