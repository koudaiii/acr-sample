# ACR Sample - Design Document

## 📋 概要

このプロジェクトは、Django アプリケーションを Azure Container Registry (ACR) と Azure Container Apps にデプロイするためのサンプル実装です。ローカル開発から本番デプロイまでの完全なワークフローを、再利用可能なスクリプトと GitHub Actions で自動化しています。

## 🎯 プロジェクトの目的

1. **開発効率**: ローカル開発から本番デプロイまでの一貫したワークフロー
2. **再現性**: スクリプトベースの自動化による環境の再現性確保
3. **保守性**: 明確な構造と設定の分離による保守性の向上
4. **セキュリティ**: 環境変数による機密情報の管理とOIDC認証の活用

## 🏗️ アーキテクチャ

### システム構成図

```
┌─────────────────┐
│  開発者          │
└────────┬────────┘
         │
         ├─ ローカル開発
         │  └─ script/server (uv run)
         │
         ├─ Docker開発
         │  ├─ script/docker-build
         │  ├─ script/docker-server
         │  └─ script/docker-push
         │
         └─ GitHub Push
                │
                ▼
    ┌───────────────────────┐
    │  GitHub Actions       │
    │  (.github/workflows)  │
    └───────────┬───────────┘
                │
                ├─ Build & Push
                │  ├─ script/docker-build
                │  └─ script/docker-push
                │        │
                │        ▼
                │  ┌─────────────────┐
                │  │ Azure Container │
                │  │   Registry      │
                │  └─────────────────┘
                │
                └─ Deploy
                   └─ Azure Container Apps
```

### テクノロジースタック

- **言語**: Python 3.13.7
- **フレームワーク**: Django 5.2.7
- **パッケージ管理**: uv (Astral)
- **コンテナ**: Docker
- **レジストリ**: Azure Container Registry (ACR)
- **ホスティング**: Azure Container Apps
- **CI/CD**: GitHub Actions

## 📁 プロジェクト構造

```
acr-sample/
├── Dockerfile                  # コンテナイメージ定義
├── .dockerignore              # Docker ビルド除外ファイル
├── .env.sample                # 環境変数テンプレート
├── .gitignore                 # Git 除外ファイル
├── pyproject.toml             # Python プロジェクト設定
├── uv.lock                    # 依存関係ロックファイル
├── manage.py                  # Django 管理スクリプト
├── README.md                  # プロジェクト概要
├── CLAUDE.md                  # 本ドキュメント
│
├── myproject/                 # Django プロジェクト
│   ├── __init__.py
│   ├── settings.py           # Django 設定
│   ├── urls.py               # URL ルーティング
│   ├── wsgi.py               # WSGI エントリポイント
│   └── asgi.py               # ASGI エントリポイント
│
├── script/                    # 自動化スクリプト
│   ├── bootstrap             # 初期セットアップ
│   ├── server                # ローカル開発サーバー
│   ├── docker-build          # Docker イメージビルド
│   ├── docker-push           # ACR プッシュ
│   └── docker-server         # Docker コンテナ起動
│
└── .github/
    └── workflows/
        └── deploy.yml        # GitHub Actions ワークフロー
```

## 🔧 コンポーネント詳細

### 1. Django アプリケーション (myproject/)

#### settings.py の主要設定

```python
# 環境変数ベースの設定
SECRET_KEY = os.environ.get('SECRET_KEY', 'default-key')
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

# ALLOWED_HOSTS の柔軟な設定
# - 環境変数で指定: その値を使用
# - DEBUGモード: 開発用ホストを自動許可
# - 本番モード: 明示的な設定を要求
allowed_hosts_env = os.environ.get('ALLOWED_HOSTS', '')
if allowed_hosts_env:
    ALLOWED_HOSTS = allowed_hosts_env.split(',')
elif DEBUG:
    ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*']
else:
    ALLOWED_HOSTS = []
```

**設計判断の理由**:
- **セキュリティ**: 本番環境では明示的な設定を強制
- **開発効率**: DEBUGモードでは柔軟に対応
- **12-Factor App**: 環境変数による設定の外部化

### 2. Docker 設定

#### Dockerfile の設計

