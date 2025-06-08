# pair-lens.nvim 実装計画書

## 概要
ブロック構造の終端に対応する開始位置の情報を表示するNeovimプラグインの実装計画。

## プロジェクト構造

```
pair-lens.nvim/
├── lua/pair-lens/
│   ├── init.lua       - コア機能とバッファ管理
│   ├── config.lua     - 設定管理とバリデーション
│   ├── queries.lua    - デフォルトクエリとカスタムクエリ管理
│   ├── formatter.lua  - フォーマット処理
│   └── utils.lua      - ユーティリティ関数
├── tests/
│   ├── busted.lua     - テスト環境設定
│   ├── helper.lua     - テスト用ヘルパー関数
│   ├── pair-lens/
│   │   ├── init_spec.lua      - コア機能のテスト
│   │   ├── config_spec.lua    - 設定管理のテスト
│   │   ├── queries_spec.lua   - クエリ機能のテスト
│   │   ├── formatter_spec.lua - フォーマッターのテスト
│   │   └── utils_spec.lua     - ユーティリティのテスト
│   └── fixtures/      - テスト用サンプルコード
│       ├── lua/
│       ├── ruby/
│       ├── python/
│       └── javascript/
├── plugin/
│   └── pair-lens.lua  - エントリーポイント
├── Makefile           - テスト実行用
├── README.md          - ドキュメント
└── .github/
    └── workflows/
        └── test.yaml  - CI/CD設定
```

## 実装フェーズ

### フェーズ1: 基本実装とテスト基盤（優先度: 高）

#### 1.1 テスト環境のセットアップ
- [ ] tests/busted.lua の作成
- [ ] tests/helper.lua の作成
- [ ] Makefile の作成
- [ ] 基本的なテスト構造の確立

#### 1.2 コア機能の実装（init.lua）
- [ ] モジュールの基本構造
- [ ] setup関数の実装
- [ ] バッファ管理機能
  - [ ] autocmdの設定（BufEnter, TextChanged, InsertLeave）
  - [ ] 100ms遅延のdebounce処理
- [ ] virtual text管理
  - [ ] 既存のvirtual textのクリア
  - [ ] 新規virtual textの設定
- [ ] Tree-sitterノードの解析
  - [ ] 言語別パーサーの取得
  - [ ] ノードの走査とペア検出
- [ ] コマンドの実装
  - [ ] PairLensEnable
  - [ ] PairLensDisable
  - [ ] PairLensToggle

#### 1.3 設定管理（config.lua）
- [ ] デフォルト設定の定義
- [ ] 設定のマージ処理
- [ ] バリデーション機能
- [ ] 設定の型定義

#### 1.4 基本的なクエリ（queries.lua）
- [ ] Luaの基本クエリ
  - [ ] function
  - [ ] if文
  - [ ] for/while文
  - [ ] do文
- [ ] クエリ管理システムの基盤

#### 1.5 ユーティリティ（utils.lua）
- [ ] 行テキスト取得関数
- [ ] ノード情報抽出関数
- [ ] デバッグ用ログ関数

### フェーズ2: 機能拡張とテスト拡充（優先度: 高）

#### 2.1 言語サポートの追加
- [ ] Ruby
  - [ ] method, class, module
  - [ ] if, unless, while, until, for
  - [ ] begin, do_block
- [ ] Python
  - [ ] function, class
  - [ ] if, for, while
  - [ ] try, with
- [ ] JavaScript/TypeScript
  - [ ] function, class, method
  - [ ] if, for, while, try
  - [ ] arrow function
  - [ ] オブジェクトリテラル
- [ ] Rust
  - [ ] function, impl, struct, enum, trait, mod
  - [ ] loop, while, for, if, match
- [ ] Go
  - [ ] function, method, type
  - [ ] if, for, switch, select

#### 2.2 フォーマッター機能（formatter.lua）
- [ ] 文字列テンプレート処理
  - [ ] {sl}, {el}, {st}, {et} の変換
- [ ] 関数形式のサポート
- [ ] PairInfo構造体の拡張
  - [ ] total_lines
  - [ ] node_text
  - [ ] bufnr
  - [ ] node_type
  - [ ] lang

#### 2.3 テストの実装
- [ ] 各モジュールのユニットテスト
- [ ] 言語別のクエリテスト
- [ ] 統合テスト
- [ ] エッジケースのテスト

#### 2.4 CI/CDの設定
- [ ] GitHub Actionsワークフローの作成
- [ ] テストの自動実行
- [ ] キャッシュ設定

### フェーズ3: 高度な機能（優先度: 中）

#### 3.1 カスタムクエリ機能
- [ ] カスタムクエリのマージシステム
- [ ] 言語別クエリの上書き機能
- [ ] クエリのバリデーション

#### 3.2 パフォーマンス最適化
- [ ] 大規模ファイルでの最適化
- [ ] 不要な再計算の回避
- [ ] メモリ使用量の最適化

#### 3.3 ドキュメント整備
- [ ] README.mdの完成
- [ ] 詳細な設定ガイド
- [ ] カスタマイズ例
- [ ] トラブルシューティング

## 技術詳細

### データ構造

```lua
-- PairInfo
{
  start_line = number,      -- 開始行番号
  end_line = number,        -- 終了行番号
  start_text = string,      -- 開始行のテキスト
  end_text = string,        -- 終了行のテキスト
  total_lines = number,     -- 総行数
  node_text = string,       -- ノード全体のテキスト
  bufnr = number,           -- バッファ番号
  node_type = string,       -- ノードタイプ
  lang = string,            -- 言語
}

-- Config
{
  enabled = boolean,
  style = {
    format = string | function,
    hl = string,
  },
  disable_filetypes = {},
  min_lines = number,
  custom_queries = {},
}
```

### Tree-sitterクエリ例

```scheme
;; Lua
(function_definition) @function
(if_statement) @if
(for_statement) @for
(while_statement) @while
(do_statement) @do

;; JavaScript
(function_declaration) @function
(class_declaration) @class
(method_definition) @method
(if_statement) @if
(for_statement) @for
(while_statement) @while
(try_statement) @try
(arrow_function) @arrow
(object) @object
```

### テスト戦略

1. **ユニットテスト**
   - 各関数の個別テスト
   - エッジケースの検証
   - エラーハンドリングの確認

2. **統合テスト**
   - 実際のバッファでの動作確認
   - 複数言語での動作検証
   - パフォーマンステスト

3. **回帰テスト**
   - 既存機能の破壊防止
   - バージョン間の互換性確保

## 成功基準

1. **機能要件**
   - すべての対象言語でブロック終端の情報表示が動作
   - カスタムフォーマットが正しく適用される
   - カスタムクエリが期待通りに動作

2. **非機能要件**
   - 1000行以上のファイルで遅延なく動作
   - メモリリークがない
   - Neovim 0.8以降で動作

3. **品質基準**
   - テストカバレッジ80%以上
   - CI/CDでのテスト自動実行
   - ドキュメントの完備

## リスクと対策

1. **Tree-sitterパーサーの互換性**
   - リスク: パーサーのバージョンによる動作の違い
   - 対策: 複数バージョンでのテスト実施

2. **パフォーマンス問題**
   - リスク: 大規模ファイルでの遅延
   - 対策: debounce処理と最適化

3. **他プラグインとの競合**
   - リスク: virtual textの重複
   - 対策: 名前空間の適切な管理

## スケジュール目安

- フェーズ1: 2-3日
- フェーズ2: 3-4日
- フェーズ3: 2-3日

合計: 約7-10日（実装とテストを含む）