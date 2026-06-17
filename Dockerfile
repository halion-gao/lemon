FROM nginx:alpine

# Copy Flutter Web build files to Nginx web directory
COPY build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
