#!/bin/bash

# Package Code Script
# Creates two zip files: lambda_package.zip and dependencies.zip

set -e  # Exit on any error

echo "🚀 Starting packaging process..."

# Clean up any existing artifacts
echo "🧹 Cleaning up existing artifacts..."
rm -f lambda_package.zip dependencies.zip requirements.txt
rm -rf python/

# Package Lambda code
echo "📦 Packaging Lambda code..."
zip -r lambda_package.zip src/
echo "✅ Created lambda_package.zip"

# Package Python dependencies
echo "📦 Packaging Python dependencies..."

# Check if pipenv is available
if ! command -v pipenv &> /dev/null; then
    echo "⚠️  Pipenv not found. Installing pipenv..."
    python -m pip install --upgrade pip
    pip install --user pipenv
fi

if [ ! -f Pipfile ]; then
  echo "❌ Pipfile not found in $(pwd). Please ensure it exists."
  exit 1
fi

# Generate requirements.txt from Pipfile
echo "📋 Generating requirements.txt from Pipfile..."
pipenv requirements > requirements.txt

# Install dependencies to python/ directory
echo "📥 Installing dependencies to python/ directory..."
pip install -r requirements.txt -t python/

# Check if python/ directory is empty
if [ -z "$(ls -A python/)" ]; then
  echo "❌ No dependencies were installed to python/. The dependencies.zip would be empty!"
  # exit 1
fi

# Package dependencies
echo "🗜️  Creating dependencies.zip..."
zip -r dependencies.zip python/
echo "✅ Created dependencies.zip"

# Clean up temporary files
echo "🧹 Cleaning up temporary files..."
rm -f requirements.txt
rm -rf python/

echo "🎉 Packaging complete!"
echo "📁 Generated files:"
echo "   - lambda_package.zip"
echo "   - dependencies.zip"

ls -ltra
ls -ltra python/ || echo "No python/ directory to list."