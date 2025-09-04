#!/usr/bin/env bats

# Integration tests for sort-pictures.sh

load 'test_helper'

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "script shows help when --help is used" {
    run "$SORT_PICTURES_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
    [[ "$output" =~ "EXAMPLES:" ]]
}

@test "script shows error for missing source directory" {
    run "$SORT_PICTURES_SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "SOURCE_DIRECTORY is required" ]]
}

@test "script shows error for non-existent source directory" {
    run "$SORT_PICTURES_SCRIPT" "/non/existent/directory"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "SOURCE_DIRECTORY does not exist" ]]
}

@test "script validates parallel jobs argument" {
    # Valid job count
    run "$SORT_PICTURES_SCRIPT" --jobs 4 --dry-run "$TEST_SOURCE_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Parallel jobs: 4" ]]

    # Invalid job count (too high)
    run "$SORT_PICTURES_SCRIPT" --jobs 20 "$TEST_SOURCE_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a number between 1 and 16" ]]

    # Invalid job count (zero)
    run "$SORT_PICTURES_SCRIPT" --jobs 0 "$TEST_SOURCE_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a number between 1 and 16" ]]
}

@test "script validates separate formats arguments" {
    # Missing JPG directory
    run "$SORT_PICTURES_SCRIPT" --separate-formats "$TEST_SOURCE_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "--jpg-dir is required" ]]

    # Missing RAW directory
    run "$SORT_PICTURES_SCRIPT" --separate-formats --jpg-dir "$TEST_JPG_DIR" "$TEST_SOURCE_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "--raw-dir is required" ]]
}

@test "dry run mode processes files without moving them" {
    create_test_image "test.jpg" "2024-03-15"
    create_test_image "photo.cr2" "2024-03-16"

    run "$SORT_PICTURES_SCRIPT" --dry-run "$TEST_SOURCE_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN MODE" ]]
    [[ "$output" =~ "Processing complete" ]]

    # Files should still be in original location
    [ -f "$TEST_SOURCE_DIR/test.jpg" ]
    [ -f "$TEST_SOURCE_DIR/photo.cr2" ]
}

@test "basic sorting moves files to year/month/day structure" {
    # Create test files with known dates
    create_test_image "img1.jpg" "2024-03-15"
    create_test_image "img2.png" "2024-04-20"

    run "$SORT_PICTURES_SCRIPT" "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Processing complete" ]]

    # Check files were moved to correct date structure
    [ -f "$TEST_DEST_DIR/2024/03/15/img1.jpg" ]
    [ -f "$TEST_DEST_DIR/2024/04/20/img2.png" ]

    # Original files should be gone
    [ ! -f "$TEST_SOURCE_DIR/img1.jpg" ]
    [ ! -f "$TEST_SOURCE_DIR/img2.png" ]
}

@test "separate formats mode sorts JPG and RAW to different directories" {
    create_test_image "photo.jpg" "2024-03-15"
    create_test_image "photo.cr2" "2024-03-15"
    create_test_image "image.png" "2024-03-16"
    create_test_image "raw.nef" "2024-03-16"

    run "$SORT_PICTURES_SCRIPT" --separate-formats \
        --jpg-dir "$TEST_JPG_DIR" \
        --raw-dir "$TEST_RAW_DIR" \
        "$TEST_SOURCE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Format separation: ENABLED" ]]

    # Check JPG files went to JPG directory
    [ -f "$TEST_JPG_DIR/2024/03/15/photo.jpg" ]
    [ -f "$TEST_JPG_DIR/2024/03/16/image.png" ]

    # Check RAW files went to RAW directory
    [ -f "$TEST_RAW_DIR/2024/03/15/photo.cr2" ]
    [ -f "$TEST_RAW_DIR/2024/03/16/raw.nef" ]
}

@test "script handles nested directory structures" {
    create_nested_test_structure

    run "$SORT_PICTURES_SCRIPT" "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]

    # Check that nested files were processed
    [ -f "$TEST_DEST_DIR/2024/03/15/IMG_001.jpg" ]
    [ -f "$TEST_DEST_DIR/2024/03/19/meeting.JPG" ]

    # Non-image files should be skipped
    [ -f "$TEST_SOURCE_DIR/work/projects/document.pdf" ]
}

@test "script handles duplicate filenames by renaming" {
    # Create two files with same name but different dates
    create_test_image "photo.jpg" "2024-03-15"
    mkdir -p "$TEST_SOURCE_DIR/subdir"
    create_test_image "subdir/photo.jpg" "2024-03-15"

    run "$SORT_PICTURES_SCRIPT" "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]

    # Should have both files, one renamed
    [ -f "$TEST_DEST_DIR/2024/03/15/photo.jpg" ]
    [ -f "$TEST_DEST_DIR/2024/03/15/photo_1.jpg" ]
}

