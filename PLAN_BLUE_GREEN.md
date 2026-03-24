# Plan de deploiement Blue/Green

## 1. Architecture generale

```
[Client]
   |
   v
[Nginx reverse proxy :80]  <-- seul point d'entree public
   |              |
   v              v
[blue]         [green]
backend :3000  backend :3000
frontend :80   frontend :80
   |              |
   +------+-------+
          |
          v
    [PostgreSQL]   <-- base de donnees partagee, unique
```

## 2. Fichiers Docker Compose

| Fichier | Role |
|---------|------|
| `docker-compose.base.yml` | Infrastructure partagee : Postgres + reverse proxy Nginx |
| `docker-compose.blue.yml` | Instance applicative blue : backend-blue + frontend-blue |
| `docker-compose.green.yml` | Instance applicative green : backend-green + frontend-green |

**Pourquoi cette separation ?**
- On peut demarrer/arreter une couleur sans toucher l'autre
- La base de donnees et le proxy ne sont jamais redemarres lors d'un deploiement
- La bascule se fait uniquement cote proxy, sans toucher les conteneurs applicatifs

## 3. Comment lancer l'ensemble

```bash
# Demarrer l'infrastructure de base (postgres + proxy)
docker compose -f docker-compose.base.yml up -d

# Demarrer la version blue (premier deploiement)
docker compose -f docker-compose.base.yml -f docker-compose.blue.yml up -d

# Demarrer la version green (nouveau deploiement)
docker compose -f docker-compose.base.yml -f docker-compose.green.yml up -d

# Les deux peuvent tourner simultanement
docker compose -f docker-compose.base.yml \
               -f docker-compose.blue.yml \
               -f docker-compose.green.yml up -d
```

## 4. Mecanisme de bascule du reverse proxy

**Option retenue : fichier `active.conf` monte en volume + reload Nginx**

### Pourquoi ce choix ?
- Simple et fiable : pas de dependance a Lua ou a des modules Nginx avances
- Rechargement a chaud : `nginx -s reload` ne coupe aucune connexion en cours
- Le fichier `active.conf` est le seul endroit a modifier pour changer la couleur active

### Fonctionnement

Le fichier `nginx/conf.d/active.conf` definit les upstreams actifs :

```nginx
# Etat blue actif
upstream active_backend  { server backend-blue:3000; }
upstream active_frontend { server frontend-blue:80; }
```

Pour basculer vers green, le script remplace ce fichier :

```nginx
# Etat green actif
upstream active_backend  { server backend-green:3000; }
upstream active_frontend { server frontend-green:80; }
```

Puis recharge Nginx sans coupure :
```bash
docker exec gym_proxy nginx -s reload
```

### Detection de la couleur active

Le script detecte automatiquement la couleur en cours en inspectant les conteneurs en cours d'execution :

```bash
if docker ps --format "{{.Names}}" | grep -q "gym_backend_blue"; then
    CURRENT_COLOR="blue"
else
    CURRENT_COLOR="green"
fi
```

Pas besoin de fichier d'etat : la source de verite est Docker lui-meme.

## 5. Scenario de deploiement complet

### Etat initial
- `blue` est en production (actif dans Nginx)
- `green` est arrete ou sur une ancienne version

### Nouveau deploiement (CI)

```
1. Build + push de la nouvelle image (github sha)
         |
2. Detection de la couleur active actuelle
   -> CURRENT = blue, NEW = green
         |
3. Pull de la nouvelle image sur la couleur inactive (green)
   docker compose -f base.yml -f green.yml up -d
         |
4. Attente que les services green soient operationnels (healthcheck)
         |
5. Bascule du proxy
   -> Réécriture de active.conf (upstreams pointent vers green)
   -> docker exec gym_proxy nginx -s reload
         |
6. green est maintenant en production
   blue est toujours en cours d'execution (pret pour rollback)
```

### Rollback instantane

Si green est defaillant apres la bascule :

```bash
# Remettre blue comme actif dans active.conf
cat > nginx/conf.d/active.conf << EOF
upstream active_backend  { server backend-blue:3000; }
upstream active_frontend { server frontend-blue:80; }
EOF

# Recharger nginx
docker exec gym_proxy nginx -s reload
```

Temps de rollback : moins de 5 secondes, aucune coupure.

## 6. Conditions d'activation dans la CI

| Branche | Jobs executes |
|---------|---------------|
| `feature/*` | lint, build, test, sonarcloud, docker |
| `develop` | lint, build, test, sonarcloud, docker, deploy classique |
| `main` | lint, build, test, sonarcloud, docker, **blue-green-deploy** |

Le deploiement blue/green est reserve a `main` uniquement.

## 7. Garanties

- La base de donnees Postgres n'est jamais redemarree lors d'un deploiement
- Les deux couleurs partagent le meme reseau Docker (`gym_network`)
- Le proxy ne rechargee que sa config, pas ses connexions actives
- Un rollback est possible tant que l'ancienne couleur n'a pas ete arretee
