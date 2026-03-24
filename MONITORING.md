# Monitoring & Observabilite – TP6

## 1. Les trois piliers de l'observabilite

| Pilier | Definition | Outil utilise |
|--------|-----------|---------------|
| **Metriques** | Valeurs numeriques agregees dans le temps (counters, gauges, histogrammes) | Prometheus + prom-client |
| **Logs** | Enregistrements d'evenements horodates et structures | Loki + Promtail |
| **Traces** | Suivi d'une requete a travers plusieurs services | *(hors scope TP6)* |

**Monitoring** = surveiller des metriques connues a l'avance (est-ce que le service repond ?).
**Observabilite** = capacite a comprendre l'etat interne du systeme a partir de ses sorties externes (logs, metriques, traces). L'observabilite permet de debugger des problemes *inconnus*.

---

## 2. Role de chaque composant

### Prometheus
- **Role** : collecteur et base de donnees de series temporelles (time-series database)
- **Fonctionnement** : il *scrape* (tire) les metriques depuis les cibles a intervalles reguliers (`scrape_interval`)
- **Requetes** : langage PromQL pour interroger et aggrefer les metriques
- **Port** : `9090`

### Grafana
- **Role** : visualisation et dashboards
- **Fonctionnement** : se connecte a plusieurs datasources (Prometheus, Loki…) et affiche les donnees sous forme de graphiques, jauges, tableaux
- **Port** : `3000`

### Loki
- **Role** : base de donnees de logs (equivalent Prometheus mais pour les logs)
- **Fonctionnement** : stocke les logs indexes uniquement sur leurs *labels* (pas full-text par defaut), tres economique en ressources
- **Requetes** : langage LogQL (proche de PromQL)
- **Port** : `3100` (interne)

### Promtail
- **Role** : agent de collecte des logs, equivalent du "scraper" pour Loki
- **Fonctionnement** : lit les logs depuis les conteneurs Docker via le socket Unix, les enrichit avec des labels (container name, service…) et les pousse vers Loki
- **Port** : `9080` (interne)

### cAdvisor
- **Role** : exporte les metriques de ressources des conteneurs Docker (CPU, RAM, reseau, I/O)
- **Fonctionnement** : surveille le daemon Docker et expose les metriques au format Prometheus
- **Port** : `8080`

---

## 3. Architecture globale

```
                                   ┌──────────────────────────────────────┐
                                   │         monitoring_network            │
                                   │                                       │
  ┌──────────────┐  scrape /metrics │  ┌────────────┐                      │
  │gym_backend_  │◄────────────────┤  │ Prometheus │──────────┐           │
  │blue :3000    │  (gym_network)  │  │  :9090     │          │           │
  └──────────────┘                │  └────────────┘          │           │
                                  │         ▲                 │           │
  ┌──────────────┐  scrape /metrics│         │ scrape         │ query      │
  │gym_backend_  │◄────────────────┤  ┌──────┴─────┐         ▼           │
  │green :3000   │  (gym_network)  │  │  cAdvisor  │  ┌────────────┐     │
  └──────────────┘                │  │   :8080    │  │  Grafana   │     │
                                  │  └────────────┘  │   :3000    │     │
  ┌──────────────┐  push logs     │                   └─────┬──────┘     │
  │ Docker       │◄───────────────┤  ┌────────────┐         │            │
  │ containers   │  (docker sock) │  │  Promtail  │         │ query      │
  │ (stdout)     │────logs───────►│  │   :9080    │  ┌──────▼──────┐    │
  └──────────────┘                │  └────────────┘  │    Loki     │    │
                                  │         │push     │   :3100    │    │
                                  │         └────────►└────────────┘    │
                                  └──────────────────────────────────────┘

Legende :
  ──► flux de donnees
  gym_network    : reseau partage avec la stack applicative (blue/green)
  monitoring_network : reseau interne des services de monitoring
```

---

## 4. Integration avec l'application

L'application tourne en mode **blue/green** (TP5) :
- Conteneurs : `gym_backend_blue` et `gym_backend_green` sur le reseau `gym_network`
- Le backend Express.js expose un endpoint `/metrics` (via `prom-client`) sur le port `3000`
- Prometheus rejoins `gym_network` pour scraper `gym_backend_blue:3000` et `gym_backend_green:3000`
- Promtail lit les logs de tous les conteneurs prefixes `gym_` via le socket Docker
- cAdvisor exporte les metriques CPU/RAM de chaque conteneur

