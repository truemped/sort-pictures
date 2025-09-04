#!/bin/bash

# Sort Pictures Script for Synology DSM
# Organizes pictures into $year/$month/$day folder structure
# Compatible with DSM 7.1.1-42962 Update 9

set -euo pipefail

# Global variables
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

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS] SOURCE_DIRECTORY [DESTINATION_DIRECTORY]
       $0 [OPTIONS] --separate-formats SOURCE_DIRECTORY --jpg-dir JPG_BASE --raw-dir RAW_BASE

Sort pictures from SOURCE_DIRECTORY into organized folder structure (year/month/day).
If DESTINATION_DIRECTORY is not provided, files will be organized within SOURCE_DIRECTORY.

With --separate-formats, JPG and RAW files are sorted into separate base directories:
  JPG files -> JPG_BASE/year/month/day
  RAW files -> RAW_BASE/year/month/day

OPTIONS:
    -d, --dry-run       Show what would be done without making changes
    -v, --verbose       Enable verbose output
    -s, --separate-formats  Enable separate sorting for JPG and RAW files
    -j, --jobs N        Number of parallel jobs (default: 1, max: 16)
    -e, --handle-eadir  Move Synology @eaDir metadata files with photos
    --jpg-dir DIR       Base directory for JPG files (requires --separate-formats)
    --raw-dir DIR       Base directory for RAW files (requires --separate-formats)
    -h, --help         Show this help message

EXAMPLES:
    # Basic usage
    $0 /volume1/photos
    $0 -d /volume1/photos /volume1/sorted_photos

    # Separate JPG and RAW files
    $0 --separate-formats --jpg-dir /volume1/JPG --raw-dir /volume1/RAW /volume1/photos
    $0 -s --jpg-dir /volume1/sorted/JPG --raw-dir /volume1/sorted/RAW -d -v /volume1/unsorted

    # Parallel processing with 4 jobs
    $0 --jobs 4 -d -v /volume1/photos
    $0 -j 8 -s --jpg-dir /volume1/JPG --raw-dir /volume1/RAW /volume1/large_collection

    # Handle Synology @eaDir metadata
    $0 --handle-eadir -d -v /volume1/photos
    $0 -e -s --jpg-dir /volume1/JPG --raw-dir /volume1/RAW /volume1/synology_photos

EOF
}

