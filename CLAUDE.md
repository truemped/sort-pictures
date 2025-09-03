# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a single Bash script (`sort-pictures.sh`) designed to organize photo collections on Synology DSM systems. The script sorts images by date into a hierarchical folder structure (`year/month/day`) and supports separate organization of JPG and RAW files.

## Core Functionality

The script provides two main operating modes:

1. **Unified Mode**: All images sorted into a single destination with date-based folders
2. **Separate Formats Mode**: JPG and RAW files sorted into independent base directories, each with date-based subfolders

Key features:
- Recursive directory traversal for nested photo collections
- EXIF metadata extraction (with fallback to file modification time)
- Parallel processing support (1-16 concurrent jobs) for large collections
- Dry-run capability for safe preview of operations
- Extensive file format support (JPG, PNG, GIF, BMP, TIFF, CR2, NEF, ARW, DNG, ORF, RW2, CR3, RAF, SRW, PEF, X3F, etc.)

## Script Architecture

The script follows a modular function-based architecture:

- **Date Extraction**: `get_image_date()` - Uses exiftool if available, falls back to stat
- **File Classification**: `is_image_file()`, `is_jpg_file()`, `is_raw_file()` - Determines file types
- **File Operations**: `move_file()`, `create_directory()` - Handles actual file movement with collision detection
- **Processing Logic**: `process_image()`, `process_directory()` - Core sorting logic with format-aware destination selection

## Command Usage

Execute the script directly (it's executable):

```bash
# Basic photo sorting
./sort-pictures.sh /path/to/photos

# Dry run to preview changes
./sort-pictures.sh -d /path/to/photos

# Separate JPG and RAW files
./sort-pictures.sh --separate-formats --jpg-dir /path/to/jpg --raw-dir /path/to/raw /path/to/photos

# Verbose dry run with format separation
./sort-pictures.sh -s --jpg-dir /sorted/JPG --raw-dir /sorted/RAW -d -v /unsorted/photos

# Parallel processing with 4 jobs
./sort-pictures.sh --jobs 4 /path/to/large/collection

# Parallel processing with format separation
./sort-pictures.sh -j 8 -s --jpg-dir /sorted/JPG --raw-dir /sorted/RAW /large/photo/collection
```

## Compatibility Requirements

- Target platform: Synology DSM 7.1.1 or compatible Linux systems
- Required tools: bash, find, stat, mkdir, mv
- Optional but recommended: exiftool (for accurate date extraction from EXIF data)
- Development dependencies: bats-core (testing), shellcheck (linting)
- Uses POSIX-compliant shell features for maximum compatibility

## Testing and Development

Test the script using dry-run mode (`-d`) before actual operations. The script includes comprehensive error handling and validation for missing directories, invalid arguments, and unsupported file formats.

When modifying the script, ensure compatibility with older DSM systems by avoiding modern shell features and verifying tool availability before use.