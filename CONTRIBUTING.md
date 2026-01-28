# Contributing to aria_planner

AI planner for complex decision-making using HTN (Hierarchical Task Network) planning.

## Features

- HTN planning with lazy refinement
- Temporal constraints with ISO 8601 format
- Entity requirements and capabilities
- Multi-goal planning
- Command execution with side effects

## Prerequisites

- **mise** (tool version manager) - Install with: `curl https://mise.run | sh`
- **PostgreSQL 16** - Managed via mise or installed separately

## Setup

### 1. Install mise (if not already installed)

```bash
curl https://mise.run | sh
# Or run: ./misc/scripts/mise-install.sh
```

### 2. Install tools and start PostgreSQL

```bash
# Install Erlang, Elixir, and PostgreSQL via mise
mise install

# Start PostgreSQL (managed by mise)
mise run postgres --version  # Verify installation
# Or start PostgreSQL service manually if not using mise
```

### 3. Configure database

For local development, the default configuration uses:
- Database: `aria_planner_dev` (dev) or `aria_planner_test` (test)
- User: `postgres`
- Password: `postgres`
- Host: `localhost`
- Port: `5432`

These can be overridden via environment variables or `.env` file.

### 4. Install dependencies and setup database

```bash
# Install Elixir dependencies
mix deps.get

# Create and migrate databases
mix ecto.create          # Creates dev database
MIX_ENV=test mix ecto.create  # Creates test database
mix ecto.migrate         # Migrates dev database
MIX_ENV=test mix ecto.migrate  # Migrates test database
```

### 5. Run tests

```bash
mix test
```

## Installation (as a dependency)

Add `aria_planner` to your dependencies:

```elixir
def deps do
  [
    {:aria_planner, git: "https://github.com/V-Sekai-fire/aria-planner.git"}
  ]
end
```

## Usage

See the main documentation for detailed usage examples and API reference.

## Development

### Database Management

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback

# Reset database (drop, create, migrate)
mix ecto.reset

# Generate new migration
mix ecto.gen.migration migration_name
```

### Environment Variables

For production or custom configurations, set these environment variables:

- `DB_USERNAME` - PostgreSQL username (default: postgres)
- `DB_PASSWORD` - PostgreSQL password (default: postgres)
- `DB_HOSTNAME` - PostgreSQL host (default: localhost)
- `DB_PORT` - PostgreSQL port (default: 5432)
- `DB_NAME` - Database name (default: aria_planner_dev or aria_planner_test)
- `DB_POOL_SIZE` - Connection pool size (default: 10)
- `DB_SSL` - Enable SSL (default: false)

Or use a `.env` file (see `.env.example`).

## License

MIT
