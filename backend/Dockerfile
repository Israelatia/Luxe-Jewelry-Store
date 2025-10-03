# Base image
FROM nginx:1.25-alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy our custom config
COPY nginx.conf /etc/nginx/conf.d/

# Copy website files
COPY website/ /usr/share/nginx/html/

# Expose frontend port
EXPOSE 80

# Run Nginx
CMD ["nginx", "-g", "daemon off;"]
