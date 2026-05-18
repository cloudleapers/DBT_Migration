# Healthcare dbt + Snowflake Training Pack

> **A complete, production-style data platform training program covering ELT, dbt modeling, star schema design, testing, and analytics — built around a healthcare claims migration scenario.**

---

## What's Inside

A 5-week training program for engineers learning **dbt + Snowflake + multi-source ELT**. By Day 25, every team member can independently extend the warehouse with new sources, models, and tests.

### What you'll build
- **Multi-source pipeline** — PostgreSQL clinical EHR + MySQL claims billing → Snowflake warehouse
- **48 dbt models** across staging, intermediate, and mart layers
- **Star schema marts** — 7 dimensions + 3 fact tables
- **80+ automated tests** for data quality
- **Auto-generated documentation** with full lineage

### What you'll learn
- Why ELT beats ETL for cloud warehouses
- How to design layered dbt projects (staging → intermediate → marts)
- Star schema modeling for analytical workloads
- Cross-source joins and bridge models
- Test-driven data engineering
- Production-style file organization and naming conventions

---

## Quick Start (15 minutes)

Already familiar with dbt? Skip to the [training plan](docs/04_TRAINING_PLAN_DAY_1_TO_25.md).

For everyone else:

```powershell
# 1. Clone the repo
git clone <your-repo-url>
cd healthcare_dbt

# 2. Install Python dependencies
python -m venv dbt_env
dbt_env\Scripts\activate
pip install -r requirements.txt

# 3. Provision Snowflake (one-shot SQL)
#    Open Snowflake worksheet, run: sql/snowflake/00_setup.sql

# 4. Load source data into Postgres + MySQL
#    Open Supabase SQL editor, run: sql/postgres/01_lookups.sql through 04_views.sql
#    Open Aiven SQL editor, run: sql/mysql/01_reference_tables.sql through 03_views.sql

# 5. Configure dbt
#    Edit ~/.dbt/profiles.yml with your Snowflake credentials
dbt deps
dbt debug

# 6. Load sources into Snowflake RAW
python scripts/load_sources.py

# 7. Build the warehouse
dbt run

# 8. Test everything
dbt test

# 9. Browse the docs
dbt docs generate
dbt docs serve
```

Open http://localhost:8080 to see the lineage graph.

---

## Documentation Map

Read in this order. Each doc takes 30-60 minutes.

| # | Document | Purpose |
|---|---|---|
| 1 | [`docs/01_ARCHITECTURE.md`](docs/01_ARCHITECTURE.md) | System design — what each component does and why |
| 2 | [`docs/02_PROJECT_WALKTHROUGH.md`](docs/02_PROJECT_WALKTHROUGH.md) | Guided 10-stop tour through the codebase with checkpoints |
| 3 | [`docs/03_DATA_LINEAGE.md`](docs/03_DATA_LINEAGE.md) | Every model documented with upstream/downstream dependencies |
| 4 | [`docs/04_TRAINING_PLAN_DAY_1_TO_25.md`](docs/04_TRAINING_PLAN_DAY_1_TO_25.md) | Day-by-day assignments, quizzes, capstone project |
| 5 | [`docs/05_EXECUTION_LOG_AND_TROUBLESHOOTING.md`](docs/05_EXECUTION_LOG_AND_TROUBLESHOOTING.md) | Every bug we hit during build with exact fixes — search by error message |

### Visual diagrams
- `diagrams/01_architecture.svg` — end-to-end system view
- `diagrams/02_data_lineage.svg` — model dependency graph

---

## Folder Structure

```
healthcare_dbt_training_pack/
├── README.md                          ← you are here
│
├── docs/                              ← All documentation
│   ├── 01_ARCHITECTURE.md
│   ├── 02_PROJECT_WALKTHROUGH.md
│   ├── 03_DATA_LINEAGE.md
│   ├── 04_TRAINING_PLAN_DAY_1_TO_25.md
│   └── 05_EXECUTION_LOG_AND_TROUBLESHOOTING.md
│
├── diagrams/                          ← System diagrams
│   ├── 01_architecture.svg
│   └── 02_data_lineage.svg
│
├── sql/                               ← All SQL scripts, organized by database
│   ├── snowflake/
│   │   └── 00_setup.sql               ← Run first: provision Snowflake
│   ├── postgres/                      ← Run in order: load Supabase
│   │   ├── 01_lookups.sql
│   │   ├── 02_master_tables.sql
│   │   ├── 03_transactional_data.sql
│   │   └── 04_views.sql
│   ├── mysql/                         ← Run in order: load Aiven
│   │   ├── 01_reference_tables.sql
│   │   ├── 02_transactional_tables.sql
│   │   └── 03_views.sql
│   └── analytics/
│       └── 06_daily_scenario_queries.sql  ← Week 5 exercises
│
└── (your dbt project goes here)       ← The actual dbt models live in your repo
    healthcare_dbt/
    ├── dbt_project.yml
    ├── packages.yml
    ├── profiles.yml (in ~/.dbt/, NOT in project)
    ├── macros/
    ├── models/
    │   ├── staging/{postgres,mysql}/
    │   ├── intermediate/
    │   └── marts/{clinical,financial}/
    └── scripts/
```

