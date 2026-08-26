#!/usr/bin/env bash

printf "%s\n" "$(tput bold)$(date) ${BASH_SOURCE[0]}$(tput sgr0)"

# Initialize counters
counter=0
subcounter=0
start_time=${SECONDS}

# Step Functions
function new_step() {
    export counter=$((counter + 1))
    export subcounter=0
    echo ""
    echo "Step ${counter}: ${1}"
}

function sub_step() {
    export subcounter=$((subcounter + 1))
    echo ""
    echo "  Substep ${counter}.${subcounter}: ${1}"
}

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

PYTHON_SCRIPT="myloop.py"
N_JOBS=25
MODULUS=10

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

new_step "Launch parallel Python jobs"

for k in $(seq 1 "${N_JOBS}"); do

    j=$((k % MODULUS))

    sub_step "Launch k=${k}, j=${j}"

    python3 "${PYTHON_SCRIPT}" "${j}" &

# bash parallelism in line 43 using the character &

done

new_step "Wait for all Python processes"

wait

new_step "Complete"

elapsed=$((SECONDS - start_time))

printf "time to execute parallel Python demo: %dh:%dm:%ds\n" \
    $((elapsed / 3600)) \
    $((elapsed % 3600 / 60)) \
    $((elapsed % 60))

echo "Elapsed time: ${elapsed} seconds"

