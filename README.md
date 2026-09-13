# Mama Salama — Azure Infrastructure

Infrastructure as Code du PFE Mama Salama. Ce dépôt est indépendant des dépôts frontend et backend.

## Architecture préparée

- Azure Container Registry pour les images Docker
- Azure Container Apps pour le backend
- Azure Static Web Apps pour le frontend, sous réserve de validation après audit
- Azure Database for PostgreSQL Flexible Server, sous réserve de validation après audit
- Azure Key Vault pour les secrets
- Azure Storage pour les fichiers applicatifs
- Log Analytics et Application Insights pour l'observabilité
- GitHub Actions avec authentification Azure OIDC
- Remote state Terraform dans Azure Storage

Les ressources de base (ACR, Storage, Key Vault, observabilité et Container Apps Environment) sont créées par défaut. PostgreSQL, le backend et le frontend sont désactivés jusqu'à l'audit des applications.

## Prérequis

- Terraform >= 1.7
- Azure CLI
- Une souscription Azure
- Les droits de création de ressources et d'attribution de rôles

## 1. Créer le remote state

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# Renseigner subscription_id et, si elle existe déjà, ci_principal_id
az login
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform output
```

Conserver les valeurs `resource_group_name`, `storage_account_name` et `container_name` retournées.

## 2. Initialiser l'environnement PFE

```bash
cd ../environments/pfe
cp terraform.tfvars.example terraform.tfvars
# Renseigner subscription_id dans terraform.tfvars
terraform init \
  -backend-config="resource_group_name=<TFSTATE_RESOURCE_GROUP>" \
  -backend-config="storage_account_name=<TFSTATE_STORAGE_ACCOUNT>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=pfe/terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform fmt -check -recursive ../../
terraform validate
terraform plan
```

Après validation du plan :

```bash
terraform apply
```

## 3. Configurer GitHub Actions

Créer un environnement GitHub nommé `pfe`. Ajouter les secrets :

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

Ajouter les variables :

- `TFSTATE_RESOURCE_GROUP`
- `TFSTATE_STORAGE_ACCOUNT`
- `TFSTATE_CONTAINER` avec la valeur `tfstate`

L'identité Azure associée à `AZURE_CLIENT_ID` doit utiliser une fédération OIDC GitHub. Elle doit avoir le rôle `Storage Blob Data Contributor` sur le compte de stockage du state, en plus des droits nécessaires sur les ressources applicatives. Protéger l'environnement `pfe` avec une approbation manuelle avant d'autoriser `terraform-apply.yml` est recommandé.

## 4. Activer les composants applicatifs

Après l'audit du frontend et du backend, modifier `environments/pfe/terraform.tfvars` :

```hcl
enable_postgres = true
enable_backend  = true
enable_frontend = true

backend_image = "<acr-name>.azurecr.io/mama-salama-backend:<tag-immuable>"
backend_port  = 8080
```

Ne pas utiliser `latest` dans les déploiements définitifs. Le pipeline applicatif devra construire l'image, la pousser dans ACR puis transmettre un tag immuable au déploiement.

## Points à confirmer après audit

- Frameworks et versions frontend/backend
- Port et health check du backend
- Type et schéma de base de données
- Variables d'environnement et secrets
- Stockage des images et documents médicaux
- Besoins réseau, CORS et authentification
- Compatibilité du frontend avec Static Web Apps
- Besoins RAG/IA, workers asynchrones et files de messages
- Contraintes de confidentialité et de conservation des données de santé

## Sécurité

- Aucun secret ne doit être commité.
- ACR utilise une identité managée et le rôle `AcrPull` ; le compte administrateur est désactivé.
- Key Vault utilise Azure RBAC et la suppression réversible.
- Le state distant est privé, versionné, protégé par une rétention de 7 jours et accessible via Microsoft Entra ID plutôt que par une clé partagée.
- Pour un PFE à budget limité, les accès publics peuvent être tolérés temporairement ; les règles réseau devront être durcies avant toute utilisation avec de vraies données médicales.
