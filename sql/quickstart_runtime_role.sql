-- ============================================================================
-- Openflow SPCS Quickstart: Runtime Role and External Access Integration
-- ============================================================================
-- This script creates the runtime role, supporting resources, and external
-- access integration needed for Openflow connectors.
--
-- Prerequisites:
--   - quickstart_setup_core.sql completed successfully
--   - Active Openflow deployment in Snowsight
--   - ACCOUNTADMIN role
--
-- Duration: ~5 minutes
-- ============================================================================

-- Step 1: Create Runtime Role and Resources
-- ----------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

-- Create runtime role
CREATE ROLE IF NOT EXISTS QUICKSTART_ROLE;

-- Create database for Openflow resources
CREATE DATABASE IF NOT EXISTS QUICKSTART_DATABASE;

-- Create warehouse for data processing
CREATE WAREHOUSE IF NOT EXISTS QUICKSTART_WH
  WAREHOUSE_SIZE = MEDIUM
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE;

-- Grant privileges to runtime role
GRANT USAGE ON DATABASE QUICKSTART_DATABASE TO ROLE QUICKSTART_ROLE;
GRANT USAGE ON WAREHOUSE QUICKSTART_WH TO ROLE QUICKSTART_ROLE;

-- Grant runtime role to Openflow admin
GRANT ROLE QUICKSTART_ROLE TO ROLE OPENFLOW_ADMIN;


-- Step 2: Create External Access Integration
-- ----------------------------------------------------------------------------
-- This creates one integration with network rules for both Google Drive and PostgreSQL.
-- Customize the network rules based on your specific connector needs.

USE ROLE ACCOUNTADMIN;

-- Create schema for network rules
CREATE SCHEMA IF NOT EXISTS QUICKSTART_DATABASE.NETWORKS;

-- Create network rule for Google APIs
CREATE OR REPLACE NETWORK RULE google_api_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = (
    'admin.googleapis.com',
    'oauth2.googleapis.com',
    'www.googleapis.com',
    'google.com'
  );

-- Create network rule for your Google Workspace domain (optional)
-- Replace 'your-domain.com' with your actual domain
CREATE OR REPLACE NETWORK RULE workspace_domain_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('your-domain.com');

-- Create network rule for PostgreSQL endpoint
-- Replace 'your-postgres-host.com:5432' with your actual endpoint
CREATE OR REPLACE NETWORK RULE postgres_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('your-postgres-host.com:5432');

-- Create ONE external access integration with ALL network rules
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION quickstart_access
  ALLOWED_NETWORK_RULES = (
    QUICKSTART_DATABASE.NETWORKS.google_api_network_rule,
    QUICKSTART_DATABASE.NETWORKS.workspace_domain_network_rule,
    QUICKSTART_DATABASE.NETWORKS.postgres_network_rule
  )
  ENABLED = TRUE
  COMMENT = 'Openflow SPCS runtime access for Google Drive and PostgreSQL connectors';

-- Grant usage to runtime role
GRANT USAGE ON INTEGRATION quickstart_access TO ROLE QUICKSTART_ROLE;


-- Step 3: Verify Setup
-- ----------------------------------------------------------------------------
-- Verify role and grants
SHOW ROLES LIKE 'QUICKSTART_ROLE';
SHOW GRANTS TO ROLE QUICKSTART_ROLE;

-- Verify integration
SHOW INTEGRATIONS LIKE 'quickstart_access';
DESC INTEGRATION quickstart_access;

-- ============================================================================
-- Setup Complete!
-- ============================================================================
-- Next Steps:
--   1. Create Openflow runtime via Snowsight UI using:
--      - Runtime Name: QUICKSTART_RUNTIME
--      - Runtime Role: QUICKSTART_ROLE
--      - External Access Integration: quickstart_access
--   2. Access the runtime canvas to add connectors
--
-- For connector-specific setup, see the companion notebooks:
--   - EAI_GDRIVE.ipynb - Google Drive connector setup
--   - EAI_POSTGRES.ipynb - PostgreSQL connector setup
--
-- Documentation: 
--   https://docs.snowflake.com/en/user-guide/data-integration/openflow/setup-openflow-spcs-create-rr
-- ============================================================================

