#!/bin/bash

# Create a new remote URL
echo "Setting up remote repository..."
git remote remove origin || true
git remote add origin https://github.com/graymount/TomatoFocus.git

# Push to GitHub
echo "Pushing code to GitHub..."
git push -u origin main

echo "Push completed!" 