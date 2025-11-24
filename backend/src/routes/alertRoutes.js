const express = require('express');
const router = express.Router();
const alertController = require('../controllers/alertController');
const { authenticateAdmin } = require('../middleware/auth');

/**
 * Alert Routes
 * All routes are prefixed with /api/admin
 * All routes require admin authentication
 */

router.get('/alerts', authenticateAdmin, alertController.getAllAlerts);
router.patch('/alert/:id/status', authenticateAdmin, alertController.updateAlertStatus);

module.exports = router;



