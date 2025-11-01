// config/auth.js - Updated JWT Configuration for SSM Integration

const jwt = require('jsonwebtoken');

/**
 * JWT configuration using environment variables
 * JWT_SECRET is populated from AWS Secrets Manager
 */
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

// Validate JWT secret
if (!JWT_SECRET) {
  console.error('❌ JWT_SECRET environment variable is required');
  console.error('💡 Ensure ECS task definition includes JWT secret from Secrets Manager');
  process.exit(1);
}

// Validate JWT secret strength
if (JWT_SECRET.length < 32) {
  console.warn('⚠️  JWT_SECRET should be at least 32 characters long for security');
}

console.log('✅ JWT configuration loaded from environment variables');
console.log(`⏰ JWT_EXPIRES_IN: ${JWT_EXPIRES_IN}`);
console.log(`🔐 JWT_SECRET: [HIDDEN - ${JWT_SECRET.length} characters]`);

/**
 * Generate JWT token
 * @param {Object} payload - Token payload
 * @param {string} expiresIn - Token expiration (optional)
 * @returns {string} JWT token
 */
const generateToken = (payload, expiresIn = JWT_EXPIRES_IN) => {
  try {
    return jwt.sign(payload, JWT_SECRET, { 
      expiresIn,
      issuer: 'myapp-backend',
      audience: 'myapp-frontend'
    });
  } catch (error) {
    console.error('❌ Error generating JWT token:', error.message);
    throw error;
  }
};

/**
 * Verify JWT token
 * @param {string} token - JWT token to verify
 * @returns {Object} Decoded token payload
 */
const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET, {
      issuer: 'myapp-backend',
      audience: 'myapp-frontend'
    });
  } catch (error) {
    console.error('❌ Error verifying JWT token:', error.message);
    throw error;
  }
};

/**
 * Middleware to verify JWT token in requests
 */
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ 
      error: 'Access token required',
      message: 'Please provide a valid JWT token'
    });
  }

  try {
    const decoded = verifyToken(token);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ 
      error: 'Invalid token',
      message: 'Token verification failed'
    });
  }
};

module.exports = {
  generateToken,
  verifyToken,
  authenticateToken
};

/* 
Migration Notes:
================

OLD (hardcoded or from .env file):
  const JWT_SECRET = 'hardcoded-secret-key';
  // or
  require('dotenv').config();
  const JWT_SECRET = process.env.JWT_SECRET;

NEW (from AWS Secrets Manager):
  # In ECS task definition:
  secrets = [
    {
      name      = "JWT_SECRET"
      valueFrom = aws_secretsmanager_secret.jwt_secret.arn
    }
  ]

Benefits:
- JWT secret is encrypted at rest in Secrets Manager
- Secret can be rotated without code changes
- No secret in environment files or Terraform
- Access logged via CloudTrail
- Fine-grained IAM permissions

Security Best Practices:
- Use strong, randomly generated secrets (32+ characters)
- Rotate secrets regularly
- Monitor secret access
- Use short token expiration times
- Implement refresh token mechanism for better UX
*/