# Logging functions
log_info() {
    echo "[INFO] $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[VERBOSE] $*" >&2
    fi
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Check if exiftool is available
check_exiftool() {
    if command -v exiftool >/dev/null 2>&1; then
        EXIFTOOL_AVAILABLE=true
        log_verbose "exiftool is available"
    else
        log_verbose "exiftool not available, using file modification time"
    fi
}

# Extract date from image using exiftool or stat
get_image_date() {
    local file="$1"
    local date_str=""

    if [[ "$EXIFTOOL_AVAILABLE" == "true" ]]; then
        # Try to get date from EXIF data
        date_str=$(exiftool -DateTimeOriginal -CreateDate -ModifyDate -d "%Y:%m:%d" -S -s "$file" 2>/dev/null | head -n1 || true)
    fi

    # Fallback to file modification time
    if [[ -z "$date_str" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS stat format
            date_str=$(stat -f "%Sm" -t "%Y:%m:%d" "$file" 2>/dev/null || true)
        else
            # Linux/Synology stat format
            date_str=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1 | tr '-' ':' || true)
        fi
    fi

    echo "$date_str"
}

# Check if file is an image and determine type
is_image_file() {
    local file="$1"
    local extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    case "$extension" in
        jpg|jpeg|png|gif|bmp|tiff|tif)
            return 0
            ;;
        raw|cr2|nef|arw|dng|orf|rw2|cr3|raf|srw|pef|x3f|rwl|iiq|3fr|fff|mef|mos|mrw|ptx|dcr|kdc|srf|sr2)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Determine if file is JPG format
is_jpg_file() {
    local file="$1"
    local extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    case "$extension" in
        jpg|jpeg|png|gif|bmp|tiff|tif)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Determine if file is RAW format
is_raw_file() {
    local file="$1"
    local extension="${file##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    case "$extension" in
        raw|cr2|nef|arw|dng|orf|rw2|cr3|raf|srw|pef|x3f|rwl|iiq|3fr|fff|mef|mos|mrw|ptx|dcr|kdc|srf|sr2)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Find @eaDir metadata files for a given image file
find_eadir_files() {
    local image_file="$1"
    local image_dir
    local image_name
    local eadir_path

    image_dir=$(dirname "$image_file")
    image_name=$(basename "$image_file")
    eadir_path="$image_dir/@eaDir"

    # Check if @eaDir exists
    if [[ ! -d "$eadir_path" ]]; then
        return 0
    fi

    # Find all files related to this image in @eaDir
    # Synology creates files like:
    # - SYNOPHOTO_THUMB_S.jpg, SYNOPHOTO_THUMB_M.jpg, SYNOPHOTO_THUMB_L.jpg, SYNOPHOTO_THUMB_XL.jpg
    # - SYNOPHOTO_FILM_*.mp4 (for videos)
    # - Original filename with different extensions
    find "$eadir_path" -name "*${image_name%.*}*" 2>/dev/null || true
}

# Move @eaDir metadata files along with the image
move_eadir_files() {
    local source_image="$1"
    local dest_image="$2"
    local source_dir
    local dest_dir
    local source_eadir
    local dest_eadir

    if [[ "$HANDLE_EADIR" != "true" ]]; then
        return 0
    fi

    source_dir=$(dirname "$source_image")
    dest_dir=$(dirname "$dest_image")
    source_eadir="$source_dir/@eaDir"
    dest_eadir="$dest_dir/@eaDir"

    # Skip if source @eaDir doesn't exist
    if [[ ! -d "$source_eadir" ]]; then
        log_verbose "No @eaDir found for: $source_image"
        return 0
    fi

    # Find related metadata files
    local image_name
    image_name=$(basename "$source_image")
    local base_name="${image_name%.*}"

    # Create destination @eaDir if it doesn't exist
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create @eaDir directory: $dest_eadir"
    else
        if [[ ! -d "$dest_eadir" ]]; then
            mkdir -p "$dest_eadir"
            log_verbose "Created @eaDir directory: $dest_eadir"
        fi
    fi

    # Find and move all related metadata files
    while IFS= read -r -d '' metadata_file; do
        if [[ -f "$metadata_file" ]]; then
            local metadata_name
            metadata_name=$(basename "$metadata_file")
            local dest_metadata="$dest_eadir/$metadata_name"

            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY RUN] Would move @eaDir file: $metadata_file -> $dest_metadata"
            else
                if [[ ! -f "$dest_metadata" ]]; then
                    mv "$metadata_file" "$dest_metadata"
                    log_verbose "Moved @eaDir file: $metadata_file -> $dest_metadata"
                else
                    log_verbose "@eaDir file already exists at destination: $dest_metadata"
                fi
            fi
        fi
    done < <(find "$source_eadir" -name "*${base_name}*" -print0 2>/dev/null || true)

    # Clean up empty @eaDir directory if all files were moved
    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ -d "$source_eadir" ]] && [[ -z "$(ls -A "$source_eadir" 2>/dev/null)" ]]; then
            rmdir "$source_eadir" 2>/dev/null || true
            log_verbose "Removed empty @eaDir directory: $source_eadir"
        fi
    fi
}

# Create directory structure
create_directory() {
    local dir="$1"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create directory: $dir"
    else
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_verbose "Created directory: $dir"
        fi
    fi
}

# Move or copy file
move_file() {
    local source="$1"
    local destination="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would move: $source -> $destination"
    else
        if [[ ! -f "$destination" ]]; then
            mv "$source" "$destination"
            log_verbose "Moved: $source -> $destination"
        else
            log_error "Destination file already exists: $destination"
            # Create unique filename
            local counter=1
            local base="${destination%.*}"
            local ext="${destination##*.}"
            while [[ -f "${base}_${counter}.${ext}" ]]; do
                ((counter++))
            done
            local new_destination="${base}_${counter}.${ext}"
            mv "$source" "$new_destination"
            log_verbose "Moved with new name: $source -> $new_destination"
        fi
    fi
}

