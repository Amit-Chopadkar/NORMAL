const mongoose = require('mongoose');

/**
 * ActivityLog Schema
 * Stores detailed activity logs for users
 */
const activityLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },
    action: {
      type: String,
      required: [true, 'Action is required'],
      enum: [
        'location_update',
        'panic_button',
        'opened_app',
        'closed_app',
        'sos_alert',
        'danger_zone_entry',
        'login',
        'logout',
      ],
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
activityLogSchema.index({ userId: 1, timestamp: -1 });

module.exports = mongoose.model('ActivityLog', activityLogSchema);



