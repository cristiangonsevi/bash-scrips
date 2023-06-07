#!/bin/bash

# Script configuration
bucket_name="bucket-name"
s3_folder="s3-folder-path"

# Local folder path where the files are located
local_folder="/path/to/local/files"

# Get the latest file in local folder
latest_file=$(ls -t "$local_folder" | head -n 1")

# Check if the file already exist in S3
existing_file=$(aws s3 le "s3://$bucket_name/$s3_folder/$latest_file" | awk '{print $4}')

if [ -z "$existing_file" ]; then
	# Upload file to s3 if it doesn't already exist
	aws s3 cp "$local_folder/$latest_file" "s3://$bucket_name/$s3_folder/$latest_file"

	# Check files age
	current_date=$(date +%s)

	older_than_days=7

	files$(ls -l | awk '{print $9}')

	for file in $files; do
		file_date=$( ls -l | awk '{print $6" " $7" "$8}')
		file_timestamp=$(date -d "$file_date" +%s)
		days_diff=$((($current_date - $file_timestamp)/(60*60*24)))

		if [ $days_diff -gt $older_than_days ]; then
			# Delete file
			rm "$local_folder/$file"
		fi
	done
else
	echo "The file '$latest_file' already exist in S3"
fi
