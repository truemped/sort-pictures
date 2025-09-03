# Sort Pictures

A Bash script for organizing photo collections into date-based folder structures on Synology NAS and other Linux systems.

## Features

- **Date-based organization**: Sorts photos into `year/month/day` folder structure
- **Dual format support**: Separate JPG and RAW files into different base directories
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

## Compatibility

- Synology DSM 7.1.1 and later
- Most Linux distributions
- macOS (with minor stat command differences handled automatically)

## Safety Features

- **Dry-run mode**: Always test with `--dry-run` first
- **File validation**: Only processes recognized image formats
- **Collision detection**: Prevents overwriting existing files
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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test thoroughly with `--dry-run`
4. Submit a pull request

## Support

For issues and questions:
- Create an issue on GitHub
- Include sample command and error output
- Specify your operating system and version