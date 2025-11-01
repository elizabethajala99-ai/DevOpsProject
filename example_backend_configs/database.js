// config/database.js - Updated Database Configuration for SSM Integration

const mysql = require('mysql2/promise');

/**
 * Database configuration using environment variables
 * These are populated by ECS from SSM Parameter Store and Secrets Manager
 */
const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT) || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Connection timeout settings
  acquireTimeout: 60000,
  timeout: 60000,
  // SSL configuration for production
  ssl: process.env.NODE_ENV === 'production' ? {
    rejectUnauthorized: false
  } : false
};

// Validate required environment variables
const requiredEnvVars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'];
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingVars.length > 0) {
  console.error('❌ Missing required environment variables:', missingVars);
  console.error('💡 Ensure ECS task definition includes secrets from SSM/Secrets Manager');
  process.exit(1);
}

// Log configuration (without sensitive data)
console.log('✅ Database configuration loaded from environment variables');
console.log(`📍 DB_HOST: ${process.env.DB_HOST}`);
console.log(`👤 DB_USER: ${process.env.DB_USER}`);
console.log(`🗄️  DB_NAME: ${process.env.DB_NAME}`);
console.log(`🔌 DB_PORT: ${process.env.DB_PORT || 3306}`);
console.log(`🌍 APP_ENV: ${process.env.APP_ENV || 'unknown'}`);
// Note: Never log passwords or JWT secrets

// Create connection pool
const pool = mysql.createPool(dbConfig);

// Test database connection
const testConnection = async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Database connection successful');
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
};

// Initialize connection test on module load
testConnection();

module.exports = {
  pool,
  testConnection
};

/* 
Migration Notes:
================

OLD (hardcoded in environment variables):
  environment = [
    { name = "DB_HOST", value = var.db_host },
    { name = "DB_USER", value = var.db_user },
    { name = "DB_PASSWORD", value = var.db_password },
    { name = "DB_NAME", value = var.db_name }
  ]

NEW (from SSM/Secrets Manager):
  secrets = [
    { name = "DB_HOST", valueFrom = aws_ssm_parameter.database_host.arn },
    { name = "DB_USER", valueFrom = aws_ssm_parameter.database_username.arn },
    { name = "DB_PASSWORD", valueFrom = aws_secretsmanager_secret.database_password.arn },
    { name = "DB_NAME", valueFrom = aws_ssm_parameter.database_name.arn }
  ]

Benefits:
- Secrets are encrypted at rest
- No sensitive data in Terraform files
- Automatic secret rotation support
- Audit trail via CloudTrail
- Fine-grained access control
*/