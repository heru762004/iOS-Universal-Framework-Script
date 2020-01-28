CONFIG="${OTHER_SWIFT_FLAGS}"
echo "${CONFIG}"
if [[ $CONFIG == *"UAT"* ]]; then
echo "It's UAT"
exec > /tmp/${PROJECT_NAME}_archive.log 2>&1
UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal
if [ "true" == ${ALREADYINVOKED:-false} ]
then
echo "RECURSION: Detected, stopping"
else
export ALREADYINVOKED="true"
# make sure the output directory exists

xcodebuild clean

echo "Building for iPhone OS"
xcodebuild -workspace "${WORKSPACE_PATH}" -scheme "${TARGET_NAME}" -sdk iphoneos -configuration ${CONFIGURATION} CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphoneos build

echo "Building for iPhoneSimulator"
xcodebuild -workspace "${WORKSPACE_PATH}" -scheme "${TARGET_NAME}" -configuration ${CONFIGURATION} -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6' ONLY_ACTIVE_ARCH=NO ARCHS='i386 x86_64' CONFIGURATION_BUILD_DIR=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator build

mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"
# Step 1. Copy the framework structure (from iphoneos build) to the universal folder
echo "Copying to output folder"
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/" "${UNIVERSAL_OUTPUTFOLDER}/"

# Step 2. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${TARGET_NAME}.framework/Modules/${TARGET_NAME}.swiftmodule/."
if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
cp -R "${SIMULATOR_SWIFT_MODULES_DIR}" "${UNIVERSAL_OUTPUTFOLDER}/${TARGET_NAME}.framework/Modules/${TARGET_NAME}.swiftmodule"
fi
# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
echo "Combining executables"

for SUB_FRAMEWORK in $( ls "${UNIVERSAL_OUTPUTFOLDER}/" ); do
BINARY_NAME="${SUB_FRAMEWORK%.*}"
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${SUB_FRAMEWORK}.framework/${SUB_FRAMEWORK}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${SUB_FRAMEWORK}.framework/${SUB_FRAMEWORK}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${SUB_FRAMEWORK}.framework/${SUB_FRAMEWORK}"
done

lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${EXECUTABLE_PATH}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${EXECUTABLE_PATH}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${EXECUTABLE_PATH}"

# Step 4. Create universal binaries for embedded frameworks
#for SUB_FRAMEWORK in $( ls "${UNIVERSAL_OUTPUTFOLDER}/${TARGET_NAME}.framework/Frameworks" ); do
#BINARY_NAME="${SUB_FRAMEWORK%.*}"
#lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${TARGET_NAME}.framework/Frameworks/${SUB_FRAMEWORK}/${BINARY_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${SUB_FRAMEWORK}/${BINARY_NAME}" "${ARCHIVE_PRODUCTS_PATH}${INSTALL_PATH}/${TARGET_NAME}.framework/Frameworks/${SUB_FRAMEWORK}/${BINARY_NAME}"
#done
# Step 5. Convenience step to copy the framework to the project's directory
echo "Copying to project dir"
yes | cp -Rf "${UNIVERSAL_OUTPUTFOLDER}/${FULL_PRODUCT_NAME}" "${PROJECT_DIR}"
open "${PROJECT_DIR}"
fi
fi
