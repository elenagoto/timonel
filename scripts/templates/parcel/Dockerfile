# Use Node.js 24 (LTS) on Alpine Linux (lightweight)
FROM node:24-alpine

# Set working directory inside container
WORKDIR /app

# Copy package files first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port 1234 (Parcel default)
EXPOSE 1234

# Start the development server
CMD ["npm", "run", "dev"]
