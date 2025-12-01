#!/bin/bash
# Script to replace all "Misago" references with "BenjForum" in the BenjForum project

echo "Starting replacement of 'Misago' with 'BenjForum'..."

cd /root/benjforum

# Backup original files
echo "Creating backups..."
find . -name "*.py" -o -name "*.html" -o -name "*.js" -o -name "*.css" -o -name "*.po" | head -5 | xargs -I {} cp {} {}.backup

# Replace in Python files (excluding backups and git)
echo "Replacing in Python files..."
find . -name "*.py" -not -path "./.git/*" -not -name "*.backup" -exec sed -i 's/Misago/BenjForum/g' {} +

# Replace in HTML templates (excluding backups and git)
echo "Replacing in HTML templates..."
find . -name "*.html" -not -path "./.git/*" -not -name "*.backup" -exec sed -i 's/Misago/BenjForum/g' {} +

# Replace in JavaScript files
echo "Replacing in JavaScript files..."
find . -name "*.js" -not -path "./.git/*" -not -name "*.backup" -exec sed -i 's/Misago/BenjForum/g' {} +

# Replace in CSS files
echo "Replacing in CSS files..."
find . -name "*.css" -not -path "./.git/*" -not -name "*.backup" -exec sed -i 's/Misago/BenjForum/g' {} +

# Replace in translation files
echo "Replacing in translation files..."
find . -name "*.po" -not -path "./.git/*" -not -name "*.backup" -exec sed -i 's/Misago/BenjForum/g' {} +

# Update README.md specifically
echo "Updating README.md..."
sed -i 's/Misago/BenjForum/g' README.md

# Update title and meta tags in index.html if exists
if [ -f "frontend/index.html" ]; then
    echo "Updating frontend/index.html..."
    sed -i 's/Misago/BenjForum/g' frontend/index.html
fi

echo "Replacement completed!"

# Show some examples of what was changed
echo "Examples of replacements made:"
grep -r "BenjForum" --include="*.py" . | head -5