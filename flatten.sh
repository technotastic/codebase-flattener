#!/bin/bash

# --- Configuration ---
# Directories to completely ignore (paths starting with these will be skipped)
# IMPORTANT: Must end with /
EXCLUDED_DIRS=(
    .git/
    node_modules/
    dist/
    build/
    target/ # Rust, Java (Maven/Gradle)
    venv/
    .venv/
    env/
    __pycache__/
    .vscode/
    .idea/ # JetBrains IDEs
    out/ # Common build output dir
    coverage/
    .cache/
    .pytest_cache/
    .mypy_cache/
    .ruff_cache/
    *.egg-info/ # Python packaging
    Pods/ # CocoaPods
    Carthage/ # Carthage
    DerivedData/ # Xcode
)

# Specific filenames to ignore
EXCLUDED_FILES=(
    package-lock.json
    yarn.lock
    Pipfile.lock
    poetry.lock
    .DS_Store
    Thumbs.db
)

# File extensions to ignore (case-insensitive)
EXCLUDED_EXTENSIONS=(
    # Logs & Locks
    log lock
    # Images
    png jpg jpeg gif svg ico bmp tif tiff webp
    # Archives
    zip gz tar rar 7z bz2 xz
    # Audio/Video
    mp3 mp4 mkv avi mov flv wmv ogg wav flac aac
    # Binaries/Executables/Libraries
    exe dll so o a lib jar class pyc pyd pyo wasm dex obj # Added dex, obj
    # Fonts
    woff woff2 ttf otf eot
    # Documents/Data/Other
    pdf psd ai swf fla db sqlite sqlite3 dat bin img iso dmg # Added more doc/binary types
    ppt pptx doc docx xls xlsx # MS Office
    pkl pickle joblib # Python serialized objects
    bak swp swo # Backup/swap files
    onnx # ML models
    ipynb # Jupyter notebooks (often contain large outputs/plots - consider including if needed, but exclude by default)
    # Compiled Assets
    css.map js.map # Source maps
)

# --- Script Logic ---
# set -e # Temporarily disable to see errors without halting
# set -o pipefail # Exit if any command in a pipeline fails (optional, but safer)

DEFAULT_OUTPUT_FILE="flattened_code.txt"
TARGET_DIR="."
OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"

# --- Helper Functions ---
usage() {
    echo "Usage: $0 [TARGET_DIRECTORY] [OUTPUT_FILE]"
    echo "  Recursively concatenates relevant text files in TARGET_DIRECTORY into OUTPUT_FILE."
    echo "  Excludes common binary files, build artifacts, and VCS directories."
    echo ""
    echo "  Arguments:"
    echo "    TARGET_DIRECTORY : Directory to scan (default: current directory '.')"
    echo "    OUTPUT_FILE      : File to write the output to (default: '$DEFAULT_OUTPUT_FILE')"
    exit 1
}

is_excluded_dir() {
    local rel_path="$1"
    for excluded in "${EXCLUDED_DIRS[@]}"; do
        if [[ "$rel_path" == "$excluded"* ]]; then
            return 0 # 0 means true (is excluded) in Bash exit codes
        fi
    done
    return 1 # 1 means false (is not excluded)
}

is_excluded_file() {
    local filename="$1"
    for excluded in "${EXCLUDED_FILES[@]}"; do
        if [[ "$filename" == "$excluded" ]]; then
            return 0 # True: is excluded
        fi
    done
    return 1 # False: is not excluded
}

is_excluded_extension() {
    local ext_lower="$1"
    if [[ -z "$ext_lower" ]]; then # No extension
      return 1 # Not excluded based on extension
    fi
    for excluded in "${EXCLUDED_EXTENSIONS[@]}"; do
        if [[ "$ext_lower" == "$excluded" ]]; then
            return 0 # True: is excluded
        fi
    done
    return 1 # False: is not excluded
}

# --- Argument Parsing ---
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

