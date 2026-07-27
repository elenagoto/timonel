# Use Node.js 20 on Alpine Linux (lightweight)
FROM node:20-alpine

# Set working directory inside container
WORKDIR /app

RUN apk add --no-cache openssl

# Copy package files first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port 3000 (Next.js default)
EXPOSE 3000

# Start the development server
CMD ["npm", "run", "dev"]
