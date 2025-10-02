# acr-sample

このリポジトリは、Azure Container Registry (ACR) を使って Django アプリケーションをコンテナ化し、Azure Container Apps にデプロイするためのサンプルです。GitHub Actions による CI/CD パイプラインも含まれています。

## 🧩 構成概要

- **Django**: Python製のWebアプリケーションフレームワーク
- **Docker**: アプリケーションのコンテナ化
- **Azure Container Registry (ACR)**: コンテナイメージの保存
- **Azure Container Apps**: コンテナのホスティング
- **GitHub Actions**: CI/CD 自動化

## 🚀 デプロイフロー

1. コードが `main` ブランチに push される
2. GitHub Actions が Django アプリを Docker イメージとしてビルド
3. ACR にイメージをプッシュ
4. Azure Container Apps に最新イメージをデプロイ

## 🔧 必要な準備

### Azure リソース

- Azure Container Registry（例: `acrsamplekoudaiii.azurecr.io`）
- Azure Container App（例: `acr-sample-app`）
- リソースグループ（例: `acr-sample-rg`）

### GitHub Secrets

- ACR_USERNAME
- ACR_PASSWORD
- AZURE_CLIENT_ID
- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID

https://github.com/pocpp/login-with-openid-connect-oidc で生成

## 📁 ディレクトリ構成

```console
acr-sample/
├── Dockerfile
├── requirements.txt
├── manage.py
├── myproject/
│   └── settings.py
└── .github/
    └── workflows/
    └── deploy.yml
```

## 🐳 Dockerfile（例）

```Dockerfile
FROM python:3.13.7-slim

WORKDIR /app

# Set up uv

COPY . .

# CMD uv run 
```

## ⚙️ GitHub Actions ワークフロー（.github/workflows/deploy.yml）

```yml
name: Deploy Django to Azure Container Apps

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Log in to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Build and push Docker image
        run: |
          docker build -t acrsample:${{ github.sha }} .
          echo "${{ secrets.ACR_PASSWORD }}" | docker login acrsamplekoudaiii.azurecr.io -u ${{ secrets.ACR_USERNAME }} --password-stdin
          docker tag acrsample:${{ github.sha }} acrsamplekoudaiii.azurecr.io/acrsample:${{ github.sha }}
          docker push acrsamplekoudaiii.azurecr.io/acrsample:${{ github.sha }}

      - name: Deploy to Azure Container Apps
        run: |
          az containerapp update \
            --name acr-sample-app \
            --resource-group acr-sample-rg \
            --image acrsamplekoudaiii.azurecr.io/acrsample:${{ github.sha }}
```

## 📚 参考リンク

- https://learn.microsoft.com/ja-jp/azure/container-apps/
- https://docs.github.com/ja/actions
