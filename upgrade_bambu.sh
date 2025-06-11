#!/bin/bash
# Copyright 2023 Marc-Antoine Ruel. All rights reserved.
# Use of this source code is governed under the Apache License, Version 2.0
# that can be found in the LICENSE file.

# Modified by Firdan Machda, more details can be seen at git history.


# Define color codes
START='\033'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

set -eu

cd "$(dirname $0)"

if [ ! -f /lib/x86_64-linux-gnu/libfuse.so.2 ]; then
  echo "sudo apt install libfuse2"
  exit 1
fi

# Always recreate the app just in case.
# It refers to "Bambu_Studio.AppImage" instead of the real file name. This is
# because the desktop file is cached and not refreshed when updated. This makes
# it so upgrading doesn't require to restart the user session.
LINK="$HOME/.local/share/applications/Bambu_Studio.desktop"
if [ ! -f "$LINK" ]; then
  mkdir -p "$HOME/.local/share/applications"
  sed -e "s#PATH#$PWD#g" Bambu_Studio.desktop > "$LINK"
fi

# Take the latest version. It happened in the past that they forgot to provide
# the Ubuntu build for a version, it seems to be 100% manual. In this case, use
# a specific older version.
DATA="$(curl -s https://api.github.com/repos/bambulab/BambuStudio/releases/latest)"
#DATA="$(curl -s https://api.github.com/repos/bambulab/BambuStudio/releases)"
# v01.07.01.62
#DATA="$(curl -s https://api.github.com/repos/bambulab/BambuStudio/releases/114743228)"
#echo "$DATA"
SCRIPT="import json,sys;
e = [i['browser_download_url'] for i in json.load(sys.stdin)['assets']];
urls = [i for i in e if 'ubuntu' in i];
for url in urls: print(url);
"

raw_urls=$(echo "$DATA" | python3 -c "$SCRIPT")
total=0
urls=()

# Make sure to list all available ubuntu release
echo -e "${BOLD} Detected Bambu Studio versions: ${NC}"
for item in $raw_urls; do
  echo "  $total) $item"
  total=$((total + 1))
  urls+=($item)
done

choice=0

# Let user choose which version to install
if [ $total -gt 1 ]; then
  read -p "Choose version to install : (0) " choice
  else
  echo "Detected only one version, continuing..."
fi

url=${urls[$choice]}

file="$(basename $url)"

if [ -f "$file" ]; then
  echo "$file is already latest"
else
  echo "Downloading $url"
  curl -sSL "$url" -o "$file"
fi

# Always +x the file just in case.
chmod +x "$file"

# Always recreate the symlink just in case.
if [ -f Bambu_Studio.AppImage ]; then
  rm Bambu_Studio.AppImage
fi
ln -s "$file" Bambu_Studio.AppImage

echo -e "${BOLD}${GREEN} It's done!${NC}"