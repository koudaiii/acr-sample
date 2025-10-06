# Infrastructure as Code - Bicep

このディレクトリには、Azure Verified Modules (AVM) を使用した Bicep コードが含まれています。

## 📋 概要

Azure Container Registry と Azure Container Apps の環境を自動的にプロビジョニングします。

## 🏗️ 構成されるリソース

1. main.bicep - subscription スコープ
  - Resource Group の作成のみを担当
  - resources.bicep モジュールを呼び出し
2. resources.bicep - resourceGroup スコープ
  - Log Analytics Workspace
  - Azure Container Registry
  - Container Apps Environment
  - Container App

| リソース | モジュール | 説明 |
|---------|-----------|------|
| Resource Group | [avm/res/resources/resource-group](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/resources/resource-group) | リソースグループ |
| Container Registry | [avm/res/container-registry/registry](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/container-registry/registry) | Azure Container Registry |
| Log Analytics | [avm/res/operational-insights/workspace](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/operational-insights/workspace) | ログ分析ワークスペース |
| Container Apps Environment | [avm/res/app/managed-environment](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/app/managed-environment) | コンテナアプリ環境 |
| Container App | [avm/res/app/container-app](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/app/container-app) | コンテナアプリ |


## 🚀 使い方

### 前提条件

1. **Azure CLI のインストール**

```bash
# macOS
brew install azure-cli

# その他
# https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli
```

2. **Bicep のインストール**

```bash
# Azure CLI に含まれています
az bicep version

# アップグレード
az bicep upgrade
```

3. **Azure へのログイン**

```bash
az login
```

4. **構文チェック**

```bash
az deployment sub validate \
  --location japaneast \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.bicepparam
```


### デプロイ手順

#### 方法 1: パラメータファイルを使用

1. **パラメータファイルのカスタマイズ**

```bash
vi main.bicepparam
```

2. **デプロイ**

```bash
az deployment sub create \
  --location japaneast \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.bicepparam
```

#### 方法 2: コマンドラインパラメータを使用

```bash
az deployment sub create \
  --location japaneast \
  --template-file infra/bicep/main.bicep \
  --parameters \
    resourceGroupName='my-acr-sample-rg' \
    acrName='myacrsample' \
    containerAppName='my-app' \
    containerAppEnvironmentName='my-env' \
    logAnalyticsWorkspaceName='my-logs'
```

#### 方法 3: What-if でプレビュー

デプロイ前に変更内容を確認：

```bash
az deployment sub what-if \
  --location japaneast \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.bicepparam
```

### デプロイ後の確認

```bash
# デプロイ状態の確認
az deployment sub show \
  --name <deployment-name> \
  --query properties.outputs

# リソースグループの確認
az group show --name acr-sample-rg

# ACR の確認
az acr list --resource-group acr-sample-rg --output table

# Container App の確認
az containerapp list --resource-group acr-sample-rg --output table
```


## 🗑️ リソースの削除

### リソースグループごと削除

```bash
az group delete --name acr-sample-rg --yes --no-wait
```

## 🔄 更新履歴

### v1.0.0 (2024-10-03)

- 初期リリース
- Azure Verified Modules を使用
- Resource Group、ACR、Container Apps、Log Analytics をサポート

## 📝 ライセンス

このプロジェクトのライセンスについては、リポジトリルートの LICENSE ファイルを参照してください。
