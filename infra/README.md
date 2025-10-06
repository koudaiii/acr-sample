# Infrastructure as Code - Azure Verified Modules

このディレクトリには、Azure Verified Modules (AVM) を使用した Terraform と Bicep のコードが含まれています。

## 📋 選択肢

- **Terraform**: `main.tf` - HashiCorp Terraform を使用したインフラ定義
- **Bicep**: `main.bicep` - Azure Bicep を使用したインフラ定義

```
infra
├── bicep
│   ├── main.bicep
│   ├── main.bicepparam
│   ├── README.md
│   └── resources.bicep
├── modules
├── README.md
└── terraform
    ├── main.tf
    └── terraform.tfvars.example
```

どちらも同じインフラストラクチャを構築しますが、好みのツールを選択してください。

詳細な使い方は各ファイルのコメントを参照してください。