```dockerfile
FROM python:3.13.7-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy project files
COPY pyproject.toml uv.lock ./
COPY manage.py ./
COPY myproject ./myproject

# Install dependencies
RUN uv sync --frozen

# Expose port
EXPOSE 8000

# Run the application
CMD ["uv", "run", "python", "manage.py", "runserver", "0.0.0.0:8000"]
```

**設計判断の理由**:
- **軽量**: slim イメージで最小限のサイズ
- **高速**: uv による依存関係の高速インストール
- **再現性**: --frozen フラグでロックファイルの厳密な使用
- **レイヤーキャッシュ**: 依存関係とアプリコードの分離

### 3. 自動化スクリプト (script/)

#### スクリプトの設計原則

1. **冪等性**: 何度実行しても同じ結果
2. **環境変数対応**: .env ファイルと環境変数のサポート
3. **デフォルト値**: 設定なしでも動作
4. **エラーハンドリング**: `set -e` による即座の失敗検知
5. **情報提供**: 実行内容の明確な表示

#### script/bootstrap

**目的**: プロジェクトの初期セットアップ

```bash
#!/bin/bash
set -e

# uv のインストール確認とインストール
# 依存関係のインストール (uv sync)
# .env ファイルの作成 (.env.sample から)
# Django マイグレーションの実行
```

**使用タイミング**: プロジェクトのクローン直後

#### script/server

**目的**: ローカル開発サーバーの起動

```bash
#!/bin/bash
set -e

# .env ファイルの読み込み
# uv run python manage.py runserver
```

**使用タイミング**: 日常的な開発作業

#### script/docker-build

**目的**: Docker イメージのビルド

```bash
#!/bin/bash
set -e

# 環境変数の読み込み
# イメージのビルド
# タグの付与 (SHA と latest)
```

**環境変数**:
- `ACR_REGISTRY`: レジストリ URL
- `IMAGE_NAME`: イメージ名
- `IMAGE_TAG`: タグ (デフォルト: git SHA)

#### script/docker-push

**目的**: ACR へのイメージプッシュ

```bash
#!/bin/bash
set -e

# ACR へのログイン
# イメージのプッシュ (SHA と latest)
```

**環境変数**:
- `ACR_REGISTRY`: レジストリ URL
- `ACR_USERNAME`: ACR ユーザー名
- `ACR_PASSWORD`: ACR パスワード
- `IMAGE_NAME`: イメージ名
- `IMAGE_TAG`: タグ

#### script/docker-server

**目的**: Docker コンテナでのアプリケーション起動

```bash
#!/bin/bash
set -e

# 既存コンテナの停止・削除
# コンテナの起動
# ポートマッピング (8000:8000)
# 便利なコマンドの表示
```

**環境変数**:
- `ACR_REGISTRY`: レジストリ URL
- `IMAGE_NAME`: イメージ名
- `IMAGE_TAG`: タグ (デフォルト: latest)
- `CONTAINER_NAME`: コンテナ名
- `PORT`: ホストポート
- `DEBUG`: Django DEBUG モード
- `ALLOWED_HOSTS`: Django ALLOWED_HOSTS

### 4. CI/CD パイプライン (.github/workflows/deploy.yml)

#### ワークフローの設計

```yaml
name: Deploy Django to Azure Container Apps

on:
  push:
    branches:
      - main

permissions:
  id-token: write  # OIDC 認証用
  contents: read

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      1. Checkout code
      2. Build Docker image (script/docker-build)
      3. Push Docker image to ACR (script/docker-push)
      4. Log in to Azure with OIDC
      5. Deploy to Azure Container Apps
```

**設計判断の理由**:
- **スクリプト再利用**: ローカルと同じスクリプトを使用
- **OIDC認証**: パスワードレス認証でセキュリティ向上
- **明確な分離**: ビルド、プッシュ、デプロイの責務分離

## 🔐 セキュリティ設計

### 機密情報の管理

#### 環境変数による管理

```
.env.sample (テンプレート)
    ↓
.env (ローカル、.gitignore に含む)
    ↓
GitHub Secrets (CI/CD)
    ↓
環境変数 (実行時)
```

