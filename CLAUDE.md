# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Brickwell Health LakehousePlumber (LHP)** project that uses declarative YAML configurations to generate Databricks Lakeflow Declarative Pipelines (formerly DLT) Python code. The project manages data pipelines using a template-based approach with environment-specific configurations.

**Key Dependencies:**
- `lakehouse-plumber>=0.7.4` - Pipeline code generation framework
- `databricks-connect>=18.0.1` - Databricks connectivity
- Python 3.12+
- Package manager: `uv` (see `uv.lock`)

## Common Commands

### LHP Pipeline Development

```bash
# Validate pipeline configurations for an environment
lhp validate --env dev

# Generate DLT Python code from YAML configurations
lhp generate --env dev

# Show resolved configuration for a flowgroup
lhp show <flowgroup>

# List available templates and presets
lhp list-templates
lhp list-presets
```

### Databricks Asset Bundle Deployment

```bash
# Validate the bundle for a target environment
databricks bundle validate --target dev

# Deploy the bundle to a target environment
databricks bundle deploy --target dev

# Run a specific pipeline after deployment
databricks bundle run <resource_name> --target dev
```

**Important:** The environment name in `substitutions/<env>.yaml` MUST match the target name in `databricks.yml`. For example, `substitutions/dev.yaml` corresponds to `databricks.yml` target `dev`.

## Project Architecture

### Directory Structure

- **`pipelines/`** - Pipeline YAML configurations organized by layer
  - `02_bronze/` - Bronze layer (raw ingestion) pipelines
  - Additional layers can be added (e.g., `03_silver/`, `04_gold/`)

- **`templates/`** - Reusable action templates for common patterns
  - `TMPL001_delta_scd2.yaml` - SCD Type 2 pattern for change tracking
  - Templates use Jinja2-style `{{ parameter }}` substitution

- **`presets/`** - Reusable configuration defaults
  - `bronze_layer.yaml.tmpl` - Standard bronze layer settings

- **`substitutions/`** - Environment-specific token/secret configurations
  - `dev.yaml` - Development environment variables (catalog, schema, paths)
  - `tst.yaml` - Test environment variables
  - `prd.yaml` - Production environment variables
  - **Critical:** File names must match `databricks.yml` target names

- **`generated/`** - LHP-generated DLT Python code (not committed to git)
  - `generated/<env>/<pipeline>/` - Environment-specific generated code
  - These files are automatically created by `lhp generate`

- **`resources/`** - Databricks Asset Bundle resource definitions
  - `resources/lhp/` - LHP-generated bundle resources for pipelines
  - User-managed resources can be added directly to `resources/`

- **`expectations/`** - Data quality expectation definitions
- **`schemas/`** - Schema definitions for data validation
- **`schema_transforms/`** - Schema transformation logic
- **`sql/`** - SQL scripts and utilities

### Configuration Files

- **`lhp.yaml`** - LHP project configuration
  - Project metadata (name, version, author)
  - Required LHP version constraints
  - Operational metadata columns (e.g., `_processing_timestamp`, `_source_file_path`)

- **`databricks.yml`** - Databricks Asset Bundle configuration
  - Multi-environment deployment targets (dev, tst, prd)
  - Bundle-level variables (e.g., `default_pipeline_catalog`, `default_pipeline_schema`)
  - Workspace configurations and permissions
  - Service principal run-as configurations for CI/CD

### Code Generation Flow

1. **Define Pipeline YAML** in `pipelines/<layer>/<domain>_<table>_TMPL<number>.yaml`
2. **Reference Template** using `use_template: TMPL<number>_<name>`
3. **Provide Parameters** under `template_parameters:`
4. **Validate** with `lhp validate --env <env>`
5. **Generate** Python code with `lhp generate --env <env>`
6. **Deploy** using `databricks bundle deploy --target <env>`

Generated Python code appears in `generated/<env>/<pipeline>/` and uses Databricks Lakeflow Declarative Pipelines API (`pyspark.pipelines`).

## Naming Conventions

**Templates:** `TMPL<number>_<source_type>_<function>.yaml`
- Examples: `TMPL001_delta_scd2.yaml`, `TMPL002_cloudfiles_bronze.yaml`

**Flowgroups using templates:** `<domain>_<final_table>_TMPL<number>.yaml`
- Examples: `billing_invoice_TMPL001.yaml`, `orders_customer_TMPL002.yaml`
- The TMPL number in the filename indicates which template is being used
- Always place in the appropriate layer directory (e.g., `pipelines/02_bronze/`)

**Pipeline naming:** `<domain>_<layer>` (e.g., `billing_bronze`, `orders_silver`)

**Environment files:** Must match databricks.yml target names exactly (e.g., `substitutions/dev.yaml` ↔ `databricks.yml` target `dev`)

## Deployment Targets

Defined in `databricks.yml`:

- **`dev`** (default) - CI/CD development workspace (Azure)
  - Catalog: `brickwell_health`
  - Schema: `edw_bronze`
  - Mode: production (for CI/CD)

- **`dev-userpyte`** - Individual developer workspace (free tier)
  - Mode: development
  - For local testing before pushing

