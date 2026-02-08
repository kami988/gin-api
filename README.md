# gin-api

Gin + Connect (Protobuf) + PostgreSQL を使った Web サーバー

## 技術スタック

- **Web Framework**: [Gin](https://github.com/gin-gonic/gin)
- **RPC**: [Connect (ConnectRPC)](https://connectrpc.com/)
- **Protocol Buffers**: Protocol Buffers v3
- **Database**: PostgreSQL
- **Language**: Go 1.21+

## 必要な環境

- Go 1.21 以上
- PostgreSQL 14 以上
- Protocol Buffers コンパイラ (protoc)

## セットアップ

### 1. 必要なツールのインストール

```bash
# Goのインストール（Windowsの場合）
# https://golang.org/dl/ からインストーラーをダウンロード

# Protocol Buffers コンパイラのインストール
# https://github.com/protocolbuffers/protobuf/releases から protoc をダウンロード

# protoc-gen-go と protoc-gen-connect-go のインストール
make install-tools
# または
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest
```

### 2. 依存関係のインストール

```bash
go mod download
go mod tidy
```

### 3. Protobuf コードの生成

```bash
make proto
# または
make gen
```

### 4. PostgreSQL データベースの準備

#### Option A: Docker Compose を使用（推奨）

```bash
# Docker Compose で PostgreSQL を起動
docker-compose up -d

# データベースが起動したか確認
docker-compose ps
```

#### Option B: ローカルの PostgreSQL を使用

```bash
# PostgreSQL をインストール後、データベースを作成
psql -U postgres
CREATE DATABASE gin_api_db;

# マイグレーションを実行（オプション）
psql -U postgres -d gin_api_db -f migrations/001_create_users_table.sql
```

### 5. 環境変数の設定

```bash
# .env.example を .env にコピー
cp .env.example .env

# .env ファイルを編集してデータベース接続情報を設定
```

### 6. サーバーの起動

```bash
make run
# または
go run cmd/server/main.go
```

サーバーは `http://localhost:8080` で起動します。

## プロジェクト構造

```
gin-api/
├── cmd/
│   └── server/          # メインアプリケーション
│       └── main.go
├── internal/
│   ├── database/        # データベース接続
│   │   └── postgres.go
│   ├── handler/         # Connect RPCハンドラー
│   │   └── user_handler.go
│   └── service/         # ビジネスロジック
│       └── user_service.go
├── proto/
│   └── user/v1/         # Protobufスキーマ
│       └── user.proto
├── gen/                 # 生成されたProtobufコード
├── go.mod
├── go.sum
├── Makefile
└── .env.example
```

## API エンドポイント

### Health Check
```bash
curl http://localhost:8080/health
```

### Connect RPC エンドポイント

Connect プロトコルを使用した RPC エンドポイント:

- **CreateUser**: ユーザーを作成
- **GetUser**: ユーザー情報を取得
- **ListUsers**: ユーザー一覧を取得
- **UpdateUser**: ユーザー情報を更新
- **DeleteUser**: ユーザーを削除

#### 使用例（curl）

```bash
# ユーザーを作成
curl -X POST http://localhost:8080/user.v1.UserService/CreateUser \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

# ユーザー情報を取得
curl -X POST http://localhost:8080/user.v1.UserService/GetUser \
  -H "Content-Type: application/json" \
  -d '{"id": 1}'

# ユーザー一覧を取得
curl -X POST http://localhost:8080/user.v1.UserService/ListUsers \
  -H "Content-Type: application/json" \
  -d '{"page_size": 10, "page": 1}'

# ユーザー情報を更新
curl -X POST http://localhost:8080/user.v1.UserService/UpdateUser \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "name": "Jane Doe", "email": "jane@example.com"}'

# ユーザーを削除
curl -X POST http://localhost:8080/user.v1.UserService/DeleteUser \
  -H "Content-Type: application/json" \
  -d '{"id": 1}'
```

## 開発

### Makeコマンド

```bash
# Protobuf コードを生成
make proto

# サーバーを起動
make run

# バイナリをビルド
make build

# クリーンアップ
make clean

# 依存関係をダウンロード
make deps
```

## Connect RPC について

このプロジェクトは [Connect](https://connectrpc.com/) を使用しています。Connect は gRPC と互換性がありながら、以下の利点があります:

- HTTP/1.1 と HTTP/2 の両方をサポート
- JSON と Binary (Protobuf) の両方をサポート
- curl などの標準的な HTTP ツールで簡単にテスト可能
- ブラウザから直接呼び出し可能（CORS サポート）

## ライセンス

MIT
