#!/bin/bash

# Function to modify the dylib ID, change /opt/local/lib to @loader_path, and sign the dylib
process_dylib() {
    local dylib="$1"
    
    # Get the current ID of the dylib
    local current_id=$(otool -D "$dylib" | tail -n 1)
    
    # Change the ID to @rpath/filename
    local new_id="@rpath/$(basename "$dylib")"
    install_name_tool -id "$new_id" "$dylib"
    echo "Changed ID of $dylib to $new_id"
    
    # Change library paths from /opt/local/lib to @loader_path
    for dep in $(otool -L "$dylib" | grep '/opt/local/lib' | awk '{print $1}'); do
        new_dep="@loader_path/$(basename "$dep")"
        install_name_tool -change "$dep" "$new_dep" "$dylib"
        echo "Updated dependency: $dep -> $new_dep"
    done
    
    # Sign the dylib with an ad-hoc signature
    codesign --force --sign - "$dylib"
    echo "Signed $dylib with an ad-hoc signature"
}

# Find and process all dylibs
find . -type f -name "*.dylib" | while read -r dylib; do
    process_dylib "$dylib"
done

echo "Finished processing all dylib files"
