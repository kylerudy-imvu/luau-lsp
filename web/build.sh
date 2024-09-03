#!/bin/bash
# the existing docker file for emscripten contains a version of cmake that has a known issue.
# my interim solution to updating emscripten-core is to simply host a patched docker image.
# see https://github.com/emscripten-core/emsdk/issues/1430
BUILD_CONTAINER=krudyimvu/emscripten_updated:20240807
# FROM artifactory.corp.imvu.com/docker-remote/emscripten/emsdk:3.1.62
# RUN apt-get update
# RUN apt-get install -y ca-certificates gpg wget ninja-build
# RUN test -f /usr/share/doc/kitware-archive-keyring/copyright || wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
# RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
# RUN apt-get update
# RUN apt-get upgrade -y
# RUN apt-get install jq -y
BUILD_NAME=Luau.LanguageServer.Web
BUILD_CONFIG=Release
JS_OUTPUT=$BUILD_NAME.js
WASM_OUTPUT=$BUILD_NAME.wasm
WEBWORKER_PREPEND=web/demoprepend.js

echo "Attempting to build with $BUILD_CONFIG configuration"

if command -v docker; then
    if command -v npm; then
        git submodule update --recursive
        mkdir -p build
        rm -f CMakeCache.txt
        echo "Configuring build for $JS_OUTPUT and $WASM_OUTPUT"
        docker run --rm -v $(pwd):/src -u $(id -u):$(id -g) $BUILD_CONTAINER emcmake cmake -S/src -B/src/build -DCMAKE_BUILD_TYPE=$BUILD_CONFIG
        echo "Building $JS_OUTPUT and $WASM_OUTPUT"
        docker run --rm -v $(pwd):/src -u $(id -u):$(id -g) $BUILD_CONTAINER cmake --build /src/build --target $BUILD_NAME --config $BUILD_CONFIG
        echo "Installing dependencies for the web demo with npm"
        pushd web
        if npm install; then
            popd
            echo "Prepending the $JS_OUTPUT with a webworker harness, $WEBWORKER_PREPEND"
            cat $WEBWORKER_PREPEND build/$JS_OUTPUT > web/public/$JS_OUTPUT
            echo "Copying wasm output build/$WASM_OUTPUT"
            cp build/$WASM_OUTPUT web/public/$WASM_OUTPUT
            echo "Build complete. You can open the demo with web/run.sh"
        else
            popd
            echo "Failure. npm could not install dependencies."
            exit 1
        fi
        exit 0
    else
        echo "Failure. The web demo requires npm."
        exit 1
    fi
else
    echo "Failure. The web demo requires docker to build the .js and .wasm output files."
    exit 1
fi