# Olist Seller Analytics

An end-to-end analytics project built on the [Olist Brazilian e-commerce
dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(2016–2018). It answers one core business question:

> **Which sellers on the Olist marketplace are at risk of churning, and
> what can Olist do to retain them?**

The project is split into two halves:

1. **A data pipeline** (Kaggle → Azure SQL → dbt) that cleans and reshapes
   the raw data into a well-structured, tested set of tables.
2. **A Power BI report** (`olist.pbix`) built on top of those tables,
   containing the actual charts, visuals, and business recommendations.

This README explains what's in the repo and how to run it — written for
someone comfortable with data analysis (Power BI, SQL, Excel) but with
**little or no programming background**.

---

## What you get out of this repo

- **If you just want to see the analysis:** open `olist.pbix` in Power BI
  Desktop. It's fully self-contained — no setup, no code, no Azure account
  needed. 
- **If you want to understand or rebuild the data pipeline:** read on. The
  rest of this document walks through how raw data becomes the tables that
  `olist.pbix` is built on.

---

## The big picture

```
Kaggle (raw CSVs)
     |
     v
Azure SQL  (cloud database — raw tables land here, unchanged)
     |
     v
    dbt    (SQL transformation tool — cleans, joins, and reshapes the data
     |       into a small set of well-named, well-tested tables)
     v
Power BI   (olist.pbix — charts, filters, and business narrative)
```

Two tools do the heavy lifting, and both are explained below because
they're not common outside data engineering:

- **Azure SQL** is Microsoft's cloud-hosted version of SQL Server — a
  database that lives on the internet instead of your own laptop. Think of
  it as "a SQL Server database, but Microsoft runs the computer it's on."
- **dbt** ("data build tool") is not a database and not a programming
  language — it's a tool that takes a folder of `.sql` files (each one
  just a `SELECT` statement) and runs them against a database *in the
  right order*, so that a table which depends on another table always
  gets rebuilt after the table it depends on. It also runs automated
  checks ("tests") on the data, e.g. "this column should never be blank"
  or "this ID should never repeat."

---

## Repo layout

```
olist_project/
├── olist.pbix                  Power BI report — open this to see the analysis
├── ingest.py                   Downloads the Kaggle dataset, uploads it to Azure SQL
├── check_connection.py         Confirms Azure SQL is awake and reachable before running dbt
├── olist_proj_dbt/             The dbt project — SQL transformations live here
│   └── models/
│       ├── staging/            One model per raw table: light cleaning only
│       ├── intermediate/       Small reusable building blocks (e.g. "latest review per order")
│       └── marts/               Final tables — this is what Power BI reads
├── notebooks/
│   ├── eda.ipynb                Exploratory analysis notebook (Python + Polars) —
│   │                            the original, hand-written version of the logic
│   │                            that now also lives in olist_proj_dbt/
│   └── power_bi_exports/        CSV files exported from the notebook — this is what
│                                olist.pbix actually reads (see note below)
├── schema.png                   Diagram of how the raw Kaggle tables relate to each other
├── PBI Data Model.png           Diagram of the final star-schema model used in Power BI
└── .github/workflows/           Automated checks that run on GitHub when code changes
```

### A note on `olist.pbix` and Azure

The dbt models in `olist_proj_dbt/` have been verified to work — Power BI
*can* connect directly to the Azure SQL tables dbt produces. However, the
`.pbix` file in this repo is built against the CSV files in
`notebooks/power_bi_exports/` instead, on purpose: anyone who opens this
file won't have the author's Azure login, so a report wired to live Azure
data would simply be broken for them. The CSVs make the report
self-contained and shareable.

---

## Option 1: Just view the report (no setup required)

