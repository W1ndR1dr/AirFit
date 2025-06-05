#\!/bin/bash
# Check for duplicate entries in project.yml

echo "Checking for duplicate entries in project.yml..."

# Find duplicate file entries
duplicates=$(grep -E "\.swift$" project.yml | sort | uniq -d)

if [ -z "$duplicates" ]; then
    echo "✅ No duplicate entries found in project.yml"
else
    echo "⚠️  Found duplicate entries:"
    echo "$duplicates"
    echo ""
    echo "Line numbers for duplicates:"
    while IFS= read -r file; do
        echo "  $file appears at lines:"
        grep -n "$file" project.yml | awk -F: '{print "    Line " $1}'
    done <<< "$duplicates"
fi

# Check for duplicate Swift files in filesystem
echo ""
echo "Checking for duplicate Swift files in filesystem..."
duplicate_files=$(find AirFit -name "*.swift" -type f | xargs -I {} basename {} | sort | uniq -d)

if [ -z "$duplicate_files" ]; then
    echo "✅ No duplicate Swift files found in filesystem"
else
    echo "⚠️  Found files with duplicate names:"
    for filename in $duplicate_files; do
        echo "  $filename found at:"
        find AirFit -name "$filename" -type f | awk '{print "    " $0}'
    done
fi
