-- ============================================================================
-- Openflow SPCS Quickstart: Cleanup
-- ============================================================================
-- This script removes all resources created by the Openflow SPCS quickstart.
--
-- WARNING: This will delete all resources and data created during the quickstart!
--          Make sure you have backups of any important data before proceeding.
--
-- Prerequisites:
--   - Deployments and runtimes already deleted via Snowsight UI
--   - ACCOUNTADMIN role
--
-- Duration: ~2 minutes
-- ============================================================================

-- IMPORTANT: Remove Deployments and Runtimes First!
-- ----------------------------------------------------------------------------
-- Before running this script, delete deployments and runtimes via Snowsight:
--   1. Navigate to Work with data → Ingestion → Openflow
--   2. Go to Runtimes tab → Delete QUICKSTART_RUNTIME
--   3. Go to Deployments tab → Delete QUICKSTART_DEPLOYMENT
--   4. Wait for deletion to complete (status should disappear)
--
-- Then run this script to clean up supporting resources.


-- Step 1: Remove External Access Integration
-- ----------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

-- Drop external access integration
DROP INTEGRATION IF EXISTS quickstart_access;


-- Step 2: Remove Network Rules
-- ----------------------------------------------------------------------------
-- Drop network rules created in the NETWORKS schema
DROP NETWORK RULE IF EXISTS QUICKSTART_DATABASE.NETWORKS.google_api_network_rule;
DROP NETWORK RULE IF EXISTS QUICKSTART_DATABASE.NETWORKS.workspace_domain_network_rule;
DROP NETWORK RULE IF EXISTS QUICKSTART_DATABASE.NETWORKS.postgres_network_rule;


-- Step 3: Remove Warehouse
-- ----------------------------------------------------------------------------
-- Drop warehouse created for data processing
DROP WAREHOUSE IF EXISTS QUICKSTART_WH;


-- Step 4: Remove Database
-- ----------------------------------------------------------------------------
-- WARNING: This will delete all ingested data!
-- Ensure you have backups of important data before proceeding.
DROP DATABASE IF EXISTS QUICKSTART_DATABASE;


-- Step 5: Remove Runtime Role
-- ----------------------------------------------------------------------------
-- Drop the runtime role
DROP ROLE IF EXISTS QUICKSTART_ROLE;


-- Step 6: (OPTIONAL) Remove Core Snowflake Resources
-- ----------------------------------------------------------------------------
-- Uncomment the following sections if you want to completely remove
-- the Openflow core setup (not recommended if you plan to use Openflow again)

/*
-- Switch to ACCOUNTADMIN to remove the admin role
USE ROLE ACCOUNTADMIN;

-- Drop Openflow admin role
DROP ROLE IF EXISTS OPENFLOW_ADMIN;
*/


-- Step 7: Verify Cleanup
-- ----------------------------------------------------------------------------
-- Verify resources are removed
SHOW INTEGRATIONS LIKE 'quickstart_access';
SHOW WAREHOUSES LIKE 'QUICKSTART_WH';
SHOW DATABASES LIKE 'QUICKSTART_DATABASE';
SHOW ROLES LIKE 'QUICKSTART_ROLE';

-- ============================================================================
-- Cleanup Complete!
-- ============================================================================
-- All quickstart resources have been removed from your Snowflake account.
--
-- Note: If you want to run the quickstart again, start with:
--   quickstart_setup_core.sql
--
-- Documentation: 
--   https://docs.snowflake.com/en/user-guide/data-integration/openflow/setup-openflow-spcs
-- ============================================================================

