#!/bin/bash
set -e

# mktext build script
# Usage: ./scripts/build.sh [--release] [--dmg]

APP_NAME="mktext"
VERSION="${VERSION:-dev}"
BUILD_CONFIG="debug"
CREATE_DMG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_CONFIG="release"
            shift
            ;;
        --dmg)
            CREATE_DMG=true
            BUILD_CONFIG="release"
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--release] [--dmg] [--version VERSION]"
            exit 1
            ;;
    esac
done

echo "Building $APP_NAME ($BUILD_CONFIG)..."

# Build the executable
if [[ "$BUILD_CONFIG" == "release" ]]; then
    swift build -c release
    EXECUTABLE=".build/release/$APP_NAME"
else
    swift build
    EXECUTABLE=".build/debug/$APP_NAME"
fi

echo "Creating app bundle..."

# Create app bundle structure
rm -rf "$APP_NAME.app"
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

# Copy executable
cp "$EXECUTABLE" "$APP_NAME.app/Contents/MacOS/"

# Generate and copy icon if script exists
if [[ -f "generate_icon.swift" ]]; then
    echo "Generating app icon..."
    swift generate_icon.swift 2>/dev/null || true
    if [[ -d "mktext.iconset" ]]; then
        iconutil -c icns mktext.iconset -o "$APP_NAME.app/Contents/Resources/AppIcon.icns" 2>/dev/null || true
    fi
fi

# Create Info.plist
cat > "$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.mktext.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
    <key>UTImportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.plain-text</string>
            </array>
            <key>UTTypeDescription</key>
            <string>Markdown Document</string>
            <key>UTTypeIdentifier</key>
            <string>net.daringfireball.markdown</string>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>md</string>
                    <string>markdown</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

# Ad-hoc code sign
codesign --force --deep --sign - "$APP_NAME.app" 2>/dev/null || true

echo "App bundle created: $APP_NAME.app"

# Create DMG if requested
if [[ "$CREATE_DMG" == true ]]; then
    echo "Creating DMG..."

    DMG_NAME="${APP_NAME}-${VERSION}.dmg"

    # Remove existing DMG
    rm -f "$DMG_NAME"

    # Create temporary directory
    rm -rf dmg_temp
    mkdir -p dmg_temp
    cp -R "$APP_NAME.app" dmg_temp/
    ln -s /Applications dmg_temp/Applications

    # Create DMG
    hdiutil create -volname "$APP_NAME" \
        -srcfolder dmg_temp \
        -ov -format UDZO \
        "$DMG_NAME"

    # Cleanup
    rm -rf dmg_temp

    echo "DMG created: $DMG_NAME"

    # Generate checksum
    shasum -a 256 "$DMG_NAME" | tee "${DMG_NAME}.sha256"
fi

echo ""
echo "Done! Run the app with:"
echo "  open $APP_NAME.app"