- **`dev-free`** - Dev with service principal authentication
- **`tst`** - Test environment with service principal
- **`prd`** - Production environment with service principal

**Service Principal Pattern:** TST and PRD environments use service principals for CI/CD automation with `run_as` and `permissions` configurations.

## Template System

The project uses a template-based approach for consistency:

### TMPL001: Delta SCD Type 2

**Purpose:** Tracks historical changes to records using SCD Type 2 pattern

**Use Cases:**
- Processing CDC (Change Data Capture) streams from databases
- Maintaining version history of business entities
- Tracking dimension table changes over time

**Pipeline Flow:**
1. **Load** - Streams from source Delta table
2. **Transform** - Excludes CDC metadata, creates sequence timestamp using `COALESCE(modified_at, created_at)`
3. **Write** - Writes to streaming table with SCD Type 2 configuration

**Key Parameters:**
- `source_table` - Fully qualified source table (e.g., `catalog.schema.table`)
- `target_table` - Target table name (no catalog/schema prefix)
- `natural_keys` - Business identifier column(s) - supports single or composite keys
- `modified_at_column` - Modification timestamp column
- `created_at_column` - Creation timestamp column (fallback)
- `exclude_columns` - Columns to exclude (defaults include PostgreSQL WAL metadata like `__START_AT`, `__END_AT`)

**Supports multiple natural keys** for composite keys (e.g., `[order_id, product_id]`)

## Medallion Architecture

The project follows the medallion architecture pattern:

- **Bronze Layer** (`pipelines/02_bronze/`) - Raw data ingestion with minimal transformation
  - Includes operational metadata: `_processing_timestamp`, `_source_file_path`, `_source_file_name`
  - Uses Change Data Feed (`delta.enableChangeDataFeed: true`)
  - Auto-optimize enabled for write performance

- **Silver Layer** - Cleaned, conformed, and business-logic-enriched data (to be added)

- **Gold Layer** - Aggregated, business-level views and analytics (to be added)

## Operational Metadata

Configured in `lhp.yaml`, operational metadata columns are automatically added to tables:

- `_processing_timestamp` - When the record was processed (applies to all table types)
- `_source_file_path` - Source file path from metadata (views only)
- `_source_file_name` - Source file name (views only)

These columns help with data lineage, debugging, and auditing.

## Working with LHP

### Creating a New Pipeline

1. Create flowgroup YAML in appropriate layer directory:
   ```bash
   touch pipelines/02_bronze/<domain>_<table>_TMPL001.yaml
   ```

2. Reference template and provide parameters:
   ```yaml
   pipeline: <domain>_bronze
   flowgroup: <domain>_<table>_TMPL001

   use_template: TMPL001_delta_scd2

   template_parameters:
     source_table: "catalog.schema.source_table"
     target_table: "target_table_name"
     natural_keys:
       - business_key_column
     modified_at_column: "modified_at"
     created_at_column: "created_at"
   ```

3. Validate and generate:
   ```bash
   lhp validate --env dev
   lhp generate --env dev
   ```

4. Review generated Python in `generated/dev/<pipeline>/`

### Creating a New Template

1. Create template file in `templates/TMPL<number>_<pattern>.yaml`
2. Define parameters with types and defaults
3. Define actions using `{{ parameter }}` substitution
4. Document in `templates/README.md`

See `.claude/skills/lhp/references/templates-presets.md` for detailed guidance.

## Environment Configuration

When adding new environments:

1. Create substitution file: `substitutions/<env>.yaml`
2. Add target to `databricks.yml` with matching name
3. Define catalog, schema, and path variables
4. Configure service principal if needed (for CI/CD)
5. Set appropriate permissions and run-as settings

## Development Workflow

1. **Local Development:**
   - Edit YAML configurations in `pipelines/`
   - Validate with `lhp validate --env dev`
   - Generate with `lhp generate --env dev`
   - Review generated Python code

2. **Testing:**
   - Deploy to dev workspace: `databricks bundle deploy --target dev`
   - Verify pipeline execution
   - Check data quality and expectations

3. **Promotion:**
   - Deploy to tst: `databricks bundle deploy --target tst`
   - Validate in test environment
   - Deploy to prd: `databricks bundle deploy --target prd`

## Important Notes

- **Never edit generated Python files directly** - they will be overwritten. Always modify YAML configurations.
- **Substitution files must match target names** - `substitutions/dev.yaml` corresponds to `databricks.yml` target `dev`
- **LHP state tracking** - `.lhp_state.json` tracks generation state (gitignored)
- **Generated code location** - Always under `generated/<env>/<pipeline>/` directory
- **Resource management** - LHP automatically generates bundle resources in `resources/lhp/`
- **Service principals** - TST and PRD use service principals for CI/CD; ensure proper workspace configuration

## LHP Skill

Use the `/lhp` skill (Claude Code skill) for help with:
- LHP project initialization and configuration
- Writing and editing pipeline YAML flowgroups
- Configuring load/transform/write/test actions
- Creating or modifying templates and presets
- Databricks Asset Bundle integration
- Dependency analysis and orchestration
- Troubleshooting LHP validation or generation errors
