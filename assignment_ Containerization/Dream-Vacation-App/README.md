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
