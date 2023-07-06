#!/bin/bash
# Thanks to https://medium.com/srcecde/aws-lambda-layer-building-made-easy-2c97572047db
set -e

if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided - please provide layer name, runtime and packages For example: ./create-layer.sh my-layer-name python3.8 requests pytz"
    exit 1
fi

LAYERNAME="$1"
RUNTIME="$2"
# shellcheck disable=SC2124
PACKAGES="${@:3}"

SUPPORT_PYTHON_RUNTIME=("python3.6,python3.7,python3.8,python3.9,python3.10,python3.11")
SUPPORT_NODE_RUNTIME=("nodejs10.x,nodejs12.x,nodejs14.x,nodejs16.x,nodejs18.x")
if [[ "${SUPPORT_NODE_RUNTIME[*]}" != *"${RUNTIME}"* ]] && [[ "${SUPPORT_PYTHON_RUNTIME[*]}" != *"${RUNTIME}"* ]]; then
    echo "${RUNTIME} is not a supported runtime. Supported are: ${SUPPORT_PYTHON_RUNTIME[*]} ${SUPPORT_NODE_RUNTIME[*]}"
    exit 1
fi

REQUIRED_OS_PACKAGES="docker unzip"
for PACKAGE in $REQUIRED_OS_PACKAGES; do
    if ! command -v "${PACKAGE}" &> /dev/null
    then
        echo "${PACKAGE} could not be found, please install it"
        exit 1
    fi
done

echo "================================="
echo "Layer name: $LAYERNAME"
echo "Runtime: $RUNTIME"
echo "Packages: ${PACKAGES}"
echo "================================="

HOST_TEMP_DIR="$(mktemp -d)"

if [[ "${SUPPORT_NODE_RUNTIME[*]}" == *"${RUNTIME}"* ]]; then
    INSTALLATION_PATH="nodejs"
    DOCKER_IMAGE="public.ecr.aws/sam/build-$RUNTIME:latest"
    echo "Preparing lambda layer"
    docker run --rm -v "${HOST_TEMP_DIR}:/lambda-layer" -w "/lambda-layer" "${DOCKER_IMAGE}" /bin/bash -c "mkdir ${INSTALLATION_PATH} && npm install --prefix ${INSTALLATION_PATH} --save ${PACKAGES} && zip -r lambda-layer.zip * && rm -rf ${INSTALLATION_PATH}"
elif [[ "${SUPPORT_PYTHON_RUNTIME[*]}" == *"${RUNTIME}"* ]]; then
    INSTALLATION_PATH="python"
    DOCKER_IMAGE="public.ecr.aws/sam/build-$RUNTIME:latest"
    echo "Preparing lambda layer"
    docker run --rm -v "${HOST_TEMP_DIR}:/lambda-layer" -w "/lambda-layer" "${DOCKER_IMAGE}" /bin/bash -c "mkdir ${INSTALLATION_PATH} && pip install ${PACKAGES} -t ${INSTALLATION_PATH}  && zip -r lambda-layer.zip * -x '*/__pycache__/*' && rm -rf ${INSTALLATION_PATH}"
fi

cp "${HOST_TEMP_DIR}"/lambda-layer.zip "${LAYERNAME}".zip

echo "Deleting temporary files"
docker run --rm -v "${HOST_TEMP_DIR}:/lambda-layer"  -w "/lambda-layer" "${DOCKER_IMAGE}" /bin/bash -c "rm -rf lambda-layer.zip";
rm -rf "${HOST_TEMP_DIR}"

echo "Finishing up - find your layer file as ${LAYERNAME}.zip"
