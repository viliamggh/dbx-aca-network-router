# Nginx based image that serves static content on port 8080
FROM nginx:stable-alpine

# Remove default configuration and add our custom one (listens on 8080)
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static site into nginx html root
COPY www /usr/share/nginx/html

# Expose the port expected by the Terraform container app (target_port = 8080)
EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
