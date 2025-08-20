#!/bin/bash

# Gitから渡されたファイルパス
FILE_PATH="$1"

# nkfを使って文字コードを自動判別する
# 存在しないファイルを渡された場合のエラー出力を捨てる
ENCODING=$(nkf -g "${FILE_PATH}" 2>/dev/null)

# 判別結果がShift_JIS（またはCP932）だった場合のみ、UTF-8に変換して出力
if [ "${ENCODING}" = "Shift_JIS" ] || [ "${ENCODING}" = "CP932" ]; then
  nkf -w "${FILE_PATH}"
else
  # それ以外の文字コード（UTF-8など）の場合は、そのままの内容を出力
  cat "${FILE_PATH}"
fi
