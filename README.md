# 🌍 WP2Gemini

WP2Gemini is a **Dockerized tool** that extracts recent posts from a **WordPress MySQL database**, converts them to **Gemtext**, and generates an **Atom feed**. It enables you to effortlessly maintain a Gemini-compatible blog using your WordPress content.

---

## ⭐ Features
- ✅ **Automated extraction** of published WordPress posts.
- ✅ **HTML to Gemtext conversion**, including headers, lists, links, and images.
- ✅ **Automatic Atom feed generation** (`atom.xml`).
- ✅ **Thumbnail & image downloads** for enhanced content display.
- ✅ **Customizable environment variables** for fine-tuned control.
- ✅ **Works with Docker & Docker Compose** for easy deployment.

---

## 📌 Prerequisites
- **Docker** installed on your system.
- Access to a **WordPress MySQL database**.
- A **Gemini server** such as Agate for hosting your Gemlog.

---

## 🛠 Setup & Installation

### **1️⃣ Clone the Repository**
```bash
git clone https://github.com/painteau/wp2gemini.git
cd wp2gemini
```

### **2️⃣ Pull the Docker Image**
```bash
docker pull ghcr.io/painteau/wp2gemini:latest
```

### **3️⃣ Using Docker Compose**

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

---

## 🐳 Running with Docker (GHCR)

WP2Gemini is available on **GitHub Container Registry (GHCR)**.

📦 **[`ghcr.io/painteau/wp2gemini`](https://ghcr.io/painteau/wp2gemini)**

---

## 🌐 Deploying a Gemini Server with Agate

To serve your generated Gemtext files, you can use [Agate](https://github.com/mbrubeck/agate), a lightweight Gemini server.

### 🐧 Running Agate with Docker

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

### 🔑 Generating SSL Certificates for Agate

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

## ⚙ Configuration

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

## 📜 License

This project is licensed under the **MIT License**.

---

## ⚠ Security Notice

Ensure that you expose the API securely and restrict access if necessary when deploying in a production environment.

---

## 💡 Contributing

1️⃣ **Fork** the repository on [GitHub](https://github.com/painteau/wp2gemini)  
2️⃣ **Create a new branch** (`feature-branch`)  
3️⃣ **Commit your changes**  
4️⃣ **Push to your branch and create a pull request**  

For major changes, please open an **issue** first to discuss the proposed modifications.

---

## 📬 Contact

For issues or improvements, open an issue on GitHub or contact **Painteau**.