#### GitHub Secrets

**必須の Secrets**:
- `ACR_REGISTRY`: ACR レジストリ URL
- `ACR_USERNAME`: ACR ユーザー名
- `ACR_PASSWORD`: ACR パスワード
- `AZURE_CLIENT_ID`: Azure OIDC クライアント ID
- `AZURE_TENANT_ID`: Azure テナント ID
- `AZURE_SUBSCRIPTION_ID`: Azure サブスクリプション ID
- `AZURE_RESOURCE_GROUP`: リソースグループ名
- `AZURE_CONTAINER_APP_NAME`: コンテナアプリ名

### ALLOWED_HOSTS のセキュリティ

```python
# 開発環境: 柔軟な設定
if DEBUG:
    ALLOWED_HOSTS = ['localhost', '127.0.0.1', '0.0.0.0', '*']

# 本番環境: 厳格な設定
else:
    ALLOWED_HOSTS = []  # 環境変数での明示を強制
```

## 🚀 開発ワークフロー

### 1. 初期セットアップ

```bash
# リポジトリのクローン
git clone <repository-url>
cd acr-sample

# 初期セットアップ
./script/bootstrap

# .env ファイルの編集（必要に応じて）
cp .env.sample .env
vi .env
```

### 2. ローカル開発

```bash
# 開発サーバーの起動
DEBUG=True ./script/server

# ブラウザでアクセス
open http://localhost:8000
```

### 3. Docker での動作確認

```bash
# イメージのビルド
./script/docker-build

# コンテナの起動
./script/docker-server

# ログの確認
docker logs -f acr-sample-app

# 停止
docker stop acr-sample-app
```

### 4. Azure へのデプロイ

```bash
# ACR へのプッシュ（手動）
./script/docker-push

# または GitHub 経由（自動）
git add .
git commit -m "Update application"
git push origin main
# → GitHub Actions が自動的にデプロイ
```

## 🔄 デプロイフロー

### 自動デプロイ (GitHub Actions)

```
1. コードを main ブランチに push
   ↓
2. GitHub Actions がトリガー
   ↓
3. script/docker-build を実行
   - Docker イメージをビルド
   - commit SHA でタグ付け
   ↓
4. script/docker-push を実行
   - ACR にログイン
   - イメージをプッシュ (SHA + latest)
   ↓
5. Azure にログイン (OIDC)
   ↓
6. Container Apps を更新
   - 新しいイメージを指定
   - 自動的にローリングアップデート
```

### 手動デプロイ

```bash
# 1. イメージのビルド
./script/docker-build

# 2. ACR へのプッシュ
./script/docker-push

# 3. Azure Container Apps の更新
az containerapp update \
  --name <app-name> \
  --resource-group <rg-name> \
  --image <registry>/<image>:<tag>
```

## 🧪 テストとデバッグ

### ローカルでのテスト

```bash
# Django のチェック
DEBUG=True uv run python manage.py check

# マイグレーションの確認
DEBUG=True uv run python manage.py showmigrations

# 設定の確認
DEBUG=True uv run python manage.py shell -c \
  "from django.conf import settings; \
   print(f'DEBUG: {settings.DEBUG}'); \
   print(f'ALLOWED_HOSTS: {settings.ALLOWED_HOSTS}')"
```

### Docker でのデバッグ

```bash
# ログの確認
docker logs -f acr-sample-app

# コンテナ内でシェルを実行
docker exec -it acr-sample-app /bin/bash

# コンテナの検査
docker inspect acr-sample-app

# イメージの確認
docker images | grep acrsample
```

### GitHub Actions のデバッグ

```bash
# ローカルでワークフローをシミュレート
ACR_REGISTRY=<registry> \
IMAGE_TAG=$(git rev-parse HEAD) \
  ./script/docker-build

ACR_REGISTRY=<registry> \
ACR_USERNAME=<username> \
ACR_PASSWORD=<password> \
IMAGE_TAG=$(git rev-parse HEAD) \
  ./script/docker-push
```

## 📊 運用とモニタリング

### ログの確認

