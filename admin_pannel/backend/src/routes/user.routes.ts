import express, { Request, Response } from 'express';
import db from '../database/db';

const router = express.Router();

// Get user by ID
router.get('/api/users/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const user = await db.getUserById(id);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    // Format user data to match frontend expectations
    const formattedUser = {
      id: user.id,
      name: user.name || 'Unknown',
      phone: user.phone || '',
      email: user.email,
      role: user.role || 'user',
      createdAt: user.createdAt || user.created_at,
      updatedAt: user.updatedAt || user.updated_at,
    };

    res.json({
      success: true,
      data: formattedUser,
    });
  } catch (error: any) {
    console.error('Error fetching user:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

// Get all users
router.get('/api/users', async (req: Request, res: Response) => {
  try {
    const users = await db.getAllUsers();

    const formattedUsers = users.map((user) => ({
      id: user.id,
      name: user.name || 'Unknown',
      phone: user.phone || '',
      email: user.email,
      role: user.role || 'user',
      createdAt: user.createdAt || user.created_at,
      updatedAt: user.updatedAt || user.updated_at,
    }));

    res.json({
      success: true,
      data: formattedUsers,
    });
  } catch (error: any) {
    console.error('Error fetching users:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

export default router;


