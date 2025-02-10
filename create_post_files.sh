#!/bin/bash

# Function to Generate Post files

create_post_files() {
    tail -n +2 "$OUTPUT_DIR/posts.csv" | while IFS=$'\t' read -r id title content date; do
        filename=$(clean_filename "$title").gmi  # Clean the filename from the title

        # Skip generation if the file already exists
        if [[ -f "$OUTPUT_DIR/$filename" ]]; then
            echo "Skipping existing file: $filename"
            continue
        fi

        echo "--------------------------------------------------------------"
        echo "Generating $filename"

        # Extract URLs
        URLS=$(echo -e "$content" | grep -oE '<a[^>]+href="https://[^"]+"' | sed -E 's/.*href="(https:\/\/[^\"]+)".*/\1/')
        URL_REFERENCES=()

        # Convert content to Gemini format
        clean_content=$(echo -e "$content" | sed -E 's|<h1[^>]*>(.*?)</h1>|# \1|g')
        clean_content=$(echo -e "$clean_content" | sed -E 's|<h2[^>]*>(.*?)</h2>|## \1|g')
        clean_content=$(echo -e "$clean_content" | sed -E 's|<h3[^>]*>(.*?)</h3>|### \1|g')
        clean_content=$(echo -e "$clean_content" | sed -E 's|<h4[^>]*>(.*?)</h4>|#### \1|g')
        clean_content=$(echo -e "$clean_content" | sed -E 's|<h5[^>]*>(.*?)</h5>|##### \1|g')
        clean_content=$(echo -e "$clean_content" | sed -E 's|<h6[^>]*>(.*?)</h6>|###### \1|g')
        clean_content=$(echo -e "$clean_content" | sed -E 's|<li[^>]*>(.*?)</li>|* \1|g')
        clean_content=$(echo -e "$clean_content" | sed -E 's|<blockquote[^>]*>(.*?)</blockquote>|> \1|g')

        clean_content=$(echo -e "$clean_content" | sed -E 's|<img[^>]*src="https?://[^/]+/.*/([^/"]+\.[^/"]+)"[^>]*/>|=> images/\1 \1|g')

        clean_content=$(echo -e "$clean_content" | while IFS= read -r line; do
            if [[ "$line" =~ ^"=> images/" ]]; then
                IMAGE_RAW_NAME=$(echo "$line" | awk '{print $2}')


                BASENAME=$(basename "$IMAGE_RAW_NAME")
                EXTENSION="${BASENAME##*.}"
                FILENAME="${BASENAME%.*}"

                TRIMMED_FILENAME=$(echo "$FILENAME" | sed 's/[^a-zA-Z0-9_-]//g' | sed 's/·//g' | cut -c1-90)

                IMAGE_NAME="${TRIMMED_FILENAME}.${EXTENSION}"

                echo "=> images/$IMAGE_NAME  $IMAGE_NAME"
            else
                echo "$line"
            fi
        done)


        # Clean the HTML tags left
        clean_content=$(echo -e "$clean_content" | sed 's/<[^>]*>//g')  # Remove remaining HTML tags

        # Format links to be clickable in Gemini
        clean_content=$(echo -e "$clean_content" | sed -E 's|(https?://[^\s]+)|=> \1 \1|g')

        # Decode HTML entities
        clean_content=$(echo -e "$clean_content" | sed 's/&lt;</</g; s/&gt;/>/g; s/&amp;/&/g; s/&quot;/"/g; s/&apos;/'"'"'/g')

        # Extract the thumbnail URL from the wp_postmeta table
        IMAGE_QUERY="SELECT meta_value FROM wp_postmeta WHERE post_id=$id AND meta_key='_thumbnail_id';"
        THUMBNAIL_ID=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$IMAGE_QUERY" | tail -n +2)

        # Retrieve the image URL from the thumbnail ID
        if [ ! -z "$THUMBNAIL_ID" ]; then
            IMAGE_URL_QUERY="SELECT guid FROM wp_posts WHERE ID=$THUMBNAIL_ID;"
            IMAGE_URL=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$IMAGE_URL_QUERY" | tail -n +2)

            # Extract the filename without extension
            BASENAME=$(basename "$IMAGE_URL")
            EXTENSION="${BASENAME##*.}"
            FILENAME="${BASENAME%.*}"

            # Remove special characters including the middle dot (·), keep only letters, numbers, underscore (_), and hyphen (-)
            TRIMMED_FILENAME=$(echo "$FILENAME" | sed 's/[^a-zA-Z0-9_-]//g' | sed 's/·//g' | cut -c1-90)

            IMAGE_NAME="${TRIMMED_FILENAME}.${EXTENSION}"

            # Download the thumbnail image into the images subfolder
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


        # Write the title to the Gemini file
        echo "# $title" > "$OUTPUT_DIR/$filename"
        [[ -n "$THUMBNAIL_REFERENCE" ]] && echo "$THUMBNAIL_REFERENCE" >> "$OUTPUT_DIR/$filename"
        echo "" >> "$OUTPUT_DIR/$filename"

        # Extract and download images from the article content
        IMAGE_URLS=$(echo "$content" | grep -oP 'src="[^"]*"' | cut -d'"' -f2)
        IMAGE_REFERENCES=()

        for IMAGE_URL in $IMAGE_URLS; do
            # Extract the filename and extension
            BASENAME=$(basename "$IMAGE_URL")
            EXTENSION="${BASENAME##*.}"
            FILENAME="${BASENAME%.*}"

            # Remove special characters including the middle dot (·), keep only letters, numbers, underscore (_), and hyphen (-)
            TRIMMED_FILENAME=$(echo "$FILENAME" | sed 's/[^a-zA-Z0-9_-]//g' | sed 's/·//g' | cut -c1-90)
            IMAGE_NAME="${TRIMMED_FILENAME}.${EXTENSION}"

            echo "Downloading image from: $IMAGE_URL"
            if curl -s -f "$IMAGE_URL" -o "$OUTPUT_DIR/images/$IMAGE_NAME"; then
                IMAGE_REFERENCES+=("=> images/$IMAGE_NAME  $IMAGE_NAME")
            else
                echo "Failed to download image: $IMAGE_URL" >&2
            fi
        done

        # Add cleaned content to file
        echo -e "$clean_content" >> "$OUTPUT_DIR/$filename"

        # Process URL references
        for URL in $URLS; do
            URL_REFERENCES+=("=> $URL $URL")
        done

        # Append the URL references to the end of the .gmi file
        if [[ ${#URL_REFERENCES[@]} -gt 0 ]]; then
            echo "" >> "$OUTPUT_DIR/$filename"
            echo "# Links" >> "$OUTPUT_DIR/$filename"
            for REFERENCE in "${URL_REFERENCES[@]}"; do
                echo "$REFERENCE" >> "$OUTPUT_DIR/$filename"
            done
        fi

        # Remove consecutive empty lines
        sed -i '/^$/N;/^\n$/D' "$OUTPUT_DIR/$filename"

        # Add a link to the index at the end of the article
        echo "" >> "$OUTPUT_DIR/$filename"
        echo "=> ./index.gmi Back to Home" >> "$OUTPUT_DIR/$filename"
    done
}
