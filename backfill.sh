#!/bin/bash
this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

for fpath in $(
    find $this_dir/recordings \
        -type f \
        -regextype egrep -regex '.*\.[0-9]+\.wav$' | \
        sort -V
); do
    modify_ts=$(stat -c %Y $fpath)
    track_name=$(date -d "@$modify_ts" +'%F-%H%M%S')
    $this_dir/upload.sh "$fpath" "$track_name"
done
