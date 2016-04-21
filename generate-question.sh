#!/bin/bash

this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
output_fname=$1
if [ -z $output_fname ]; then
    echo "Usage: ./generate-question.sh <output_fname>"
    exit 1
fi

question=$(shuf -n1 "$this_dir/questions")
question="Question <break strength='strong'/>
    <prosody rate='.85'>$question</prosody>
    <break strength='strong'/>Answer in 60 seconds."
tts $output_fname $question >/dev/null 2>&1

if [ ! -f "$output_fname" ]; then
    exit 1
fi
