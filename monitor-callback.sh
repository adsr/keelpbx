#!/bin/bash

# Source SoundCloud auth vars
this_dir=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source "$this_dir/soundcloud-auth.sh"

# Mix into single audio file
sox -m $1 $2 $3 gain -n -l 6 >/dev/null 2>&1
[ $? -eq 0 ] || exit 1
rm -f $1 $2

# Remove question wav
question_fname="$(dirname $3)/$(basename -s .wav $3)-question.wav";
rm -f $question_fname

# Get SoundCloud auth token
auth_token=$(curl -sX POST 'https://api.soundcloud.com/oauth2/token' \
    -F "client_id=${sc_client_id}" \
    -F "client_secret=${sc_client_secret}" \
    -F "grant_type=password" \
    -F "username=${sc_username}" \
    -F "password=${sc_password}" | \
    grep -Po '(?<="access_token":")[^"]+(?=")')
[ -n "$auth_token" ] || exit 1

# Upload audio to SoundCloud
track_name=$(date +'%F-%H%M%S')
curl --fail -sX POST 'https://api.soundcloud.com/tracks.json' \
    -F "oauth_token=${auth_token}" \
    -F "track[asset_data]=@${3}" \
    -F "track[title]=${track_name}" \
    -F 'track[sharing]=public' >/dev/null
[ $? -eq 0 ] && echo "$3 -> $track_name"
