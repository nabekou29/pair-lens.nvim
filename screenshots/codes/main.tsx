import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom/client';

// User interface matching the Go server structure
interface User {
  id: number;
  name: string;
  email: string;
  age: number;
  role: string;
  created_at: string;
}

// API Response interface
interface ApiResponse<T> {
  message: string;
  data?: T;
}

// User card component
const UserCard: React.FC<{ user: User }> = ({ user }) => {
  return (
    <div className="user-card">
      <h3>{user.name}</h3>
      <p><strong>Email:</strong> {user.email}</p>
      <p><strong>Age:</strong> {user.age}</p>
      <p><strong>Role:</strong> {user.role}</p>
      <p><strong>Created:</strong> {new Date(user.created_at).toLocaleDateString()}</p>
    </div>
  );
};

// Create user form component
const CreateUserForm: React.FC<{ onUserCreated: (user: User) => void }> = ({ onUserCreated }) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    age: '',
    role: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const response = await fetch('/user/create', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...formData,
          age: parseInt(formData.age),
          created_at: new Date().toISOString()
        }),
      });

      if (response.ok) {
        const result: ApiResponse<User> = await response.json();
        if (result.data) {
          onUserCreated(result.data);
          setFormData({ name: '', email: '', age: '', role: '' });
        }
      } else {
        console.error('Failed to create user');
      }
    } catch (error) {
      console.error('Error creating user:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <form onSubmit={handleSubmit} className="create-user-form">
      <h3>Create New User</h3>
      <div className="form-group">
        <label htmlFor="name">Name:</label>
        <input
          type="text"
          id="name"
          name="name"
          value={formData.name}
          onChange={handleChange}
          required
        />
      </div>
      <div className="form-group">
        <label htmlFor="email">Email:</label>
        <input
          type="email"
          id="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          required
        />
      </div>
      <div className="form-group">
        <label htmlFor="age">Age:</label>
        <input
          type="number"
          id="age"
          name="age"
          value={formData.age}
          onChange={handleChange}
          min="1"
          max="120"
          required
        />
      </div>
      <div className="form-group">
        <label htmlFor="role">Role:</label>
        <select
          id="role"
          name="role"
          value={formData.role}
          onChange={handleChange}
          required
        >
          <option value="">Select a role</option>
          <option value="admin">Admin</option>
          <option value="user">User</option>
          <option value="moderator">Moderator</option>
          <option value="guest">Guest</option>
        </select>
      </div>
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Creating...' : 'Create User'}
      </button>
    </form>
  );
};

// Main App component
const App: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch users from API
  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await fetch('/users');
      if (response.ok) {
        const result: ApiResponse<User[]> = await response.json();
        if (result.data) {
          setUsers(result.data);
        }
      } else {
        setError('Failed to fetch users');
      }
    } catch (err) {
      setError('Error fetching users');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // Handle new user creation
  const handleUserCreated = (newUser: User) => {
    setUsers(prevUsers => [...prevUsers, newUser]);
  };

  // Fetch users on component mount
  useEffect(() => {
    fetchUsers();
  }, []);

  if (loading) {
    return <div className="loading">Loading users...</div>;
  }

  if (error) {
    return <div className="error">Error: {error}</div>;
  }

  return (
    <div className="app">
      <header>
        <h1>User Management System</h1>
        <p>React frontend connected to Go backend</p>
      </header>

      <main>
        <section className="create-user-section">
          <CreateUserForm onUserCreated={handleUserCreated} />
        </section>

        <section className="users-section">
          <div className="section-header">
            <h2>Users ({users.length})</h2>
            <button onClick={fetchUsers} className="refresh-btn">
              Refresh
            </button>
          </div>
          
          {users.length === 0 ? (
            <p>No users found</p>
          ) : (
            <div className="users-grid">
              {users.map(user => (
                <UserCard key={user.id} user={user} />
              ))}
            </div>
          )}
        </section>
      </main>

      <style jsx>{`
        .app {
          max-width: 1200px;
          margin: 0 auto;
          padding: 20px;
          font-family: Arial, sans-serif;
        }

        header {
          text-align: center;
          margin-bottom: 40px;
        }

        header h1 {
          color: #333;
          margin-bottom: 10px;
        }

        .create-user-section {
          background: #f5f5f5;
          padding: 20px;
          border-radius: 8px;
          margin-bottom: 30px;
        }

        .create-user-form h3 {
          margin-top: 0;
          color: #333;
        }

        .form-group {
          margin-bottom: 15px;
        }

        .form-group label {
          display: block;
          margin-bottom: 5px;
          font-weight: bold;
        }

        .form-group input,
        .form-group select {
          width: 100%;
          max-width: 300px;
          padding: 8px;
          border: 1px solid #ddd;
          border-radius: 4px;
        }

        button {
          background: #007bff;
          color: white;
          padding: 10px 20px;
          border: none;
          border-radius: 4px;
          cursor: pointer;
        }

        button:hover {
          background: #0056b3;
        }

        button:disabled {
          background: #ccc;
          cursor: not-allowed;
        }

        .section-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 20px;
        }

        .refresh-btn {
          background: #28a745;
        }

        .refresh-btn:hover {
          background: #1e7e34;
        }

        .users-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
          gap: 20px;
        }

        .user-card {
          background: white;
          border: 1px solid #ddd;
          border-radius: 8px;
          padding: 20px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .user-card h3 {
          margin-top: 0;
          color: #333;
        }

        .user-card p {
          margin: 5px 0;
          color: #666;
        }

        .loading,
        .error {
          text-align: center;
          padding: 40px;
          font-size: 18px;
        }

        .error {
          color: #dc3545;
        }
      `}</style>
    </div>
  );
};

// Render the app
const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
root.render(<App />);