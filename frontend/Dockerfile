# Use Node LTS image
FROM node:18-bullseye

# Set work directory
WORKDIR /app

# Copy package files first for caching
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy all frontend files
COPY . .

# Build the production frontend
RUN npm run build

# Expose port (serve via a simple server like serve)
RUN npm install -g serve
EXPOSE 3000

# Start the app
CMD ["serve", "-s", "build", "-l", "3000"]
