#!/bin/bash

# environment variables
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"3306"}
DB_USER=${DB_USER:-"root"}
DB_PASS=${DB_PASS:-"password"}
DB_NAME=${DB_NAME:-"wordpress"}
OUTPUT_DIR="/gemlog"
SITE_URL=${SITE_URL:-"gemini://your-site.com"}
BLOG_TITLE=${BLOG_TITLE:-"My Gemlog"}
BLOG_INTRO=${BLOG_INTRO:-"Welcome to my gemlog!"}
AUTHOR_NAME=${AUTHOR_NAME:-"Your Name"}  # Adding variable for author's name

# Clean existing files in the output directory
rm -rf "$OUTPUT_DIR/"*  
mkdir -p "$OUTPUT_DIR/images"

# Output files
INDEX_FILE="$OUTPUT_DIR/index.gmi"
ATOM_FILE="$OUTPUT_DIR/atom.xml"

# Gemlog index header
echo "# $BLOG_TITLE" > "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
echo "$BLOG_INTRO" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
echo "## Articles" >> "$INDEX_FILE"

# Atom file header
echo '<?xml version="1.0" encoding="utf-8"?>' > "$ATOM_FILE"
echo '<feed xmlns="http://www.w3.org/2005/Atom">' >> "$ATOM_FILE"
echo "  <title>$BLOG_TITLE</title>" >> "$ATOM_FILE"  # Using BLOG_TITLE
echo "  <link href=\"$SITE_URL/index.gmi\"/>" >> "$ATOM_FILE"
echo "  <updated>$(date --utc +%Y-%m-%dT%H:%M:%SZ)</updated>" >> "$ATOM_FILE"
echo "  <id>$SITE_URL/</id>" >> "$ATOM_FILE"
echo "  <author><name>$AUTHOR_NAME</name></author>" >> "$ATOM_FILE"  # Using AUTHOR_NAME

# Function to clean the filename
clean_filename() {
    local name="$1"
    echo "$name" | tr ' ' '_' | tr -dc '[:alnum:]_'  # Sanitize filename
}

# SQL query to extract WordPress posts
SQL_QUERY="SELECT ID, post_title, post_content, post_date FROM wp_posts WHERE post_status='publish' AND post_type='post' ORDER BY post_date DESC;"

# Execute the SQL query
mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$SQL_QUERY" --default-character-set=utf8mb4 > "$OUTPUT_DIR/posts.csv"

