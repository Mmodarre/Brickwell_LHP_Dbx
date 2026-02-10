-- Create ingestion schemas for Brickwell Health
-- These schemas are organized by domain to separate ingested data by source schema

-- Regulatory domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.regulatory_ingestion_schema
COMMENT 'Ingestion schema for regulatory domain tables (age_based_discount, bank_account, lhc_loading, phi_rebate_entitlement, suspension, upgrade_request)';

-- Claims domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.claims_ingestion_schema
COMMENT 'Ingestion schema for claims domain tables (ambulance_claim, benefit_usage, claim, claim_assessment, claim_line, extras_claim, hospital_admission, medical_service, prosthesis_claim)';

-- Policy domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.policy_ingestion_schema
COMMENT 'Ingestion schema for policy domain tables (application, application_member, coverage, health_declaration, member, member_update, policy, policy_member, waiting_period)';

-- Billing domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.billing_ingestion_schema
COMMENT 'Ingestion schema for billing domain tables (arrears, direct_debit_mandate, direct_debit_result, invoice, payment, premium_discount, refund)';

-- Communication domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.communication_ingestion_schema
COMMENT 'Ingestion schema for communication domain tables (campaign, campaign_response, communication, communication_preference)';

-- CRM domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.crm_ingestion_schema
COMMENT 'Ingestion schema for CRM domain tables (complaint, interaction, service_case)';

-- Survey domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.survey_ingestion_schema
COMMENT 'Ingestion schema for survey domain tables (csat_survey, nps_survey)';

-- Digital domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.digital_ingestion_schema
COMMENT 'Ingestion schema for digital domain tables (digital_event, web_session)';

-- Reference domain ingestion schema
CREATE SCHEMA IF NOT EXISTS brickwell_health.reference_ingestion_schema
COMMENT 'Ingestion schema for reference domain tables (benefit_category, campaign_type, case_type, claim_rejection_reason, clinical_category, communication_template, complaint_category, excess_option, extras_item_code, hospital, interaction_outcome, interaction_type, mbs_item, product, product_tier, prosthesis_list_item, provider, provider_location, state_territory, survey_type)';
