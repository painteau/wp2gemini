# WP2Gemini

This Docker container extracts recent posts from a WordPress MySQL database, converts the content to Gemtext, and generates an Atom feed. It is designed to help you maintain a Gemini-compatible blog from your WordPress data.

## Repository

- **GitHub**: [https://github.com/painteau/wp2gemini](https://github.com/painteau/wp2gemini)
- **Container Registry**: [ghcr.io/painteau/wp2gemini](https://ghcr.io/painteau/wp2gemini)

## Prerequisites

- [Docker](https://www.docker.com/get-started) installed on your system
- Access to a WordPress MySQL database

## Getting Started

### Step 1: Pull the Docker Image

You can pull the Docker image directly from the GitHub Container Registry:

```bash
docker pull ghcr.io/painteau/wp2gemini:latest
```

### Step 2a: Using Docker Compose

An example `docker-compose.yml` file is available in the root of the repository. You can use it to run the container. 

The contents of the `docker-compose.yml` file are as follows:

```yaml
services:
  wp2gemini:
    image: ghcr.io/painteau/wp2gemini
    container_name: wp2gemini
    environment:
      DB_HOST: "localhost"
      DB_USER: "wordpress-user"
      DB_PORT: "3306"
      DB_PASS: "my-password"
      DB_NAME: "wordpress"
      SITE_URL: "gemini://my.url.com"
      BLOG_TITLE: "My gemlog title"
      AUTHOR_NAME: "My name"
      BLOG_INTRO: "Welcome to my gemblog !"
    volumes:
      - /path/to/output:/gemlog
```

- Replace the environment variable values with your own database credentials and desired gemlog settings.
- Change `/path/to/output` to the directory where you want the gemlog and Atom feed to be generated.
- BE CAREFUL : your `/path/to/output` directory WILL BE WIPED by our script

To run the container with Docker Compose, execute the following command:

```bash
docker-compose up -d
```

### Step 2b: Using Docker run command

```bash
docker run -d \
    --name wp2gemini \
    -e DB_HOST="your-db-host" \
    -e DB_PORT="3306" \
    -e DB_USER="your-db-username" \
    -e DB_PASS="your-db-password" \
    -e DB_NAME="your-db-name" \
    -e SITE_URL="gemini://your-site.org" \
    -e BLOG_TITLE="Your gemlog title" \
    -e BLOG_INTRO="Welcome to my gemlog!" \
    -e AUTHOR_NAME="Your Name" \
    -v /path/to/output:/gemlog \
    ghcr.io/painteau/wp2gemini
```

- Replace the environment variable values with your own database credentials and desired gemlog settings.
- Change `/path/to/output` to the directory where you want the gemlog and Atom feed to be generated.
- BE CAREFUL : your `/path/to/output` directory WILL BE WIPED by our script

### Step 3: Access Your Gemlog

After running the container, the generated Gemtext files and Atom feed will be available in the specified output directory.

## Customization

You can adjust the following environment variables for customization:

- `DB_HOST`: Hostname of your MySQL server (default: `localhost`)
- `DB_PORT`: MySQL port (default: `3306`)
- `DB_USER`: MySQL username (default: `root`)
- `DB_PASS`: MySQL password (default: `password`)
- `DB_NAME`: WordPress database name (default: `wordpress`)
- `SITE_URL`: Base URL of your Gemini site
- `BLOG_TITLE`: The title of your gemlog
- `BLOG_INTRO`: Introduction text for your gemlog's homepage
- `AUTHOR_NAME`: Name of the gemlog's author

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
