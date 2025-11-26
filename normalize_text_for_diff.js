#!/usr/bin/env node
// 契約書等のテキスト差分比較用の正規化スクリプト
//
// 使用法:
//   node normalize_text_for_diff.js input.txt > output.normalized.txt
//   node normalize_text_for_diff.js input.txt -o output.normalized.txt
//
// 処理内容:
//   1. 改行・スペース・タブ（全角含む）を全部取っ払う
//   2. 「。」を「。\n」に変換
//
// 背景:
//   PDF/docxから抽出したテキストは、元のレイアウトによって
//   改行位置が毎回異なることがある。そのままdiffすると
//   余計な差分が大量に出るため、一度正規化してから比較する。
//
// 参考: https://pxgrid.esa.io/posts/3758

const fs = require('fs');

const args = process.argv.slice(2);
let inputFile = null;
let outputFile = null;

// 引数のパース
for (let i = 0; i < args.length; i++) {
  if (args[i] === '-o' || args[i] === '--output') {
    outputFile = args[i + 1];
    i++;
  } else if (!inputFile) {
    inputFile = args[i];
  }
}

if (!inputFile) {
  console.error('Usage: node normalize_text_for_diff.js <input_file> [-o output_file]');
  console.error('');
  console.error('Options:');
  console.error('  -o, --output  出力ファイルを指定（省略時は標準出力）');
  process.exit(1);
}

if (!fs.existsSync(inputFile)) {
  console.error(`Error: File not found: ${inputFile}`);
  process.exit(1);
}

const content = fs.readFileSync(inputFile, 'utf-8');

const normalized = content
  .replace(/[\r\n\t\s　]+/g, '')  // 改行・タブ・スペース（全角含む）を削除
  .replace(/。/g, '。\n');        // 「。」の後に改行を挿入

if (outputFile) {
  fs.writeFileSync(outputFile, normalized);
  console.error(`Normalized: ${inputFile} -> ${outputFile}`);
} else {
  console.log(normalized);
}
