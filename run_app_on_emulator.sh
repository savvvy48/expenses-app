#!/bin/bash

# Define ADB path
ADB="$HOME/Library/Android/sdk/platform-tools/adb"

echo "🚀 Launching Daily Expenses..."

# Check if emulator is already running
if "$ADB" devices | grep -q "emulator-"; then
    echo "✅ Active emulator detected."
else
    echo "📱 No active emulator found. Launching Medium_Phone_API_36.1..."
    flutter emulators --launch Medium_Phone_API_36.1
    
    echo "hourglass_flowing_sand Waiting for emulator to be ready..."
    "$ADB" wait-for-device
    echo "✅ Emulator connected!"
fi

echo "🔨 Building and Installing App..."
echo "ℹ️  Using 'flutter run' in debug mode."
echo "ℹ️  Hot Reload: Press 'r' in this terminal."
echo "ℹ️  Quit: Press 'q'."

flutter run -d emulator-5554
