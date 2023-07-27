#!/usr/bin/env bash

sizes=$(forge build --sizes)
names=($(cat ./configs/package.yaml | grep "    contractName:" | sed -r 's/.{18}//'))

for i in "${!names[@]}"; do
    line=$(echo "$sizes" | grep -w "${names[i]}")
    echo $line

    if [[ $line == *"-"* ]]; then
        echo "${names[i]} is too large"
        exit 1
    fi
done