---

## 5. Ports d'execution

| Service    | Port expose | Usage |
|------------|-------------|-------|
| Grafana    | `3000`      | Interface web – http://localhost:3000 |
| Prometheus | `9090`      | Interface web + API – http://localhost:9090 |
| Loki       | `3100`      | API interne (pas d'interface graphique) |
| Promtail   | `9080`      | API interne |
| cAdvisor   | `8080`      | Interface web + metriques – http://localhost:8080 |

> **Note** : Loki et Promtail ne sont pas exposes publiquement, ils sont uniquement accessibles sur `monitoring_network`.

---

## 6. Demarrage de la stack monitoring

### Prerequis

1. La stack applicative (blue ou green) doit etre demarree en premier pour que `gym_network` existe :

```bash
docker compose -f docker-compose.base.yml -f docker-compose.blue.yml up -d
```

2. Copier et configurer le fichier d'environnement :

```bash
cp .env.monitoring.example .env
# Editer .env et definir GRAFANA_ADMIN_PASSWORD
```

### Lancer la stack monitoring

```bash
docker compose -f docker-compose.monitoring.yml --env-file .env up -d
```

### Verifier l'etat des conteneurs

```bash
docker compose -f docker-compose.monitoring.yml ps
```

Tous les conteneurs doivent etre en etat `healthy` ou `running`.

### Arreter la stack monitoring

```bash
docker compose -f docker-compose.monitoring.yml down
```

---

## 7. Verification de Prometheus

1. Ouvrir http://localhost:9090
2. Aller dans **Status → Targets**
3. Les cibles `backend-blue`, `backend-green` et `cadvisor` doivent etre en etat **UP**
4. Tester une requete PromQL :

```promql
http_requests_total{job="backend-blue"}
```

---

## 8. Metriques disponibles (backend)

Grace a `prom-client`, les metriques suivantes sont exposees sur `/metrics` :

| Metrique | Type | Description |
|----------|------|-------------|
| `http_requests_total` | Counter | Nombre total de requetes HTTP (labels: method, route, status_code) |
| `http_request_duration_seconds` | Histogram | Duree des requetes HTTP en secondes |
| `process_cpu_seconds_total` | Counter | Temps CPU consomme par le processus Node.js |
| `process_resident_memory_bytes` | Gauge | Memoire vive utilisee |
| `nodejs_heap_size_used_bytes` | Gauge | Taille du heap Node.js utilise |
| `nodejs_eventloop_lag_seconds` | Gauge | Latence de l'event loop Node.js |

---

## 9. Configuration des datasources Grafana

Les datasources sont **provisionnees automatiquement** au demarrage via `monitoring/grafana/provisioning/datasources/datasources.yml` :
- **Prometheus** : http://prometheus:9090 (defaut)
- **Loki** : http://loki:3100

---

## 10. Dashboards Grafana recommandes

### Dashboard 1 : Metriques backend

Panels sugeres (datasource : Prometheus) :

```promql
# Nombre de requetes par seconde
rate(http_requests_total[1m])

# Latence moyenne (p50)
histogram_quantile(0.5, rate(http_request_duration_seconds_bucket[5m]))

# Latence p95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Taux d'erreurs 5xx
rate(http_requests_total{status_code=~"5.."}[1m])

# Memoire heap Node.js
nodejs_heap_size_used_bytes

# CPU process
rate(process_cpu_seconds_total[1m])
```

### Dashboard 2 : Logs correles

Panels sugeres (datasource : Loki) :

```logql
# Tous les logs du backend blue
{container="gym_backend_blue"}

# Logs d'erreur uniquement
{container=~"gym_backend.*"} |= "error"

# Repartition par niveau de log
sum by (logstream) (count_over_time({container=~"gym_backend.*"}[5m]))
```

### Dashboards communautaires importables

- **Node.js Application Dashboard** : ID Grafana `11159`
- **Docker cAdvisor** : ID Grafana `193`
- **Loki Dashboard** : ID Grafana `13639`

Pour importer : Grafana → Dashboards → Import → saisir l'ID.
