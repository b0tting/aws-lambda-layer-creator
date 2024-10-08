#!/bin/bash
# Thanks to https://medium.com/srcecde/aws-lambda-layer-building-made-easy-2c97572047db
set -e

function add_creation_message() {
  INCLUDE_MESSAGE=$(echo "This lambda layer has been created by the 'aws-layer-creator' script (https://github.com/b0tting/aws-lambda-layer-creator). To recreate this layer, use the following command:")
  INCLUDE_MESSAGE="${INCLUDE_MESSAGE}\n\n$*"
  docker run ${DOCKER_PARAMETERS} "${DOCKER_IMAGE}" /bin/bash -c "echo -e \"${INCLUDE_MESSAGE}\" > README.md"
}


if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided - please provide layer name, runtime and packages For example: ./create-layer.sh my-layer-name python3.8 requests pytz"
    exit 1
fi


while getopts ":n:r:p:m:" opt
   do
     case $opt in
        n ) LAYERNAME=$OPTARG;;
        r ) RUNTIME=$OPTARG;;
        p ) PROXY=$OPTARG;;
        m ) PACKAGES=$OPTARG;;
        * ) echo "Invalid option: -$OPTARG" >&2
            exit 1;;
     esac
done

if [[ -z $LAYERNAME || -z $RUNTIME || -z $PACKAGES ]]; then
  echo 'One or more requirements (-n, -r , -m) are missing'
  exit 1
fi

# Rescueing precious chars from bash expansion
PACKAGES="${PACKAGES/</\\<}"
PACKAGES="${PACKAGES/>/\\>}"

SUPPORT_PYTHON_RUNTIME=("python3.6,python3.7,python3.8,python3.9,python3.10,python3.11,python3.12,python3.13")
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
if [[ -n $PROXY ]]; then
    echo "Proxy: $PROXY"
fi
echo "================================="

HOST_TEMP_DIR="$(mktemp -d)"
DOCKER_PARAMETERS="--rm -v ${HOST_TEMP_DIR}:/lambda-layer -w /lambda-layer"
if [[ -n $PROXY ]]; then
    # shellcheck disable=SC2089
    DOCKER_PARAMETERS="${DOCKER_PARAMETERS} --env HTTP_PROXY=\"${PROXY}\" --env HTTPS_PROXY=\"${PROXY}\""
fi

if [[ "${SUPPORT_NODE_RUNTIME[*]}" == *"${RUNTIME}"* ]]; then
    INSTALLATION_PATH="nodejs"
    DOCKER_IMAGE="public.ecr.aws/sam/build-$RUNTIME:latest"
    echo "Preparing lambda layer"
    # shellcheck disable=SC2090,SC2086
    docker run ${DOCKER_PARAMETERS} "${DOCKER_IMAGE}" /bin/bash -c "mkdir ${INSTALLATION_PATH}"
    add_creation_message "$0 $*"
    # shellcheck disable=SC2090,SC2086
    docker run ${DOCKER_PARAMETERS} "${DOCKER_IMAGE}" /bin/bash -c "npm install --prefix ${INSTALLATION_PATH} --save ${PACKAGES} && zip -r lambda-layer.zip * && rm -rf ${INSTALLATION_PATH}"
elif [[ "${SUPPORT_PYTHON_RUNTIME[*]}" == *"${RUNTIME}"* ]]; then
    INSTALLATION_PATH="python"
    DOCKER_IMAGE="public.ecr.aws/sam/build-$RUNTIME:latest"
    echo "Preparing lambda layer"
    # shellcheck disable=SC2090,SC2086
    docker run ${DOCKER_PARAMETERS} "${DOCKER_IMAGE}" /bin/bash -c "mkdir ${INSTALLATION_PATH}"
    add_creation_message "$0 $*"
    # shellcheck disable=SC2090,SC2086
    docker run ${DOCKER_PARAMETERS} "${DOCKER_IMAGE}" /bin/bash -c "pip install ${PACKAGES} -t ${INSTALLATION_PATH}  && zip -r lambda-layer.zip * -x '*/__pycache__/*' && rm -rf ${INSTALLATION_PATH}"
fi

cp "${HOST_TEMP_DIR}"/lambda-layer.zip "${LAYERNAME}".zip

echo "Deleting temporary files"
docker run --rm -v "${HOST_TEMP_DIR}:/lambda-layer"  -w "/lambda-layer" "${DOCKER_IMAGE}" /bin/bash -c "rm -rf lambda-layer.zip";
rm -rf "${HOST_TEMP_DIR}"

echo "Finishing up - find your layer file as ${LAYERNAME}.zip"
