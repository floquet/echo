#!/usr/bin/env python3

import datetime
import os
import platform
import socket
import sys
import time
from pathlib import Path


def print_provenance():

    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    user = os.getlogin()
    script_path = Path(__file__).resolve()
    working_directory = Path.cwd()

    print("\n=== BASIC PROVENANCE ===")
    print(f"Timestamp: {current_time}")
    print(f"User: {user}")
    print(f"Script: {script_path}")
    print(f"Working directory: {working_directory}")

    print("\n=== SYSTEM ===")
    print(f"OS: {platform.system()} {platform.release()}")
    print(f"Machine: {platform.machine()}")
    print(f"Processor: {platform.processor()}")

    print("\n=== PYTHON ===")
    print(f"Version: {platform.python_version()}")
    print(f"Executable: {sys.executable}")
    print(f"Implementation: {platform.python_implementation()}")


def main():

    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <job_number>")
        sys.exit(1)

    job_number = int(sys.argv[1])

    pid = os.getpid()
    ppid = os.getppid()
    hostname = socket.gethostname()

    start_time = datetime.datetime.now()
    start_perf = time.perf_counter()

    print("")
    print("=== PROCESS START ===")
    print(f"Job number: {job_number}")
    print(f"PID: {pid}")
    print(f"Parent PID: {ppid}")
    print(f"Hostname: {hostname}")
    print(f"Start time: {start_time:%Y-%m-%d %H:%M:%S.%f}")

    #
    # Deliberately make each process take a different amount of time.
    #
    sleep_time = job_number

    print(f"Sleep time: {sleep_time} seconds")
    print(f"State: RUNNING")

    time.sleep(sleep_time)

    stop_time = datetime.datetime.now()
    elapsed = time.perf_counter() - start_perf

    print("")
    print("=== PROCESS COMPLETE ===")
    print(f"Job number: {job_number}")
    print(f"PID: {pid}")
    print(f"State: COMPLETE")
    print(f"Stop time: {stop_time:%Y-%m-%d %H:%M:%S.%f}")
    print(f"Elapsed time: {elapsed:.6f} seconds")

    # print_provenance()


if __name__ == "__main__":
    main()
