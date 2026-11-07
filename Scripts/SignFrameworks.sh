LOCATION="${BUILT_PRODUCTS_DIR}"/"${FRAMEWORKS_FOLDER_PATH}"

# 默认使用工程/目标中配置的签名身份
IDENTITY="${CODE_SIGN_IDENTITY}"
if [ "$IDENTITY" == "" ]
then
    # 若未指定签名身份，则使用 ad-hoc 临时签名
    IDENTITY="-"
fi
codesign --verbose --force --deep -o runtime --sign "$IDENTITY" "$LOCATION/Sparkle.framework/Versions/A/Resources/Autoupdate.app"
codesign --verbose --force -o runtime --sign "$IDENTITY" "$LOCATION/Sparkle.framework/Versions/A"
