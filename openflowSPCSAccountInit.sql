-- This script prepares a workspace for Openflow SPCS Notebooks
-- Set the role to ACCOUNTADMIN for creating top-level objects
USE ROLE ACCOUNTADMIN;

-- Attach to the Openflow Database
CREATE DATABASE IF NOT EXISTS OPENFLOW;
USE DATABASE OPENFLOW;
CREATE SCHEMA IF NOT EXISTS OPENFLOW;
USE SCHEMA OPENFLOW;
