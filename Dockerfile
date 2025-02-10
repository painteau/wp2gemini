# Use a Debian or Alpine image with necessary tools
FROM debian:bullseye-slim

# Install MySQL client and other necessary tools
RUN apt-get update && apt-get upgrade -y \
    default-mysql-client \
    curl \
    bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*  # Clean the cache to reduce image size

# Create a directory for the script and files
WORKDIR /app

# Copy all script files
COPY build_gemlog.sh /app/
COPY create_atom_feed.sh /app/
COPY create_index_files.sh /app/
COPY create_post_files.sh /app/

# Make scripts executable
RUN chmod +x /app/*.sh

# Default command for executing the script
ENTRYPOINT ["/app/build_gemlog.sh"]
