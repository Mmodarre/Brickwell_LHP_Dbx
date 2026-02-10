# LHP Templates

This directory contains reusable LHP templates for common data pipeline patterns.

## Naming Conventions

**Templates:** `TMPL<number>_<source_type>_<function>.yaml`

- Example: `TMPL001_delta_scd2.yaml`, `TMPL002_cloudfiles_bronze.yaml`

**Flowgroups using templates:** `<domain>_<final_table>_TMPL<number>`
- Example: `billing_invoice_TMPL001`, `orders_customer_TMPL002`
- The TMPL number must match the template being used

## Available Templates

### TMPL001_delta_scd2.yaml

**Purpose:** Implements SCD Type 2 (Slowly Changing Dimension Type 2) pattern for tracking historical changes to records.

**Use Cases:**
- Tracking historical changes to dimension tables
- Maintaining version history of business entities
- Processing CDC (Change Data Capture) streams from databases like PostgreSQL

**How it Works:**
1. **Load**: Streams data from a source Delta table
2. **Transform**:
   - Excludes CDC metadata columns (e.g., `__START_AT`, `__END_AT` from PostgreSQL WAL)
   - Excludes audit columns (e.g., `created_by`, `modified_by`)
   - Creates a sequence timestamp using `COALESCE(modified_at, created_at)` for SCD2 ordering
3. **Write**: Writes to streaming table with SCD Type 2 configuration

**Required Parameters:**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `source_table` | string | Fully qualified source table name | `"catalog.schema.invoice"` |
| `target_table` | string | Target table name (no catalog/schema) | `"invoice"` |
| `natural_keys` | array | Business identifier columns | `["invoice_number"]` or `["customer_id", "order_id"]` |
| `modified_at_column` | string | Modification timestamp column name | `"modified_at"` or `"updated_at"` |
| `created_at_column` | string | Creation timestamp column name (fallback) | `"created_at"` |

**Optional Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `exclude_columns` | array | `["__START_AT", "__END_AT", "created_at", "modified_at", "created_by", "modified_by"]` | Columns to exclude from output |
| `sequence_timestamp_name` | string | `"_sequence_timestamp"` | Name for generated sequence column |

**Example Usage:**

```yaml
pipeline: billing_bronze
flowgroup: billing_invoice_TMPL001

use_template: TMPL001_delta_scd2

template_parameters:
  source_table: "brickwell_health.billing_ingestion_schema.invoice"
  target_table: "invoice"
  natural_keys:
    - invoice_number
  modified_at_column: "modified_at"
  created_at_column: "created_at"
  exclude_columns:
    - "__START_AT"
    - "__END_AT"
    - "created_at"
    - "modified_at"
    - "created_by"
    - "modified_by"
```

**Multiple Natural Keys Example:**

For composite keys (e.g., a junction table):

```yaml
template_parameters:
  source_table: "catalog.schema.order_items"
  target_table: "order_items"
  natural_keys:
    - order_id
    - product_id
  modified_at_column: "updated_at"
  created_at_column: "created_at"
```

**Benefits:**
- ✅ Consistent SCD2 implementation across all tables
- ✅ Reduces boilerplate YAML configuration
- ✅ Makes it easy to onboard new CDC sources
- ✅ Handles PostgreSQL WAL metadata automatically
- ✅ Supports both single and composite natural keys

## Using Templates

To use a template in your flowgroup YAML:

1. Reference the template with `use_template: <template_name>`
2. Provide required parameters under `template_parameters:`
3. Run validation: `lhp validate --env dev`
4. Generate Python: `lhp generate --env dev`

## Creating New Templates

See the [LHP templates-presets reference](../.claude/skills/lhp/references/templates-presets.md) for detailed guidance on creating templates.

**Template Structure:**
```yaml
name: template_name
version: "1.0"
description: "What this template does"

parameters:
  - name: param_name
    type: string|array|object|boolean|number
    required: true|false
    default: value  # if not required

actions:
  # Use {{ param_name }} for substitution
  - name: load_{{ table_name }}
    # ... action configuration
```
