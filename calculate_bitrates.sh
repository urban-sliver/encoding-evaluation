#!/bin/bash

# This is handled by the python script now, but I left in case I didn't want to use the python script
# or I needed to refer back to it.  It may help someone in the future.

for FILE in ./data/*; do
    mkvpropedit --add-track-statistics-tags "${FILE}" > /dev/null 2>&1

    # I was getting an additional line of output, "side_data", so I'm ignoring that and grabbing
    # the first line of output, which is the BPS as tagged by mkvpropedit
    ffprobe -v error -select_streams v:0 -show_entries stream_tags=BPS -of csv=p=0 "${FILE}" | head -n1
done
