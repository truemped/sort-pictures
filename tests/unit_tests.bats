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

@test "find_eadir_files: returns empty when @eaDir doesn't exist" {
    local test_file="$TEST_TEMP_DIR/photo.jpg"
    echo "dummy" > "$test_file"

    run find_eadir_files "$test_file"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "find_eadir_files: finds related metadata files" {
    local test_file="$TEST_TEMP_DIR/photo.jpg"
    echo "dummy" > "$test_file"

    # Create @eaDir with metadata files
    mkdir -p "$TEST_TEMP_DIR/@eaDir"
    echo "thumb" > "$TEST_TEMP_DIR/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg"
    echo "thumb" > "$TEST_TEMP_DIR/@eaDir/SYNOPHOTO_THUMB_M_photo.jpg"
    echo "unrelated" > "$TEST_TEMP_DIR/@eaDir/other_file.jpg"

    run find_eadir_files "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SYNOPHOTO_THUMB_S_photo.jpg" ]]
    [[ "$output" =~ "SYNOPHOTO_THUMB_M_photo.jpg" ]]
    [[ ! "$output" =~ "other_file.jpg" ]]
}

@test "move_eadir_files: skips when HANDLE_EADIR is false" {
    HANDLE_EADIR=false
    DRY_RUN=false

    local source_file="$TEST_TEMP_DIR/source/photo.jpg"
    local dest_file="$TEST_TEMP_DIR/dest/photo.jpg"
    mkdir -p "$(dirname "$source_file")" "$(dirname "$dest_file")"
    echo "dummy" > "$source_file"

    run move_eadir_files "$source_file" "$dest_file"
    [ "$status" -eq 0 ]
}

@test "move_eadir_files: works in dry run mode" {
    HANDLE_EADIR=true
    DRY_RUN=true
    VERBOSE=false

    local source_file="$TEST_TEMP_DIR/source/photo.jpg"
    local dest_file="$TEST_TEMP_DIR/dest/photo.jpg"
    mkdir -p "$(dirname "$source_file")" "$(dirname "$dest_file")"
    mkdir -p "$TEST_TEMP_DIR/source/@eaDir"
    echo "dummy" > "$source_file"
    echo "thumb" > "$TEST_TEMP_DIR/source/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg"

    run move_eadir_files "$source_file" "$dest_file"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
}
