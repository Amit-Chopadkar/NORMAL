import express, { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import db from '../database/db';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'admin-secret-key-change-in-production';

// Admin login
router.post('/api/auth/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required',
      });
    }

    // For demo: hardcoded admin credentials
    // In production, store admin users in database
    const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@tourguard.com';
    const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123';

    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
      const token = jwt.sign(
        {
          id: 'admin-1',
          email: ADMIN_EMAIL,
          role: 'admin',
        },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      return res.json({
        success: true,
        data: {
          token,
          user: {
            id: 'admin-1',
            name: 'Admin User',
            email: ADMIN_EMAIL,
            role: 'admin',
          },
        },
      });
    }

    // Check if user exists in database
    const user = await db.getUserByEmail(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials',
      });
    }

    // For now, allow any user to login as admin (for demo)
    // In production, check user.role === 'admin'
    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role || 'admin',
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          name: user.name || user.email,
          email: user.email,
          role: user.role || 'admin',
        },
      },
    });
  } catch (error: any) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

export default router;


