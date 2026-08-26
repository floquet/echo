#!/usr/bin/env python3

import datetime
import getpass
import os
import platform
import sqlite3
import sys
import uuid


DB_FILE = "sets.db"


def make_uuid():
    return str(uuid.uuid4())


def create_database(conn):

    conn.execute("""
        CREATE TABLE IF NOT EXISTS provenance (
            provenance_id     INTEGER PRIMARY KEY,
            uuid              TEXT NOT NULL UNIQUE,
            created_at        TEXT NOT NULL,
            user_name         TEXT NOT NULL,
            host_name         TEXT NOT NULL,
            cwd               TEXT NOT NULL,
            os_name           TEXT NOT NULL,
            os_release        TEXT NOT NULL,
            python_version    TEXT NOT NULL,
            python_executable TEXT NOT NULL
        )
    """)

    conn.execute("""
        CREATE TABLE IF NOT EXISTS sets (
            set_id          INTEGER PRIMARY KEY,
            uuid            TEXT NOT NULL UNIQUE,
            tag             TEXT NOT NULL UNIQUE,
            provenance_id   INTEGER NOT NULL,

            FOREIGN KEY (provenance_id)
                REFERENCES provenance(provenance_id)
        )
    """)

    conn.execute("""
        CREATE TABLE IF NOT EXISTS members (
            set_id      INTEGER NOT NULL,
            value       INTEGER NOT NULL,

            PRIMARY KEY (set_id, value),

            FOREIGN KEY (set_id)
                REFERENCES sets(set_id)
        )
    """)

    conn.commit()


def store_provenance(conn):

    provenance_uuid = make_uuid()

    created_at = datetime.datetime.now(
        datetime.timezone.utc
    ).isoformat()

    cursor = conn.execute("""
        INSERT INTO provenance (
            uuid,
            created_at,
            user_name,
            host_name,
            cwd,
            os_name,
            os_release,
            python_version,
            python_executable
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        provenance_uuid,
        created_at,
        getpass.getuser(),
        platform.node(),
        os.getcwd(),
        platform.system(),
        platform.release(),
        platform.python_version(),
        sys.executable
    ))

    conn.commit()

    return cursor.lastrowid


def store_set(conn, set_id, tag, values, provenance_id):

    set_uuid = make_uuid()

    conn.execute("""
        INSERT INTO sets (
            set_id,
            uuid,
            tag,
            provenance_id
        )
        VALUES (?, ?, ?, ?)
    """, (
        set_id,
        set_uuid,
        tag,
        provenance_id
    ))

    for value in sorted(set(values)):
        conn.execute("""
            INSERT INTO members (
                set_id,
                value
            )
            VALUES (?, ?)
        """, (
            set_id,
            value
        ))

    conn.commit()

    return set_uuid


def load_set(conn, tag):

    rows = conn.execute("""
        SELECT members.value
        FROM members
        JOIN sets
          ON members.set_id = sets.set_id
        WHERE sets.tag = ?
        ORDER BY members.value
    """, (tag,))

    return {row[0] for row in rows}


def show_set(name, values):
    print(f"{name:12s} = {sorted(values)}")


def main():

    conn = sqlite3.connect(DB_FILE)

    #
    # SQLite does not enforce foreign keys unless requested.
    #
    conn.execute("PRAGMA foreign_keys = ON")

    create_database(conn)

    #
    # Fresh demonstration.
    #
    conn.execute("DELETE FROM members")
    conn.execute("DELETE FROM sets")
    conn.execute("DELETE FROM provenance")
    conn.commit()

    #
    # One provenance record describes this execution.
    #
    provenance_id = store_provenance(conn)

    #
    # Define sets.
    #
    universe = set(range(1, 11))

    odd = {
        1, 3, 5, 7, 9
    }

    even = {
        2, 4, 6, 8, 10
    }

    test_input = (
        1, 2, 2, 1
    )

    test = set(test_input)

    #
    # Store original sets.
    #
    store_set(
        conn,
        1,
        "universe",
        universe,
        provenance_id
    )

    store_set(
        conn,
        2,
        "odd",
        odd,
        provenance_id
    )

    store_set(
        conn,
        3,
        "even",
        even,
        provenance_id
    )

    store_set(
        conn,
        4,
        "test",
        test,
        provenance_id
    )

    #
    # Retrieve sets.
    #
    U = load_set(conn, "universe")
    O = load_set(conn, "odd")
    E = load_set(conn, "even")
    T = load_set(conn, "test")

    print()
    print("Stored sets")
    print("-----------")

    show_set("universe", U)
    show_set("odd", O)
    show_set("even", E)
    show_set("test", T)

    #
    # Set operations.
    #
    print()
    print("Set operations")
    print("--------------")

    show_set(
        "even + odd",
        E | O
    )

    assert E | O == U

    print()
    print(f"test input   = {test_input}")

    show_set(
        "test set",
        T
    )

    assert T == {1, 2}

    show_set(
        "U + test",
        U | T
    )

    assert U | T == U

    print()

    show_set(
        "U - test",
        U - T
    )

    show_set(
        "test - U",
        T - U
    )

    #
    # Symmetric difference.
    #
    result = U ^ T

    print()

    show_set(
        "result",
        result
    )

    assert result == T ^ U

    #
    # Store calculated result.
    #
    store_set(
        conn,
        5,
        "result",
        result,
        provenance_id
    )

    #
    # Report database contents.
    #
    print()
    print("Database contents")
    print("-----------------")

    rows = conn.execute("""
        SELECT
            sets.set_id,
            sets.uuid,
            sets.tag,
            provenance.uuid,
            GROUP_CONCAT(members.value)
        FROM sets

        JOIN provenance
          ON sets.provenance_id =
             provenance.provenance_id

        LEFT JOIN members
          ON sets.set_id =
             members.set_id

        GROUP BY sets.set_id

        ORDER BY sets.set_id
    """)

    for (
        set_id,
        set_uuid,
        tag,
        provenance_uuid,
        values
    ) in rows:

        print(
            f"{set_id:2d}  "
            f"{set_uuid}  "
            f"{tag:8s}  "
            f"{values}"
        )

        print(
            f"    provenance: "
            f"{provenance_uuid}"
        )

    #
    # Show provenance record.
    #
    print()
    print("Provenance")
    print("----------")

    row = conn.execute("""
        SELECT
            uuid,
            created_at,
            user_name,
            host_name,
            cwd,
            os_name,
            os_release,
            python_version,
            python_executable
        FROM provenance
        WHERE provenance_id = ?
    """, (provenance_id,)).fetchone()

    labels = (
        "UUID",
        "Created",
        "User",
        "Host",
        "CWD",
        "OS",
        "Release",
        "Python",
        "Executable"
    )

    for label, value in zip(labels, row):
        print(f"{label:12s}: {value}")

    conn.close()


if __name__ == "__main__":
    main()