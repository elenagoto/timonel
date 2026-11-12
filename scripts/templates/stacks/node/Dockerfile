# Shared image for every Node project (Next.js, Vite, Parcel...)
# Node.js 24 (LTS) on Alpine Linux (lightweight)
FROM node:24-alpine

# Set working directory inside container
WORKDIR /app

# OpenSSL is needed by some packages (e.g. Prisma)
RUN apk add --no-cache openssl

# Copy package files first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Start the development server. The port and any extra flags come from
# the framework settings (scripts/lib/frameworks.sh) via docker-compose.yml.
CMD ["npm", "run", "dev"]
