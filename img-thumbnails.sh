#!/bin/bash

#set -x

# Directory containing images
read -p "Enter the directory: " image_dir

# Ask the user to add info to the filename
read -p "Do you want to add info to the filename? (If not, hit enter): " filenameinfo

# Check for whitespace; if found, exit and alert
whitespace=$(find "$image_dir" -name "* *")
if [[ -n ${whitespace[@]} ]]; then
    echo -ne "Whitespace found in file or directory name. Please fix before proceeding:\n$whitespace"
    exit 1
fi

# Find all photo files recursively in the directory and put them in an array
image_list=$(find "$image_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.tif" -o -iname "*.tiff" -o -iname "*.cr2" -o -iname "*.dng" -o -iname "*.gif" -o -iname "*.heic" -o -iname "*.nef" -o -iname "*.png" -o -iname "*.psd" -o -iname "*.arw" \))

# If no photo files found, exit and alert
if [[ -z ${image_list[@]} ]]; then
    echo "No images found"
    exit 1
fi

# Create directory to store thumbnails
thumbnails_dir="$image_dir/thumbnails"
mkdir -p –m777 "$thumbnails_dir"

# For each item in the image_list, create a thumbnail
for image_file in $image_list; do
    # Get the directory of the image file
    dir=$(dirname "$image_file")

    # Get the filename without extension
    filename=$(basename -- "$image_file")
    filename_no_ext="${filename%.*}"

    # Output thumbnail filename
    thumbnail_filename="$thumbnails_dir/$filename_no_ext-th.png"

    # Create thumbnail
    magick "$image_file" -thumbnail '200x200' "$thumbnail_filename"

    # Check if extraction was successful
    if [ $? -eq 0 ]; then
        echo "Thumbnail extracted for $filename"
    else
        echo "Error extracting thumbnail for $filename"
    fi
done

# Find all the thumbnails in the directory
find "$thumbnails_dir" -type f -iname "*-th.png" > $thumbnails_dir/thumb_list.txt

# Enclose each line in thumb_list.txt with quotes
while IFS= read -r line; do
    echo "\"$line\""
done < "$thumbnails_dir/thumb_list.txt" > "$thumbnails_dir/thumb_list_quotes.txt"

# Use the modified thumb_list_quotes.txt for further processing
mv "$thumbnails_dir/thumb_list_quotes.txt" "$thumbnails_dir/thumb_list.txt"

# Split thumbnails into groups of 120 (to try to improve montage creation time for large directories? 🤞)
gsplit -l 120 -a 3 --additional-suffix=.txt $thumbnails_dir/thumb_list.txt $thumbnails_dir/thumb_list_

# Counter for PNG filenames
counter=1

# For each group of thumbnails ...
for thumb_list_file in "$thumbnails_dir"/thumb_list_*; do
    # ... create contact sheets
    montage -label '%t' -font Helvetica -pointsize 10 -size 200x200 @"$thumb_list_file" -geometry 280x190 -tile 6x "$thumbnails_dir/__${filenameinfo}-img-thumbnails-$counter.png"

    # Check if thumbnails.png was successfully created
    if test -f "$thumbnails_dir/__${filenameinfo}-img-thumbnails-$counter.png"; then
        echo "__${filenameinfo}-img-thumbnails-$counter.png successfully created"
    else
        echo "Error in creating __${filenameinfo}-img-thumbnails-$counter.png"
    fi

    ((counter++))
done

# Combine thumbnail PNGs into a PDF
montage "$thumbnails_dir/__${filenameinfo}-img-thumbnails-"*.png -tile 1x -geometry +0+0 "$image_dir/__${filenameinfo}_img-thumbnails.pdf"

# Check if PDF was successfully created
if test -f "$image_dir/__${filenameinfo}_img-thumbnails.pdf"; then
    echo "__${filenameinfo}_img-thumbnails.pdf successfully created"
else
    echo "Error creating __${filenameinfo}_img-thumbnails.pdf"
fi

# Delete thumbnails directory
rm -rf "$thumbnails_dir"
