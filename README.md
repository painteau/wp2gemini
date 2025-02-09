# **WP2Gemini**

WP2Gemini is a **Dockerized tool** that extracts recent posts from a WordPress MySQL database, converts them to **Gemtext**, and generates an **Atom feed**. It enables you to effortlessly maintain a Gemini-compatible blog using your WordPress content.

## **🔗 Repository & Container**

- **GitHub**: [https://github.com/painteau/wp2gemini](https://github.com/painteau/wp2gemini)
- **Container Registry**: [ghcr.io/painteau/wp2gemini](https://ghcr.io/painteau/wp2gemini)

---

## **✨ Features**

- ✅ **Automated extraction** of published WordPress posts
- ✅ **HTML to Gemtext** conversion, including headers, lists, links, and images
- ✅ **Automatic Atom feed generation** (`atom.xml`)
- ✅ **Thumbnail & image downloads** for enhanced content display
- ✅ **Customizable environment variables** for fine-tuned control
- ✅ **Works with Docker & Docker Compose** for easy deployment

---

## **📌 Prerequisites**

- **[Docker](https://www.docker.com/get-started)** installed on your system
- Access to a **WordPress MySQL database**
- A **Gemini server** such as Agate for hosting your Gemlog

---

## **🚀 Getting Started**

### **Step 1: Pull the Docker Image**

Pull the latest version of the image from the GitHub Container Registry:

```bash
docker pull ghcr.io/painteau/wp2gemini:latest
```

---

## **Running WP2Gemini**

### **Option 1: Using Docker Compose**

Use the provided `docker-compose.yml` to simplify deployment.

#### **Example `docker-compose.yml`**

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
      BLOG_INTRO: "Welcome to my gemblog!"
    volumes:
      - /path/to/output:/gemlog
    restart: always
```

Run the container:

```bash
docker-compose up -d
```

### **Option 2: Using `docker run`**

Alternatively, you can run WP2Gemini manually with:

```bash
docker run -d \
    --name wp2gemini \
    --restart always \
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

---

## **Deploying a Gemini Server with Agate**

To serve your generated Gemtext files, you can use [Agate](https://github.com/mbrubeck/agate), a lightweight Gemini server.

### **Running Agate with Docker**

```bash
docker run --name=agate \
    --volume=/path/to/output:/var/agate/content \
    --volume=/path/to/keys:/var/agate/keys \
    --network=bridge \
    -p 1965:1965 \
    --restart=unless-stopped \
    thejf/agate \
    /usr/local/cargo/bin/agate 0.0.0.0:1965 /var/agate/content /var/agate/keys/cert.pem /var/agate/keys/key.rsa
```

### **Generating SSL Certificates for Agate**

This will generate `cert.pem` and `key.rsa` inside `/path/to/keys`, which Agate will use for encryption. These files should not be publicly accessible for security reasons. Avoid placing them in a subdirectory of `/path/to/output` to prevent accidental exposure.


Generate a self-signed certificate:

```bash
mkdir -p /path/to/keys
openssl req -x509 -newkey rsa:4096 -keyout /path/to/keys/key.rsa -out /path/to/keys/cert.pem -days 365 -nodes -subj "/CN=localhost"
```

---

## **⏲️ Automating with Cron**

To restart the WP2Gemini container every 6 hours:

```bash
crontab -e
```

Add the following line:

```bash
0 */6 * * * docker restart wp2gemini
```

---

## **⚙️ Customization**

You can configure WP2Gemini with the following **environment variables**:

| Variable      | Default Value            | Description                  |
| ------------- | ------------------------ | ---------------------------- |
| `DB_HOST`     | `localhost`              | MySQL database host          |
| `DB_PORT`     | `3306`                   | MySQL port                   |
| `DB_USER`     | `root`                   | MySQL username               |
| `DB_PASS`     | `password`               | MySQL password               |
| `DB_NAME`     | `wordpress`              | WordPress database name      |
| `SITE_URL`    | `gemini://your-site.com` | Base URL of your Gemini site |
| `BLOG_TITLE`  | `My Gemlog`              | Title of your Gemini blog    |
| `BLOG_INTRO`  | `Welcome to my gemlog!`  | Blog introduction text       |
| `AUTHOR_NAME` | `Your Name`              | Name of the blog’s author    |

---

## **🐞 Troubleshooting**

### **1. My posts are missing or not updated**

Check if the database is reachable:

```bash
mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;"
```

Ensure that posts have `post_status='publish'` in `wp_posts`.

### **2. The script is wiping my output folder!**

⚠️ **This is intentional**! `/path/to/output` is cleared before each execution.

---

## **📜 License**

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.

## **📣 Contributing**

Contributions are welcome! Feel free to **open an issue** or **submit a pull request** on [GitHub](https://github.com/painteau/wp2gemini).

