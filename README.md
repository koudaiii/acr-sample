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

#### インフラストラクチャのデプロイ

`infra/` ディレクトリには、Azure Verified Modules (AVM) を使用した Terraform と Bicep のコードが含まれています。

- **Terraform**: `infra/terraform/` - HashiCorp Terraform を使用したインフラ定義
- **Bicep**: `infra/bicep/` - Azure Bicep を使用したインフラ定義

どちらも同じインフラストラクチャを構築しますが、好みのツールを選択してください。

詳細な使い方は [infra/README.md](./infra/README.md) を参照してください。

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
├── .dockerignore
├── .env.sample
├── .python-version
├── .gitignore
├── LICENSE
├── README.md
├── pyproject.toml
├── uv.lock
├── script/
│   ├── docker-build
│   ├── docker-push
│   ├── docker-server
│   ├── bootstrap
│   └── server
├── manage.py
├── myproject/
│   └── settings.py
└── .github/
    └── workflows/
        └── deploy.yml
```

## 📚 参考リンク

- https://learn.microsoft.com/ja-jp/azure/container-apps/
- https://docs.github.com/ja/actions
