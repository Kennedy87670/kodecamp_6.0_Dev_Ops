# Dream Vacation Destinations

A full-stack app where users build a list of countries they'd like to visit, with details fetched from the REST Countries API and persisted in PostgreSQL.

**Stack:** React · Node.js/Express · PostgreSQL · Docker

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2+)

---

## Quick Start

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd Dream-Vacation-App

# 2. Copy the environment file (edit values if needed)
cp .env .env.local   # optional — .env works out of the box

# 3. Build and start all services
docker-compose up --build
```

| Service  | URL                          |
|----------|------------------------------|
| Frontend | http://localhost             |
| Backend  | http://localhost:3001        |

---

## Environment Variables

All variables live in `.env` at the project root. Docker Compose reads this file automatically.

| Variable            | Default value                                          | Used by        |
|---------------------|--------------------------------------------------------|----------------|
| `POSTGRES_USER`     | `postgres`                                             | db             |
| `POSTGRES_PASSWORD` | `postgres`                                             | db             |
| `POSTGRES_DB`       | `dreamvacations`                                       | db             |
| `DATABASE_URL`      | `postgresql://postgres:postgres@db:5432/dreamvacations`| backend        |
| `PORT`              | `3001`                                                 | backend        |
| `REACT_APP_API_URL` | `http://localhost:3001`                                | frontend build |

> `DATABASE_URL` uses the service name `db` as the host — Docker's internal DNS resolves it within the `app-network` bridge network.

---

## Architecture

```
┌─────────────────────────────────────────┐
│              app-network                │
│                                         │
│  ┌──────────┐    ┌──────────┐           │
│  │ frontend │───▶│ backend  │           │
│  │  :80     │    │  :3001   │           │
│  └──────────┘    └────┬─────┘           │
│                       │                 │
│                  ┌────▼─────┐           │
│                  │    db    │           │
│                  │  :5432   │           │
│                  └──────────┘           │
└─────────────────────────────────────────┘
```

- **frontend** — React app built with a multi-stage Dockerfile, served by nginx.
- **backend** — Express API; waits for `db` to pass a health check before starting.
- **db** — PostgreSQL 15; schema is auto-created via `db/init.sql` on first run.
- **postgres_data** — named Docker volume that persists database data across restarts.

---

## Useful Commands

```bash
# Start in detached mode
docker-compose up --build -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove the database volume (full reset)
docker-compose down -v
```

---

## Features

- Add countries to your dream vacation list
- View capital, population, and region for each country
- Remove countries from the list
- Data persists across container restarts via a named Docker volume

---

## Technologies

- **Frontend:** React 18, Axios
- **Backend:** Node.js, Express, pg, dotenv, cors
- **Database:** PostgreSQL 15
- **External API:** [REST Countries API](https://restcountries.com)
- **Containerization:** Docker, Docker Compose
- **CI/CD:** GitHub Actions

---

## CI/CD Pipeline

This project includes automated GitHub Actions workflows that build, test, and deploy the application on every push and pull request.

### How It Works

**Trigger Conditions**
- Workflows activate on `push` and `pull_request` events to `main` or `dev` branches
- Path filters ensure workflows only run when relevant code changes (backend or frontend only rebuilds if its code changed)

**CI Stage (Build & Test)**
- Checkout code and install dependencies (`npm ci`)
- Run linter checks (`npm run lint --if-present`)
- Execute tests (`npm test` with `--passWithNoTests` to gracefully handle services without tests)
- Build Docker images locally to catch errors early
- This stage runs for all pushes and pull requests

**CD Stage (Registry Push)**
- Only runs on `push` events to `main`/`dev` — **pull requests do not push images**
- Authenticates with Docker Hub using stored secrets
- Builds and pushes Docker images tagged with:
  - `latest` — always points to the most recent build
  - Commit SHA (e.g., `abc123def456`) — immutable reference to code at that commit

**Image Naming**
- Backend: `<DOCKER_USERNAME>/dream-vacation-backend:<tag>`
- Frontend: `<DOCKER_USERNAME>/dream-vacation-frontend:<tag>`

### Setup GitHub Secrets

Before workflows can push images, add two secrets to your GitHub repository:

1. Go to **Settings → Secrets and variables → Actions**
2. Create `DOCKER_USERNAME` — your Docker Hub username
3. Create `DOCKER_TOKEN` — a Docker Hub access token (not your password)
   - Generate at [Docker Hub Access Tokens](https://hub.docker.com/settings/security)
   - Give it "Read & Write" permissions

**Without these secrets, the push job will fail with authentication error — this is expected.**

### Workflow Files

- `.github/workflows/backend.yml` — CI/CD for Node.js backend
- `.github/workflows/frontend.yml` — CI/CD for React frontend

Each workflow follows the same pattern: CI stage → optional CD stage (push only).

### Local Testing

To test workflows locally (using [act](https://github.com/nektos/act)):

```bash
# Build and test backend
act push --job build-and-test --secret DOCKER_USERNAME=your_user --secret DOCKER_TOKEN=your_token -W .github/workflows/backend.yml

# Build and test frontend
act push --job build-and-test --secret DOCKER_USERNAME=your_user --secret DOCKER_TOKEN=your_token -W .github/workflows/frontend.yml
```
