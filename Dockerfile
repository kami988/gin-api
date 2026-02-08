# syntax=docker/dockerfile:1.7

FROM golang:1.25.7-bookworm AS base

ENV APP_DIR=/app
WORKDIR ${APP_DIR}

# 必要なパッケージのインストール
RUN apt-get update -qq && \
    apt-get install -y \
      curl \
      gcc \
      g++ \
      make \
      git \
      gnupg \
      openssh-client \
      xz-utils \
      tzdata \
      chromium \
            fonts-noto-cjk \
            protobuf-compiler && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# go.modとgo.sumをコピーして依存関係をダウンロード（BuildKit cache）
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

# ソースコードをコピー
COPY . .

FROM base AS build
# アプリケーションをビルド（BuildKit cache）
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o main ./cmd/api

FROM debian:bookworm-slim AS production

RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    chromium \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# chromedp が確実に Chromium を見つけられるようにする
ENV CHROME_PATH=/usr/bin/chromium

# ユーザー作成
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# ビルドステージからバイナリをコピーして実行権限を付与
COPY --from=build /app/main ./main
RUN chmod +x ./main && chown -R appuser:appgroup ./main

# 非rootユーザーに切り替え
USER appuser

# ポートの公開
EXPOSE 8080

# アプリケーションの実行
CMD ["./main"]

FROM base AS development

# ローカル開発時のみ利用するツール（psql 等）
RUN apt-get update -qq && \
    apt-get install -y \
      postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# chromedp が確実に Chromium を見つけられるようにする
ENV CHROME_PATH=/usr/bin/chromium

# 開発用ツールのインストール（BuildKit cache）
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go install github.com/air-verse/air@v1.64.5

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go install github.com/pressly/goose/v3/cmd/goose@v3.26.0

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go install github.com/golang/mock/mockgen@v1.6.0

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@2.8.0

# sqlfluff のインストール
RUN apt-get update -qq && \
    apt-get install -y python3 python3-pip python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m venv /opt/sqlfluff && \
    /opt/sqlfluff/bin/pip install sqlfluff && \
    ln -s /opt/sqlfluff/bin/sqlfluff /usr/local/bin/sqlfluff

# ポートの公開
EXPOSE 8080