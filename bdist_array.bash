#!/bin/bash
set -e

DESC="Build distributable python wheel files for multiple python versions"
USAGE="Usage: $0 CONDA_INIT_PATH"
if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
	echo $DESC
	echo $USAGE
	exit 0
fi

if [ ! $(command -v cmake) ]; then
	echo "cmake is required"
fi

######## Source conda.sh
if [[ ! $1 ]] ; then
	echo "Expecting CONDA_INIT_PATH"
	echo $USAGE
	exit 1
fi

if [[ ! -f $1 ]] || [[ $1 != *"conda.sh" ]]; then
	echo "Please provide a valid CONDA_INIT_PATH"
	echo $USAGE
	exit 1
fi

source $1

######## Build array

function clean_build_files() {
	rm -rf build xcode python/opencc/clib *.egg-info dist/*.egg
}

VERSIONS="2.7 3.5 3.6 3.7 3.8"
ROOT_DIR=$PWD

for VER in ${VERSIONS}; do
	echo "Building for python==$VER"
	ENV_NAME=opencc-$VER

	# Clean up existing builds
	cd $ROOT_DIR
	clean_build_files

	# Create and initialize new environment
	cd $ROOT_DIR
	conda create -y -n $ENV_NAME "python=$VER"
	conda activate $ENV_NAME
	pip install --no-cache-dir setuptools wheel pytest

	# Build, install, and test
	cd $ROOT_DIR
	python setup.py build_ext install
	cd $ROOT_DIR/python
	pytest .

	# Package and clean up
	cd $ROOT_DIR
	python setup.py bdist_wheel
	clean_build_files

	conda deactivate

	echo "Finished building for python==$VER"
done

clean_build_files
echo "Done"
echo "whl files saved to ./dist"
