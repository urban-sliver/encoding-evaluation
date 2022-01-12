#!/bin/bash

#
# Execution: bash template.sh 8 degrain
# (Use the non-degrain scripts for non-degrain sources)
#

#####################
# Predefined Values #
#####################

# First arg, default to index 7 if not provided.
if [[ "$1" == "" ]]; then
    SOURCE_KEY="7"
else
    SOURCE_KEY="$1"
fi

# First arg, default to name "degrain" if not provided.
if [[ "$2" == "" ]]; then
    SOURCE_NAME="degrain"
else
    SOURCE_NAME="$2"
fi

REFERENCE="${SOURCE_KEY}0000. ${SOURCE_NAME} reference.mkv"

OUTPUT_DIRECTORY="${SOURCE_KEY}. ${SOURCE_NAME}"

PROFILES=(
    "Debug/H.264 TV Debug"
    "Debug/H.265 TV Debug"
    "Debug/H.264 TV (NVENC)"
    "Debug/H.265 TV (NVENC)"
    "Debug/H.264 TV Debug QSV"
    "Debug/H.265 TV Debug QSV"
)

DENOISE_PROFILES=(
    "Debug/H.264 TV Debug (Denoise)"
    "Debug/H.265 TV Debug (Denoise)"
    "Debug/H.264 TV (NVENC) (Denoise)"
    "Debug/H.265 TV (NVENC) (Denoise)"
    "Debug/H.264 TV Debug QSV (Denoise)"
    "Debug/H.265 TV Debug QSV (Denoise)"
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
    "${SOURCE_KEY}0110"
    "${SOURCE_KEY}0111"
    "${SOURCE_KEY}0112"
    "${SOURCE_KEY}0113"
    "${SOURCE_KEY}0115"
    "${SOURCE_KEY}0116"
)
DESCRIPTIONS=(
    "h264 to h264_degrain"
    "h264 to h265_degrain"
    "h264 to h264_nvenc_degrain"
    "h264 to h265_nvenc_degrain"
    "h264 to h264_qsv_v6_q_degrain"
    "h264 to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.265            ="
echo "============================="
BASE="${SOURCE_KEY}0200. ${SOURCE_NAME} h265"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.265 TV Debug"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0210"
    "${SOURCE_KEY}0211"
    "${SOURCE_KEY}0212"
    "${SOURCE_KEY}0213"
    "${SOURCE_KEY}0215"
    "${SOURCE_KEY}0216"
)
DESCRIPTIONS=(
    "h265 to h264_degrain"
    "h265 to h265_degrain"
    "h265 to h264_nvenc_degrain"
    "h265 to h265_nvenc_degrain"
    "h265 to h264_qsv_v6_q_degrain"
    "h265 to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.264 (NVENC)    ="
echo "============================="
BASE="${SOURCE_KEY}0300. ${SOURCE_NAME} h264_nvenc"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.264 TV (NVENC)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0310"
    "${SOURCE_KEY}0311"
    "${SOURCE_KEY}0312"
    "${SOURCE_KEY}0313"
    "${SOURCE_KEY}0315"
    "${SOURCE_KEY}0316"
)
DESCRIPTIONS=(
    "h264_nvenc to h264_degrain"
    "h264_nvenc to h265_degrain"
    "h264_nvenc to h264_nvenc_degrain"
    "h264_nvenc to h265_nvenc_degrain"
    "h264_nvenc to h264_qsv_v6_q_degrain"
    "h264_nvenc to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.265 (NVENC)    ="
echo "============================="
BASE="${SOURCE_KEY}0400. ${SOURCE_NAME} h265_nvenc"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}"  "Debug/H.265 TV (NVENC)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0410"
    "${SOURCE_KEY}0411"
    "${SOURCE_KEY}0412"
    "${SOURCE_KEY}0413"
    "${SOURCE_KEY}0415"
    "${SOURCE_KEY}0416"
)
DESCRIPTIONS=(
    "h265_nvenc to h264_degrain"
    "h265_nvenc to h265_degrain"
    "h265_nvenc to h264_nvenc_degrain"
    "h265_nvenc to h265_nvenc_degrain"
    "h265_nvenc to h264_qsv_v6_q_degrain"
    "h265_nvenc to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.264 (QSV-V6-Q) ="
echo "============================="
BASE="${SOURCE_KEY}0600. ${SOURCE_NAME} h264_qsv_v6_q"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}"  "Debug/H.264 TV Debug QSV"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0610"
    "${SOURCE_KEY}0611"
    "${SOURCE_KEY}0612"
    "${SOURCE_KEY}0613"
    "${SOURCE_KEY}0615"
    "${SOURCE_KEY}0616"
)
DESCRIPTIONS=(
    "h264_qsv_v6_q to h264_degrain"
    "h264_qsv_v6_q to h265_degrain"
    "h264_qsv_v6_q to h264_nvenc_degrain"
    "h264_qsv_v6_q to h265_nvenc_degrain"
    "h264_qsv_v6_q to h264_qsv_v6_q_degrain"
    "h264_qsv_v6_q to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "============================="
echo "= Encoding H.265 (QSV-V6-Q) ="
echo "============================="
BASE="${SOURCE_KEY}0700. ${SOURCE_NAME} h265_qsv_v6_q"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}"  "Debug/H.265 TV Debug QSV"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}0710"
    "${SOURCE_KEY}0711"
    "${SOURCE_KEY}0712"
    "${SOURCE_KEY}0713"
    "${SOURCE_KEY}0715"
    "${SOURCE_KEY}0716"
)
DESCRIPTIONS=(
    "h265_qsv_v6_q to h264_degrain"
    "h265_qsv_v6_q to h265_degrain"
    "h265_qsv_v6_q to h264_nvenc_degrain"
    "h265_qsv_v6_q to h265_nvenc_degrain"
    "h265_qsv_v6_q to h264_qsv_v6_q_degrain"
    "h265_qsv_v6_q to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "================================"
echo "= Encoding H.264 DN            ="
echo "================================"
BASE="${SOURCE_KEY}1000. ${SOURCE_NAME} h264_degrain"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.264 TV Debug (Denoise)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1001"
    "${SOURCE_KEY}1002"
    "${SOURCE_KEY}1003"
    "${SOURCE_KEY}1004"
    "${SOURCE_KEY}1005"
    "${SOURCE_KEY}1006"
)
DESCRIPTIONS=(
    "h264_degrain to h264"
    "h264_degrain to h265"
    "h264_degrain to h264_nvenc"
    "h264_degrain to h265_nvenc"
    "h264_degrain to h264_qsv_v6_q"
    "h264_degrain to h265_qsv_v6_q"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1010"
    "${SOURCE_KEY}1011"
    "${SOURCE_KEY}1012"
    "${SOURCE_KEY}1013"
    "${SOURCE_KEY}1014"
    "${SOURCE_KEY}1015"
)
DESCRIPTIONS=(
    "h264_degrain to h264_degrain"
    "h264_degrain to h265_degrain"
    "h264_degrain to h264_nvenc_degrain"
    "h264_degrain to h265_nvenc_degrain"
    "h264_degrain to h264_qsv_v6_q_degrain"
    "h264_degrain to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "================================"
echo "= Encoding H.265 DN            ="
echo "================================"
BASE="${SOURCE_KEY}1100. ${SOURCE_NAME} h265_degrain"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.265 TV Debug (Denoise)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1101"
    "${SOURCE_KEY}1102"
    "${SOURCE_KEY}1103"
    "${SOURCE_KEY}1104"
    "${SOURCE_KEY}1105"
    "${SOURCE_KEY}1106"
)
DESCRIPTIONS=(
    "h265_degrain to h264"
    "h265_degrain to h265"
    "h265_degrain to h264_nvenc"
    "h265_degrain to h265_nvenc"
    "h265_degrain to h264_qsv_v6_q"
    "h265_degrain to h265_qsv_v6_q"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1110"
    "${SOURCE_KEY}1111"
    "${SOURCE_KEY}1112"
    "${SOURCE_KEY}1113"
    "${SOURCE_KEY}1114"
    "${SOURCE_KEY}1115"
)
DESCRIPTIONS=(
    "h265_degrain to h264_degrain"
    "h265_degrain to h265_degrain"
    "h265_degrain to h264_nvenc_degrain"
    "h265_degrain to h265_nvenc_degrain"
    "h265_degrain to h264_qsv_v6_q_degrain"
    "h265_degrain to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "================================"
echo "= Encoding H.264 (NVENC) DN    ="
echo "================================"
BASE="${SOURCE_KEY}1200. ${SOURCE_NAME} h264_nvenc_degrain"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.264 TV (NVENC) (Denoise)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1201"
    "${SOURCE_KEY}1202"
    "${SOURCE_KEY}1203"
    "${SOURCE_KEY}1204"
    "${SOURCE_KEY}1205"
    "${SOURCE_KEY}1206"
)
DESCRIPTIONS=(
    "h264_nvenc_degrain to h264"
    "h264_nvenc_degrain to h265"
    "h264_nvenc_degrain to h264_nvenc"
    "h264_nvenc_degrain to h265_nvenc"
    "h264_nvenc_degrain to h264_qsv_v6_q"
    "h264_nvenc_degrain to h265_qsv_v6_q"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1210"
    "${SOURCE_KEY}1211"
    "${SOURCE_KEY}1212"
    "${SOURCE_KEY}1213"
    "${SOURCE_KEY}1214"
    "${SOURCE_KEY}1215"
)
DESCRIPTIONS=(
    "h264_nvenc_degrain to h264_degrain"
    "h264_nvenc_degrain to h265_degrain"
    "h264_nvenc_degrain to h264_nvenc_degrain"
    "h264_nvenc_degrain to h265_nvenc_degrain"
    "h264_nvenc_degrain to h264_qsv_v6_q_degrain"
    "h264_nvenc_degrain to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "================================"
echo "= Encoding H.265 (NVENC) DN    ="
echo "================================"
BASE="${SOURCE_KEY}1300. ${SOURCE_NAME} h265_nvenc_degrain"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.265 TV (NVENC) (Denoise)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1301"
    "${SOURCE_KEY}1302"
    "${SOURCE_KEY}1303"
    "${SOURCE_KEY}1304"
    "${SOURCE_KEY}1305"
    "${SOURCE_KEY}1306"
)
DESCRIPTIONS=(
    "h265_nvenc_degrain to h264"
    "h265_nvenc_degrain to h265"
    "h265_nvenc_degrain to h264_nvenc"
    "h265_nvenc_degrain to h265_nvenc"
    "h265_nvenc_degrain to h264_qsv_v6_q"
    "h265_nvenc_degrain to h265_qsv_v6_q"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1310"
    "${SOURCE_KEY}1311"
    "${SOURCE_KEY}1312"
    "${SOURCE_KEY}1313"
    "${SOURCE_KEY}1314"
    "${SOURCE_KEY}1315"
)
DESCRIPTIONS=(
    "h265_nvenc_degrain to h264_degrain"
    "h265_nvenc_degrain to h265_degrain"
    "h265_nvenc_degrain to h264_nvenc_degrain"
    "h265_nvenc_degrain to h265_nvenc_degrain"
    "h265_nvenc_degrain to h264_qsv_v6_q_degrain"
    "h265_nvenc_degrain to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "================================"
echo "= Encoding H.264 (QSV-V6-Q) DN ="
echo "================================"
BASE="${SOURCE_KEY}1500. ${SOURCE_NAME} h264_qsv_v6_q_degrain"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.264 TV Debug QSV (Denoise)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1501"
    "${SOURCE_KEY}1502"
    "${SOURCE_KEY}1503"
    "${SOURCE_KEY}1504"
    "${SOURCE_KEY}1505"
    "${SOURCE_KEY}1506"
)
DESCRIPTIONS=(
    "h264_qsv_v6_q_degrain to h264"
    "h264_qsv_v6_q_degrain to h265"
    "h264_qsv_v6_q_degrain to h264_nvenc"
    "h264_qsv_v6_q_degrain to h265_nvenc"
    "h264_qsv_v6_q_degrain to h264_qsv_v6_q"
    "h264_qsv_v6_q_degrain to h265_qsv_v6_q"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1510"
    "${SOURCE_KEY}1511"
    "${SOURCE_KEY}1512"
    "${SOURCE_KEY}1513"
    "${SOURCE_KEY}1514"
    "${SOURCE_KEY}1515"
)
DESCRIPTIONS=(
    "h264_qsv_v6_q_degrain to h264_degrain"
    "h264_qsv_v6_q_degrain to h265_degrain"
    "h264_qsv_v6_q_degrain to h264_nvenc_degrain"
    "h264_qsv_v6_q_degrain to h265_nvenc_degrain"
    "h264_qsv_v6_q_degrain to h264_qsv_v6_q_degrain"
    "h264_qsv_v6_q_degrain to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done


echo "================================"
echo "= Encoding H.265 (QSV-V6-Q) DN ="
echo "================================"
BASE="${SOURCE_KEY}1600. ${SOURCE_NAME} h265_qsv_v6_q_degrain"

# Creating first encode file
encode "${REFERENCE%.*}" "${BASE}" "Debug/H.265 TV Debug QSV (Denoise)"

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1601"
    "${SOURCE_KEY}1602"
    "${SOURCE_KEY}1603"
    "${SOURCE_KEY}1604"
    "${SOURCE_KEY}1605"
    "${SOURCE_KEY}1606"
)
DESCRIPTIONS=(
    "h265_qsv_v6_q_degrain to h264"
    "h265_qsv_v6_q_degrain to h265"
    "h265_qsv_v6_q_degrain to h264_nvenc"
    "h265_qsv_v6_q_degrain to h265_nvenc"
    "h265_qsv_v6_q_degrain to h264_qsv_v6_q"
    "h265_qsv_v6_q_degrain to h265_qsv_v6_q"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${PROFILES[$i]}"
done

# Creating second encode files
INDEXES=(
    "${SOURCE_KEY}1610"
    "${SOURCE_KEY}1611"
    "${SOURCE_KEY}1612"
    "${SOURCE_KEY}1613"
    "${SOURCE_KEY}1614"
    "${SOURCE_KEY}1615"
)
DESCRIPTIONS=(
    "h265_qsv_v6_q_degrain to h264_degrain"
    "h265_qsv_v6_q_degrain to h265_degrain"
    "h265_qsv_v6_q_degrain to h264_nvenc_degrain"
    "h265_qsv_v6_q_degrain to h265_nvenc_degrain"
    "h265_qsv_v6_q_degrain to h264_qsv_v6_q_degrain"
    "h265_qsv_v6_q_degrain to h265_qsv_v6_q_degrain"
)

for i in "${!INDEXES[@]}"; do 
    ENCODING_STEP_STRING="${INDEXES[$i]}. ${SOURCE_NAME} ${DESCRIPTIONS[$i]}"
    encode "${BASE}" "${ENCODING_STEP_STRING}" "${DENOISE_PROFILES[$i]}"
done
