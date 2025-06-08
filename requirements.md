# pair-lens.nvim 要件定義書

## 1. プロジェクト概要
ブロック構造の終端に対応する開始位置の情報を表示するNeovimプラグイン。Tree-sitterを使用した正確な構文解析により、複数のプログラミング言語に対応し、カスタマイズ可能な表示機能を提供する。

## 2. 機能要件

### 2.1 基本機能
- ブロック構造の終端（`end`、`}`など）に、対応する開始位置の情報をvirtual textとして表示
- 表示情報には開始行番号、終了行番号、開始行のコードを含む
- 設定可能な最小行数以上のブロックのみ表示（デフォルト: 5行）

### 2.2 対応言語と構文
Tree-sitterクエリによる以下の言語と構文のサポート：

- **Lua**: function, if, for, while, do文
- **Ruby**: method, if, unless, while, until, for, begin, class, module, do_block
- **Python**: function, class, if, for, while, try, with文
- **JavaScript**: function, class, method, if, for, while, try, arrow function, **オブジェクトリテラル（新規）**
- **TypeScript**: JavaScript機能 + interface, enum
- **Rust**: function, impl, struct, enum, trait, mod, loop, while, for, if, match
- **Go**: function, method, type, if, for, switch, select

### 2.3 カスタマイズ機能

#### 2.3.1 表示設定
- **フォーマット設定**:
  - 文字列テンプレート形式（既存）: `{sl}`, `{el}`, `{st}`, `{et}` などの変数を使用
  - **関数形式（新規）**: より柔軟なカスタマイズのための関数指定
    ```lua
    format = function(info)
      -- info: {
      --   start_line: number,
      --   end_line: number,
      --   start_text: string,
      --   end_text: string,
      --   total_lines: number,  -- 新規
      --   node_text: string,     -- 新規: ノード全体のテキスト
      --   bufnr: number,         -- 新規
      --   node_type: string,     -- 新規: 構文の種類
      -- }
      return "カスタムフォーマット"
    end
    ```

#### 2.3.2 Tree-sitterクエリのカスタマイズ（新規）
- ユーザーが独自のTree-sitterクエリを設定で追加・上書き可能
- 言語ごとにクエリを定義
  ```lua
  custom_queries = {
    javascript = [[
      (object) @object
      (variable_declarator
        value: (object) @object)
    ]],
    -- 他の言語...
  }
  ```

#### 2.3.3 その他の設定
- グローバル有効/無効設定
- ハイライトグループのカスタマイズ
- ファイルタイプごとの無効化設定
- 表示する最小行数の設定

### 2.4 コマンド
- `:PairLensEnable` - プラグインを有効化
- `:PairLensDisable` - プラグインを無効化
- `:PairLensToggle` - 有効/無効を切り替え

## 3. 非機能要件

### 3.1 パフォーマンス
- バッファ変更時の更新は100ms遅延で実行
- 大規模ファイルでも軽快に動作
- 不要な再計算を避ける最適化

### 3.2 互換性
- Neovim 0.8以降に対応
- nvim-treesitter/nvim-treesitterへの依存

### 3.3 品質保証
- **充実したユニットテスト（新規）**
  - 各言語のクエリテスト
  - フォーマット関数のテスト
  - カスタムクエリの動作テスト
  - エッジケースの処理テスト

### 3.4 拡張性
- 新しい言語の追加が容易
- カスタムクエリによる柔軟な拡張
- APIの公開による他プラグインとの連携可能性

## 4. 技術仕様

### 4.1 アーキテクチャ
- モジュール構成:
  - `init.lua` - コア機能とバッファ管理
  - `config.lua` - 設定管理とバリデーション
  - `queries.lua` - デフォルトクエリとカスタムクエリの管理
  - `formatter.lua` - フォーマット処理（新規）
  - `utils.lua` - ユーティリティ関数

### 4.2 データ構造
```lua
-- 拡張されたPairInfo
PairInfo = {
  start_line: number,
  end_line: number,
  start_text: string,
  end_text: string,
  total_lines: number,    -- 新規
  node_text: string,      -- 新規
  bufnr: number,          -- 新規
  node_type: string,      -- 新規
  lang: string,           -- 新規
}
```

### 4.3 設定構造
```lua
Config = {
  enabled: boolean,
  style: {
    format: string | function,  -- 関数も受け付ける
    hl: string,
  },
  disable_filetypes: string[],
  min_lines: number,
  custom_queries: table<string, string>,  -- 新規
}
```

## 5. 制約事項
- Tree-sitterパーサーがインストールされている言語のみ対応
- virtual textの表示制限（Neovimの仕様に依存）
- 複数のvirtual textが重なる場合の処理は未対応

## 6. 今後の検討事項
- ネストしたブロックの親子関係の可視化
- 折りたたみ機能との連携
- パフォーマンスメトリクスの収集機能