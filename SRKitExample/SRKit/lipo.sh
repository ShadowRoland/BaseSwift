#!/bin/bash

products_path="$1"
cd "${products_path}"
cd ../..
products_path="${PWD}"

if [[ ! -d "${products_path}" ]]; then
    echo "product path is invalid"
    exit 1
fi

if [ -d "${HOME}/Desktop/${FRAMEWORK_NAME}.framework" ]; then
    rm -rf "${HOME}/Desktop/${FRAMEWORK_NAME}.framework"
fi

FRAMEWORK_NAME="SRKit"

cp -r "${products_path}/Release-iphoneos/${FRAMEWORK_NAME}.framework" "${HOME}/Desktop/${FRAMEWORK_NAME}.framework"

lipo -create -output "${HOME}/Desktop/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${products_path}/Release-iphoneos/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${products_path}/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"

cp -r "${products_path}/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${HOME}/Desktop/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule"