```bash
# Container Apps のログ
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg-name> \
  --tail 100

# ログのストリーミング
az containerapp logs tail \
  --name <app-name> \
  --resource-group <rg-name> \
  --follow
```

### メトリクスの確認

```bash
# レプリカの状態
az containerapp replica list \
  --name <app-name> \
  --resource-group <rg-name>

# アプリケーションの詳細
az containerapp show \
  --name <app-name> \
  --resource-group <rg-name>
```

## 🔧 カスタマイズ

### 環境変数の追加

1. `.env.sample` に変数を追加
2. `myproject/settings.py` で変数を使用
3. `script/docker-server` に必要に応じて追加
4. GitHub Secrets に追加

### 新しい依存関係の追加

```bash
# パッケージの追加
uv add <package-name>

# 開発用パッケージの追加
uv add --dev <package-name>

# ロックファイルの更新
uv sync
```

### スクリプトの拡張

新しいスクリプトを追加する場合:

```bash
# 1. スクリプトを作成
vi script/my-script

# 2. 実行権限を付与
chmod +x script/my-script

# 3. ヘッダーを追加
#!/bin/bash
set -e

# 4. 環境変数の読み込みを追加
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi
```

## 📝 ベストプラクティス

### 1. コミット前のチェック

```bash
# コードのチェック
DEBUG=True uv run python manage.py check

# Dockerビルドの確認
./script/docker-build

# ローカルテスト
./script/docker-server
```

### 2. 環境変数の管理

- ローカル: `.env` ファイル（.gitignore に含める）
- CI/CD: GitHub Secrets
- 本番: Azure Container Apps の環境変数

### 3. イメージのタグ戦略

- `latest`: 最新の main ブランチ
- `<git-sha>`: 特定のコミット
- `v1.0.0`: リリースバージョン

### 4. セキュリティ

- SECRET_KEY は必ず変更
- DEBUG=False を本番環境で設定
- ALLOWED_HOSTS を本番環境で明示的に設定
- 機密情報を Git にコミットしない

## 🐛 トラブルシューティング

### よくある問題と解決方法

#### 1. DisallowedHost エラー

```
解決: DEBUG=True を設定するか、ALLOWED_HOSTS を設定
DEBUG=True ./script/server
```

#### 2. uv が見つからない

```bash
# uv のインストール
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"
```

#### 3. Docker ビルドエラー

```bash
# キャッシュをクリア
docker builder prune

# イメージを再ビルド
./script/docker-build
```

#### 4. ACR へのプッシュエラー

```bash
# 認証情報の確認
echo $ACR_USERNAME
echo $ACR_PASSWORD

# 手動でログイン
docker login <registry> -u <username> -p <password>
```

#### 5. Container Apps デプロイエラー

```bash
# ログの確認
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg-name>

# レプリカの状態確認
az containerapp replica list \
  --name <app-name> \
  --resource-group <rg-name>
```

## 🔄 更新履歴

### v1.0.0 (2024-XX-XX)

- 初期リリース
- Python 3.13.7 対応
- Django 5.2.7 対応
- uv パッケージマネージャー採用
- GitHub Actions による自動デプロイ
- Azure Container Apps 対応

## 📚 参考リンク

### Azure ドキュメント

- [Azure Container Registry](https://learn.microsoft.com/ja-jp/azure/container-registry/)
- [Azure Container Apps](https://learn.microsoft.com/ja-jp/azure/container-apps/)
- [GitHub Actions で OIDC を使用](https://learn.microsoft.com/ja-jp/azure/developer/github/connect-from-azure)

### Python/Django ドキュメント

- [Django ドキュメント](https://docs.djangoproject.com/)
- [uv ドキュメント](https://github.com/astral-sh/uv)
- [Python 公式ドキュメント](https://docs.python.org/3.13/)

### Docker ドキュメント

- [Docker 公式ドキュメント](https://docs.docker.com/)
- [Docker ベストプラクティス](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 コントリビューション

プロジェクトへの貢献を歓迎します！

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 ライセンス

このプロジェクトのライセンスについては LICENSE ファイルを参照してください。

---

**Last Updated**: 2024-10-03
**Version**: 1.0.0
**Maintained by**: @koudaiii