1. Install [Power BI Desktop](https://www.microsoft.com/en-us/power-platform/products/power-bi/desktop) (Windows only; Mac users need a Windows VM or Power BI Service).
2. Open `olist.pbix`.

That's it — the data is bundled in via the CSV exports, so there's nothing
else to configure.

---

## Option 2: Run the full pipeline yourself

This is for anyone who wants to regenerate the data from scratch, or
understand how the tables in Power BI are actually built. It requires a
few tools to be installed first.

### What you'll need installed

| Tool | What it is | Why you need it |
|---|---|---|
| [Python](https://www.python.org/) 3.13+ | The programming language the scripts are written in | Runs `ingest.py` and `check_connection.py` |
| [uv](https://docs.astral.sh/uv/) | A Python project/package manager | See explanation below |
| An Azure account with an Azure SQL database | Cloud database | Where the raw and transformed data lives |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`) | Command-line tool for logging into Azure | Lets Python/dbt authenticate without a password |
| ODBC Driver 18 for SQL Server | A driver that lets Python talk to SQL Server-type databases | Required by both the ingest script and dbt |
| [dbt](https://www.getdbt.com/) | Installed automatically by `uv` — no separate install needed | Runs the SQL transformations |

**What is `uv`, exactly?** If you're not a programmer, the easiest mental
model: this project depends on a specific list of other people's code
("packages" — e.g. the library that talks to Azure, the library that
reads CSVs). Those dependencies are listed in a file called
`pyproject.toml`, with exact versions pinned in `uv.lock`. `uv` reads
those two files and installs *exactly* the right versions into a private,
project-local folder (`.venv`) — so it doesn't matter what Python
packages you do or don't already have on your computer; running anything
with `uv run ...` guarantees it uses the correct, tested versions. You
never edit `pyproject.toml`/`uv.lock` by hand for this — you just prefix
commands with `uv run` and it handles the rest.

### Step 1 — Set up Azure access

1. Create an Azure SQL database (any tier — the free/serverless tier works
   fine for this project's data volume).
2. Log in from your terminal:
   ```
   az login
   ```
   This opens a browser window to sign in. Once done, your terminal stays
   "logged in" for a while, and Python scripts in this project pick up
   that login automatically — no password is stored anywhere in the repo.
3. Copy `.env.example` to a new file named `.env`, and fill in your
   database's server name and database name:
   ```
   AZURE_SQL_SERVER=your-server-name
   AZURE_SQL_DATABASE=your-database-name
   ```
   `.env` is intentionally excluded from git (see `.gitignore`) — it's
   specific to your own Azure setup and should never be committed.

### Step 2 — Install project dependencies

From the repo root:
```
uv sync
```
This reads `pyproject.toml`/`uv.lock` and installs everything needed
(pandas, polars, the Azure SDK, dbt, etc.) into a local `.venv` folder.
You only need to run this once, and again any time the dependency list
changes.

### Step 3 — Load the raw data into Azure SQL

```
uv run python ingest.py
```
This downloads the Kaggle dataset and uploads each CSV as a raw table
into your Azure SQL database. It's safe to re-run — it checks whether the
data is already loaded and skips the download/upload if so.

### Step 4 — Confirm the database is awake and ready

```
uv run python check_connection.py
```
Azure SQL's free/serverless tier "falls asleep" after a period of
inactivity and can take 30–60 seconds to wake back up. This script waits
and retries until the database responds, so the next step doesn't fail
due to a slow cold start. **Run this before every dbt command** if you
haven't used the database in a while.

### Step 5 — Run the dbt transformations

All dbt commands are run from inside the `olist_proj_dbt/` folder. `uv`
automatically finds the project's dependency files one level up (at the
repo root), so no extra flags are needed:

```
cd olist_proj_dbt
uv run dbt run
```

This builds every table, in the correct dependency order, in your Azure
SQL database. To also run the data-quality checks:

```
uv run dbt test
```

Or do both in one step:

```
uv run dbt build
```

### Step 6 — Point Power BI at the tables (optional)

If you want to connect Power BI directly to the Azure SQL tables (instead
of using the pre-built `olist.pbix`, which reads from CSVs): in Power BI
Desktop's "Get Data" dialog, choose **Azure SQL Database**, enter your
server/database name, and for **Authentication kind** choose
**Organizational account** (this is Power BI's label for Microsoft Entra
ID / Azure AD login — the same kind of login `az login` sets up).

---

## The three-layer dbt structure

Inside `olist_proj_dbt/models/`, tables are organized into three layers,
each one built on top of the last:

- **`staging/`** — one model per raw Kaggle table. Light cleaning only
  (e.g. fixing data types, dropping a clearly broken column). Still
  roughly "the raw data," just tidied up.
- **`intermediate/`** — small, reusable building blocks that don't belong
  in the final report on their own, e.g. "the single most recent review
  score per order" (an order can have multiple reviews; this picks one).
- **`marts/`** — the final tables. This is what Power BI actually reads.
  Organized as a **star schema**: one central table of transactions
  (`fact_sales`) surrounded by descriptive tables (`dim_seller`,
  `dim_product`, `dim_customer`, etc.) that each answer "who/what/when"
  for a row in the fact table. See `PBI Data Model.png` for the full
  diagram.

Every model has automated tests attached (defined in the `.yml` files
next to the `.sql` files in each folder) — things like "this column must
never be empty" or "this ID must be unique." Run `dbt test` to check all
of them at once.

---

## Automated checks (CI)

This repo has one automated check, defined in
`.github/workflows/dbt-parse.yml`, which runs automatically whenever a
pull request is opened against the `main` branch.

**What it checks:** that every dbt model file is structurally valid — no
typos in table references, no broken SQL templating, no malformed
`.yml` files. It does this *without* connecting to the real Azure
database (that would require storing real credentials in GitHub, which
this project deliberately avoids).

---

## Other files in this repo
- **`schema.png`** — how the *raw* Kaggle tables relate to each other
  (foreign keys, etc.), before any cleaning.
- **`PBI Data Model.png`** — the final star-schema model, as it appears
  in Power BI.
