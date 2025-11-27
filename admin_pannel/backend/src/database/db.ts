import sqlite3 from 'sqlite3';
import path from 'path';

// Resolve database path relative to project root
const DB_PATH = path.resolve(
  __dirname,
  '../../../../tourguard-backend Final/database.sqlite'
);

class Database {
  private db: sqlite3.Database;

  constructor() {
    this.db = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        console.error('❌ Error connecting to SQLite database:', err);
        throw err;
      }
      console.log('✅ Connected to SQLite database:', DB_PATH);
    });
  }

  // Promisify database methods
  private run(sql: string, params?: any[]): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params || [], function(err) {
        if (err) reject(err);
        else resolve({ lastID: this.lastID, changes: this.changes });
      });
    });
  }

  private get(sql: string, params?: any[]): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params || [], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });
  }

  private all(sql: string, params?: any[]): Promise<any[]> {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params || [], (err, rows) => {
        if (err) reject(err);
        else resolve(rows || []);
      });
    });
  }

  // Get all users
  async getAllUsers(): Promise<any[]> {
    try {
      const users = await this.all('SELECT * FROM users ORDER BY createdAt DESC');
      return users || [];
    } catch (error) {
      console.error('Error fetching users:', error);
      throw error;
    }
  }

  // Get user by ID
  async getUserById(id: string): Promise<any | null> {
    try {
      const user = await this.get('SELECT * FROM users WHERE id = ?', [id]);
      return user || null;
    } catch (error) {
      console.error('Error fetching user:', error);
      throw error;
    }
  }

  // Get user by email
  async getUserByEmail(email: string): Promise<any | null> {
    try {
      const user = await this.get('SELECT * FROM users WHERE email = ?', [email]);
      return user || null;
    } catch (error) {
      console.error('Error fetching user by email:', error);
      throw error;
    }
  }

  // Get all incidents
  async getAllIncidents(): Promise<any[]> {
    try {
      const incidents = await this.all('SELECT * FROM incidents ORDER BY createdAt DESC');
      return incidents || [];
    } catch (error) {
      console.error('Error fetching incidents:', error);
      throw error;
    }
  }

  // Get incident by ID
  async getIncidentById(id: string): Promise<any | null> {
    try {
      const incident = await this.get('SELECT * FROM incidents WHERE id = ?', [id]);
      return incident || null;
    } catch (error) {
      console.error('Error fetching incident:', error);
      throw error;
    }
  }

  // Get SOS incidents (incidents with title = 'SOS Alert')
  async getSOSIncidents(): Promise<any[]> {
    try {
      const incidents = await this.all(
        "SELECT * FROM incidents WHERE title = 'SOS Alert' ORDER BY createdAt DESC"
      );
      return incidents || [];
    } catch (error) {
      console.error('Error fetching SOS incidents:', error);
      throw error;
    }
  }

  // Update incident status (for SOS events)
  // Store status in description as JSON
  async updateIncidentStatus(id: string, status: string): Promise<boolean> {
    try {
      const incident = await this.getIncidentById(id);
      if (!incident) return false;

      // Parse existing description or create new object
      let descObj: any = {};
      try {
        if (typeof incident.description === 'string') {
          descObj = JSON.parse(incident.description);
        } else if (incident.description) {
          descObj = incident.description;
        }
      } catch {
        // If description is plain text, preserve it
        descObj = { originalMessage: incident.description, status };
      }

      // Update status
      descObj.status = status;
      if (status === 'acknowledged') {
        descObj.acknowledgedAt = new Date().toISOString();
      }
      if (status === 'resolved') {
        descObj.resolvedAt = new Date().toISOString();
      }

      // Update description with new JSON
      await this.run('UPDATE incidents SET description = ? WHERE id = ?', [
        JSON.stringify(descObj),
        id,
      ]);
      return true;
    } catch (error) {
      console.error('Error updating incident status:', error);
      return false;
    }
  }

  // Close database connection
  close(): void {
    this.db.close((err) => {
      if (err) {
        console.error('Error closing database:', err);
      } else {
        console.log('Database connection closed');
      }
    });
  }
}

export default new Database();

