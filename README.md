# contrast_app

A web application for **searching and comparing news articles across the main Spanish
online newspapers**. It was built as a bachelor's thesis project.

The idea: pick a topic, search it against several newspapers at once, select the
articles that cover the same story from different outlets, and put them side by side —
including an automatic semantic **similarity score** between their texts.

## What it does

- **Search by topic** across multiple Spanish news outlets from a single query.
- **Fetch and normalize** the full content of an article (title, subtitle, author,
  date, body) regardless of the source site's HTML.
- **Compare articles side by side** in the browser, with selectable layouts.
- **Similarity ratio** between two article texts, computed via the
  [Dandelion Text Similarity API](https://dandelion.eu/docs/api/datatxt/sim/v1/).

### Supported newspapers

| Newspaper           | Scraper module          |
| ------------------- | ----------------------- |
| El País             | `ElPaisScraper`         |
| El Mundo            | `ElMundoScraper`        |
| La Voz de Galicia   | `LaVozDeGaliciaScraper` |

Adding a new outlet means implementing the `NewspaperScraper.Core.Scraper`
behaviour and registering it in the config.

## Architecture

```
┌──────────────┐        HTTP/JSON        ┌───────────────────────┐      HTTP scraping     ┌──────────────────┐
│  Frontend    │ ─────────────────────▶  │   Scraper API         │ ─────────────────────▶ │  Newspaper sites │
│  (React SPA) │                         │   (Elixir / Plug)     │                        │  El País, ...    │
│              │ ◀───────────────────────│                       │ ◀───────────────────── │                  │
└──────┬───────┘   articles / summaries  └───────────────────────┘                        └──────────────────┘
       │
       │  JSON/HTTP (text similarity)
       ▼
┌──────────────┐
│ Dandelion API│
└──────────────┘
```

### Backend — `backend/` (Elixir)

An OTP application (`newspaper_scraper`) that exposes a small HTTP API and runs the
scraping pipeline.

- **`boundary/routes`** – `Plug.Router` with the public endpoints.
- **`boundary/validators`** – request validation.
- **`boundary/managers`** – a `GenStage` / `GenServer` pipeline
  (`ScraperManager` → request handlers → parsing handler supervisor) that
  parallelizes fetching and parsing across outlets.
- **`core/scraper`** – the `Scraper` behaviour and one implementation per newspaper,
  plus the shared HTTP client (`Tesla`) and parser (`Floki`).
- **`model`** – `Article`, `ArticleSummary`, `Author`, `AppError` structs.
- **`mocks`** – mock newspaper servers used by the test suite (ports 8081/8082).

#### HTTP API

| Method | Path               | Query params            | Description                               |
| ------ | ------------------ | ----------------------- | ----------------------------------------- |
| `GET`  | `/search_articles` | `topic`, `page`, `limit`| Article summaries matching a topic        |
| `GET`  | `/get_article`     | `url`                   | Full parsed article for a given URL       |

Runs on `http://localhost:8080` in `dev`.

### Frontend — `frontend/` (React + TypeScript + Vite)

- **Redux Toolkit + RTK Query** for state and API calls
  (`services/scraper.ts`, `services/compareArticles.ts`).
- **Chakra UI** for components and theming (light/dark).
- **i18next** for internationalization (Spanish / English, in `src/locales`).
- **redux-persist** to keep the article cart between sessions.
- Feature folders under `src/components`: `searchArticles`, `compareArticles`,
  `articleCart`, `common`.

## Running locally

### Backend

```bash
cd backend
mix deps.get
MIX_ENV=dev mix run --no-halt   # or: iex -S mix
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The frontend reads its configuration from `frontend/.env.<mode>`:

| Variable            | Meaning                                              |
| ------------------- | --------------------------------------------------- |
| `SCRAPER_URL`       | Base URL of the backend Scraper API                 |
| `COMPARE_API_URL`   | Dandelion similarity API endpoint                   |
| `COMPARE_API_TOKEN` | **Your** Dandelion API token (get one at dandelion.eu) |

> `COMPARE_API_TOKEN` is intentionally left empty in the committed `.env` files.
> Supply your own token locally and do **not** commit it.

## Testing

```bash
cd backend  && mix test          # Elixir, with coverage
cd frontend && npm test          # Jest + Testing Library
```

## Documentation

C4 architecture diagrams live in `docs/diagrams/` (PlantUML sources + rendered PNGs).

## License

See [LICENSE](LICENSE).
