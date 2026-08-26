#!/usr/bin/env python3

import os
import sys
import threading
import time


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

def main():

    j = int(sys.argv[1])

    pid = os.getpid()
    tid = threading.get_native_id()
    cpu_count = os.cpu_count()

    print(
        f"I am process {pid}, thread {tid}, "
        f"job {j}, running on a machine with {cpu_count} CPUs.",
        flush=True,
    )

    time.sleep(j)

    print(
        f"I am process {pid}, thread {tid}, "
        f"job {j}, and I am finished.",
        flush=True,
    )


if __name__ == "__main__":
    main()

# :dantopa@isomer:~/repos-isomer/github/jop/python/bae/parallel$ ./myloop.sh 
# Mon Aug 17 02:48:43 PM MDT 2026 ./myloop.sh
# 
# Step 1: Launch parallel Python jobs
# 
#   Substep 1.1: Launch k=1, j=1
# 
#   Substep 1.2: Launch k=2, j=2
# 
#   Substep 1.3: Launch k=3, j=3
# 
#   Substep 1.4: Launch k=4, j=4
# 
#   Substep 1.5: Launch k=5, j=5
# 
#   Substep 1.6: Launch k=6, j=6
# 
#   Substep 1.7: Launch k=7, j=7
# 
#   Substep 1.8: Launch k=8, j=8
# 
#   Substep 1.9: Launch k=9, j=9
# 
#   Substep 1.10: Launch k=10, j=0
# 
#   Substep 1.11: Launch k=11, j=1
# 
#   Substep 1.12: Launch k=12, j=2
# 
#   Substep 1.13: Launch k=13, j=3
# 
#   Substep 1.14: Launch k=14, j=4
# 
#   Substep 1.15: Launch k=15, j=5
# 
#   Substep 1.16: Launch k=16, j=6
# 
#   Substep 1.17: Launch k=17, j=7
# 
#   Substep 1.18: Launch k=18, j=8
# 
#   Substep 1.19: Launch k=19, j=9
# 
#   Substep 1.20: Launch k=20, j=0
# 
#   Substep 1.21: Launch k=21, j=1
# 
#   Substep 1.22: Launch k=22, j=2
# 
#   Substep 1.23: Launch k=23, j=3
# 
#   Substep 1.24: Launch k=24, j=4
# 
#   Substep 1.25: Launch k=25, j=5
# 
# Step 2: Wait for all Python processes
# I am process 660618, thread 660618, job 4, running on a machine with 14 CPUs.
# I am process 660619, thread 660619, job 5, running on a machine with 14 CPUs.
# I am process 660616, thread 660616, job 2, running on a machine with 14 CPUs.
# I am process 660622, thread 660622, job 8, running on a machine with 14 CPUs.
# I am process 660623, thread 660623, job 9, running on a machine with 14 CPUs.
# I am process 660624, thread 660624, job 0, running on a machine with 14 CPUs.
# I am process 660624, thread 660624, job 0, and I am finished.
# I am process 660640, thread 660640, job 5, running on a machine with 14 CPUs.
# I am process 660617, thread 660617, job 3, running on a machine with 14 CPUs.
# I am process 660628, thread 660628, job 4, running on a machine with 14 CPUs.
# I am process 660638, thread 660638, job 3, running on a machine with 14 CPUs.
# I am process 660615, thread 660615, job 1, running on a machine with 14 CPUs.
# I am process 660625, thread 660625, job 1, running on a machine with 14 CPUs.
# I am process 660630, thread 660630, job 6, running on a machine with 14 CPUs.
# I am process 660632, thread 660632, job 8, running on a machine with 14 CPUs.
# I am process 660621, thread 660621, job 7, running on a machine with 14 CPUs.
# I am process 660634, thread 660634, job 0, running on a machine with 14 CPUs.
# I am process 660627, thread 660627, job 3, running on a machine with 14 CPUs.
# I am process 660634, thread 660634, job 0, and I am finished.
# I am process 660639, thread 660639, job 4, running on a machine with 14 CPUs.
# I am process 660629, thread 660629, job 5, running on a machine with 14 CPUs.
# I am process 660631, thread 660631, job 7, running on a machine with 14 CPUs.
# I am process 660620, thread 660620, job 6, running on a machine with 14 CPUs.
# I am process 660636, thread 660636, job 2, running on a machine with 14 CPUs.
# I am process 660633, thread 660633, job 9, running on a machine with 14 CPUs.
# I am process 660635, thread 660635, job 1, running on a machine with 14 CPUs.
# I am process 660626, thread 660626, job 2, running on a machine with 14 CPUs.
# I am process 660615, thread 660615, job 1, and I am finished.
# I am process 660625, thread 660625, job 1, and I am finished.
# I am process 660635, thread 660635, job 1, and I am finished.
# I am process 660616, thread 660616, job 2, and I am finished.
# I am process 660636, thread 660636, job 2, and I am finished.
# I am process 660626, thread 660626, job 2, and I am finished.
# I am process 660617, thread 660617, job 3, and I am finished.
# I am process 660638, thread 660638, job 3, and I am finished.
# I am process 660627, thread 660627, job 3, and I am finished.
# I am process 660618, thread 660618, job 4, and I am finished.
# I am process 660628, thread 660628, job 4, and I am finished.
# I am process 660639, thread 660639, job 4, and I am finished.
# I am process 660619, thread 660619, job 5, and I am finished.
# I am process 660640, thread 660640, job 5, and I am finished.
# I am process 660629, thread 660629, job 5, and I am finished.
# I am process 660630, thread 660630, job 6, and I am finished.
# I am process 660620, thread 660620, job 6, and I am finished.
# I am process 660621, thread 660621, job 7, and I am finished.
# I am process 660631, thread 660631, job 7, and I am finished.
# I am process 660622, thread 660622, job 8, and I am finished.
# I am process 660632, thread 660632, job 8, and I am finished.
# I am process 660623, thread 660623, job 9, and I am finished.
# I am process 660633, thread 660633, job 9, and I am finished.
# 
# Step 3: Complete
# time to execute parallel Python demo: 0h:0m:9s
# Elapsed time: 9 seconds

