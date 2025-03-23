#!/bin/bash

SCRIPT_NAME="networkstat"
INSTALL_PATH="/usr/local/bin/$SCRIPT_NAME"
MAN_PATH="/usr/local/share/man/man1/$SCRIPT_NAME.1"
CONFIG_DIR="$HOME/.config/networkstat"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Make script executable
chmod +x networkstat.py

# Install globally
sudo cp networkstat.py "$INSTALL_PATH"

# Install man page
if [ -f "networkstat.1" ]; then
    sudo cp networkstat.1 "$MAN_PATH"
    sudo gzip -f "$MAN_PATH"
    sudo mandb
    echo "📚 Installed man page. Try: man $SCRIPT_NAME"
else
    echo "⚠️  No man page (networkstat.1) found in current directory."
fi

# Create config directory and file if not exist
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
  echo '{ "default_sleep": 1 }' > "$CONFIG_FILE"
  echo "🛠️  Created default config at $CONFIG_FILE with sleep = 1s"
else
  echo "⚠️  Config already exists at $CONFIG_FILE, not overwritten."
fi

set -e

# Check and install psutil silently
echo "🔧 Checking Python dependencies..."
if ! python3 -c "import psutil" 2>/dev/null; then
    echo "📦 Installing psutil globally..."
    if sudo pip3 install psutil > /dev/null 2>&1; then
        echo "✅ psutil installed successfully."
    else
        echo "❌ Failed to install psutil. Please check your pip configuration."
        exit 1
    fi
else
    echo "✅ psutil already installed."
fi

echo "✅ Installed '$SCRIPT_NAME' globally. Try running: $SCRIPT_NAME --help"

