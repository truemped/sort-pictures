# Sort Pictures

[![Tests](https://github.com/username/sort-pictures/workflows/Tests/badge.svg)](https://github.com/username/sort-pictures/actions)

A Bash script for organizing photo collections into date-based folder structures on Synology NAS and other Linux systems.

## Features

- **Date-based organization**: Sorts photos into `year/month/day` folder structure
- **Dual format support**: Separate JPG and RAW files into different base directories
- **Parallel processing**: Handle thousands of files efficiently with 1-16 concurrent jobs
- **Synology @eaDir support**: Optionally moves metadata and thumbnail files along with photos
- **EXIF metadata extraction**: Uses photo creation date when available, falls back to file modification time
- **Recursive processing**: Handles nested folder structures automatically
- **Dry-run mode**: Preview changes before execution
- **Extensive format support**: JPG, PNG, GIF, BMP, TIFF, CR2, NEF, ARW, DNG, ORF, RW2, CR3, RAF, SRW, PEF, X3F, and more
- **Synology DSM compatible**: Tested on DSM 7.1.1-42962 Update 9

## Installation

1. Download the script:
   ```bash
   wget https://github.com/your-repo/sort-pictures/raw/main/sort-pictures.sh
   # or
   curl -O https://github.com/your-repo/sort-pictures/raw/main/sort-pictures.sh
   ```

2. Make it executable:
   ```bash
   chmod +x sort-pictures.sh
   ```

3. (Optional) Install exiftool for better metadata extraction:
   ```bash
   # On Synology DSM
   # Install via Package Center or Entware

   # On Ubuntu/Debian
   sudo apt install exiftool

   # On macOS
   brew install exiftool
   ```

## Usage

### Basic Usage

Sort photos in-place with date-based folders:
```bash
./sort-pictures.sh /volume1/photos
```

Sort photos to a different location:
```bash
./sort-pictures.sh /volume1/unsorted /volume1/organized
```

### Dry Run (Recommended First Step)

Preview what the script will do without making changes:
```bash
./sort-pictures.sh --dry-run /volume1/photos
```

### Separate JPG and RAW Files

Sort JPG and RAW files into separate base directories:
```bash
./sort-pictures.sh --separate-formats \
  --jpg-dir /volume1/Photos/JPG \
  --raw-dir /volume1/Photos/RAW \
  /volume1/unsorted
```

### Verbose Output

Get detailed information about what's happening:
```bash
./sort-pictures.sh --verbose --dry-run /volume1/photos
```

### Parallel Processing (for Large Collections)

Process files using multiple parallel jobs:
```bash
# Use 4 parallel jobs
./sort-pictures.sh --jobs 4 /volume1/large_photo_collection

# Combine with other options
./sort-pictures.sh -j 8 --separate-formats --jpg-dir /volume1/JPG --raw-dir /volume1/RAW -d -v /volume1/photos
```

### Synology @eaDir Support

When using Synology DSM Photos, enable @eaDir handling to move metadata and thumbnails:
```bash
# Enable @eaDir handling
./sort-pictures.sh --handle-eadir /volume1/photos

# Combine with other options
./sort-pictures.sh -e --separate-formats --jpg-dir /volume1/JPG --raw-dir /volume1/RAW /volume1/photos

# Dry run to see what @eaDir files would be moved
./sort-pictures.sh --handle-eadir --dry-run --verbose /volume1/photos
```

### Combined Options

```bash
./sort-pictures.sh -s --jpg-dir /sorted/JPG --raw-dir /sorted/RAW -d -v /unsorted
```

## Command Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--dry-run` | `-d` | Show what would be done without making changes |
| `--verbose` | `-v` | Enable detailed output |
| `--separate-formats` | `-s` | Enable separate sorting for JPG and RAW files |
| `--jobs N` | `-j` | Number of parallel jobs (1-16, default: 1) |
| `--handle-eadir` | `-e` | Move Synology @eaDir metadata files with photos |
| `--jpg-dir DIR` | | Base directory for JPG files (requires `--separate-formats`) |
| `--raw-dir DIR` | | Base directory for RAW files (requires `--separate-formats`) |
| `--help` | `-h` | Show help message |

## Examples

### Example 1: Basic Organization
```bash
# Before
/volume1/photos/
├── IMG_001.jpg
├── IMG_002.CR2
└── vacation/
    ├── beach.jpg
    └── sunset.NEF

# Command
./sort-pictures.sh /volume1/photos

# After
/volume1/photos/
├── 2024/
│   ├── 03/
│   │   └── 15/
│   │       ├── IMG_001.jpg
│   │       └── beach.jpg
│   └── 04/
│       └── 02/
│           ├── IMG_002.CR2
│           └── sunset.NEF
```

### Example 2: Separate JPG and RAW
```bash
# Command
./sort-pictures.sh --separate-formats \
  --jpg-dir /volume1/JPG \
  --raw-dir /volume1/RAW \
  /volume1/photos

# Result
/volume1/JPG/2024/03/15/
├── IMG_001.jpg
└── beach.jpg

/volume1/RAW/2024/03/15/
├── IMG_002.CR2
└── sunset.NEF
```

## Supported File Formats

### JPG Formats
- JPG, JPEG, PNG, GIF, BMP, TIFF, TIF

### RAW Formats
- RAW, CR2, CR3, NEF, ARW, DNG, ORF, RW2
- RAF, SRW, PEF, X3F, RWL, IIQ, 3FR, FFF
- MEF, MOS, MRW, PTX, DCR, KDC, SRF, SR2

## Date Detection

The script determines photo dates in this order:
1. **EXIF DateTimeOriginal** (if exiftool is available)
2. **EXIF CreateDate** (if exiftool is available)
3. **EXIF ModifyDate** (if exiftool is available)
4. **File modification time** (fallback)

## Error Handling

- **Duplicate files**: Automatically renames with numeric suffix (`_1`, `_2`, etc.)
- **Invalid dates**: Logs error and skips file
- **Missing directories**: Creates directory structure automatically
- **Permission errors**: Provides clear error messages

## Requirements

- Bash 4.0 or later
- Standard Unix tools: `find`, `stat`, `mkdir`, `mv`
- Optional: `exiftool` for EXIF metadata extraction
- Development only: `bats-core` (testing), `shellcheck` (linting)

## Compatibility

- Synology DSM 7.1.1 and later
- Most Linux distributions
- macOS (with minor stat command differences handled automatically)

## Performance Features

- **Parallel processing**: Use `--jobs N` to process multiple files simultaneously
- **Progress tracking**: Shows progress every 100 files when processing large collections
- **Optimized for large datasets**: Efficiently handles thousands of files
- **Memory efficient**: Uses streaming processing to minimize memory usage

## Safety Features

- **Dry-run mode**: Always test with `--dry-run` first
- **File validation**: Only processes recognized image formats
- **Collision detection**: Prevents overwriting existing files
- **@eaDir preservation**: Maintains Synology metadata when enabled
- **Verbose logging**: Track exactly what's happening
- **Error recovery**: Continues processing other files if one fails

## Troubleshooting

### Script says "exiftool not available"
This is normal if exiftool isn't installed. The script will use file modification times instead.

### Files aren't being moved
- Check that source directory exists and is readable
- Use `--verbose` to see detailed processing information
- Verify file permissions

### Wrong dates being used
- Install exiftool for accurate EXIF date extraction
- Some cameras don't set EXIF dates correctly

### Permission denied errors
- Ensure write permissions to destination directories
- On Synology, make sure you're running as a user with appropriate permissions

### Slow processing with large collections
- Use parallel processing: `--jobs 4` (or higher, up to 16)
- Monitor system resources - too many jobs can overwhelm slower systems
- For Synology NAS, start with `--jobs 2` and increase if system handles it well

### Synology Photos app doesn't show thumbnails after sorting
- Use `--handle-eadir` to move metadata and thumbnail files with photos
- The Photos app will regenerate missing thumbnails automatically
- Consider running DSM's "Re-index" function after large reorganizations

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Development and Testing

### Running Tests

This project uses [Bats](https://github.com/bats-core/bats-core) for testing:

```bash
# Install dependencies (macOS)
brew install bats-core shellcheck

# Install dependencies (Ubuntu)
sudo apt-get install bats shellcheck

# Run all tests
make test

# Run specific test suites
make test-unit          # Unit tests only
make test-integration   # Integration tests only
make test-performance   # Performance tests only

# Run linting and syntax checks
make check
make lint

# Quick smoke test
make smoke-test

# Test GitHub Actions workflow locally
.github/workflows/workflow-test.sh
```

### Test Structure

- **Unit Tests** (`tests/unit_tests.bats`): Test individual functions
- **Integration Tests** (`tests/integration_tests.bats`): Test full script functionality
- **Performance Tests** (`tests/performance_tests.bats`): Test with large file collections

### Continuous Integration

Tests run automatically on all pull requests via GitHub Actions, testing on both Ubuntu and macOS.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `make test-all`
5. Test thoroughly with `--dry-run`
6. Submit a pull request

## Support

For issues and questions:
- Create an issue on GitHub
- Include sample command and error output
- Specify your operating system and version
