#!/usr/bin/env python3

import re
import sqlite3
import hashlib
from pathlib import Path
from datetime import datetime


# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------

input_file = Path("bravo.txt")
database_file = Path("word-harvest.sqlite")


# ----------------------------------------------------------------------
# Database
# ----------------------------------------------------------------------

connection = sqlite3.connect(database_file)
connection.execute("PRAGMA foreign_keys = ON")

cursor = connection.cursor()


# ----------------------------------------------------------------------
# Create schema
# ----------------------------------------------------------------------

cursor.execute("""
CREATE TABLE IF NOT EXISTS documents
(
    document_id      INTEGER PRIMARY KEY,
    filename         TEXT NOT NULL,
    sha256           TEXT NOT NULL,
    imported_at      TEXT NOT NULL
)
""")

cursor.execute("""
CREATE TABLE IF NOT EXISTS lines
(
    line_id          INTEGER PRIMARY KEY,
    document_id      INTEGER NOT NULL,
    line_number      INTEGER NOT NULL,
    raw_text         TEXT NOT NULL,

    FOREIGN KEY (document_id)
        REFERENCES documents(document_id)
)
""")

cursor.execute("""
CREATE TABLE IF NOT EXISTS fields
(
    field_id         INTEGER PRIMARY KEY,
    document_id      INTEGER NOT NULL,
    line_number      INTEGER NOT NULL,
    field_name       TEXT NOT NULL,
    field_value      TEXT,

    FOREIGN KEY (document_id)
        REFERENCES documents(document_id)
)
""")


# ----------------------------------------------------------------------
# Read input
# ----------------------------------------------------------------------

text = input_file.read_text(encoding="utf-8")

checksum = hashlib.sha256(
    input_file.read_bytes()
).hexdigest()


# ----------------------------------------------------------------------
# Register document
# ----------------------------------------------------------------------

cursor.execute(
    """
    INSERT INTO documents
    (
        filename,
        sha256,
        imported_at
    )
    VALUES (?, ?, ?)
    """,
    (
        input_file.name,
        checksum,
        datetime.now().astimezone().isoformat()
    )
)

document_id = cursor.lastrowid


# ----------------------------------------------------------------------
# Harvest lines
# ----------------------------------------------------------------------

field_pattern = re.compile(
    r"^([^:]+):\s*(.*)$"
)

for line_number, line in enumerate(text.splitlines(), start=1):

    raw_text = line.rstrip()

    # Preserve every line exactly as harvested.

    cursor.execute(
        """
        INSERT INTO lines
        (
            document_id,
            line_number,
            raw_text
        )
        VALUES (?, ?, ?)
        """,
        (
            document_id,
            line_number,
            raw_text
        )
    )

    # Skip blank lines for field parsing.

    if not raw_text.strip():
        continue

    # Skip provenance comments for now.
    # They are still safely preserved in lines.

    if raw_text.lstrip().startswith("#"):
        continue

    # Parse:
    #
    # Date: ...
    # Account: ...
    # score_L: ...
    # Area_1: ...
    #
    # Split only on the FIRST colon.

    match = field_pattern.match(raw_text)

    if not match:
        continue

    field_name = match.group(1).strip()
    field_value = match.group(2).strip()

    cursor.execute(
        """
        INSERT INTO fields
        (
            document_id,
            line_number,
            field_name,
            field_value
        )
        VALUES (?, ?, ?, ?)
        """,
        (
            document_id,
            line_number,
            field_name,
            field_value
        )
    )


# ----------------------------------------------------------------------
# Commit
# ----------------------------------------------------------------------

connection.commit()


# ----------------------------------------------------------------------
# Report
# ----------------------------------------------------------------------

n_lines = cursor.execute(
    """
    SELECT COUNT(*)
    FROM lines
    WHERE document_id = ?
    """,
    (document_id,)
).fetchone()[0]

n_fields = cursor.execute(
    """
    SELECT COUNT(*)
    FROM fields
    WHERE document_id = ?
    """,
    (document_id,)
).fetchone()[0]


print(f"input:       {input_file}")
print(f"database:    {database_file}")
print(f"document_id: {document_id}")
print(f"sha256:      {checksum}")
print(f"lines:       {n_lines}")
print(f"fields:      {n_fields}")


# ----------------------------------------------------------------------
# Show harvested fields
# ----------------------------------------------------------------------

print()

for row in cursor.execute(
    """
    SELECT
        line_number,
        field_name,
        field_value
    FROM fields
    WHERE document_id = ?
    ORDER BY line_number
    """,
    (document_id,)
):

    line_number, field_name, field_value = row

    print(
        f"{line_number:4d}  "
        f"{field_name:15s}  "
        f"{field_value[:70]}"
    )


connection.close()