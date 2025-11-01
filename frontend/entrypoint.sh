#!/bin/sh

# Set defaults for environment variables if not provided
export API_URL=${API_URL:-"http://internal-backend-alb-123456789.us-east-1.elb.amazonaws.com"}

echo "Starting nginx with API_URL: $API_URL"

# Replace API_URL placeholder in nginx configuration
envsubst '${API_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Verify the substitution worked
echo "Generated nginx configuration API section:"
grep -A 10 "location /api/" /etc/nginx/nginx.conf

# Test nginx configuration
nginx -t

# Start nginx
echo "Starting nginx..."
exec nginx -g "daemon off;"