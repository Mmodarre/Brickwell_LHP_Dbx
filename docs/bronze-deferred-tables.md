# Bronze Layer - Deferred Tables

## Overview

This document lists tables that were **not implemented** in the bronze layer due to missing `modified_at` column. These tables only have `created_at` timestamp, which limits SCD Type 2 historical tracking capability.

**Total Tables Deferred**: 29 tables across 6 domains

---

## Implementation Options

For tables without `modified_at`, we have several options:

### Option 1: SCD Type 2 with Fallback (Recommended for transactional tables)
- Use `created_at` for both `sequence_by` and fallback
- Pros: Maintains architectural consistency, tracks initial load
- Cons: Limited history if source doesn't update timestamp
- **Best for**: Transactional tables that may get modified_at in future

### Option 2: SCD Type 1 (Simple Overwrite)
- No history tracking - latest record only
- Pros: Simpler, appropriate for static lookups
- Cons: No history tracking, loses audit trail
- **Best for**: Reference/lookup tables that rarely change

### Option 3: Append-Only (No SCD)
- All records appended with processing timestamp
- Pros: Complete audit trail
- Cons: No current state view, query complexity
- **Best for**: Event/log tables

---

## Deferred Tables by Domain

### 1. Billing Domain (3 tables)

**Schema**: `billing_ingestion_schema`
**Pipeline**: `billing_bronze`
**Status**: ⏳ Deferred

| Table | created_at | modified_at | Row Count | Recommendation |
|-------|-----------|-------------|-----------|----------------|
| direct_debit_result | ✓ | ✗ | TBD | Option 1 - May need history for reconciliation |
| premium_discount | ✓ | ✗ | TBD | Option 1 - Discount changes should be tracked |
| refund | ✓ | ✗ | TBD | Option 1 - Financial audit requires history |

**Recommendation**: Implement with **SCD Type 2 fallback** (`modified_at = created_at`) to maintain audit trail for financial records.

---

### 2. Communication Domain (2 tables)

**Schema**: `communication_ingestion_schema`
**Pipeline**: `communication_bronze`
**Status**: ⏳ Deferred