@test "parallel processing works with multiple jobs" {
    create_test_image "img1.jpg" "2024-03-15"
    create_test_image "img2.png" "2024-03-16"
    create_test_image "img3.cr2" "2024-03-17"

    run "$SORT_PICTURES_SCRIPT" --jobs 2 "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Using 2 parallel jobs" ]]

    # Files should be moved correctly
    [ -f "$TEST_DEST_DIR/2024/03/15/img1.jpg" ]
    [ -f "$TEST_DEST_DIR/2024/03/16/img2.png" ]
    [ -f "$TEST_DEST_DIR/2024/03/17/img3.cr2" ]
}

@test "verbose mode provides detailed output" {
    create_test_image "test.jpg" "2024-03-15"

    run "$SORT_PICTURES_SCRIPT" --verbose --dry-run "$TEST_SOURCE_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Processing:" ]]
    [[ "$output" =~ "exiftool" ]]
}

@test "script skips non-image files" {
    create_test_image "photo.jpg" "2024-03-15"
    echo "text content" > "$TEST_SOURCE_DIR/readme.txt"
    echo "binary data" > "$TEST_SOURCE_DIR/data.bin"

    run "$SORT_PICTURES_SCRIPT" --verbose "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]

    # Image file should be moved
    [ -f "$TEST_DEST_DIR/2024/03/15/photo.jpg" ]

    # Non-image files should remain
    [ -f "$TEST_SOURCE_DIR/readme.txt" ]
    [ -f "$TEST_SOURCE_DIR/data.bin" ]
}

@test "configuration is displayed correctly" {
    run "$SORT_PICTURES_SCRIPT" --dry-run --verbose \
        --separate-formats --jpg-dir "$TEST_JPG_DIR" --raw-dir "$TEST_RAW_DIR" \
        --jobs 4 "$TEST_SOURCE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Configuration:" ]]
    [[ "$output" =~ "Format separation: ENABLED" ]]
    [[ "$output" =~ "Parallel jobs: 4" ]]
    [[ "$output" =~ "Dry run: true" ]]
    [[ "$output" =~ "Verbose: true" ]]
}

@test "@eaDir handling can be enabled" {
    run "$SORT_PICTURES_SCRIPT" --handle-eadir --dry-run "$TEST_SOURCE_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Handle @eaDir: true" ]]
}

@test "@eaDir files are moved with photos when enabled" {
    # Create test image and @eaDir structure
    create_test_image "photo.jpg" "2024-03-15"
    mkdir -p "$TEST_SOURCE_DIR/@eaDir"
    echo "thumbnail data" > "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg"
    echo "thumbnail data" > "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_M_photo.jpg"

    run "$SORT_PICTURES_SCRIPT" --handle-eadir "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]

    # Check that photo was moved
    [ -f "$TEST_DEST_DIR/2024/03/15/photo.jpg" ]

    # Check that @eaDir files were moved
    [ -f "$TEST_DEST_DIR/2024/03/15/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg" ]
    [ -f "$TEST_DEST_DIR/2024/03/15/@eaDir/SYNOPHOTO_THUMB_M_photo.jpg" ]

    # Original @eaDir files should be gone
    [ ! -f "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg" ]
    [ ! -f "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_M_photo.jpg" ]
}

@test "@eaDir files are ignored when option is disabled" {
    # Create test image and @eaDir structure
    create_test_image "photo.jpg" "2024-03-15"
    mkdir -p "$TEST_SOURCE_DIR/@eaDir"
    echo "thumbnail data" > "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg"

    run "$SORT_PICTURES_SCRIPT" "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]

    # Check that photo was moved
    [ -f "$TEST_DEST_DIR/2024/03/15/photo.jpg" ]

    # Check that @eaDir files were NOT moved
    [ ! -f "$TEST_DEST_DIR/2024/03/15/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg" ]

    # Original @eaDir files should still exist
    [ -f "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg" ]
}

@test "@eaDir dry run shows what would be moved" {
    create_test_image "photo.jpg" "2024-03-15"
    mkdir -p "$TEST_SOURCE_DIR/@eaDir"
    echo "thumbnail data" > "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg"

    run "$SORT_PICTURES_SCRIPT" --handle-eadir --dry-run --verbose "$TEST_SOURCE_DIR" "$TEST_DEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Would create @eaDir directory" ]]
    [[ "$output" =~ "Would move @eaDir file" ]]

    # Files should not actually be moved in dry run
    [ ! -f "$TEST_DEST_DIR/2024/03/15/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg" ]
    [ -f "$TEST_SOURCE_DIR/@eaDir/SYNOPHOTO_THUMB_S_photo.jpg" ]
}
