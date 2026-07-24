# Dockerized Acquisitions App with Neon Database

This project uses Docker to containerize the application with two distinct environments: **Development** (using Neon Local) and **Production** (using Neon Cloud directly).

## Prerequisites

- Docker & Docker Compose
- A [Neon](https://neon.tech) account with an API key and Project ID

## Environment Setup

### 1. Get Your Neon Credentials

1. **NEON_API_KEY**: Go to [Neon Console > API Keys](https://console.neon.tech/app/settings/api-keys) and create a new key.
2. **NEON_PROJECT_ID**: Go to [Neon Console > Project Settings](https://console.neon.tech) and copy your Project ID.
3. **PARENT_BRANCH_ID**: From your Neon dashboard, copy your main branch ID (used as the base for ephemeral dev branches).

### 2. Configure Environment Files

**Development** (`.env.development`):

```bash
NEON_API_KEY=your_neon_api_key
NEON_PROJECT_ID=your_project_id
PARENT_BRANCH_ID=your_main_branch_id
ARCJET_KEY=your_arcjet_key
JWT_SECRET=your_jwt_secret
```

**Production** (`.env.production`):

```bash
DATABASE_URL=postgresql://user:password@ep-xxx-yyy.region.aws.neon.tech/dbname?sslmode=require
ARCJET_KEY=your_arcjet_key
JWT_SECRET=your_jwt_secret
```

## Development (Neon Local)

### Quick Setup (Recommended)

Run the setup script to automate everything — prerequisite checks, env prompts, container build, migrations, and health verification:

```bash
chmod +x setup-docker.sh
./setup-docker.sh
```

The script will:
1. Verify Docker and Docker Compose are installed
2. Create `.env.development` from `.env.example` if missing
3. Prompt for any missing Neon credentials
4. Auto-generate `JWT_SECRET` if left blank
5. Build and start containers
6. Wait for Neon Local to be healthy
7. Run database migrations
8. Verify the app is reachable

### Manual Setup

Neon Local runs a proxy container that creates ephemeral database branches from your Neon project. Each `docker compose up` creates a fresh branch; `docker compose down` deletes it.

```bash
docker compose -f docker-compose.dev.yml up --build
```

### Stop Development

```bash
docker compose -f docker-compose.dev.yml down
```

### What Happens

1. The `neon-local` container starts and creates an ephemeral branch from your `PARENT_BRANCH_ID`.
2. The app container connects to Postgres via `neon-local:5432` using the Neon serverless driver.
3. On shutdown, the ephemeral branch is automatically deleted.

### Running Migrations (Dev)

```bash
docker compose -f docker-compose.dev.yml exec app npx drizzle-kit migrate
```

## Production (Neon Cloud)

Production connects directly to your Neon Cloud database URL. No Neon Local proxy is involved.

### Start Production

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

### Stop Production

```bash
docker compose -f docker-compose.prod.yml down
```

## Environment Variables

| Variable | Dev | Prod | Description |
|---|---|---|---|
| `PORT` | 3000 | 3000 | App listen port |
| `NODE_ENV` | development | production | Node environment |
| `LOG_LEVEL` | debug | info | Logging verbosity |
| `DATABASE_URL` | Auto-set by compose | Required | Postgres connection string |
| `NEON_API_KEY` | Required | Not used | Neon API key for Neon Local |
| `NEON_PROJECT_ID` | Required | Not used | Neon project ID for Neon Local |
| `PARENT_BRANCH_ID` | Required | Not used | Branch ID to fork ephemeral branches from |
| `ARCJET_KEY` | Required | Required | Arcjet security key |
| `JWT_SECRET` | Required | Required | JWT signing secret |

## Architecture

```
┌─────────────────────────────────────┐
│         docker-compose.dev.yml       │
│                                     │
│  ┌──────────┐    ┌───────────────┐  │
│  │   app    │───▶│  neon-local   │  │
│  │ :3000    │    │  :5432        │──┼──▶ Neon Cloud
│  └──────────┘    └───────────────┘  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│        docker-compose.prod.yml       │
│                                     │
│  ┌──────────┐                       │
│  │   app    │───────────────────────┼──▶ Neon Cloud
│  │ :3000    │                       │
│  └──────────┘                       │
└─────────────────────────────────────┘
```

## Local Development (Without Docker)

If you prefer to run without Docker:

```bash
cp .env.example .env
# Fill in your DATABASE_URL (direct Neon connection)
npm install
npm run dev
```

## Logs

Logs are written to the `logs/` directory and are mounted as a volume in Docker. Check `logs/combined.log` and `logs/error.log` for application logs.
