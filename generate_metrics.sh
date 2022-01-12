#!/bin/bash

# Execution: bash generate_metrics.sh <index> <name>
#      e.g.: bash generate_metrics.sh 1 bluray


#####################
# Pre-Check         #
#####################
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "ffmpeg (compiled with libvmaf) and ffprobe required"
    echo "You can either compile manually, or acquire binaries from:"
    echo "    (Linux)   https://www.johnvansickle.com/ffmpeg/"
    echo "    (Windows) https://www.gyan.dev/ffmpeg/builds/"
    exit 1
fi

if ! command -v ffmpeg_quality_metrics &> /dev/null; then
    echo "ffmpeg_quality_metrics required"
    echo "Download/installation instructions can be found at: https://github.com/slhck/ffmpeg-quality-metrics"
    exit 1
fi

#####################
# Variables         #
#####################
# First arg, default to index 0 if not provided.
if [[ "$1" == "" ]]; then
    SOURCE_KEY="1"
else
    SOURCE_KEY="$1"
fi

# Second arg, default to name "webdl" if not provided.
if [[ "$2" == "" ]]; then
    SOURCE_NAME="bluray"
else
    SOURCE_NAME="$2"
fi

# Number of cores and threads, used for VMAF and PSNR/SSIM respectively
THREADS=$(grep -c MHz /proc/cpuinfo)
CORES=$((THREADS / 2))

REFERENCE="./data/${SOURCE_KEY}0000. ${SOURCE_NAME} reference.mkv"
if [[ ! -f "${REFERENCE}" ]]; then
    echo "Reference \"${REFERENCE}\" does not exist"
    exit 1
fi

REFERENCE_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 "${REFERENCE}")
echo "Reference Height: ${REFERENCE_HEIGHT}"

if [[ "${REFERENCE_HEIGHT}" == "2160" ]]; then
    MODEL_FILE="vmaf_4k_v0.6.1.json"
else
    MODEL_FILE="vmaf_v0.6.1.json"
fi
echo "Model to use: ${MODEL_FILE}"

if [[ ! -f "${MODEL_FILE}" ]]; then
    echo "Downloading model"
    curl https://raw.githubusercontent.com/Netflix/vmaf/master/model/"${MODEL_FILE}" --output "${MODEL_FILE}"
fi

# Work loop
for FILE in ./data/"${SOURCE_KEY}"*.mkv; do
    shortname=$(basename "$FILE")
    report_file=$(basename "$shortname" .mkv).xml
    quality_file=$(basename "$shortname" .mkv).json

    if [[ "${shortname}" != *"0000"* ]]; then
        echo "Processing \"${shortname}\""

        if [[ ! -f "./reports/${report_file}" ]]; then
            # "-hide_banner -loglevel warning -stats" removes output except warnings and progress
            # Feel free to remove those options if you want to see file information before computing VMAF
            ffmpeg -hide_banner -loglevel warning -stats -i "${FILE}" -i "${REFERENCE}" -lavfi libvmaf=model_path="${MODEL_FILE}":log_path="./reports/${report_file}":n_threads="${CORES}" -f null -
        fi

        # I'm aware that ffmpeg_quality_metrics can compute vmaf as well, but I:
        #  1. wasn't aware until after I started computing vmaf
        #  2. couldn't get it working and accepted this as good enough
        if [[ ! -f "./reports/${quality_file}" ]]; then
            # I generated my data and only discovered "-p" prints progress to not stdout, which
            # has exhausted me greatly.
            ffmpeg_quality_metrics --metrics psnr ssim --threads "${THREADS}" "${FILE}" "${REFERENCE}" -p > "./reports/${quality_file}"
        fi
    fi
done
