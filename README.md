# Cathletics API (Rails)

## Tests (RSpec)

Run the test suite **inside Docker** from this directory (`backend/`), where `compose.yaml` lives. Do not assume `bundle exec rspec` works on the host unless your environment matches the container.

**All specs:**

```bash
docker compose run --rm rails bundle exec rspec
```

**Single file or pattern:**

```bash
docker compose run --rm rails bundle exec rspec spec/models/scheduled_event_spec.rb
docker compose run --rm rails bundle exec rspec spec/requests/api/v1/scheduled_events_spec.rb
```

**With options:**

```bash
docker compose run --rm rails bundle exec rspec --format documentation
```

The `rails` service has the app code, Ruby gems, and `DATABASE_URL` pointed at the Compose Postgres service, so database-backed specs run correctly.

## Local development

See `compose.yaml` for services (`rails`, `db`, `redis`, etc.). Typical app server:

```bash
docker compose up rails
```

---

*Legacy placeholder sections (Ruby version, dependencies, deployment) can be filled in as the project matures.*
