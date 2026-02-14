#!/bin/bash

# 1. Open the project in Android Studio
echo "Opening Daily Expenses in Android Studio..."
open -a "Android Studio" .

# 2. Launch the Android Emulator immediately
echo "Launching Android Emulator (Medium_Phone_API_36.1)..."
flutter emulators --launch Medium_Phone_API_36.1

echo "✅ Android Studio opened and Emulator launching."
echo "👉 Once the emulator boots, press the Run button (▶) in Android Studio to start the app."
