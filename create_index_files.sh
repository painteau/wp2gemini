#!/bin/bash

# Function to create paginated Index files

create_index_files() {
    echo "Cleaning old index files..."
    rm -f "$OUTPUT_DIR"/index*.gmi  # Supprime les anciens fichiers index

    local count=0
    local page=1
    local index_file
    local previous_file=""
    local total_posts=$(($(wc -l < "$OUTPUT_DIR/posts.csv") - 1))  # Nombre total de posts (sans l'entête)
    local total_pages=$(( (total_posts + MAX_INDEX_POSTS - 1) / MAX_INDEX_POSTS ))  # Nombre total de pages

    echo "Generating paginated index files..."

    tail -n +2 "$OUTPUT_DIR/posts.csv" | while IFS=$'\t' read -r ID TITLE CONTENT DATE; do
        index_file="$OUTPUT_DIR/index${page}.gmi"
        [[ $page -eq 1 ]] && index_file="$OUTPUT_DIR/index.gmi"

        if (( count % MAX_INDEX_POSTS == 0 )); then
            echo "# $BLOG_TITLE" > "$index_file"
            echo "" >> "$index_file"
            echo "$BLOG_INTRO" >> "$index_file"
            echo "" >> "$index_file"
            echo "## Articles" >> "$index_file"

            if [[ -n "$previous_file" ]]; then
                echo "=> ./$previous_file Previous page" >> "$index_file"
                echo "" >> "$index_file"
            fi

            previous_file=$(basename "$index_file") 
        fi

        filename="$(clean_filename "$TITLE").gmi"

        # Vérification et conversion de la date
        if FORMATTED_DATE=$(date -d "$DATE" +"%Y-%m-%d" 2>/dev/null); then
            echo "=> ./$filename $FORMATTED_DATE - $TITLE" >> "$index_file"
        else
            echo "Error : invalid date ($DATE)" >&2
        fi

        ((count++))

        if (( count % MAX_INDEX_POSTS == 0 )) || (( count == total_posts )); then
            if (( count < total_posts )); then
                next_page="index$((page+1)).gmi"
                echo "" >> "$index_file"
                echo "=> ./$next_page Next page" >> "$index_file"
            fi

            if (( page == 1 )); then
                echo "" >> "$index_file"
                echo "=> ./atom.xml Atom.xml feed" >> "$index_file"
                echo "" >> "$index_file"
            fi

            if (( count == total_posts )); then
                echo "" >> "$index_file"
                echo "This is the end...." >> "$index_file"
            fi

            ((page++))
        fi
    done

    echo "Index files generated with pagination."
}