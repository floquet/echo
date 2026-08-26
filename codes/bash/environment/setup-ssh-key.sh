#!/usr/bin/env bash
printf "%s\n" "$(date), $(tput bold)${BASH_SOURCE[0]}$(tput sgr0)"
counter=0; start_time=${SECONDS}

function new_step() { counter=$((counter + 1)); echo -e "\nStep ${counter}: ${1}"; }

new_step "Generating SSH Key: ssh-keygen -t ed25519 -N \"\" -f ~/.ssh/id_ed25519"
                              ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

new_step "Reading Public Key: cat ~/.ssh/id_ed25520.pub"
                    pub_key=$(cat ~/.ssh/id_ed25519.pub)

echo -e "\n------------------------------------------------------------"
echo "Key to use with gitlab. Protect this key. Access as \$pub_key"
echo "$pub_key"
echo "------------------------------------------------------------"

elapsed=$((${SECONDS} - ${start_time}))
printf 'elapsed time: %dh:%dm:%ds\n' $((${elapsed} / 3600)) $((${elapsed} % 3600 / 60)) $((${elapsed} % 60))