| Table | created_at | modified_at | Row Count | Recommendation |
|-------|-----------|-------------|-----------|----------------|
| campaign_response | ✓ | ✗ | TBD | Option 3 - Append-only (responses don't change) |
| communication | ✓ | ✗ | TBD | Option 3 - Append-only (sent communications) |

**Recommendation**: Implement as **append-only** tables since responses and sent communications are immutable events.

---

### 3. Regulatory Domain (1 table)

**Schema**: `regulatory_ingestion_schema`
**Pipeline**: `regulatory_bronze`
**Status**: ⏳ Deferred

| Table | created_at | modified_at | Row Count | Recommendation |
|-------|-----------|-------------|-----------|----------------|
| phi_rebate_entitlement | ✓ | ✗ | TBD | Option 1 - Rebate changes need tracking |

**Recommendation**: Implement with **SCD Type 2 fallback** to track rebate entitlement changes over time.

---

### 4. Digital Domain (2 tables)

**Schema**: `digital_ingestion_schema`
**Pipeline**: `digital_bronze`
**Status**: ⏳ Deferred

| Table | created_at | modified_at | Row Count | Recommendation |
|-------|-----------|-------------|-----------|----------------|
| digital_event | ✓ | ✗ | TBD | Option 3 - Append-only (events are immutable) |
| web_session | ✓ | ✗ | TBD | Option 3 - Append-only (sessions don't change) |

**Recommendation**: Implement as **append-only** tables. Digital events and web sessions are immutable time-series data.

---

### 5. Survey Domain (2 tables)

**Schema**: `survey_ingestion_schema`
**Pipeline**: `survey_bronze`
**Status**: ⏳ Deferred

| Table | created_at | modified_at | Row Count | Recommendation |
|-------|-----------|-------------|-----------|----------------|
| csat_survey | ✓ | ✗ | TBD | Option 3 - Append-only (survey responses) |
| nps_survey | ✓ | ✗ | TBD | Option 3 - Append-only (survey responses) |

**Recommendation**: Implement as **append-only** tables. Survey responses are point-in-time snapshots that don't change.

---

### 6. Reference Domain (19 tables)

**Schema**: `reference_ingestion_schema`
**Pipeline**: `reference_bronze`
**Status**: ⏳ Deferred

All reference tables are lookup/dimension tables with only `created_at` timestamp.

| Table | Type | Recommendation |
|-------|------|----------------|
| benefit_category | Lookup | SCD Type 1 |
| campaign_type | Lookup | SCD Type 1 |
| case_type | Lookup | SCD Type 1 |
| clinical_category | Lookup | SCD Type 1 |
| communication_template | Lookup | SCD Type 1 |
| complaint_category | Lookup | SCD Type 1 |
| excess_option | Lookup | SCD Type 1 |
| extras_item_code | Lookup | SCD Type 1 |
| hospital | Dimension | SCD Type 2 fallback |
| interaction_outcome | Lookup | SCD Type 1 |
| interaction_type | Lookup | SCD Type 1 |
| mbs_item | Lookup | SCD Type 1 |
| product | Dimension | SCD Type 2 fallback |
| product_tier | Lookup | SCD Type 1 |
| prosthesis_list_item | Lookup | SCD Type 1 |
| provider | Dimension | SCD Type 2 fallback |
| provider_location | Dimension | SCD Type 2 fallback |
| state_territory | Lookup | SCD Type 1 |
| survey_type | Lookup | SCD Type 1 |

**Recommendation**:
- **Lookups** (15 tables): Use **SCD Type 1** - Simple overwrite since these rarely change
- **Dimensions** (4 tables): Use **SCD Type 2 fallback** - Hospital, product, provider data needs history

---

## Next Steps

### Priority 1: Financial & Regulatory (4 tables)
Implement SCD Type 2 with fallback for audit compliance:
1. `billing.direct_debit_result`
2. `billing.premium_discount`
3. `billing.refund`
4. `regulatory.phi_rebate_entitlement`

### Priority 2: Event Tables (6 tables)
Implement as append-only for analytics:
1. `communication.campaign_response`
2. `communication.communication`
3. `digital.digital_event`
4. `digital.web_session`
5. `survey.csat_survey`
6. `survey.nps_survey`

### Priority 3: Reference Dimensions (4 tables)
Implement SCD Type 2 for key dimensions:
1. `reference.hospital`
2. `reference.product`
3. `reference.provider`
4. `reference.provider_location`

### Priority 4: Reference Lookups (15 tables)
Implement SCD Type 1 for static lookups:
- All remaining reference tables

---

## Template Modifications Needed

### For Append-Only Tables
Create new template: `TMPL002_append_only.yaml`
- No CDC configuration
- No SCD tracking
- Simple streaming append with processing timestamp

### For SCD Type 1 Tables
Create new template: `TMPL003_scd_type1.yaml`
- Use MERGE instead of CDC
- Overwrite on natural key match
- No history columns

---

## Data Quality Considerations

### Missing modified_at Impact
- **Audit Trail**: Limited to creation timestamp only
- **Change Tracking**: Cannot detect updates vs inserts
- **History Accuracy**: SCD Type 2 fallback assumes no in-place updates
- **Reconciliation**: Harder to track data lineage

### Mitigation Strategies
1. **Source System Enhancement**: Request `modified_at` column addition
2. **Hash-Based Change Detection**: Use row hash to detect changes
3. **Full Snapshot Comparison**: Compare full snapshots to detect changes
4. **Processing Timestamp**: Use ingestion timestamp as proxy

---

## Implementation Tracking

| Domain | Tables Deferred | Priority | Status |
|--------|----------------|----------|--------|
| Billing | 3 | High | ⏳ Planning |
| Communication | 2 | Medium | ⏳ Planning |
| Regulatory | 1 | High | ⏳ Planning |
| Digital | 2 | Medium | ⏳ Planning |
| Survey | 2 | Low | ⏳ Planning |
| Reference | 19 | Low | ⏳ Planning |

**Last Updated**: 2026-02-10
**Document Owner**: Data Engineering Team
