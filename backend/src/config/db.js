const mongoose = require('mongoose');

/**
 * MongoDB Database Connection
 * Connects to MongoDB using the connection string from environment variables
 */
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Error connecting to MongoDB: ${error.message}`);
    console.warn('Continuing without MongoDB. Admin panel will run in read-only mode.');
    // Do not exit the process here so the admin panel can still be served
    // If you need DB functionality, ensure MONGO_URI is set and MongoDB is reachable.
  }
};

module.exports = connectDB;