if [ -n "$1" ]; then
    TARGET_DIR="$1"
fi
if [ -n "$2" ]; then
    OUTPUT_FILE="$2"
fi

# --- Input Validation ---
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' not found or is not a directory." >&2
    usage
fi

# Resolve absolute path for output file for clarity, especially if TARGET_DIR is relative
# This prevents accidentally writing into the TARGET_DIR if OUTPUT_FILE is just a name
if [[ "$OUTPUT_FILE" != /* ]]; then
  OUTPUT_FILE="$(pwd)/$OUTPUT_FILE"
fi

# Ensure target dir path doesn't end with a slash for cleaner relative path calculation later
TARGET_DIR_CLEAN="${TARGET_DIR%/}"
# Handle case where target dir is root '/'
if [[ -z "$TARGET_DIR_CLEAN" ]]; then
    TARGET_DIR_CLEAN="/"
fi

echo "Scanning directory: '$TARGET_DIR'"
echo "Outputting to file: '$OUTPUT_FILE'"

# --- Main Processing ---
# Clear or create the output file
> "$OUTPUT_FILE"

# Counter for processed files
file_count=0

# Use find to locate all files, print0 for safety, pipe to while read loop
find "$TARGET_DIR" -type f -print0 | while IFS= read -r -d $'\0' file_path; do
    # Calculate relative path from the original target directory argument
    # Using string manipulation for better compatibility than realpath
    relative_path="${file_path#"$TARGET_DIR_CLEAN/"}"
    # If TARGET_DIR was '.', the above might not remove anything, handle that:
    if [[ "$relative_path" == "$file_path" && "$TARGET_DIR_CLEAN" == "." ]]; then
         relative_path="${file_path#./}"
    fi
    # If TARGET_DIR was '/', ensure relative path doesn't start with '//'
    relative_path="${relative_path#/}"

    # --- Apply Exclusions ---
    # 1. Check if path is within an excluded directory
    if is_excluded_dir "$relative_path"; then
        # echo "Skipping (excluded dir): $relative_path" >&2 # Optional debug logging
        continue
    fi

    # 2. Check specific filenames
    filename=$(basename "$file_path")
    if is_excluded_file "$filename"; then
        # echo "Skipping (excluded file): $relative_path" >&2 # Optional debug logging
        continue
    fi

    # 3. Check file extensions
    extension="${filename##*.}"
    if [[ "$filename" == "$extension" ]]; then # Handle files with no extension
        extension=""
    fi
    # Convert extension to lowercase for case-insensitive comparison
    extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    if is_excluded_extension "$extension_lower"; then
        # echo "Skipping (excluded ext): $relative_path" >&2 # Optional debug logging
        continue
    fi

    # --- Append to Output File ---
    echo "Processing: $relative_path" >&2 # Log processed files to stderr

    # Check if file is potentially binary (simple heuristic: contains null bytes)
    # This is an extra check, might slow things down but increases safety
    if grep -qP '\x00' "$file_path"; then
        echo "Skipping (likely binary based on null byte): $relative_path" >&2
        continue
    fi


    # Append start marker
    echo "--- START FILE: $relative_path ---" >> "$OUTPUT_FILE"

    # Append file content
    cat "$file_path" >> "$OUTPUT_FILE"

    # Ensure a newline exists at the end of the file content before the END marker
    # Check if the last character is a newline
    if [[ $(tail -c1 "$file_path" | wc -l) -eq 0 ]]; then
        echo "" >> "$OUTPUT_FILE" # Add a newline if missing
    fi

    # Append end marker
    echo "--- END FILE: $relative_path ---" >> "$OUTPUT_FILE"
    # Append an extra blank line for separation between file blocks
    echo "" >> "$OUTPUT_FILE"

    ((file_count++))

done

# --- Completion ---
echo "----------------------------------------"
echo "Processing complete."
echo "Processed $file_count files."
echo "Flattened codebase snapshot written to: $OUTPUT_FILE"

exit 0

