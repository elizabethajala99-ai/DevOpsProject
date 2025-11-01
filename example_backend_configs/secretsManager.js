// Optional: utils/secretsManager.js - Runtime Secret Fetching

const AWS = require('aws-sdk');

// Initialize AWS SDK clients
const secretsManager = new AWS.SecretsManager({
  region: process.env.AWS_REGION || 'eu-west-2'
});

const ssm = new AWS.SSM({
  region: process.env.AWS_REGION || 'eu-west-2'
});

/**
 * Get secret value from AWS Secrets Manager
 * @param {string} secretName - Name or ARN of the secret
 * @returns {Promise<string>} Secret value
 */
const getSecret = async (secretName) => {
  try {
    console.log(`🔍 Fetching secret: ${secretName}`);
    
    const data = await secretsManager.getSecretValue({ 
      SecretId: secretName 
    }).promise();
    
    if ('SecretString' in data) {
      console.log(`✅ Secret retrieved: ${secretName}`);
      return data.SecretString;
    } else {
      // Handle binary secret
      const buff = Buffer.from(data.SecretBinary, 'base64');
      return buff.toString('ascii');
    }
  } catch (error) {
    console.error(`❌ Error retrieving secret ${secretName}:`, error.message);
    throw new Error(`Failed to retrieve secret: ${secretName}`);
  }
};

/**
 * Get parameter value from SSM Parameter Store
 * @param {string} parameterName - Name of the parameter
 * @param {boolean} decrypt - Whether to decrypt SecureString parameters
 * @returns {Promise<string>} Parameter value
 */
const getParameter = async (parameterName, decrypt = true) => {
  try {
    console.log(`🔍 Fetching parameter: ${parameterName}`);
    
    const data = await ssm.getParameter({
      Name: parameterName,
      WithDecryption: decrypt
    }).promise();
    
    console.log(`✅ Parameter retrieved: ${parameterName}`);
    return data.Parameter.Value;
  } catch (error) {
    console.error(`❌ Error retrieving parameter ${parameterName}:`, error.message);
    throw new Error(`Failed to retrieve parameter: ${parameterName}`);
  }
};

/**
 * Get multiple parameters by path
 * @param {string} path - Parameter path prefix
 * @param {boolean} decrypt - Whether to decrypt SecureString parameters
 * @returns {Promise<Object>} Object with parameter names as keys
 */
const getParametersByPath = async (path, decrypt = true) => {
  try {
    console.log(`🔍 Fetching parameters by path: ${path}`);
    
    const data = await ssm.getParametersByPath({
      Path: path,
      WithDecryption: decrypt,
      Recursive: true
    }).promise();
    
    const parameters = {};
    data.Parameters.forEach(param => {
      // Remove path prefix from parameter name for easier access
      const key = param.Name.replace(path, '').replace(/^\//, '');
      parameters[key] = param.Value;
    });
    
    console.log(`✅ Retrieved ${data.Parameters.length} parameters from path: ${path}`);
    return parameters;
  } catch (error) {
    console.error(`❌ Error retrieving parameters by path ${path}:`, error.message);
    throw new Error(`Failed to retrieve parameters by path: ${path}`);
  }
};

/**
 * Cache for secrets and parameters to avoid excessive API calls
 */
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

/**
 * Get secret with caching
 * @param {string} secretName - Name or ARN of the secret
 * @returns {Promise<string>} Secret value
 */
const getCachedSecret = async (secretName) => {
  const cacheKey = `secret:${secretName}`;
  const cached = cache.get(cacheKey);
  
  if (cached && (Date.now() - cached.timestamp) < CACHE_TTL) {
    console.log(`💾 Using cached secret: ${secretName}`);
    return cached.value;
  }
  
  const value = await getSecret(secretName);
  cache.set(cacheKey, { value, timestamp: Date.now() });
  return value;
};

/**
 * Get parameter with caching
 * @param {string} parameterName - Name of the parameter
 * @param {boolean} decrypt - Whether to decrypt SecureString parameters
 * @returns {Promise<string>} Parameter value
 */
const getCachedParameter = async (parameterName, decrypt = true) => {
  const cacheKey = `parameter:${parameterName}`;
  const cached = cache.get(cacheKey);
  
  if (cached && (Date.now() - cached.timestamp) < CACHE_TTL) {
    console.log(`💾 Using cached parameter: ${parameterName}`);
    return cached.value;
  }
  
  const value = await getParameter(parameterName, decrypt);
  cache.set(cacheKey, { value, timestamp: Date.now() });
  return value;
};

/**
 * Clear the cache (useful for testing or forced refresh)
 */
const clearCache = () => {
  cache.clear();
  console.log('🗑️  Cache cleared');
};

/**
 * Initialize configuration from SSM/Secrets Manager
 * This is useful for applications that need to fetch secrets at startup
 */
const initializeConfig = async () => {
  try {
    console.log('🚀 Initializing configuration from AWS...');
    
    // Fetch all application parameters
    const parameters = await getParametersByPath('/myapp');
    
    // Fetch critical secrets
    const dbPassword = await getSecret('/myapp/database/master-password');
    const jwtSecret = await getSecret('/myapp/jwt/secret');
    
    // Set environment variables if not already set
    if (!process.env.DB_HOST && parameters['database/host']) {
      process.env.DB_HOST = parameters['database/host'];
    }
    if (!process.env.DB_USER && parameters['database/username']) {
      process.env.DB_USER = parameters['database/username'];
    }
    if (!process.env.DB_NAME && parameters['database/name']) {
      process.env.DB_NAME = parameters['database/name'];
    }
    if (!process.env.DB_PASSWORD) {
      process.env.DB_PASSWORD = dbPassword;
    }
    if (!process.env.JWT_SECRET) {
      process.env.JWT_SECRET = jwtSecret;
    }
    
    console.log('✅ Configuration initialization complete');
    return { parameters, secrets: { dbPassword, jwtSecret } };
  } catch (error) {
    console.error('❌ Failed to initialize configuration:', error.message);
    throw error;
  }
};

module.exports = {
  getSecret,
  getParameter,
  getParametersByPath,
  getCachedSecret,
  getCachedParameter,
  clearCache,
  initializeConfig
};

/* 
Usage Examples:
===============

1. Basic secret retrieval:
   const dbPassword = await getSecret('/myapp/database/master-password');

2. Parameter retrieval:
   const dbHost = await getParameter('/myapp/database/host');

3. Bulk parameter retrieval:
   const config = await getParametersByPath('/myapp/database');
   // Returns: { host: "...", username: "...", name: "..." }

4. Cached retrieval (for frequent access):
   const jwtSecret = await getCachedSecret('/myapp/jwt/secret');

5. Application initialization:
   await initializeConfig(); // Sets process.env variables

When to use runtime fetching vs ECS secrets:
============================================

ECS Secrets (Recommended):
- Secrets are available as environment variables
- No additional AWS API calls during runtime
- Better performance
- Automatic retry and error handling by ECS

Runtime Fetching (Use when):
- Need to refresh secrets without container restart
- Implementing secret rotation
- Need to fetch secrets conditionally
- Building development/testing utilities

Note: Runtime fetching requires additional IAM permissions
and AWS SDK dependencies in your container.
*/