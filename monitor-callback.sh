#!/bin/bash

# Set vars
snd_them=$1
snd_us=$2
snd_mix=$3
phone_num=$(basename $snd_mix | cut -d'-' -f4)
question_fname="$(dirname $snd_mix)/$(basename -s .wav $snd_mix)-question.wav";
this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
sc_auth_path="$this_dir/soundcloud-auth.sh"

# Source SoundCloud auth vars
if [ ! -f "$sc_auth_path" ]; then
    echo "SoundCloud auth file not found at $sc_auth_path" >&2
    exit 1
fi
source $sc_auth_path

# Mix into single audio file
sox -m $snd_us $snd_them $snd_mix gain -n -l 6 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "sox failed to mix audio" >&2
    exit 1
fi
rm -f $snd_us

# Remove question wav
question_len=$(sox $question_fname -n stat 2>&1 | grep Length | awk '{print $3}' | cut -d'.' -f1)
question_len=$((question_len+0))
rm -f $question_fname

# Do not upload hang-up calls
mix_len=$(sox $snd_mix -n stat 2>&1 | grep Length | awk '{print $3}' | cut -d'.' -f1)
mix_len=$((mix_len-2))
if [ "$mix_len" -le "$question_len" ]; then
    echo "Discarding hang-up call from phone_num=${phone_num}" >&2
    rm -f $snd_them $snd_mix
    exit 1
fi

# Get SoundCloud auth token
auth_token=$(curl -sX POST 'https://api.soundcloud.com/oauth2/token' \
    -F "client_id=${sc_client_id}" \
    -F "client_secret=${sc_client_secret}" \
    -F "grant_type=password" \
    -F "username=${sc_username}" \
    -F "password=${sc_password}" | \
    grep -Po '(?<="access_token":")[^"]+(?=")')
if [ -z "$auth_token" ]; then
    echo "Failed to get auth token from SoundCloud" >&2
    exit 1
fi

# Upload audio to SoundCloud
track_name=$(date +'%F-%H%M%S')
curl --fail -sX POST 'https://api.soundcloud.com/tracks.json' \
    -F "oauth_token=${auth_token}" \
    -F "track[asset_data]=@${snd_mix}" \
    -F "track[title]=${track_name}" \
    -F 'track[sharing]=public' >/dev/null
if [ $? -ne 0 ]; then
    echo "Possibly failed to upload audio to SoundCloud" >&2
fi
echo "$snd_mix -> $track_name"
