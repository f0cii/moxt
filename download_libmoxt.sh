# Use GitHub API to get the latest release information
LATEST_RELEASE_INFO=$(curl -s https://api.github.com/repos/f0cii/moxt-cpp/releases/latest)

# Parse the assets array and extract the file name that matches the pattern (for example, files ending with .so)
FILE_NAME=$(echo "$LATEST_RELEASE_INFO" | jq -r '.assets[] | .name | select(endswith(".so"))')

echo "File Name: $FILE_NAME"

# Directly parse the assets array and extract the download URL corresponding to the file name
DOWNLOAD_URL=$(echo "$LATEST_RELEASE_INFO" | jq -r ".assets[] | select(.name == \"$FILE_NAME\") | .browser_download_url")

echo "Download URL: $DOWNLOAD_URL"

# Use curl to download the file, save it as libmoxt.so
curl -L -o libmoxt.so $DOWNLOAD_URL

# Or use wget to download the file, save it as libmoxt.so
# wget -O libmoxt.so $DOWNLOAD_URL