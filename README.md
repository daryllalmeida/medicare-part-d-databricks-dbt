# Medicare Part D Prescribers — Databricks + dbt Pipeline

A dimensional data pipeline built on Databricks and dbt, using CMS's public **Medicare Part D Prescribers by Provider and Drug** dataset (2024). It takes a 4GB raw CSV plus two CMS summary files, runs them through a bronze → silver → gold medallion architecture, tests every layer, and deploys automatically across three environments via CI/CD.

## What this project answers

- Which prescribers and drugs drive Medicare Part D claims and spend in 2024?
- How much of the official national activity does the public detail file actually capture, and where does it fall short?

That second question turned out to be the more interesting one. CMS suppresses any prescriber-drug combination with fewer than 11 claims, to protect patient privacy. That means the detail file systematically undercounts activity, and the undercount isn't uniform: it hits cost harder than claims, because the suppressed combinations skew toward lower-volume, often higher-cost drugs. A dedicated mart (below) measures and tests this gap directly rather than letting it sit as an unverified footnote.

## Architecture

**Source data:** CMS Medicare Part D Prescribers by Provider and Drug, data year 2024 — a ~4GB detail CSV (28M+ rows, one row per prescriber × brand name × generic name), plus two CMS summary workbooks: national totals by calendar year (2013–2024) and a drug classification list (opioid / antibiotic / antipsychotic / long-acting-opioid flags).

**Bronze — raw, as published**
Loaded via `read_files()` directly in Databricks SQL, no transformation. Three tables: the full detail file, the yearly national totals, and the drug classification flags.

**Silver — cleaned, typed, one source table per model**
Three dbt staging models. Columns renamed to snake_case, text cast to proper types, blank/suppressed values converted to real nulls (not zeros), with explicit `is_*_suppressed` flags so downstream consumers know *why* a value is missing rather than assuming it's zero.

**Gold — dimensional model + marts**
- `dim_drug` — one row per unique brand/generic name, with classification flags. Built from the fact-level data (not the flags table) via a `left join`, so every drug that actually appears in claims is represented, not just the ~474 CMS happened to classify.
- `dim_prescriber` — one row per NPI, with name, location, and specialty.
- `fct_prescriber_drug_year` — the fact table: one row per prescriber × drug × year, keys and measures only. Descriptive attributes live in the dimensions, not repeated across 28M rows.
- `mart_reconciliation_coverage` — compares `fct_prescriber_drug_year` (aggregated to year) against the official CMS national totals, year by year. This is where the coverage gap above is made explicit and testable.

## Data limitations (read this before trusting any number from this project)

The detail file excludes any prescriber-drug combination with fewer than 11 claims. For 2024, this means the detail data captures:

- **86.5%** of official national claims
- **78.6%** of official national drug cost

The gap between those two percentages is the finding worth remembering: low-volume, often expensive, specialty prescriptions are disproportionately excluded. Any claims or cost figure built on `fct_prescriber_drug_year` is a **lower bound**, not a complete picture, and understates cost more than it understates volume.

`mart_reconciliation_coverage` makes this measurable rather than anecdotal, and a dbt test (`assert_2024_coverage_within_expected_range`) fails the build automatically if a future reload drifts outside the expected 80–95% (claims) / 70–90% (cost) bands — turning a one-time manual finding into a standing data-quality check.

## Environments

Three parallel schema sets in the same Databricks catalog (`medicare_part_d`), one dbt project, three targets:

| Target | Schema | Built by | Purpose |
|---|---|---|---|
| `dev` | `dbt_dev_silver` / `dbt_dev_gold` | Local, manual (`dbt build`) | Development sandbox |
| `ci` | `dbt_ci_silver` / `dbt_ci_gold` | GitHub Actions, every push/PR to `main` | Verification — proves the project builds and all tests pass on a machine with no local state |
| `prod` | `dbt_prod_silver` / `dbt_prod_gold` | GitHub Actions, only on push to `main`, only after `ci` passes | The stable layer anything downstream (dashboard, reporting) should read from |

CI and CD are two jobs in one GitHub Actions workflow (`.github/workflows/dbt_ci.yml`). The deploy job declares `needs: dbt-build`, so it only runs after tests pass, and is gated with `if: github.ref == 'refs/heads/main' && github.event_name == 'push'`, so a pull request runs tests but never touches `prod`. Credentials (a Databricks personal access token, scoped to `sql` only) are stored as encrypted GitHub repository secrets, never committed.

## Testing

37 tests across sources, staging, and gold, run on every build in every environment:

- `unique` / `not_null` on every primary and foreign key
- `relationships` tests from `fct_prescriber_drug_year` to both dimensions, catching orphaned keys
- `accepted_values` on the CMS suppression flag codes
- A custom singular test on the reconciliation mart, asserting the coverage percentages stay within a defensible range

## Key design decisions

- **Hash surrogate key for `dim_drug`, natural key for `dim_prescriber`.** A drug is identified by two text columns (brand + generic name) with no stable single value, so `md5(brand_name || generic_name)` gives the fact table one narrow, deterministic join column. A prescriber already has a single stable identifier, the NPI, so adding a synthetic key on top would be redundant.
- **One fact table, two dimensions.** The dataset has exactly one measurable event (a prescriber's claims for a drug in a year) and two independent descriptive entities (drug, prescriber) that don't describe each other. A date dimension wasn't added, since the project deliberately scopes to a single static year.
- **Full-refresh tables, not incremental.** CMS publishes this file once a year and this project isn't tracking multiple years, so incremental logic would add complexity with no real benefit. The full `dbt build` runs in under 90 seconds.
- **Suppressed values are nulls with flags, never zeros.** CMS suppression means "we don't know," not "it didn't happen." Treating a suppressed cell as zero would understate real activity; a null with an explicit `is_*_suppressed` flag preserves that distinction for anyone querying the data.
- **CI and prod build into fully separate schemas from dev**, so local experimentation can never leak into, or be overwritten by, an automated run.

## Stack

Databricks (Unity Catalog, SQL Warehouse, Volumes) · dbt-databricks · GitHub Actions · Python/pandas (file prep)