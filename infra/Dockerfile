# ---------- Stage 1: Build React app ----------
FROM node:18-alpine AS build
WORKDIR /app

# Install deps first (better cache)
COPY jewelry-store/package*.json ./
RUN npm ci

# Copy source and build
COPY jewelry-store/ .
RUN npm run build

# ---------- Stage 2: Nginx to serve the build ----------
FROM nginx:alpine
# SPA routing + health endpoint
COPY infra/nginx.conf /etc/nginx/conf.d/default.conf
# Copy compiled React build
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
