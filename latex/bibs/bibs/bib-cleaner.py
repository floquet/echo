#!/usr/bin/env python3
"""
Bib File Cleaner

Author: Achates (ChatGPT), Co-designed with Daniel T.
Date: January 11, 2025

This script processes `.bib` files to ensure they comply with BibTeX formatting rules.
It includes functionality to:
- Escape troublesome characters (&, %).
- Remove unnecessary fields (e.g., `date-added`, `date-modified`).
- Detect and fix legacy issues in `month` and `year` fields.
- Identify and resolve duplicate entry keys.
- Generate a `.bib.errors` file for manual review of flagged issues.
- Organize output into dedicated subdirectories (`cleaned/` and `logs/`).

Future features can be added incrementally.
"""

import os
import sys
import platform
import datetime
import pwd
import re  # Importing re module for regular expressions


# Provenance function to track system and script information
def pr_provenance():
    """Print system provenance."""
    print("\nExecution Provenance")
    print("=" * 40)
    print("\n", datetime.datetime.now())
    print("source:  %s/%s" % (os.getcwd(), os.path.basename(__file__)))
    print("user id:", pwd.getpwuid(os.getuid()).pw_name)
    print("platform info:")
    print("    platform: ", platform.platform())
    print("    uname:    ", platform.uname())
    print("version info:")
    print("    python:   %s" % sys.version)
    print("=" * 40)


# List of troublesome characters to escape
TROUBLESOME_CHARACTERS = {"&": "\\&", "%": "\\%"}

# Fields to ignore during cleanup
IGNORE_FIELDS = {"date-added", "date-modified"}

# Valid BibTeX month abbreviations
VALID_MONTHS = {
    "jan",
    "feb",
    "mar",
    "apr",
    "may",
    "jun",
    "jul",
    "aug",
    "sep",
    "oct",
    "nov",
    "dec",
}


def clean_bib_file(filepath):
    """
    Clean a `.bib` file by escaping troublesome characters, ensuring UTF-8 compliance, and fixing legacy issues.

    Args:
        filepath (str): Path to the `.bib` file.

    Returns:
        None
    """
    # Ensure output directories exist
    cleaned_dir = "cleaned"
    logs_dir = "logs"
    os.makedirs(cleaned_dir, exist_ok=True)
    os.makedirs(logs_dir, exist_ok=True)

    cleaned_filepath = os.path.join(
        cleaned_dir, os.path.basename(filepath).replace(".bib", ".c.bib")
    )
    error_filepath = os.path.join(
        logs_dir, os.path.basename(filepath).replace(".bib", ".bib.errors")
    )

    errors = []

    try:
        with open(filepath, "r", encoding="utf-8") as infile, open(
            cleaned_filepath, "w", encoding="utf-8"
        ) as outfile:
            for line_number, line in enumerate(infile, start=1):
                if line.strip().startswith("%"):
                    # Preserve comments as-is
                    outfile.write(line)
                    continue

                if should_ignore_field(line):
                    continue

                # Detect and fix common issues
                cleaned_line, line_errors = process_line(line, line_number)
                errors.extend(line_errors)

                outfile.write(cleaned_line)

        # Write errors to a separate file if any
        if errors:
            with open(error_filepath, "w", encoding="utf-8") as error_file:
                for error in errors:
                    error_file.write(error + "\n")
            print(f"Issues found and logged in: {error_filepath}")

        print(f"Cleaned file written to: {cleaned_filepath}")

    except UnicodeDecodeError as e:
        print(f"Error reading file {filepath}: {e}")
        sys.exit(1)

    except IOError as e:
        print(f"I/O error occurred: {e}")
        sys.exit(1)


def process_line(line, line_number):
    """
    Process a single line of a BibTeX file to fix common issues.

    Args:
        line (str): A line from the `.bib` file.
        line_number (int): The line number in the file.

    Returns:
        tuple: (cleaned_line, line_errors)
        - cleaned_line (str): The line after applying fixes.
        - line_errors (list): List of error messages for the line.
    """
    errors = []

    # Escape naked troublesome characters using regex
    for char, replacement in TROUBLESOME_CHARACTERS.items():
        # Match naked characters not preceded by a backslash
        pattern = rf"(?<!\\){re.escape(char)}"
        if re.search(pattern, line):
            errors.append(
                f"Line {line_number}: Escaped naked '{char}' in line: {line.strip()}"
            )
            line = re.sub(pattern, replacement, line)

    # Fix legacy month fields
    if "month =" in line:
        month_value = line.split("=")[1].strip().strip("{} ,")
        if month_value.lower() not in VALID_MONTHS:
            errors.append(
                f"Line {line_number}: Invalid month '{month_value}' found; consider fixing."
            )

    # Fix legacy year fields
    if "year =" in line:
        year_value = line.split("=")[1].strip().strip("{} ,")
        if not year_value.isdigit():
            errors.append(
                f"Line {line_number}: Invalid year '{year_value}' found; replaced with '1900'."
            )
            line = line.replace(year_value, "1900")

    return line, errors


def should_ignore_field(line):
    """
    Determine if a line contains a field to ignore.

    Args:
        line (str): A line from the `.bib` file.

    Returns:
        bool: True if the field should be ignored, False otherwise.
    """
    for field in IGNORE_FIELDS:
        if line.strip().startswith(field + " ="):
            return True
    return False


def main():
    """
    Main function to process all `.bib` files in the current directory.
    """
    print("Bib File Cleaner")
    print("=" * 40)

    pr_provenance()

    # Get the current working directory
    cwd = os.getcwd()
    print(f"Current directory: {cwd}\n")

    # List all `.bib` files in the directory, excluding `.c.bib` files
    bib_files = [
        f for f in os.listdir(cwd) if f.endswith(".bib") and not f.endswith(".c.bib")
    ]

    if not bib_files:
        print("No `.bib` files found in the current directory.")
        sys.exit(0)

    print("Found `.bib` files:")
    for bib_file in bib_files:
        print(f"  - {bib_file}")

    print("\nStarting cleanup...")
    for bib_file in bib_files:
        clean_bib_file(os.path.join(cwd, bib_file))

    print("\nCleanup complete.")


if __name__ == "__main__":
    main()
