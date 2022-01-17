#!/bin/bash
this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

# Set vars
snd_them=$1
snd_us=$2
snd_mix=$3
snd_tmp1="${snd_mix}.tmp1.wav"
snd_tmp2="${snd_mix}.tmp2.wav"
min_len=3
phone_num=$(basename $snd_mix | cut -d'-' -f4)
playback_fname="$(dirname $snd_mix)/$(basename -s .wav $snd_mix)-playback.wav";

# Define die function
die() { echo "$@" >&2; exit 1; }

# Define cleanup function to run on exit
cleanup() { rm -f $playback_fname $snd_tmp1 $snd_tmp2 $snd_us; }
trap cleanup EXIT

# Ensure snd_them is not silent
sox $snd_them $snd_tmp1 silence 1 0.1 1% &>/dev/null || die "sox failed to trim snd_them (1)"
sox $snd_tmp1 $snd_tmp2 reverse          &>/dev/null || die "sox failed to reverse snd_them (1)"
sox $snd_tmp2 $snd_tmp1 silence 1 0.1 1% &>/dev/null || die "sox failed to trim snd_them (2)"
sox $snd_tmp1 $snd_tmp2 reverse          &>/dev/null || die "sox failed to reverse snd_them (2)"
them_len=$(sox $snd_tmp2 -n stat 2>&1 | grep Length | awk '{print $3}' | cut -d'.' -f1)
if [ "$them_len" -le "$min_len" ]; then
    snd_them_silent="${snd_them}.silent"
    mv $snd_them $snd_them_silent
    die "Not uploading short call; snd_them=$snd_them_silent them_len=${them_len}"
fi

# Mix into single audio file
sox -m $snd_us $snd_them $snd_mix gain -n -l 3 &>/dev/null || die "sox failed to mix snd_mix"

# Trim both ends of mix
sox $snd_mix  $snd_tmp1 silence 1 0.1 1% &>/dev/null || die "sox failed to trim snd_mix (1)"
sox $snd_tmp1 $snd_tmp2 reverse          &>/dev/null || die "sox failed to reverse snd_mix (1)"
sox $snd_tmp2 $snd_tmp1 silence 1 0.1 1% &>/dev/null || die "sox failed to trim snd_mix (2)"
sox $snd_tmp1 $snd_mix  reverse          &>/dev/null || die "sox failed to reverse snd_mix (2)"

# Trim silence from beginning of in audio
sox $snd_them $snd_tmp1 silence 1 0.1 1% &>/dev/null || die "sox failed to trim in audio"
cp -f $snd_tmp1 $snd_them

# Bail early if KEELPBX_NO_SC
[ -n "$KEELPBX_NO_SC" ] && die "Bailing early because KEELPBX_NO_SC==$KEELPBX_NO_SC"

# Invoke upload script
track_name=$(date +'%F-%H%M%S')
$this_dir/upload.sh "$snd_mix" "$track_name" || die "Failed to upload $snd_mix"

# Fin
echo "Uploaded! $snd_mix -> $track_name"
