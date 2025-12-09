#!/bin/bash
# Fix hardcoded messages in all modules

find modules -name "*.bash" | while read -r file; do
    echo "Processing $file..."
    
    # Replace hardcoded error messages with log_error calls
    sed -i 's/echo "\[ERROR\] \(.*\)"/log_error "\1"/g' "$file"
    
    # Replace hardcoded warning messages with log_warning calls  
    sed -i 's/echo "\[WARNING\] \(.*\)"/log_warning "\1"/g' "$file"
    
    # Replace hardcoded info messages with log_info calls
    sed -i 's/echo "\[INFO\] \(.*\)"/log_info "\1"/g' "$file"
    
    # Replace hardcoded success messages with log_success calls
    sed -i 's/echo "\[SUCCESS\] \(.*\)"/log_success "\1"/g' "$file"
    
    # Fix stderr redirects
    sed -i 's/log_error "\(.*\)">&2/log_error "\1"/g' "$file"
    sed -i 's/log_warning "\(.*\)">&2/log_warning "\1"/g' "$file"
    sed -i 's/log_info "\(.*\)">&2/log_info "\1"/g' "$file"
    sed -i 's/log_success "\(.*\)">&2/log_success "\1"/g' "$file"
done

echo "i18n fixes completed!"
