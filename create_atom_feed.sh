#!/bin/bash

# Function to create Atom feed

create_atom_feed() {
    # Atom file header
    echo '<?xml version="1.0" encoding="UTF-8"?>' > "$ATOM_FILE"
    echo '<feed xmlns="http://www.w3.org/2005/Atom">' >> "$ATOM_FILE"
    echo "  <title>$BLOG_TITLE</title>" >> "$ATOM_FILE"
    echo "  <link href=\"$SITE_URL/index.gmi\"/>" >> "$ATOM_FILE"
    echo "  <updated>$(date --utc +%Y-%m-%dT%H:%M:%SZ)</updated>" >> "$ATOM_FILE"
    echo "  <author><name>$AUTHOR_NAME</name></author>" >> "$ATOM_FILE"
    echo "  <id>$SITE_URL</id>" >> "$ATOM_FILE"

    local count=0
    tail -n +2 "$OUTPUT_DIR/posts.csv" | while IFS=$'\t' read -r ID TITLE CONTENT DATE; do
        if [[ $count -ge $MAX_ATOM_POSTS ]]; then
            break
        fi
        
        filename="$(clean_filename "$TITLE").gmi"
        ENTRY_ID="$SITE_URL/$filename"

        # Check if valid date
        if ISO_DATE=$(date --utc -d "$DATE" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null); then
            echo "  <entry>" >> "$ATOM_FILE"
            echo "    <title><![CDATA[$TITLE]]></title>" >> "$ATOM_FILE"
            echo "    <link href=\"$ENTRY_ID\"/>" >> "$ATOM_FILE"
            echo "    <id>$ENTRY_ID</id>" >> "$ATOM_FILE"
            echo "    <updated>$ISO_DATE</updated>" >> "$ATOM_FILE"
            echo "    <summary><![CDATA[$(echo "$CONTENT" | head -n 10)]]></summary>" >> "$ATOM_FILE"
            echo "  </entry>" >> "$ATOM_FILE"
            ((count++))
        else
            echo "Error : invalid date ($DATE)" >&2
        fi

    done

    echo '</feed>' >> "$ATOM_FILE"
}
