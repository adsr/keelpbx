#!/bin/bash

this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

# Check for output argument
output_fname=$1
if [ -z $output_fname ]; then
    echo "Usage: ./generate-question.sh <output_fname>"
    exit 1
fi

# Run question through text-to-speech
question=$(shuf -n1 "$this_dir/questions")
question="Question <break strength='strong'/>
    <prosody rate='.85'>$question</prosody>
    <break strength='strong'/>Answer in 60 seconds."
tts $output_fname $question >/dev/null 2>&1

if [ ! -f "$output_fname" ]; then
    echo "tts failed to output $output_fname" >&2
    exit 1
fi