# Process a single image file
process_image() {
    local file="$1"
    local date_str
    local base_dir

    log_verbose "Processing: $file"

    # Get image date
    date_str=$(get_image_date "$file")

    if [[ -z "$date_str" ]]; then
        log_error "Could not determine date for: $file"
        return 1
    fi

    # Parse date components
    local year month day
    IFS=':' read -r year month day <<< "$date_str"

    if [[ -z "$year" || -z "$month" || -z "$day" ]]; then
        log_error "Invalid date format for: $file (got: $date_str)"
        return 1
    fi

    # Determine base directory based on file type and settings
    if [[ "$SEPARATE_FORMATS" == "true" ]]; then
        if is_jpg_file "$file"; then
            base_dir="$JPG_DIR"
            log_verbose "File classified as JPG: $file"
        elif is_raw_file "$file"; then
            base_dir="$RAW_DIR"
            log_verbose "File classified as RAW: $file"
        else
            log_error "Unknown image format for: $file"
            return 1
        fi
    else
        base_dir="$DEST_DIR"
    fi

    # Create destination path
    local dest_path="$base_dir/$year/$month/$day"
    local filename
    filename=$(basename "$file")
    local dest_file="$dest_path/$filename"

    # Create directory structure
    create_directory "$dest_path"

    # Move file
    if [[ "$file" != "$dest_file" ]]; then
        move_file "$file" "$dest_file"
        # Move associated @eaDir metadata files if enabled
        move_eadir_files "$file" "$dest_file"
    else
        log_verbose "File already in correct location: $file"
    fi
}

# Note: Worker function is now created dynamically in process_directory

# Create configuration file for parallel workers
create_worker_config() {
    cat > "$TEMP_DIR/worker_config.sh" << EOF
# Worker configuration
DRY_RUN=$DRY_RUN
VERBOSE=$VERBOSE
SOURCE_DIR="$SOURCE_DIR"
DEST_DIR="$DEST_DIR"
JPG_DIR="$JPG_DIR"
RAW_DIR="$RAW_DIR"
SEPARATE_FORMATS=$SEPARATE_FORMATS
HANDLE_EADIR=$HANDLE_EADIR
EXIFTOOL_AVAILABLE=$EXIFTOOL_AVAILABLE
EOF
}

