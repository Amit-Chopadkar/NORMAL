/**
 * Standardized API Response Utility
 * Provides consistent response format across all endpoints
 */

/**
 * Success response
 */
const successResponse = (res, statusCode = 200, message = 'Success', data = null) => {
  const response = {
    success: true,
    message,
  };

  if (data !== null) {
    response.data = data;
  }

  return res.status(statusCode).json(response);
};

/**
 * Error response
 */
const errorResponse = (res, statusCode = 400, message = 'Error', errors = null) => {
  const response = {
    success: false,
    message,
  };

  if (errors) {
    response.errors = errors;
  }

  return res.status(statusCode).json(response);
};

/**
 * Validation error response
 */
const validationError = (res, errors) => {
  return errorResponse(res, 400, 'Validation failed', errors);
};

module.exports = {
  successResponse,
  errorResponse,
  validationError,
};