---

## Prerequisites

### Tools
- Windows 10/11 (Mac and Linux work too with minor command adjustments)
- Python 3.11 or higher
- VS Code with extensions: **dbt Power User**, Python, SQLTools (with PostgreSQL, MySQL, Snowflake drivers)
- Git
- A web browser for Snowflake / Supabase / Aiven web consoles

### Cloud accounts (all free trials)
- **Snowflake** — sign up at https://signup.snowflake.com (30 days, $400 credits)
- **Supabase** — sign up at https://supabase.com (forever-free tier sufficient)
- **Aiven** — sign up at https://aiven.io (30-day MySQL trial)

### Time commitment
- **3-4 hours/day** for 5 weeks
- Daily structure: read → build → verify → exercise

---

## Daily Operating Cycle

Once everything is set up, your daily workflow is:

```powershell
# Morning - refresh data
python scripts/load_sources.py

# Develop - iterate on models
dbt run --select <changed_model>+
dbt test --select <changed_model>

# Before commit - full pipeline
dbt build

# Update docs
dbt docs generate

# Commit and push
git add models/
git commit -m "feat: add provider performance dim"
git push
```

---

## Getting Help

### Step 1 — Search the troubleshooting doc
Most issues you'll hit are documented in [`05_EXECUTION_LOG_AND_TROUBLESHOOTING.md`](docs/05_EXECUTION_LOG_AND_TROUBLESHOOTING.md). Search by error message keyword (Ctrl+F).

### Step 2 — Check what dbt actually ran
```powershell
type target\run\healthcare_dbt\models\<layer>\<model_name>.sql
```
This is the EXACT SQL Snowflake received. Often the bug is visible here.

### Step 3 — Reproduce in Snowflake worksheet
Copy the SQL from step 2, paste into Snowflake worksheet, run directly. The error message there is usually clearer than dbt's wrapper.

### Step 4 — Ask the team
- Slack #data-platform channel
- Tag @data-eng-on-call for urgent blockers
- Include: full error message, what you tried, link to the failing model

---

## Project Stats

| Metric | Value |
|---|---|
| Source databases | 2 (PostgreSQL + MySQL) |
| Source tables | 30 |
| Source views | 25 |
| Total source rows | ~311,000 |
| dbt models | 48 |
| dbt tests | 80+ |
| Lines of SQL | ~10,000 |
| Lines of Python | ~500 |
| Documentation | ~80 pages |
| Training duration | 5 weeks (25 days) |

---

## Capstone Project (Day 25)

Choose ONE to demonstrate end-to-end mastery:

### Option A — Add a third source system
Build a pharmacy claims source. Adds new staging, intermediate, and mart models. Tests cross-source data quality.

### Option B — Implement SCD Type 2
Use dbt snapshots to track historical changes. Adds time-travel capability to the warehouse.

### Option C — Build a reporting layer
Pre-aggregated cubes for BI tools. Demonstrates incremental materialization patterns.

Full requirements in [`04_TRAINING_PLAN_DAY_1_TO_25.md`](docs/04_TRAINING_PLAN_DAY_1_TO_25.md) → Day 25.

---

## What You'll Walk Away Knowing

After 25 days, you'll be able to:

- ☐ Architect a multi-source dbt + Snowflake pipeline
- ☐ Build, test, and document dbt models across 3 layers
- ☐ Design star schema marts with proper dim/fact separation
- ☐ Use Jinja templating and dbt macros effectively
- ☐ Debug compilation, test, and runtime failures
- ☐ Read lineage graphs and trace any column to its source
- ☐ Write production-quality SQL with phase comments and clear structure
- ☐ Extend the warehouse without breaking existing tests

---

## License & Attribution

This training pack is for internal team use. Synthetic data is generated procedurally; no real PHI is involved.

Built with:
- [dbt-core](https://github.com/dbt-labs/dbt-core) (Apache 2.0)
- [Snowflake](https://www.snowflake.com/)
- [Supabase](https://supabase.com/) (Postgres)
- [Aiven](https://aiven.io/) (MySQL)
- [pandas](https://pandas.pydata.org/), [SQLAlchemy](https://www.sqlalchemy.org/)

---

## Feedback

Found a bug in this training pack? An unclear instruction? A better explanation?

Open a PR with your improvement. Each correction makes onboarding faster for the next person.

---

**Ready to start?** Open [`docs/01_ARCHITECTURE.md`](docs/01_ARCHITECTURE.md) for the architectural overview, then jump into [`docs/04_TRAINING_PLAN_DAY_1_TO_25.md`](docs/04_TRAINING_PLAN_DAY_1_TO_25.md) Day 1.
