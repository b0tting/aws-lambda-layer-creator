#!/bin/bash
# Thanks to https://medium.com/srcecde/aws-lambda-layer-building-made-easy-2c97572047db
set -e

if [ $# -eq 0 ]; then
    >&2 echo "No arguments provided - please provide layer name, runtime and packages. For example: ./create-layer.sh my-layer-name python3.8 requests pytz"
    exit 1
fi

layername="$1"
runtime="$2"
# shellcheck disable=SC2124
packages="${@:3}"

if ! command -v aws &> /dev/null
then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
fi

if ! command -v docker &> /dev/null
then
  curl -fsSL "https://get.docker.com" -o get-docker.sh
  sh ./get-docker.sh --dry-run
fi

echo "================================="
echo "LayerName: $layername"
echo "Runtime: $runtime"
echo "Packages: $packages"
echo "================================="

host_temp_dir="$(mktemp -d)"

support_python_runtime=("python3.6,python3.7,python3.8,python3.9,python3.10,python3.11")

support_node_runtime=("nodejs10.x,nodejs12.x,nodejs14.x,nodejs16.x,nodejs18.x")

if [[ "${support_node_runtime[*]}" == *"${runtime}"* ]]; then
    installation_path="nodejs"
    docker_image="public.ecr.aws/sam/build-$runtime:latest"
    echo "Preparing lambda layer"
    docker run --rm -v "$host_temp_dir:/lambda-layer" -w "/lambda-layer" "$docker_image" /bin/bash -c "mkdir $installation_path && npm install --prefix $installation_path --save $packages && zip -r lambda-layer.zip *"
elif [[ "${support_python_runtime[*]}" == *"${runtime}"* ]]; then
    installation_path="python"
    docker_image="public.ecr.aws/sam/build-$runtime:latest"
    echo "Preparing lambda layer"
    docker run --rm -v "$host_temp_dir:/lambda-layer" -w "/lambda-layer" "$docker_image" /bin/bash -c "mkdir $installation_path && pip install $packages -t $installation_path  && zip -r lambda-layer.zip * -x '*/__pycache__/*'"
else
    echo "Invalid runtime"
    exit 1
fi

mv "$host_temp_dir"/lambda-layer.zip "${layername}".zip

echo "Finishing up - find your layer file as ${layername}.zip"
rm -rf "$host_temp_dir"
