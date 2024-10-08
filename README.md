# AWS Lambda Layer Creator
**Python** & **NodeJS** lambda layer creation made easy!

## Prerequisites
- Docker (Install)

Not required are any of the runtimes, we'll use docker images for that. 

## Installation
Clone the repository or simply download the create-layer.sh and execute below commands
```bash
cp create-layer.sh /usr/local/bin/create-layer
chmod +x /usr/local/bin/create-layer
```
OR (Follow one-click install)
```bash
SCRIPT_INSTALL_LOC=/usr/local/bin/create-layer.sh; curl https://raw.githubusercontent.com/b0tting/aws-lambda-layer-creator/main/create-layer.sh > $SCRIPT_INSTALL_LOC; chmod +x $SCRIPT_INSTALL_LOC
```
## Usage
### Python
To create the layer the command should be in the specified format.
```bash
create-layer.sh -n <layer-name> -r <python-runtime> -m "[package1 package...]"
```
- **create-layer** - Command to invoke the script to create lambda layer
- **layer-name** - Name of the lambda layer (Please make sure to follow the lambda layer naming convention)
- **python-runtime** - Python runtime
- **package** - Name of the package, library that you want to install

Some limited dependencies are supported, for example:
```bash
create-layer.sh -n requests_310 -r python3.10 -m "requests urllib3<2"
```
..would create a layer with requests and the urllib3 dependency in a version below 2.0. 

The result will be a ZIP file ready to be uploaded to AWS Lambda. A README.md will be added to the zip with the command used to create the layer.

#### Supported python runtime
- python3.6
- python3.7
- python3.8
- python3.9
- python3.10
- python3.11 
- python3.12
- python3.13
#### Example
```bash
create-layer -n pandas-numpy-layer -r python3.9 -m "numpy pandas"
```
### Node JS
To create the layer the command should be in the specified format.
```bash
create-layer.sh -n <layer-name> -r <node-runtime> -m "[package1 package...]"
```
- **create-layer** - Command to invoke the script to create lambda layer
- **layer-name** - Name of the lambda layer (Please make sure to follow the lambda layer naming convention)
- **nodejs-runtime** - NodeJS runtime
- **package** - Name of the package, library that you want to install

#### Supported Node JS runtime
- nodejs10.x
- nodejs12.x
- nodejs14.x
- nodejs16.x
- nodejs18.x

#### Example
```bash
create-layer.sh -n request-moment-layer -r nodejs14.x -m "request moment"
```

### Proxy configuration
This script supports proxy configuration for locations with no direct access to internet. Use the -p flag to specify the proxy URL. 
```bash
create-layer -n pandas-numpy-layer -r python3.9 -m "numpy pandas" -p http://proxy.example.com:8080
```
