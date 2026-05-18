# Welcome — Healthcare dbt + Snowflake Training

This is your bundle. Everything you need for the 25-day program is here.

## Read in this order

1. **`docs/01_ARCHITECTURE.md`** — Understand the system you're building
2. **`docs/04_TRAINING_PLAN_DAY_1_TO_25.md`** — Your daily curriculum
3. **`docs/02_PROJECT_WALKTHROUGH.md`** — Guided tour of the codebase
4. **`docs/03_DATA_LINEAGE.md`** — How data flows through models
5. **`docs/07_TRAINEE_ASSIGNMENT_SPECS.md`** — Your homework book — what to build each day
6. **`docs/05_EXECUTION_LOG_AND_TROUBLESHOOTING.md`** — Hit a bug? Search this first.

## What you DON'T have

The reference solutions for dbt models live with your trainer. You'll see them after you submit your work for review.

That's intentional. The point is to build it yourself, not copy.

## SQL scripts

`sql/` contains the source database setup scripts. These ARE meant to be copy-pasted (they create the source data; they're not the homework).

## Submission format

When you finish a model:
1. Submit your `.sql` file
2. Paste the output of `dbt run --select <your_model>`
3. Paste the output of the verification query from the assignment spec

Trainer will compare against reference and provide feedback.

Good luck! 🚀
