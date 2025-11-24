require('dotenv').config();
const connectDB = require('../config/db');
const User = require('../models/User');

const getArg = (name) => {
  const prefix = `${name}=`;
  for (let i = 2; i < process.argv.length; i++) {
    if (process.argv[i].startsWith(prefix)) return process.argv[i].substring(prefix.length);
  }
  return null;
};

(async () => {
  try {
    const email = process.env.ADMIN_EMAIL || getArg('--email') || getArg('-e') || process.argv[2];
    const password = process.env.ADMIN_PASSWORD || getArg('--password') || getArg('-p') || process.argv[3];
    const name = process.env.ADMIN_NAME || getArg('--name') || 'Admin';
    const phone = process.env.ADMIN_PHONE || getArg('--phone') || '0000000000';

    if (!email || !password) {
      console.error('Usage: Set ADMIN_EMAIL and ADMIN_PASSWORD in .env or pass --email=... --password=...');
      process.exit(2);
    }

    await connectDB();

    let user = await User.findOne({ email: email.toLowerCase() }).select('+password');

    if (user) {
      user.password = password; // pre-save hook will hash
      user.role = 'admin';
      // ensure required fields exist
      user.name = user.name || name;
      user.phone = user.phone || phone;

      await user.save();
      console.log(`Updated existing user ${email} to admin.`);
    } else {
      user = new User({
        name,
        email: email.toLowerCase(),
        phone,
        password,
        role: 'admin',
      });
      await user.save();
      console.log(`Created new admin user ${email}.`);
    }

    console.log('Done. You can now login via /api/user/login with the admin credentials.');
    process.exit(0);
  } catch (error) {
    console.error('Failed to create/update admin user:', error);
    process.exit(1);
  }
})();
