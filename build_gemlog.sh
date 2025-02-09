#!/bin/bash
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

# Environment variables
db_host=${DB_HOST:-"localhost"}
db_port=${DB_PORT:-"3306"}
db_user=${DB_USER:-"root"}
db_pass=${DB_PASS:-"password"}
db_name=${DB_NAME:-"wordpress"}
output_dir="/gemlog"
site_url=${SITE_URL:-"gemini://your-site.com"}
blog_title=${BLOG_TITLE:-"My Gemlog"}
blog_intro=${BLOG_INTRO:-"Welcome to my gemlog!"}
author_name=${AUTHOR_NAME:-"Your Name"}

# Clean existing files in the output directory
rm -rf "$output_dir/"*  
mkdir -p "$output_dir/images"

# Output files
index_file="$output_dir/index.gmi"
atom_file="$output_dir/atom.xml"

# Generate Index Header
echo "# $blog_title" > "$index_file"
echo "" >> "$index_file"
echo "$blog_intro" >> "$index_file"
echo "" >> "$index_file"
echo "## Articles" >> "$index_file"

# Generate Atom Header
echo '<?xml version="1.0" encoding="utf-8"?>' > "$atom_file"
echo '<feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/">' >> "$atom_file"
echo "  <title>$blog_title</title>" >> "$atom_file"
echo "  <link href=\"$site_url/index.gmi\"/>" >> "$atom_file"
echo "  <updated>$(date --utc +%Y-%m-%dT%H:%M:%SZ)</updated>" >> "$atom_file"
echo "  <id>$site_url/</id>" >> "$atom_file"
echo "  <author><name>$author_name</name></author>" >> "$atom_file"

# SQL Query to Fetch Published Posts
sql_query="SELECT ID, post_title, post_content, post_date FROM wp_posts WHERE post_status='publish' AND post_type='post' ORDER BY post_date DESC;"

# Execute SQL Query and Export to CSV
mysql -h "$db_host" -P "$db_port" -u"$db_user" -p"$db_pass" "$db_name" -e "$sql_query" --default-character-set=utf8mb4 > "$output_dir/posts.csv"

# Process Each Post
tail -n +2 "$output_dir/posts.csv" | while IFS=$'\t' read -r id title content date; do
    filename="$(echo "$title" | tr ' ' '_' | tr -dc '[:alnum:]_').gmi"
    clean_title=$(echo "$title" | tr -d '"' | tr -d '\'' | tr -d '\`')
    
    # Extract and Clean HTML Content
    clean_content=$(echo -e "$content" | sed -E 's|<[^>]*>||g')
    clean_content=$(echo "$clean_content" | sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/&/g; s/&quot;/"/g; s/&apos;/'"'"'/g')
    
    # Write Post to Gemtext File
    echo "# $clean_title" > "$output_dir/$filename"
    echo "" >> "$output_dir/$filename"
    echo "$clean_content" >> "$output_dir/$filename"
    
    # Append Post to Index
echo "=> ./$filename $(date -d "$date" +%Y-%m-%d) - $clean_title" >> "$index_file"

done

# Finalize Atom Feed
echo '</feed>' >> "$atom_file"

# Add Atom Feed to Index
echo "" >> "$index_file"
echo "=> ./atom.xml Atom.xml feed" >> "$index_file"
echo "" >> "$index_file"

# Clean up Temporary Files
rm "$output_dir/posts.csv"
