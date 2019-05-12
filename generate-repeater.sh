#!/bin/bash
this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

# Check for arguments
phone_num=$1
output_fname=$2
if [ -z "$phone_num" -o -z "$output_fname" ]; then
    echo "Usage: ./generate-speaker.sh <phone_num> <output_fname>"
    exit 1
fi

# Get random incoming call not from caller
# Only look at `$last_n` recordings
last_n=30
speaker_fname=$(ls -1t "$this_dir/recordings/" | grep '\-in\.wav$' | grep -v $phone_num | grep -Pv '(playback|tmp|out)' | head -n $last_n | shuf -n1)
speaker_fname="$this_dir/recordings/$speaker_fname"

# Copy to output_fname
cp -f $speaker_fname $output_fname

# This shouldn't happen
if [ ! -f "$output_fname" ]; then
    echo "Failed to generate speaker at $output_fname" >&2
    exit 1
fi
