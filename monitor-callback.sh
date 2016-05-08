#!/bin/bash

# Source SoundCloud auth vars
this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
sc_auth_path="$this_dir/soundcloud-auth.sh"
if [ ! -f "$sc_auth_path" ]; then
    echo "SoundCloud auth file not found at $sc_auth_path" >&2
    exit 1
fi
source $sc_auth_path

# Mix into single audio file
sox -m $1 $2 $3 gain -n -l 6 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "sox failed to mix audio" >&2
    exit 1
fi
rm -f $1 $2

# Remove question wav
question_fname="$(dirname $3)/$(basename -s .wav $3)-question.wav";
rm -f $question_fname

# Do not upload calls from weird numbers
phone_num=$(basename $3 | cut -d'-' -f4)
if [ ${#phone_num} -lt 10 ]; then
    echo "Not uploading call from phone_num=${phone_num}" >&2
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
    -F "track[asset_data]=@${3}" \
    -F "track[title]=${track_name}" \
    -F 'track[sharing]=public' >/dev/null
if [ $? -eq 0 ]; then
    echo "$3 -> $track_name"
else
    echo "Failed to upload audio to SoundCloud" >&2
    exit
fi
