# Gym Management System

[![CI Pipeline](https://github.com/Kaz5273/CloudNativeApplicationCurse/actions/workflows/ci.yml/badge.svg)](https://github.com/Kaz5273/CloudNativeApplicationCurse/actions/workflows/ci.yml)
[![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=Kaz5273_CloudNativeApplicationCurse)](https://sonarcloud.io/summary/new_code?id=Kaz5273_CloudNativeApplicationCurse)

Application fullstack de gestion de salle de sport, construite avec des technologies web modernes.

## Fonctionnalites

### Fonctionnalites utilisateur
- **Tableau de bord** : Statistiques, facturation et reservations recentes
- **Reservation de cours** : Reserver et annuler des cours de fitness
- **Gestion des abonnements** : Consulter les details d'abonnement et la facturation
- **Gestion du profil** : Modifier ses informations personnelles

### Fonctionnalites administrateur
- **Tableau de bord admin** : Vue d'ensemble des statistiques et revenus
- **Gestion des utilisateurs** : Operations CRUD sur les utilisateurs
- **Gestion des cours** : Creer, modifier et supprimer des cours
- **Gestion des reservations** : Consulter et gerer toutes les reservations
- **Gestion des abonnements** : Gerer les abonnements des utilisateurs

### Logique metier
- **Gestion des capacites** : Limite de places par cours
- **Prevention des conflits horaires** : Impossible de reserver deux cours qui se chevauchent
- **Politique d'annulation** : 2 heures avant le cours (annulation tardive = absence)
- **Systeme de facturation** : Tarification dynamique avec penalites pour absence
- **Types d'abonnements** : Standard (30€), Premium (50€), Etudiant (20€)

## Stack technique

### Backend
- **Node.js** avec Express.js
- **Prisma** ORM avec PostgreSQL
- **API RESTful** avec gestion des erreurs
- **Architecture MVC** avec pattern repositories

### Frontend
- **Vue.js 3** avec Composition API
- **Pinia** pour la gestion d'etat
- **Vue Router** avec navigation guards
- **CSS responsive**

### DevOps
- **Docker** pour la conteneurisation
- **Docker Compose** pour l'orchestration
- **PostgreSQL** comme base de donnees
- **Nginx** comme reverse proxy et pour servir le frontend
- **Strategie blue/green** pour les deploiements sans coupure

## Workflow Git

### Strategie de branches

- **Branches principales** :
  - `main` - Code pret pour la production
  - `develop` - Branche d'integration des fonctionnalites

- **Branches de fonctionnalites** : `feature/<nom>`
  - Creees depuis `develop`
  - Mergees dans `develop` via Pull Request

### Regles Git

- Pas de commits directs sur `main` ou `develop`
- Pull Request obligatoire pour merger dans `develop`
- Tout le travail de fonctionnalite doit etre dans des branches `feature/*`

### Convention de commits

Ce projet suit la specification **Conventional Commits** :

**Format** : `<type>: <description>`

**Types** :
- `feat` : Nouvelle fonctionnalite
- `fix` : Correction de bug
- `chore` : Taches de maintenance (dependances, config)
- `docs` : Modifications de la documentation
- `style` : Changements de style de code (formatage, points-virgules manquants, etc.)
- `refactor` : Refactorisation du code
- `test` : Ajout ou mise a jour de tests
- `perf` : Ameliorations de performances

**Exemples** :
```bash
feat: ajout de l'authentification
fix: correction de la connexion Postgres
chore: mise a jour des dependances NestJS
docs: mise a jour du README avec les regles Git
```

### Hooks Git actifs

Ce projet utilise **Husky** pour l'automatisation des hooks Git :

- **`pre-commit`** : Execute le lint sur le code frontend et backend
  - Valide la qualite du code avant chaque commit
  - Garantit un style de code coherent

- **`commit-msg`** : Valide le format du message de commit
  - Impose la specification Conventional Commits
  - Bloque les commits avec des messages invalides

**Installation** :
```bash
npm install  # Installe automatiquement les hooks Husky
```

## Pipeline CI/CD

### Workflow GitHub Actions

Le projet utilise un pipeline CI/CD complet qui s'execute a chaque push et pull request sur les branches `main`, `develop` et `feature/*`.

**Jobs du pipeline :**

1. **Lint** - Verification de la qualite du code
   - Lint frontend avec ESLint
   - Lint backend avec ESLint

2. **Build** - Verification de la compilation
   - Build frontend avec Vite
   - Build backend (si applicable)

3. **Test** - Tests automatises
   - Tests unitaires backend
   - Rapport de couverture de code

4. **SonarCloud** - Analyse de la qualite du code
   - Analyse statique du code
   - Detection de vulnerabilites de securite
   - Analyse de la couverture de code
   - **Quality Gate** (bloque le merge en cas d'echec)

5. **Docker** - Build et publication des images
   - Build des images Docker backend et frontend
   - Tests de demarrage des conteneurs
   - Tag des images avec le SHA du commit et `latest`
   - Publication sur GitHub Container Registry (GHCR)

6. **Deploy** - Deploiement automatique
   - Arret propre des conteneurs en cours
   - Recuperation des nouvelles images depuis GHCR
   - Redemarrage complet de la stack applicative
   - Verification que tous les services sont operationnels

### Prerequis du pipeline

**Runner self-hosted :**
- Tous les jobs s'executent sur un runner self-hosted
- Docker doit etre installe sur le runner
- Bash doit etre disponible (Linux/macOS)

**Secrets requis :**
- `SONAR_TOKEN` - Token d'authentification SonarCloud
- `GITHUB_TOKEN` - Fourni automatiquement pour l'authentification GHCR

**Declenchement du workflow :**
```yaml
on:
  push:
    branches: [develop, main, feature/**]
  pull_request:
    branches: [develop, main]
```

## Architecture Docker

### Dockerfile Backend

Build multi-stage optimise pour la production :

- **Stage Build** : Installation des dependances et generation du client Prisma
- **Stage Production** : Image minimale `node:18-alpine`
- Configuration via variables d'environnement
- Expose le port `3000`
- Endpoint de health check
- Utilisateur non-root pour la securite

**Build :**
```bash
cd backend
docker build -t gym-backend .
docker run -p 3000:3000 gym-backend
```

### Dockerfile Frontend

Build multi-stage avec Nginx :

- **Stage Build** : Build de l'application Vue.js avec Vite
- **Stage Production** : Image legere `nginx:alpine`
- `nginx.conf` personnalise avec :
  - Support du routing cote client (Vue Router)
  - Mise en cache des assets statiques
  - Compression Gzip
  - En-tetes de securite
- Expose le port `80`

**Build :**
```bash
cd frontend
docker build -t gym-frontend .
docker run -p 8080:80 gym-frontend
```

### Docker Compose

Orchestration de la stack complete :
- Frontend (Nginx)
- Backend (Node.js)
- Base de donnees PostgreSQL
- Isolation reseau
- Persistance des volumes

**Demarrer l'application complete :**
```bash
docker compose up --build
```

**Acceder a l'application :**
- **Frontend** : http://localhost:8080
- **Backend API** : http://localhost:3000
- **PostgreSQL** : localhost:5432 (interne uniquement)

**Autres commandes :**
```bash
# Arreter tous les services
docker compose down

# Voir les logs
docker compose logs -f [nom-service]

# Reconstruire un service specifique
docker compose up --build [nom-service]
```

### Images Docker

Les images pre-buildees sont disponibles sur GitHub Container Registry :

**Recuperer les images :**
```bash
# Backend
docker pull ghcr.io/kaz5273/cloudnative-backend:latest

# Frontend
docker pull ghcr.io/kaz5273/cloudnative-frontend:latest
```

**Depots des images :**
- Backend : [`ghcr.io/kaz5273/cloudnative-backend`](https://github.com/Kaz5273/cloudnative-backend/pkgs/container/cloudnative-backend)
- Frontend : [`ghcr.io/kaz5273/cloudnative-frontend`](https://github.com/Kaz5273/cloudnative-frontend/pkgs/container/cloudnative-frontend)

## Deploiement local automatise

### Fonctionnement du deploiement

Le projet integre un **pipeline de deploiement automatique** qui redeploit l'application apres chaque build reussi. Aucune intervention manuelle n'est necessaire.

**Architecture du workflow complet :**
```
build -> test -> lint -> SonarCloud -> build images -> push registre -> deploy
```

**Detail des etapes :**

1. **Verification de la qualite** - Lint et tests
2. **Analyse SonarCloud** - Validation du Quality Gate
3. **Build Docker** - Construction des images backend et frontend
4. **Test des conteneurs** - Verification que les images demarrent correctement
5. **Publication registre** - Push vers GitHub Container Registry (GHCR)
6. **Deploiement automatique** - Recuperation des images et redemarrage de la stack

### Branches ou le deploiement est actif

Le stage `deploy` ne se declenche que sur les branches suivantes :

- **`main`** - Deploiement de production
- **`develop`** - Deploiement de staging
- Les branches `feature/*` - Build et tests uniquement (pas de deploiement)

### Script de deploiement

Le deploiement utilise le script bash **idempotent** `scripts/deploy.sh` :

```bash
#!/bin/bash
# 1. Arret propre des conteneurs (les volumes sont preserves)
docker compose down

# 2. Recuperation des nouvelles images depuis GHCR
docker pull ghcr.io/<owner>/cloudnative-backend:${GITHUB_SHA}
docker pull ghcr.io/<owner>/cloudnative-frontend:${GITHUB_SHA}

# 3. Demarrage de la stack avec les nouvelles images
BACKEND_IMAGE=ghcr.io/<owner>/cloudnative-backend:${GITHUB_SHA} \
FRONTEND_IMAGE=ghcr.io/<owner>/cloudnative-frontend:${GITHUB_SHA} \
docker compose up -d
```

**Execution manuelle :**
```bash
# Avec le SHA d'un commit specifique
GITHUB_SHA=<sha> OWNER=kaz5273 ./scripts/deploy.sh

# Avec les images "latest"
./scripts/deploy.sh
```

### Prerequis pour le deploiement automatique

**1. Runner self-hosted actif**
- Runner GitHub Actions en cours d'execution sur la machine locale
- Docker installe et en cours d'execution
- Bash disponible (Linux/macOS)

**2. Secrets requis**
- `GITHUB_TOKEN` - Fourni automatiquement par GitHub Actions pour GHCR
- `SONAR_TOKEN` - Authentification SonarCloud

**3. Acces au registre distant**
- Le runner doit pouvoir acceder a `ghcr.io` pour puller les images
- Authentification automatique via le token GitHub

### Securite du deploiement

Le deploiement est concu pour etre **sur et idempotent** :

- Peut etre execute plusieurs fois sans probleme
- **Ne supprime jamais les volumes de base de donnees** (`docker compose down` sans `--volumes`)
- Preserve toutes les donnees PostgreSQL entre les deploiements
- Arret et redemarrage gracieux des conteneurs
- Verification automatique que tous les services sont operationnels

**Le deploiement n'utilise jamais :**
- `--volumes` (supprimerait les donnees de la base)
- `--rmi` (supprimerait les images)
- `-v` (supprimerait les volumes)

## Deploiement blue/green

### Principe

La strategie blue/green maintient **deux versions de l'application** en parallele. Un reverse proxy Nginx route tout le trafic vers la version active. La bascule est instantanee et le rollback trivial.

```
[Client]
   |
   v
[Nginx :80]  <-- seul point d'entree public
   |              |
   v              v
[blue]         [green]
backend :3000  backend :3000
frontend :80   frontend :80
   |              |
   +------+-------+
          |
          v
    [PostgreSQL]   <-- base de donnees partagee
```

- **blue** = version actuellement en production (active dans Nginx)
- **green** = nouvelle version a deployer (ou ancienne version pour rollback)
- **postgres** = unique, partage entre les deux, jamais redemarree lors d'un deploiement

### Role du reverse proxy

Le conteneur Nginx ecoute sur le port **80** (seul port public expose). Il route :
- `/api/*` → backend de la couleur active
- `/` → frontend de la couleur active

La couleur active est definie dans `nginx/conf.d/active.conf` :

```nginx
upstream active_backend  { server backend-blue:3000; }
upstream active_frontend { server frontend-blue:80; }
```

Pour basculer, ce fichier est reecrit et Nginx est rechargee a chaud :
```bash
docker exec gym_proxy nginx -s reload
```
Aucune connexion en cours n'est interrompue.

### Fichiers Docker Compose

| Fichier | Role |
|---------|------|
| `docker-compose.base.yml` | Postgres + reverse proxy (infrastructure partagee) |
| `docker-compose.blue.yml` | backend-blue + frontend-blue |
| `docker-compose.green.yml` | backend-green + frontend-green |

### Deroulement d'un deploiement

```
1. Build + push de la nouvelle image (SHA du commit)
         |
2. Detection de la couleur active (inspection des conteneurs Docker)
   ex: blue actif -> cible = green
         |
3. Pull de la nouvelle image + demarrage de la couleur inactive (green)
   docker compose -f base.yml -f green.yml up -d
         |
4. Health check sur le backend green (attente)
         |
5. Bascule du proxy : réécriture de active.conf + nginx -s reload
         |
6. green est en production, blue reste disponible pour rollback
```

### Conditions d'activation dans la CI

| Branche | Deploiement |
|---------|-------------|
| `feature/*` | Aucun deploiement |
| `develop` | Deploiement classique (`deploy.sh`) |
| `main` | Deploiement blue/green (`deploy-blue-green.sh`) |

Le job `blue-green-deploy` ne se declenche que sur `main`, apres la publication des images Docker.

### Rollback instantane

Si la nouvelle version est defaillante apres bascule :

```bash
# Rebascule vers l'ancienne couleur en moins de 5 secondes
./scripts/rollback-blue-green.sh
```

L'ancienne couleur reste toujours en cours d'execution jusqu'au prochain deploiement.

### Commandes manuelles

```bash
# Demarrer l'infrastructure de base
docker compose -f docker-compose.base.yml up -d

# Demarrer la version blue
docker compose -f docker-compose.base.yml -f docker-compose.blue.yml up -d

# Demarrer la version green
docker compose -f docker-compose.base.yml -f docker-compose.green.yml up -d

# Deploiement blue/green manuel
GITHUB_SHA=latest OWNER=kaz5273 ./scripts/deploy-blue-green.sh

# Rollback manuel
./scripts/rollback-blue-green.sh
```

## Demarrage rapide

### Prerequis
- Docker et Docker Compose
- Git
- Node.js (pour le developpement local)

### Installation

1. **Cloner le depot**
   ```bash
   git clone https://github.com/Kaz5273/CloudNativeApplicationCurse.git
   cd CloudNativeApplicationCurse
   ```

2. **Configurer les variables d'environnement**
   ```bash
   cp .env.example .env
   ```
   Modifier le fichier `.env` si necessaire (les valeurs par defaut fonctionnent pour le developpement).

3. **Demarrer l'application**
   ```bash
   docker compose up --build
   ```

4. **Acceder a l'application**
   - Frontend : http://localhost:8080
   - Backend API : http://localhost:3000
   - Base de donnees : localhost:5432

### Identifiants par defaut

L'application est livree avec des donnees de test pre-chargees :

**Utilisateur admin :**
- Email : admin@gym.com
- Mot de passe : admin123
- Role : ADMIN

**Utilisateurs reguliers :**
- Email : john.doe@email.com
- Email : jane.smith@email.com
- Email : mike.wilson@email.com
- Mot de passe : password123 (pour tous les utilisateurs)

## Structure du projet

```
gym-management-system/
├── .github/
│   └── workflows/
│       └── ci.yml           # Pipeline CI/CD complet
├── scripts/
│   ├── deploy.sh            # Script de deploiement bash (CI)
│   └── deploy.ps1           # Script de deploiement PowerShell
├── backend/
│   ├── src/
│   │   ├── controllers/     # Gestionnaires de requetes
│   │   ├── services/        # Logique metier
│   │   ├── repositories/    # Couche d'acces aux donnees
│   │   ├── routes/          # Routes API
│   │   └── prisma/          # Schema et client base de donnees
│   ├── seed/                # Donnees initiales
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── views/           # Composants/pages Vue
│   │   ├── services/        # Communication API
│   │   ├── store/           # Stores Pinia
│   │   └── router/          # Vue Router
│   ├── Dockerfile
│   └── nginx.conf
└── docker-compose.yml
```

## Endpoints API

### Authentification
- `POST /api/auth/login` - Connexion utilisateur

### Utilisateurs
- `GET /api/users` - Lister tous les utilisateurs
- `GET /api/users/:id` - Obtenir un utilisateur par ID
- `POST /api/users` - Creer un utilisateur
- `PUT /api/users/:id` - Mettre a jour un utilisateur
- `DELETE /api/users/:id` - Supprimer un utilisateur

### Cours
- `GET /api/classes` - Lister tous les cours
- `GET /api/classes/:id` - Obtenir un cours par ID
- `POST /api/classes` - Creer un cours
- `PUT /api/classes/:id` - Mettre a jour un cours
- `DELETE /api/classes/:id` - Supprimer un cours

### Reservations
- `GET /api/bookings` - Lister toutes les reservations
- `GET /api/bookings/user/:userId` - Reservations d'un utilisateur
- `POST /api/bookings` - Creer une reservation
- `PUT /api/bookings/:id/cancel` - Annuler une reservation
- `DELETE /api/bookings/:id` - Supprimer une reservation

### Abonnements
- `GET /api/subscriptions` - Lister tous les abonnements
- `GET /api/subscriptions/user/:userId` - Abonnement d'un utilisateur
- `POST /api/subscriptions` - Creer un abonnement
- `PUT /api/subscriptions/:id` - Mettre a jour un abonnement

### Tableau de bord
- `GET /api/dashboard/user/:userId` - Tableau de bord utilisateur
- `GET /api/dashboard/admin` - Tableau de bord administrateur

## Developpement

### Configuration locale

1. **Backend**
   ```bash
   cd backend
   npm install
   npm run dev
   ```

2. **Frontend**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

3. **Base de donnees**
   ```bash
   cd backend
   npx prisma migrate dev
   npm run seed
   ```

### Gestion de la base de donnees

- **Visualiser la BDD** : `npx prisma studio`
- **Reinitialiser la BDD** : `npx prisma db reset`
- **Generer le client** : `npx prisma generate`
- **Executer les migrations** : `npx prisma migrate deploy`

### Commandes utiles

```bash
# Arreter tous les conteneurs
docker compose down

# Voir les logs
docker compose logs -f [nom-service]

# Reconstruire un service specifique
docker compose up --build [nom-service]

# Acceder a la base de donnees
docker exec -it gym_db psql -U postgres -d gym_management
```

## Fonctionnalites en detail

### Systeme d'abonnements
- **STANDARD** : 30€/mois, 5€ par absence
- **PREMIUM** : 50€/mois, 3€ par absence
- **ETUDIANT** : 20€/mois, 7€ par absence

### Regles de reservation
- Les utilisateurs ne peuvent reserver que des cours futurs
- La capacite maximale par cours est controlee
- Pas de double reservation sur le meme creneau
- Politique d'annulation de 2 heures

### Tableau de bord admin
- Nombre total d'utilisateurs et abonnements actifs
- Statistiques de reservations (confirmees, absences, annulations)
- Calcul des revenus mensuels
- Outils de gestion des utilisateurs

### Tableau de bord utilisateur
- Statistiques personnelles et activite
- Details de l'abonnement en cours
- Facturation mensuelle avec penalites d'absence
- Historique des reservations recentes

## Contribuer

1. Forker le depot
2. Creer une branche de fonctionnalite
3. Effectuer les modifications
4. Ajouter des tests si applicable
5. Soumettre une pull request

## Licence

Ce projet est sous licence MIT.

## Support

Pour obtenir de l'aide ou poser des questions, ouvrez une issue dans le depot.
