# Codebase Flattener (`flatten.sh`)

A Bash script to recursively scan a directory, gather the content of relevant source code and text files, and concatenate them into a single output file. This is particularly useful for preparing a codebase to be ingested by Large Language Models (LLMs) for analysis, review, or context.

The script automatically filters out common directories (like `.git`, `node_modules`), specific files (lock files), and binary file extensions to keep the output focused on actual source content.

## Features

*   **Recursive Traversal:** Scans all subdirectories within the target path.
*   **Intelligent Filtering:** Excludes version control metadata, dependency folders, build artifacts, binary files, images, and other non-essential content based on predefined lists.
*   **LLM-Friendly Output:** Formats the output with clear delimiters indicating the start and end of each file's content, including its relative path.
*   **Customizable Exclusions:** Exclusion lists (directories, filenames, extensions) are defined directly within the script for easy modification.
*   **Command-Line Interface:** Simple CLI accepts target directory and output file path as arguments.
*   **Cross-Platform:** Designed for Bash environments (Linux, macOS, Windows via Git Bash/WSL).

## Prerequisites

*   **Bash:** The script is written for Bash.
*   **Standard Unix Utilities:** Requires common tools like `find`, `cat`, `grep`, `tail`, `basename`, `tr`, `wc`. These are typically pre-installed on Linux and macOS. Git Bash for Windows also includes them.
*   **`grep` with `-P` support (Perl Regex):** The script uses `grep -P '\x00'` for a basic binary file check (detecting null bytes). GNU `grep` (default on most Linux distros) supports this. The default `grep` on macOS **does not**.
    *   **macOS users:** You may need to install GNU `grep` (e.g., via Homebrew: `brew install grep`) and potentially ensure it's used (e.g., by alias or adjusting the script if necessary, though often `ggrep` is available after install). If `grep -P` fails, the script will issue a warning and skip the file.

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/codebase-flattener.git
    cd codebase-flattener
    ```
    (Replace `your-username/codebase-flattener.git` with your actual repository URL)

2.  **Make the script executable:**
    ```bash
    chmod +x flatten.sh
    ```

## Usage

Run the script from your terminal, optionally providing the target directory and output filename.

```bash
./flatten.sh [TARGET_DIRECTORY] [OUTPUT_FILE]
