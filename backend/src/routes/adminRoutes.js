const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateAdmin } = require('../middleware/auth');

/**
 * Admin Routes
 * All routes are prefixed with /api/admin
 * All routes require admin authentication
 */

router.get('/users', authenticateAdmin, adminController.getAllUsers);
router.get('/user/:id', authenticateAdmin, adminController.getUserById);
router.get('/user/:id/activity', authenticateAdmin, adminController.getUserActivity);
router.get('/live-locations', authenticateAdmin, adminController.getLiveLocations);

module.exports = router;



