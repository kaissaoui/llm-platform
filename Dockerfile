FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY package-lock.json* ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Create public directory if it doesn't exist
RUN mkdir -p public

# Build the application
RUN npm run build

# Expose port
EXPOSE 3000

# Set production environment
ENV NODE_ENV=production

# Start the application
CMD ["npm", "start"]
