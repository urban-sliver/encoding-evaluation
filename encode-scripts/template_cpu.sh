#!/bin/bash

#
# Execution: bash template.sh <index> <name>
#      e.g.: bash template.sh 1 bluray
#            bash template.sh 5 fork
# 

#####################
# Predefined Values #
#####################

# First arg, default to index 1 if not provided.
if [[ "$1" == "" ]]; then
    SOURCE_KEY="1"
else
    SOURCE_KEY="$1"
fi

# First arg, default to name "bluray" if not provided.
if [[ "$2" == "" ]]; then
    SOURCE_NAME="bluray"
else
    SOURCE_NAME="$2"
fi

REFERENCE="${SOURCE_KEY}0000. ${SOURCE_NAME} reference.mkv"

OUTPUT_DIRECTORY="${SOURCE_KEY}. ${SOURCE_NAME}"

PROFILES=(
    "Debug/H.264 TV Debug"
    "Debug/H.265 TV Debug"
)

PRESET_PATH="./presets.json"

#####################
# Functions         #
#####################
function debug {
    echo "$(date +%T) [  DEBUG] ${1}"
}

function log {
    echo "$(date +%T) [    LOG] ${1}"
}

function warning {
    echo "$(date +%T) [WARNING] ${1}"
}

function error {
    echo "$(date +%T) [  ERROR] ${1}"
}

function encode {
    # Args: input name, output name, profile
    INPUT_NAME="$1"
    OUTPUT_NAME="$2"
    PROFILE="$3"
    
    if [[ ! -f "${OUTPUT_DIRECTORY}/${INPUT_NAME}.mkv" ]]; then
        warning "Can't encode \"${OUTPUT_DIRECTORY}/${OUTPUT_NAME}.mkv\"; missing input ${OUTPUT_DIRECTORY}/${INPUT_NAME}"
        return
    fi
    
    if [[ -f "${OUTPUT_DIRECTORY}/${OUTPUT_NAME}.mkv" ]]; then
        warning "Won't encode \"${OUTPUT_DIRECTORY}/${OUTPUT_NAME}.mkv\"; file already exists"
        return
    fi
    
    if [[ "${INPUT_NAME}" != *"00. "* ]]; then
        if [[ ! -f "${OUTPUT_DIRECTORY}/logs/${INPUT_NAME}.txt" ]] || ! grep -q "Encode done!" "${OUTPUT_DIRECTORY}/logs/${INPUT_NAME}.txt"; then
            warning "Won't encode \"${OUTPUT_DIRECTORY}/${OUTPUT_NAME}.mkv\"; input encode has not finished"
            return
        fi
    fi
    
    log "Encoding ${OUTPUT_DIRECTORY}/${OUTPUT_NAME}.mkv"
    debug "HandBrakeCLI --preset-import-file \"${PRESET_PATH}\" -i \"${OUTPUT_DIRECTORY}/${INPUT_NAME}.mkv\"  -o \"${OUTPUT_DIRECTORY}/${OUTPUT_NAME}.mkv\" -Z \"${PROFILE}\" > \"./${OUTPUT_DIRECTORY}/logs/${OUTPUT_NAME}.txt\""
    HandBrakeCLI --preset-import-file "${PRESET_PATH}" -i "${OUTPUT_DIRECTORY}/${INPUT_NAME}.mkv" -o "${OUTPUT_DIRECTORY}/${OUTPUT_NAME}.mkv" -Z "${PROFILE}" > "./${OUTPUT_DIRECTORY}/logs/${OUTPUT_NAME}.txt" 2>&1
    
    # Reports FPS at the end of encode
    # && grep "task 1 of 1" "./logs/${OUTPUT_NAME}.txt" | tail -n 1 | cut -d "," -f 3 | cut -d " " -f 3
}


#####################
# Script Start      #
#####################
mkdir -p "${OUTPUT_DIRECTORY}"/logs


echo "============================="
echo "= Encoding H.264            ="
echo "============================="
BASE="${SOURCE_KEY}0100. ${SOURCE_NAME} h264"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.264 TV Debug"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0101"
    "${SOURCE_KEY}0102"
)
DESCRIPTIONS=(
    "h264 to h264"
    "h264 to h265"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.265            ="
echo "============================="
BASE="${SOURCE_KEY}0200. ${SOURCE_NAME} h265"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.265 TV Debug"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0201"
    "${SOURCE_KEY}0202"
)
DESCRIPTIONS=(
    "h265 to h264"
    "h265 to h265"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.264 (NVENC)    ="
echo "============================="
BASE="${SOURCE_KEY}0300. ${SOURCE_NAME} h264_nvenc"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0301"
    "${SOURCE_KEY}0302"
)
DESCRIPTIONS=(
    "h264_nvenc to h264"
    "h264_nvenc to h265"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.265 (NVENC)    ="
echo "============================="
BASE="${SOURCE_KEY}0400. ${SOURCE_NAME} h265_nvenc"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0401"
    "${SOURCE_KEY}0402"
)
DESCRIPTIONS=(
    "h265_nvenc to h264"
    "h265_nvenc to h265"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.264 (QSV-V6-Q) ="
echo "============================="
BASE="${SOURCE_KEY}0600. ${SOURCE_NAME} h264_qsv_v6_q"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0601"
    "${SOURCE_KEY}0602"
)
DESCRIPTIONS=(
    "h264_qsv_v6_q to h264"
    "h264_qsv_v6_q to h265"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.265 (QSV-V6-Q) ="
echo "============================="
BASE="${SOURCE_KEY}0700. ${SOURCE_NAME} h265_qsv_v6_q"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0701"
    "${SOURCE_KEY}0702"
)
DESCRIPTIONS=(
    "h265_qsv_v6_q to h264"
    "h265_qsv_v6_q to h265"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done
