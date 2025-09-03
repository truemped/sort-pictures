#!/bin/bash

# Script to create sample test images with various formats and dates
# Used by tests to create realistic test scenarios

create_sample_images() {
    local base_dir="$1"
    
    mkdir -p "$base_dir"/{mixed,nested/vacation,nested/work/projects}
    
    # JPG files
    echo "JPEG dummy content" > "$base_dir/IMG_001.jpg"
    echo "JPEG dummy content" > "$base_dir/photo.JPG"
    echo "PNG dummy content" > "$base_dir/screenshot.png"
    echo "GIF dummy content" > "$base_dir/animated.gif"
    
    # RAW files
    echo "CR2 dummy content" > "$base_dir/DSC_001.CR2"
    echo "NEF dummy content" > "$base_dir/DSC_002.nef"
    echo "ARW dummy content" > "$base_dir/Sony_001.arw"
    echo "DNG dummy content" > "$base_dir/Adobe_001.dng"
    
    # Mixed directory
    echo "JPEG mixed" > "$base_dir/mixed/vacation_1.jpg"
    echo "CR2 mixed" > "$base_dir/mixed/vacation_1.cr2"
    echo "PNG mixed" > "$base_dir/mixed/landscape.png"
    echo "NEF mixed" > "$base_dir/mixed/portrait.NEF"
    
    # Nested structure
    echo "Beach photo" > "$base_dir/nested/vacation/beach.jpg"
    echo "Sunset RAW" > "$base_dir/nested/vacation/sunset.CR2"
    echo "Meeting photo" > "$base_dir/nested/work/meeting.jpg"
    echo "Project file" > "$base_dir/nested/work/projects/diagram.png"
    
    # Non-image files (should be ignored)
    echo "Text document" > "$base_dir/readme.txt"
    echo "Binary data" > "$base_dir/data.bin"
    echo "Config file" > "$base_dir/nested/config.conf"
    
    # Set realistic modification times
    touch -t 202401150800 "$base_dir/IMG_001.jpg"
    touch -t 202402200900 "$base_dir/photo.JPG"
    touch -t 202403051000 "$base_dir/screenshot.png"
    touch -t 202403101100 "$base_dir/animated.gif"
    
    touch -t 202401150815 "$base_dir/DSC_001.CR2"
    touch -t 202402200915 "$base_dir/DSC_002.nef"
    touch -t 202403121200 "$base_dir/Sony_001.arw"
    touch -t 202403151300 "$base_dir/Adobe_001.dng"
    
    touch -t 202406101400 "$base_dir/mixed/vacation_1.jpg"
    touch -t 202406101405 "$base_dir/mixed/vacation_1.cr2"
    touch -t 202406151500 "$base_dir/mixed/landscape.png"
    touch -t 202406201600 "$base_dir/mixed/portrait.NEF"
    
    touch -t 202407010700 "$base_dir/nested/vacation/beach.jpg"
    touch -t 202407010705 "$base_dir/nested/vacation/sunset.CR2"
    touch -t 202408150800 "$base_dir/nested/work/meeting.jpg"
    touch -t 202409010900 "$base_dir/nested/work/projects/diagram.png"
}

# Create images with duplicate names (for collision testing)
create_duplicate_test_images() {
    local base_dir="$1"
    
    mkdir -p "$base_dir"/{dir1,dir2,dir3}
    
    # Same filename, different dates
    echo "Photo 1" > "$base_dir/dir1/photo.jpg"
    echo "Photo 2" > "$base_dir/dir2/photo.jpg"
    echo "Photo 3" > "$base_dir/dir3/photo.jpg"
    
    touch -t 202403150800 "$base_dir/dir1/photo.jpg"
    touch -t 202403150900 "$base_dir/dir2/photo.jpg"
    touch -t 202403151000 "$base_dir/dir3/photo.jpg"
    
    # Same filename, same date (collision test)
    echo "Same date 1" > "$base_dir/dir1/collision.jpg"
    echo "Same date 2" > "$base_dir/dir2/collision.jpg"
    
    touch -t 202403200800 "$base_dir/dir1/collision.jpg"
    touch -t 202403200800 "$base_dir/dir2/collision.jpg"
}

# Create large collection for performance testing
create_large_test_collection() {
    local base_dir="$1"
    local count="${2:-100}"
    
    mkdir -p "$base_dir"
    
    for i in $(seq 1 "$count"); do
        # Mix of JPG and RAW files
        if [ $((i % 2)) -eq 0 ]; then
            echo "JPG file $i" > "$base_dir/img_$(printf "%04d" $i).jpg"
            # Random date in 2024
            local month=$(( (i % 12) + 1 ))
            local day=$(( (i % 28) + 1 ))
            touch -t "2024$(printf "%02d%02d" $month $day)0800" "$base_dir/img_$(printf "%04d" $i).jpg"
        else
            echo "RAW file $i" > "$base_dir/raw_$(printf "%04d" $i).cr2"
            local month=$(( (i % 12) + 1 ))
            local day=$(( (i % 28) + 1 ))
            touch -t "2024$(printf "%02d%02d" $month $day)0900" "$base_dir/raw_$(printf "%04d" $i).cr2"
        fi
    done
    
    echo "Created $count test files in $base_dir"
}

# Export functions for use in tests
export -f create_sample_images
export -f create_duplicate_test_images
export -f create_large_test_collection