# Generate Gemtext and Atom files
tail -n +2 "$OUTPUT_DIR/posts.csv" | while IFS=$'\t' read -r id title content date; do
    filename=$(clean_filename "$title").gmi  # Clean the filename from the title

    # Extract URLs
    # URLS=$(echo "$clean_content" | grep -oE 'https://[^"]+')
    URLS=$(echo -e "$content" | grep -oE '<a[^>]+href="https://[^"]+"' | sed -E 's/.*href="(https:\/\/[^"]+)".*/\1/')

    # Convert content
    clean_content=$(echo -e "$content" | sed -E 's|<h1[^>]*>(.*?)<\/h1>|# \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<h2[^>]*>(.*?)<\/h2>|## \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<h3[^>]*>(.*?)<\/h3>|### \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<h4[^>]*>(.*?)<\/h4>|#### \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<h5[^>]*>(.*?)<\/h5>|##### \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<h6[^>]*>(.*?)<\/h6>|###### \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<li[^>]*>(.*?)<\/li>|* \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<ol[^>]*>(.*?)<\/ol>|(\1)|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<blockquote[^>]*>(.*?)<\/blockquote>|> \1|g')
    # clean_content=$(echo -e "$clean_content" | sed -E 's|<pre[^>]*>(.*?)<\/pre>|```\n\1\n```|g')
    # clean_content=$(echo -e "$clean_content" | sed -E 's|<code[^>]*>(.*?)<\/code>|`\n\1\n`|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<hr\s*\/?>|---|g')

    # Extract images
    # clean_content=$(echo -e "$clean_content" | sed -E 's|<img src="https?://[^/]+/.*/([^/"]+\.[^/"]+)"[^>]*>|=> images/\1  \1|g')
    clean_content=$(echo -e "$clean_content" | sed -E 's|<img[^>]*src="https?://[^/]+/.*/([^/"]+\.[^/"]+)"[^>]*/>|=> images/\1  \1|g')

    # Clean the HTML tags left
    clean_content=$(echo -e "$clean_content" | sed 's/<[^>]*>//g')  # Remove remaining HTML tags

    # Format links to be clickable
    clean_content=$(echo -e "$clean_content" | sed -E 's|(https?://[^\s]+)|=> \1 \1|g')

    # Decode HTML 
    clean_content=$(echo -e "$clean_content" | sed 's/&lt;</</g')
    clean_content=$(echo -e "$clean_content" | sed 's/&gt;/>/g')
    clean_content=$(echo -e "$clean_content" | sed 's/&amp;/&/g')
    clean_content=$(echo -e "$clean_content" | sed 's/&quot;/"/g')
    clean_content=$(echo -e "$clean_content" | sed 's/&apos;/'"'"'/g')
    


    # Extract the thumbnail URL from the wp_postmeta table
    IMAGE_QUERY="SELECT meta_value FROM wp_postmeta WHERE post_id=$id AND meta_key='_thumbnail_id';"
    THUMBNAIL_ID=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$IMAGE_QUERY" | tail -n +2)

    # Retrieve the image URL from the thumbnail ID
    if [ ! -z "$THUMBNAIL_ID" ]; then
        IMAGE_URL_QUERY="SELECT guid FROM wp_posts WHERE ID=$THUMBNAIL_ID;"
        IMAGE_URL=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$IMAGE_URL_QUERY" | tail -n +2)

        # Download the thumbnail image into the images subfolder
        IMAGE_NAME=$(basename "$IMAGE_URL")
        echo "Downloading thumbnail from: $IMAGE_URL"
        if curl -s "$IMAGE_URL" -o "$OUTPUT_DIR/images/$IMAGE_NAME"; then
            echo "Downloaded thumbnail: $IMAGE_NAME"
            THUMBNAIL_REFERENCE="=> images/$IMAGE_NAME  $title"
        else
            echo "Failed to download thumbnail: $IMAGE_URL"
            THUMBNAIL_REFERENCE=""
        fi
    else
        THUMBNAIL_REFERENCE=""
    fi

    # Write the title to the Gemtext file
    echo "# $title" > "$OUTPUT_DIR/$filename"  # Write the title only
    echo "$THUMBNAIL_REFERENCE" >> "$OUTPUT_DIR/$filename"  # Add the thumbnail reference if it exists
    echo "" >> "$OUTPUT_DIR/$filename"  # Ensure there's a new line

    # Extract images from the article content
    IMAGE_URLS=$(echo "$content" | grep -oP 'src="[^"]*"' | cut -d'"' -f2)
    IMAGE_REFERENCES=()  # Initialize an array to hold image references

    for IMAGE_URL in $IMAGE_URLS; do
        # Download each image into the images subfolder
        IMAGE_NAME=$(basename "$IMAGE_URL")
        echo "Downloading image from: $IMAGE_URL"
        if curl -s "$IMAGE_URL" -o "$OUTPUT_DIR/images/$IMAGE_NAME"; then
            echo "Downloaded image: $IMAGE_NAME"
            IMAGE_NAME_NO_EXT="${IMAGE_NAME%.*}"  # Get the name without the extension
            IMAGE_REFERENCES+=("=> images/$IMAGE_NAME  $IMAGE_NAME_NO_EXT")  # Store the image reference
        else
            echo "Failed to download image: $IMAGE_URL"
        fi
    done

    # Add the cleaned content
    echo -e "$clean_content" >> "$OUTPUT_DIR/$filename"  # Add the cleaned content

    # Add references at the end
    URL_REFERENCES=()

    # Loop through each extracted URL
    for URL in $URLS; do
        echo "Processing URL: $URL"
        URL_REFERENCES+=("=> $URL $URL")  # Store the URL reference
    done

    # Append the URL references to the end of the .gmi file
    for REFERENCE in "${URL_REFERENCES[@]}"; do
        echo "$REFERENCE" >> "$OUTPUT_DIR/$filename"
    done

    # Add the entry to the index
    echo "=> ./$filename $(date -d "$date" +%Y-%m-%d) - $title" >> "$INDEX_FILE"

    # Add the entry to the Atom file
    echo '  <entry>' >> "$ATOM_FILE"
    echo "    <title>$title</title>" >> "$ATOM_FILE"
    echo "    <link href=\"$SITE_URL/$filename\"/>" >> "$ATOM_FILE"
    echo "    <id>$SITE_URL/$filename</id>" >> "$ATOM_FILE"
    echo "    <updated>$(date --utc -d "$date" +%Y-%m-%dT%H:%M:%SZ)</updated>" >> "$ATOM_FILE"
    echo "    <summary>$(echo "$clean_content" | head -n 1)</summary>" >> "$ATOM_FILE"
    echo '  </entry>' >> "$ATOM_FILE"

    # Clean the GMI file of empty lines greater than 1
    sed -i '/^$/N;/^\n$/D' "$OUTPUT_DIR/$filename"

    # Add a link to the index at the end of the article
    echo "" >> "$OUTPUT_DIR/$filename"  # Ensure there's a new line before the link
    echo "=> ./index.gmi Back to home" >> "$OUTPUT_DIR/$filename"

done

# Footer of the Atom file
echo '</feed>' >> "$ATOM_FILE"

# Adding the Gemfeed to the index
echo "" >> "$INDEX_FILE"
echo "Thanks !" >> "$INDEX_FILE"
echo "=> ./atom.xml Atom feed" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"

# Delete the posts.csv file after processing
rm "$OUTPUT_DIR/posts.csv"