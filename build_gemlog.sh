#!/bin/bash
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

# Load external functions
source /app/create_atom_feed.sh
source /app/create_index_files.sh
source /app/create_post_files.sh

# Environment variables

# Database connection details (defaults to local MySQL setup)
DB_HOST=${DB_HOST:-"localhost"}   # Database host (default: localhost)
DB_PORT=${DB_PORT:-"3306"}        # Database port (default: 3306)
DB_USER=${DB_USER:-"root"}        # Database username (default: root)
DB_PASS=${DB_PASS:-"password"}    # Database password (default: password)
DB_NAME=${DB_NAME:-"wordpress"}   # Database name (default: wordpress)

# Output directory where generated files will be stored
OUTPUT_DIR="/gemlog"              # Directory for storing generated Gemini files

# Site metadata
SITE_URL=${SITE_URL:-"gemini://your-site.com"}  # Base URL of the Gemini site
BLOG_TITLE=${BLOG_TITLE:-"My Gemlog"}           # Title of the blog
BLOG_INTRO=${BLOG_INTRO:-"Welcome to my gemlog!"}  # Introduction message

# Author information
AUTHOR_NAME=${AUTHOR_NAME:-"Your Name"}  # Name of the author (optional)

# Configuration for post limits
MAX_ATOM_POSTS=${MAX_ATOM_POSTS:-"10"}   # Maximum number of posts in Atom feed
MAX_INDEX_POSTS=${MAX_INDEX_POSTS:-"10"} # Maximum number of posts per Index file


# Output files
INDEX_FILE="$OUTPUT_DIR/index.gmi"
ATOM_FILE="$OUTPUT_DIR/atom.xml"

# Create images directory
mkdir -p "$OUTPUT_DIR/images"

# Function to clean the filename
clean_filename() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -dc '[:alnum:]_'
}

# SQL query to extract WordPress posts
SQL_QUERY="SELECT ID, post_title, post_content, post_date FROM wp_posts WHERE post_status='publish' AND post_type='post' ORDER BY post_date DESC;"

# Execute the SQL query
mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$SQL_QUERY" --default-character-set=utf8mb4 > "$OUTPUT_DIR/posts.csv"

# Generate Atom feed
echo "--------------------------------------------------------------"
echo "Generating Atom Feed..."
create_atom_feed
echo "--------------------------------------------------------------"
echo "Generating Index File..."
create_index_files
echo "--------------------------------------------------------------"
echo "Generating Post Files..."
create_post_files