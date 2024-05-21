#!/bin/bash

# set -x

# Directory containing images
read -p "Enter the directory: " image_dir

# Check for whitespace; if found, exit and alert
whitespace=`find "$video_dir" -name "* *"`
if [[ -n ${whitespace[@]} ]]; then
	echo -ne "Whitespace found in file or directory name. Please fix before proceeding:\n$whitespace"
	exit 1
fi

# file_exts=("*.jpg" "*.jpeg" "*.tif" ".*tiff" "*.cr2" "*.dng" "*.gif" "*.heic" "*.nef" "*.png" "*.psd" "*.webp")

# Find all photo files recursively in the directory and put them in an array
image_list=`find "$image_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.tif" -o -iname "*.tiff" -o -iname "*.cr2" -o -iname "*.dng" -o -iname "*.gif" -o -iname "*.heic" -o -iname "*.nef" -o -iname "*.png" -o -iname "*.psd" -o -iname "*.arw" \)`

# If no video files found, exit and alert
if [[ -z ${image_list[@]} ]]; then
    echo "No images found"
    exit 1
fi

# For each item in the image_list, create a thumbnail
for image_file in $image_list
do
    # Get the directory of the video file
    dir=$(dirname "$image_file")

    # Get the filename without extension
    filename=$(basename -- "$image_file")
    filename_no_ext="${filename%.*}"

    # Output thumbnail filename
    thumbnail_filename="$dir/$filename_no_ext-th.png"

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
find "$image_dir" -type f -iname *-th.png > $image_dir/thumb_list.txt

# Determine number of columns for imagemagick
read num_imgs <<< $(sed -n '$=' $image_dir/thumb_list.txt)
if [[ $num_imgs -gt 5 ]]
then
   let num_columns=6
else
	let num_columns=num_imgs	   
fi

# Create contact sheets
montage -label '%t' -font Helvetica -pointsize 10 -size 200x200 @$image_dir/thumb_list.txt -geometry 280x190 -tile "$num_columns"x $image_dir/contactsheet.png

# Check if contact sheet was successfully created
if test -f $image_dir/contactsheet.png; then
	echo "Contact sheet successfully created"
else
	echo "Error in creating contact sheet"
fi

# Remove that no-longer-needed list
rm $image_dir/thumb_list.txt

# Delete thumbnails
thumb_list=`find "$image_dir" -type f \( -iname "*-th.png" \)`

for delete_me in $thumb_list
do
	rm $delete_me
done