# Process directory recursively
process_directory() {
    local dir="$1"
    local file_count=0
    local processed_count=0
    local skipped_count=0

    log_info "Processing directory: $dir"

    if [[ "$PARALLEL_JOBS" -eq 1 ]]; then
        # Sequential processing (original logic)
        while IFS= read -r -d '' file; do
            file_count=$((file_count + 1))
            # Skip files in @eaDir directories - they will be handled separately
            if [[ "$file" =~ /@eaDir/ ]]; then
                log_verbose "Skipping @eaDir file (will be moved with parent image): $file"
                skipped_count=$((skipped_count + 1))
            elif is_image_file "$file"; then
                if process_image "$file"; then
                    processed_count=$((processed_count + 1))
                fi
            else
                log_verbose "Skipping non-image file: $file"
                skipped_count=$((skipped_count + 1))
            fi
        done < <(find "$dir" -type f -print0)
    else
        # Parallel processing
        log_info "Using $PARALLEL_JOBS parallel jobs"

        # Create temporary directory for worker communication
        TEMP_DIR=$(mktemp -d)
        trap 'rm -rf "$TEMP_DIR"' EXIT

        # Create worker configuration file
        create_worker_config

        # Find all files and process in parallel
        # Create worker script
        cat > "$TEMP_DIR/worker.sh" << 'WORKER_EOF'
#!/bin/bash
# Worker script for parallel processing
file="$1"
config_file="$2"
script_path="$3"

# Source the main script to get function definitions
source "$script_path"

# Source the configuration
source "$config_file"

# Skip files in @eaDir directories - they will be handled separately
if [[ "$file" =~ /@eaDir/ ]]; then
    if [[ "$VERBOSE" == "true" ]]; then
        echo "SKIPPED:$file (will be moved with parent image)"
    fi
elif is_image_file "$file"; then
    if process_image "$file"; then
        echo "PROCESSED:$file"
    else
        echo "FAILED:$file"
    fi
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo "SKIPPED:$file"
    fi
fi
WORKER_EOF
        chmod +x "$TEMP_DIR/worker.sh"

        # Process files in parallel and read results
        # shellcheck disable=SC2016
        while IFS=':' read -r status file_path; do
            file_count=$((file_count + 1))
            case "$status" in
                "PROCESSED")
                    processed_count=$((processed_count + 1))
                    log_verbose "Processed: $file_path"
                    ;;
                "FAILED")
                    log_error "Failed to process: $file_path"
                    # Don't increment processed_count for failures
                    ;;
                "SKIPPED")
                    skipped_count=$((skipped_count + 1))
                    ;;
            esac

            # Progress indicator for large collections
            if [[ $((file_count % 100)) -eq 0 ]]; then
                log_info "Progress: $file_count files checked, $processed_count processed"
            fi
        done < <(find "$dir" -type f -print0 | \
                 xargs -0 -n 1 -P "$PARALLEL_JOBS" -I {} bash "$TEMP_DIR/worker.sh" {} "$TEMP_DIR/worker_config.sh" "${BASH_SOURCE[0]}")

        # Clean up
        rm -rf "$TEMP_DIR"
    fi

    log_info "Completed: $processed_count processed, $skipped_count skipped out of $file_count total files"
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--separate-formats)
                SEPARATE_FORMATS=true
                shift
                ;;
            -j|--jobs)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ && "$2" -gt 0 && "$2" -le 16 ]]; then
                    PARALLEL_JOBS="$2"
                    shift 2
                else
                    log_error "--jobs requires a number between 1 and 16"
                    usage
                    exit 1
                fi
                ;;
            -e|--handle-eadir)
                HANDLE_EADIR=true
                shift
                ;;
            --jpg-dir)
                if [[ -n "$2" && "$2" != -* ]]; then
                    JPG_DIR="$2"
                    shift 2
                else
                    log_error "--jpg-dir requires a directory argument"
                    usage
                    exit 1
                fi
                ;;
            --raw-dir)
                if [[ -n "$2" && "$2" != -* ]]; then
                    RAW_DIR="$2"
                    shift 2
                else
                    log_error "--raw-dir requires a directory argument"
                    usage
                    exit 1
                fi
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$SOURCE_DIR" ]]; then
                    SOURCE_DIR="$1"
                elif [[ -z "$DEST_DIR" && "$SEPARATE_FORMATS" == "false" ]]; then
                    DEST_DIR="$1"
                else
                    log_error "Too many arguments or unexpected positional argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$SOURCE_DIR" ]]; then
        log_error "SOURCE_DIRECTORY is required"
        usage
        exit 1
    fi

    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "SOURCE_DIRECTORY does not exist: $SOURCE_DIR"
        exit 1
    fi

    # Validate separate formats configuration
    if [[ "$SEPARATE_FORMATS" == "true" ]]; then
        if [[ -z "$JPG_DIR" ]]; then
            log_error "--jpg-dir is required when using --separate-formats"
            usage
            exit 1
        fi
        if [[ -z "$RAW_DIR" ]]; then
            log_error "--raw-dir is required when using --separate-formats"
            usage
            exit 1
        fi
        # Create JPG and RAW directories
        create_directory "$JPG_DIR"
        create_directory "$RAW_DIR"
    else
        # Set default destination directory for single-destination mode
        if [[ -z "$DEST_DIR" ]]; then
            DEST_DIR="$SOURCE_DIR"
        fi
        # Create destination directory if it doesn't exist
        if [[ "$DEST_DIR" != "$SOURCE_DIR" ]]; then
            create_directory "$DEST_DIR"
        fi
    fi

    # Check for available tools
    check_exiftool

    # Show configuration
    log_info "Configuration:"
    log_info "  Source directory: $SOURCE_DIR"
    if [[ "$SEPARATE_FORMATS" == "true" ]]; then
        log_info "  Format separation: ENABLED"
        log_info "  JPG base directory: $JPG_DIR"
        log_info "  RAW base directory: $RAW_DIR"
    else
        log_info "  Format separation: DISABLED"
        log_info "  Destination directory: $DEST_DIR"
    fi
    log_info "  Parallel jobs: $PARALLEL_JOBS"
    log_info "  Handle @eaDir: $HANDLE_EADIR"
    log_info "  Dry run: $DRY_RUN"
    log_info "  Verbose: $VERBOSE"
    log_info "  ExifTool available: $EXIFTOOL_AVAILABLE"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No files will be moved"
    fi

    # Process the directory
    process_directory "$SOURCE_DIR"

    log_info "Processing complete!"
}

# Run main function with all arguments only if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
