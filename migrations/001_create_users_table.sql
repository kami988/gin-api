-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Insert sample data (optional, for testing)
-- INSERT INTO users (name, email) VALUES
--     ('Alice Smith', 'alice@example.com'),
--     ('Bob Johnson', 'bob@example.com'),
--     ('Charlie Brown', 'charlie@example.com');
