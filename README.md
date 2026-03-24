# Gym Management System

[![CI Pipeline](https://github.com/Kaz5273/CloudNativeApplicationCurse/actions/workflows/ci.yml/badge.svg)](https://github.com/Kaz5273/CloudNativeApplicationCurse/actions/workflows/ci.yml)
[![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=Kaz5273_CloudNativeApplicationCurse)](https://sonarcloud.io/summary/new_code?id=Kaz5273_CloudNativeApplicationCurse)

A complete fullstack gym management application built with modern web technologies.

## Features

### User Features
- **User Dashboard**: View stats, billing, and recent bookings
- **Class Booking**: Book and cancel fitness classes
- **Subscription Management**: View subscription details and billing
- **Profile Management**: Update personal information

### Admin Features
- **Admin Dashboard**: Overview of gym statistics and revenue
- **User Management**: CRUD operations for users
- **Class Management**: Create, update, and delete fitness classes
- **Booking Management**: View and manage all bookings
- **Subscription Management**: Manage user subscriptions

### Business Logic
- **Capacity Management**: Classes have maximum capacity limits
- **Time Conflict Prevention**: Users cannot book overlapping classes
- **Cancellation Policy**: 2-hour cancellation policy (late cancellations become no-shows)
- **Billing System**: Dynamic pricing with no-show penalties
- **Subscription Types**: Standard (€30), Premium (€50), Student (€20)

## Tech Stack

### Backend
- **Node.js** with Express.js
- **Prisma** ORM with PostgreSQL
- **RESTful API** with proper error handling
- **MVC Architecture** with repositories pattern

### Frontend
- **Vue.js 3** with Composition API
- **Pinia** for state management
- **Vue Router** with navigation guards
- **Responsive CSS** styling

### DevOps
- **Docker** containerization
- **Docker Compose** for orchestration
- **PostgreSQL** database
- **Nginx** for frontend serving

## Git Workflow

### Branch Strategy

- **Main branches**:
  - `main` - Production-ready code
  - `develop` - Integration branch for features

- **Feature branches**: `feature/<nom>`
  - Created from `develop`
  - Merged back to `develop` via Pull Request

### Git Rules

- ❌ **No direct commits** on `main` or `develop`
- ✅ **Pull Request required** to merge into `develop`
- ✅ All feature work must be done in `feature/*` branches

### Commit Convention

This project follows **Conventional Commits** specification:

**Format**: `<type>: <description>`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `chore`: Maintenance tasks (dependencies, config)
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semi-colons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `perf`: Performance improvements

**Examples**:
```bash
feat: ajout de l'authentification
fix: correction de la connexion Postgres
chore: mise à jour des dépendances NestJS
docs: mise à jour du README avec les règles Git
```

### Active Git Hooks

This project uses **Husky** for Git hooks automation:

- **`pre-commit`**: Runs linting on frontend and backend code
  - Validates code quality before committing
  - Ensures consistent code style
  
- **`commit-msg`**: Validates commit message format
  - Enforces Conventional Commits specification
  - Prevents commits with invalid messages

**Installation**:
```bash
npm install  # Installs husky hooks automatically
```

## CI/CD Pipeline

### GitHub Actions Workflow

The project uses a comprehensive CI/CD pipeline that runs on every push and pull request to `main`, `develop`, and `feature/*` branches.

**Pipeline Jobs:**

1. **Lint** - Code quality checks
   - Frontend linting with ESLint
   - Backend linting with ESLint

2. **Build** - Application build verification
   - Frontend build with Vite
   - Backend build (if applicable)

3. **Test** - Automated testing
   - Backend unit tests
   - Test coverage reporting

4. **SonarCloud** - Code quality analysis
   - Static code analysis
   - Security vulnerability scanning
   - Code coverage analysis
   - **Quality Gate enforcement** (blocks merge if failed)

5. **Docker** - Container image build and deployment
   - Build backend and frontend Docker images
   - Run container health checks
   - Tag images with commit SHA and `latest`
   - Push to GitHub Container Registry (GHCR)

### Pipeline Requirements

**Self-Hosted Runner:**
- All jobs run on a self-hosted runner
- Requires Docker installed on the runner
- Requires PowerShell 5.1+ (Windows)

**Required Secrets:**
- `SONAR_TOKEN` - SonarCloud authentication token
- `GITHUB_TOKEN` - Automatically provided for GHCR authentication

**Workflow Trigger:**
```yaml
on:
  push:
    branches: [develop, main, feature/**]
  pull_request:
    branches: [develop, main]
```

## Docker Architecture

### Backend Dockerfile

Multi-stage build with production optimization:

- **Build Stage**: Dependencies installation and Prisma client generation
- **Production Stage**: Minimal `node:18-alpine` image
- Environment configuration via env variables
- Exposes port `3000`
- Health check endpoint
- Non-root user for security

**Build:**
```bash
cd backend
docker build -t gym-backend .
docker run -p 3000:3000 gym-backend
```

### Frontend Dockerfile

Multi-stage build with Nginx serving:

- **Build Stage**: Vue.js application build with Vite
- **Production Stage**: Lightweight `nginx:alpine` image
- Custom `nginx.conf` with:
  - Client-side routing support (Vue Router)
  - Static asset caching
  - Gzip compression
  - Security headers
- Exposes port `80`

**Build:**
```bash
cd frontend
docker build -t gym-frontend .
docker run -p 8080:80 gym-frontend
```

### Docker Compose

Full stack orchestration with:
- Frontend (Nginx)
- Backend (Node.js)
- PostgreSQL database
- Network isolation
- Volume persistence

**Start the entire application:**
```bash
docker compose up --build
```

**Access the application:**
- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:3000
- **PostgreSQL**: localhost:5432 (internal only)

**Other commands:**
```bash
# Stop all services
docker compose down

# View logs
docker compose logs -f [service-name]

# Rebuild specific service
docker compose up --build [service-name]
```

### Docker Images

Pre-built images are available on GitHub Container Registry:

**Pull images:**
```bash
# Backend
docker pull ghcr.io/kaz5273/cloudnative-backend:latest

# Frontend
docker pull ghcr.io/kaz5273/cloudnative-frontend:latest
```

**Image repositories:**
- Backend: [`ghcr.io/kaz5273/cloudnative-backend`](https://github.com/Kaz5273/cloudnative-backend/pkgs/container/cloudnative-backend)
- Frontend: [`ghcr.io/kaz5273/cloudnative-frontend`](https://github.com/Kaz5273/cloudnative-frontend/pkgs/container/cloudnative-frontend)

## 🔄 Automated Deployment

### Deployment Workflow

The project includes an **automated deployment pipeline** that deploys the application locally after successful builds:

```
Lint → Build → Test → SonarCloud → Docker Build & Push → Deploy
```

**Workflow Steps:**

1. **Code Quality Checks** - Linting and testing
2. **SonarCloud Analysis** - Quality gate validation
3. **Docker Build** - Build backend and frontend images
4. **Container Testing** - Verify images start correctly
5. **Push to Registry** - Publish to GitHub Container Registry
6. **Automated Deploy** - Pull images and deploy locally

### Deployment Trigger

The deployment stage is **automatically executed** after successful image publication on specific branches:

- ✅ **`main` branch** - Production deployment
- ✅ **`develop` branch** - Staging deployment
- ❌ Feature branches - Build and test only (no deployment)

### Deployment Script

The deployment uses an **idempotent** PowerShell script (`scripts/deploy.ps1`) that:

- Stops running containers (preserves PostgreSQL data)
- Pulls latest images from GHCR
- Tags images for docker-compose compatibility
- Starts the application stack
- Verifies all services are running

**Manual deployment:**
```powershell
./scripts/deploy.ps1 -ImageTag "latest" -Owner "kaz5273"
```

### Deployment Requirements

To enable automated deployment, you need:

**1. Self-Hosted Runner**
- Active GitHub Actions runner on your local machine
- Docker installed and running
- PowerShell 5.1+ (Windows) or PowerShell Core (Linux/Mac)

**2. Required Secrets**
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions for GHCR
- `SONAR_TOKEN` - SonarCloud authentication

**3. Registry Access**
- Runner must have access to pull from `ghcr.io`
- Automatic login via GitHub token

### Deployment Safety

The deployment is designed to be **safe and idempotent**:

- ✅ Can be run multiple times without issues
- ✅ **Never deletes database volumes** (`docker compose down` without `--volumes`)
- ✅ Preserves all PostgreSQL data between deployments
- ✅ Graceful container shutdown and restart
- ✅ Automatic health checks and verification

**Important:** The deployment does NOT use destructive options like:
- ❌ `--volumes` (would delete database data)
- ❌ `--rmi` (would delete images)
- ❌ `-v` (would delete volumes)

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- Node.js (for local development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Kaz5273/CloudNativeApplicationCurse.git
   cd CloudNativeApplicationCurse
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file if needed (default values should work for development).

3. **Start the application**
   ```bash
   docker-compose up --build
   ```

4. **Access the application**
   - Frontend: http://localhost:8080
   - Backend API: http://localhost:3000
   - Database: localhost:5432

### Default Login Credentials

The application comes with seeded test data:

**Admin User:**
- Email: admin@gym.com
- Password: admin123
- Role: ADMIN

**Regular Users:**
- Email: john.doe@email.com
- Email: jane.smith@email.com  
- Email: mike.wilson@email.com
- Password: password123 (for all users)

## Project Structure

```
gym-management-system/
├── backend/
│   ├── src/
│   │   ├── controllers/     # Request handlers
│   │   ├── services/        # Business logic
│   │   ├── repositories/    # Data access layer
│   │   ├── routes/          # API routes
│   │   └── prisma/          # Database schema and client
│   ├── seed/                # Database seeding
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── views/           # Vue components/pages
│   │   ├── services/        # API communication
│   │   ├── store/           # Pinia stores
│   │   └── router/          # Vue router
│   ├── Dockerfile
│   └── nginx.conf
└── docker-compose.yml
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Classes
- `GET /api/classes` - Get all classes
- `GET /api/classes/:id` - Get class by ID
- `POST /api/classes` - Create class
- `PUT /api/classes/:id` - Update class
- `DELETE /api/classes/:id` - Delete class

### Bookings
- `GET /api/bookings` - Get all bookings
- `GET /api/bookings/user/:userId` - Get user bookings
- `POST /api/bookings` - Create booking
- `PUT /api/bookings/:id/cancel` - Cancel booking
- `DELETE /api/bookings/:id` - Delete booking

### Subscriptions
- `GET /api/subscriptions` - Get all subscriptions
- `GET /api/subscriptions/user/:userId` - Get user subscription
- `POST /api/subscriptions` - Create subscription
- `PUT /api/subscriptions/:id` - Update subscription

### Dashboard
- `GET /api/dashboard/user/:userId` - Get user dashboard
- `GET /api/dashboard/admin` - Get admin dashboard

## Development

### Local Development Setup

1. **Backend Development**
   ```bash
   cd backend
   npm install
   npm run dev
   ```

2. **Frontend Development**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

3. **Database Setup**
   ```bash
   cd backend
   npx prisma migrate dev
   npm run seed
   ```

### Database Management

- **View Database**: `npx prisma studio`
- **Reset Database**: `npx prisma db reset`
- **Generate Client**: `npx prisma generate`
- **Run Migrations**: `npx prisma migrate deploy`

### Useful Commands

```bash
# Stop all containers
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Rebuild specific service
docker-compose up --build [service-name]

# Access database
docker exec -it gym_db psql -U postgres -d gym_management
```

## Features in Detail

### Subscription System
- **STANDARD**: €30/month, €5 per no-show
- **PREMIUM**: €50/month, €3 per no-show  
- **ETUDIANT**: €20/month, €7 per no-show

### Booking Rules
- Users can only book future classes
- Maximum capacity per class is enforced
- No double-booking at the same time slot
- 2-hour cancellation policy

### Admin Dashboard
- Total users and active subscriptions
- Booking statistics (confirmed, no-show, cancelled)
- Monthly revenue calculations
- User management tools

### User Dashboard
- Personal statistics and activity
- Current subscription details
- Monthly billing with no-show penalties
- Recent booking history

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support or questions, please open an issue in the repository.

