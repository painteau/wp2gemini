# Use a Debian or Alpine image with the necessary tools
FROM debian:bullseye-slim

# Install the MySQL client and other necessary tools
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    curl \
    bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*  # Clean the cache to reduce the image size

# Create a directory for the script and files
WORKDIR /app

# Copy the Bash script into the image
COPY build_gemlog.sh /app/

# Make the script executable
RUN chmod +x /app/build_gemlog.sh

# Entry point for executing the script
ENTRYPOINT ["/app/build_gemlog.sh"]