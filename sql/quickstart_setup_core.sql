-- ============================================================================
-- Openflow SPCS Quickstart: Core Snowflake Setup
-- ============================================================================
-- This script sets up the core Snowflake components required for Openflow SPCS
-- including the admin role, network rules, and required configurations.
--
-- Prerequisites:
--   - ACCOUNTADMIN role or equivalent privileges
--   - Snowflake account in AWS or Azure Commercial Regions
--
-- Duration: ~10 minutes
-- ============================================================================

-- Step 1: Create Openflow Admin Role
-- ----------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

-- Create the Openflow admin role
CREATE ROLE IF NOT EXISTS OPENFLOW_ADMIN;

-- Grant necessary privileges
GRANT CREATE DATABASE ON ACCOUNT TO ROLE OPENFLOW_ADMIN;
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE OPENFLOW_ADMIN;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE OPENFLOW_ADMIN;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE OPENFLOW_ADMIN;

-- Grant role to current user and ACCOUNTADMIN
GRANT ROLE OPENFLOW_ADMIN TO ROLE ACCOUNTADMIN;
SET id = CURRENT_USER();
GRANT ROLE OPENFLOW_ADMIN TO USER IDENTIFIER($id);


-- Step 2: BCR Bundle Status
-- ----------------------------------------------------------------------------
-- Check if BCR Bundle 2025_06 is already enabled

CALL SYSTEM$BEHAVIOR_CHANGE_BUNDLE_STATUS('2025_06');

-- If the result shows 'DISABLED', uncomment and run the following command:
/*
CALL SYSTEM$ENABLE_BEHAVIOR_CHANGE_BUNDLE('2025_06');
*/


-- Step 3: Verify Setup
-- ----------------------------------------------------------------------------
-- Verify role exists
SHOW ROLES LIKE 'OPENFLOW_ADMIN';

-- Verify grants
SHOW GRANTS TO ROLE OPENFLOW_ADMIN;


-- ============================================================================
-- Setup Complete!
-- ============================================================================
-- Next Steps:
--   1. Create Openflow deployment via Snowsight UI
--   2. Run quickstart_runtime_role.sql to create runtime resources
--
-- Documentation: 
--   https://docs.snowflake.com/en/user-guide/data-integration/openflow/setup-openflow-spcs-sf
-- ============================================================================

