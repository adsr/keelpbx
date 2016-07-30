#!/bin/bash

this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

# Check for output argument
output_fname=$1
if [ -z "$output_fname" ]; then
    echo "Usage: ./generate-speaker.sh <output_fname>"
    exit 1
fi

# Get last incoming call
speaker_fname=$(ls -1t "$this_dir/recordings/" | grep 'in.wav$' | head -n1)
speaker_fname="$this_dir/recordings/$speaker_fname"

# Copy to output_fname
cp -f $speaker_fname $output_fname

# This shouldn't happen
if [ ! -f "$output_fname" ]; then
    echo "Failed to generate speaker at $output_fname" >&2
    exit 1
fi
