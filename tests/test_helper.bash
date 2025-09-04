#!/usr/bin/env bash

# Test helper functions for sort-pictures.sh tests

# Set up test environment
export BATS_TEST_DIRNAME="${BATS_TEST_DIRNAME}"
export SORT_PICTURES_SCRIPT="${BATS_TEST_DIRNAME}/../sort-pictures.sh"

# Source the script functions for unit testing
setup_script_functions() {
    # Source the script to get access to functions without executing main
    # The script now only runs main when executed directly
    source "${SORT_PICTURES_SCRIPT}"
    
    # Initialize global variables that would normally be set by argument parsing
    DRY_RUN=false
    VERBOSE=false
    SOURCE_DIR=""
    DEST_DIR=""
    JPG_DIR=""
    RAW_DIR=""
    SEPARATE_FORMATS=false
    PARALLEL_JOBS=1
    HANDLE_EADIR=false
    EXIFTOOL_AVAILABLE=false
    TEMP_DIR=""
}

# Create a temporary directory for test files
setup_test_dir() {
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_SOURCE_DIR="${TEST_TEMP_DIR}/source"
    export TEST_DEST_DIR="${TEST_TEMP_DIR}/dest"
    export TEST_JPG_DIR="${TEST_TEMP_DIR}/jpg"
    export TEST_RAW_DIR="${TEST_TEMP_DIR}/raw"
    
    mkdir -p "$TEST_SOURCE_DIR" "$TEST_DEST_DIR" "$TEST_JPG_DIR" "$TEST_RAW_DIR"
}

# Clean up temporary directory
teardown_test_dir() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create test image files with specific dates
create_test_image() {
    local filename="$1"
    local date="$2"  # Format: YYYY-MM-DD
    local filepath="${TEST_SOURCE_DIR}/${filename}"
    
    # Create dummy file
    echo "dummy image content" > "$filepath"
    
    # Set modification time if date provided
    if [[ -n "$date" ]]; then
        touch -t "${date//[-]/}0000" "$filepath"
    fi
    
    # Return filepath only if requested (avoid polluting test output)
    # echo "$filepath"
}

# Create nested directory structure with test files
create_nested_test_structure() {
    mkdir -p "${TEST_SOURCE_DIR}/vacation/beach"
    mkdir -p "${TEST_SOURCE_DIR}/work/projects"
    
    create_test_image "IMG_001.jpg" "2024-03-15"
    create_test_image "vacation/sunset.CR2" "2024-03-16"
    create_test_image "vacation/beach/photo.NEF" "2024-03-17"
    create_test_image "work/projects/document.pdf" "2024-03-18"
    create_test_image "work/meeting.JPG" "2024-03-19"
}

# Assert directory exists
assert_directory_exists() {
    local dir="$1"
    [[ -d "$dir" ]] || {
        echo "Expected directory to exist: $dir"
        return 1
    }
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo "Expected file to exist: $file"
        return 1
    }
}

# Assert file does not exist
assert_file_not_exists() {
    local file="$1"
    [[ ! -f "$file" ]] || {
        echo "Expected file to not exist: $file"
        return 1
    }
}

# Count files in directory
count_files_in_dir() {
    local dir="$1"
    find "$dir" -type f | wc -l | tr -d ' '
}

# Mock exiftool for testing
mock_exiftool() {
    local exiftool_script="${TEST_TEMP_DIR}/exiftool"
    cat > "$exiftool_script" << 'EOF'
#!/bin/bash
# Mock exiftool for testing
case "$1" in
    *IMG_001.jpg) echo "2024:03:15" ;;
    *sunset.CR2) echo "2024:03:16" ;;
    *photo.NEF) echo "2024:03:17" ;;
    *meeting.JPG) echo "2024:03:19" ;;
    *) echo "2024:01:01" ;;
esac
EOF
    chmod +x "$exiftool_script"
    export PATH="${TEST_TEMP_DIR}:$PATH"
}

# Setup function called before each test
setup() {
    setup_test_dir
}

# Teardown function called after each test
teardown() {
    teardown_test_dir
}