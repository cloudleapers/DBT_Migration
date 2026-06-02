# My dbt Project

## Steps Completed

1. **Project Setup**
   - Created a new dbt project called `my_project`.
   - Configured Snowflake as the target.

2. **Development**
   - Built macros, staging models, marts, and tests.
   - Added one snapshot (`snap_customers`) to track changes in customer data.

3. **Testing**
   - Ran `dbt run` to build models successfully.
   - Ran `dbt test` — all schema and custom tests passed.

4. **Snapshots**
   - Created and executed `snap_customers.sql`.
   - Verified historical tracking with `dbt_valid_from` and `dbt_valid_to`.

5. **Documentation**
   - Added descriptions in YAML files for models and columns.
   - Generated documentation with `dbt docs generate`.
   - Viewed lineage graph in docs site and captured screenshot.

6. **Deliverables**
   - Screenshots of `dbt run`, `dbt test`, lineage graph, and snapshot history.
   - Sample output from `MARTS.FCT_ORDERS`.

7. **Git Workflow**
   - Created branch `dbt_bhargavi`.
   - Added `.gitignore` to exclude compiled files.
   - Committed and pushed final project with docs and screenshots.

---

## How to Reproduce
```bash
dbt run
dbt test
dbt snapshot
dbt docs generate



 
