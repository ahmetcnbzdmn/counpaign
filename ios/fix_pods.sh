#!/bin/bash
# Fix for Xcode 26.2 compatibility issues
# This script removes the problematic -GCC_WARN_INHIBIT_ALL_WARNINGS flag

echo "🔧 Fixing Pods project for Xcode 26.2 compatibility..."

# Remove -GCC_WARN_INHIBIT_ALL_WARNINGS from Pods project
sed -i '' 's/-GCC_WARN_INHIBIT_ALL_WARNINGS//g' Pods/Pods.xcodeproj/project.pbxproj

echo "✅ Pods project fixed!"
