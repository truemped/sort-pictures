#!/usr/bin/env bats

# Unit tests for sort-pictures.sh core functions

load 'test_helper'

setup() {
    setup_test_dir
    setup_script_functions
}

teardown() {
    teardown_test_dir
}

@test "is_image_file: recognizes JPG files" {
    run is_image_file "test.jpg"
    [ "$status" -eq 0 ]
    
    run is_image_file "test.JPG"
    [ "$status" -eq 0 ]
    
    run is_image_file "test.jpeg"
    [ "$status" -eq 0 ]
}

@test "is_image_file: recognizes PNG files" {
    run is_image_file "test.png"
    [ "$status" -eq 0 ]
    
    run is_image_file "test.PNG"
    [ "$status" -eq 0 ]
}

@test "is_image_file: recognizes RAW files" {
    run is_image_file "test.cr2"
    [ "$status" -eq 0 ]
    
    run is_image_file "test.NEF"
    [ "$status" -eq 0 ]
    
    run is_image_file "test.arw"
    [ "$status" -eq 0 ]
    
    run is_image_file "test.dng"
    [ "$status" -eq 0 ]
}

@test "is_image_file: rejects non-image files" {
    run is_image_file "test.txt"
    [ "$status" -eq 1 ]
    
    run is_image_file "test.pdf"
    [ "$status" -eq 1 ]
    
    run is_image_file "test.doc"
    [ "$status" -eq 1 ]
}

@test "is_jpg_file: correctly identifies JPG formats" {
    run is_jpg_file "photo.jpg"
    [ "$status" -eq 0 ]
    
    run is_jpg_file "photo.PNG"
    [ "$status" -eq 0 ]
    
    run is_jpg_file "photo.gif"
    [ "$status" -eq 0 ]
    
    run is_jpg_file "photo.bmp"
    [ "$status" -eq 0 ]
}

@test "is_jpg_file: rejects RAW formats" {
    run is_jpg_file "photo.cr2"
    [ "$status" -eq 1 ]
    
    run is_jpg_file "photo.nef"
    [ "$status" -eq 1 ]
}

@test "is_raw_file: correctly identifies RAW formats" {
    run is_raw_file "photo.cr2"
    [ "$status" -eq 0 ]
    
    run is_raw_file "photo.NEF"
    [ "$status" -eq 0 ]
    
    run is_raw_file "photo.arw"
    [ "$status" -eq 0 ]
    
    run is_raw_file "photo.dng"
    [ "$status" -eq 0 ]
    
    run is_raw_file "photo.cr3"
    [ "$status" -eq 0 ]
}

@test "is_raw_file: rejects JPG formats" {
    run is_raw_file "photo.jpg"
    [ "$status" -eq 1 ]
    
    run is_raw_file "photo.png"
    [ "$status" -eq 1 ]
}

@test "get_image_date: falls back to stat when exiftool unavailable" {
    # Create a test file with known modification time
    local test_file="${TEST_TEMP_DIR}/test.jpg"
    echo "dummy" > "$test_file"
    touch -t 202403150800 "$test_file"  # March 15, 2024, 08:00
    
    # Ensure exiftool is not available
    EXIFTOOL_AVAILABLE=false
    
    run get_image_date "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" =~ 2024:03:15 ]]
}

@test "create_directory: creates directory in normal mode" {
    DRY_RUN=false
    local test_dir="${TEST_TEMP_DIR}/new_dir"
    
    run create_directory "$test_dir"
    [ "$status" -eq 0 ]
    [ -d "$test_dir" ]
}

@test "create_directory: does not create directory in dry run mode" {
    DRY_RUN=true
    local test_dir="${TEST_TEMP_DIR}/dry_run_dir"
    
    run create_directory "$test_dir"
    [ "$status" -eq 0 ]
    [ ! -d "$test_dir" ]
    [[ "$output" =~ "DRY RUN" ]]
}

@test "log_verbose: outputs when VERBOSE is true" {
    VERBOSE=true
    
    run log_verbose "test message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test message" ]]
}

@test "log_verbose: does not output when VERBOSE is false" {
    VERBOSE=false
    
    run log_verbose "test message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}