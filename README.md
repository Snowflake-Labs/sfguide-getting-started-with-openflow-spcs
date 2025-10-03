# Openflow Notebooks

## Description

This is a collection of Notebooks and SnowSQL Scripts to help with Openflow Deployments and Runtimes.

### General

There are Notebooks to:
- Set up a persistent network ingress rule so your Openflow Deployments don't disconnect during important demos
- Fully run you through SPCS Openflow setup from start to finish
- A method to integrate Gitlab into a Database in Snowsight

### Ingress Persistence and Openflow SPCS Setup

You can follow your nose for both of these Notebooks as they will get you set up with Openflow as an SE

### EAI

The EAI_* Notebooks are intended to be run on an SPCS (Snowpark Container Services) container such that you create or validate the necessary networking connectivity from SPCS to various sources before using more complex tooling like Openflow or Native Applications to connect to them.

You should end up with an EAI (External Access Integration) which can then be used with an SPCS Openflow deployment that is already known to be able to Connect/Authenticate/Pull data from some Source service.

The intention is that you can help the customer get networking sorted before launching into a PoC of a given Product or feature.

## Audience
These notebooks should be usable by anyone fairly simply.

It is always recommended that you should review them and then execute them in your own environment before sharing them with a Customer.

It is recommended that we jointly execute them with Customers so that we can discuss the errors and resolutions for different connectivity issues to provide a good customer experience.

## Installation
Most of these notebooks are intended to be executed in Snowsight, backed by an SPCS compute pool.

The easiest approach here is to attach a compute pool to your Openflow Database in the account, you can use the following commands as an example of setting this up:

``` SQL
-- Use some role with sufficient privileges
USE ROLE ACCOUNTADMIN;

-- Explicitly use the Openflow Database
USE DATABASE OPENFLOW;

-- Create a compute pool for the SPCS container runtime
-- Choose an appropriate instance family. CPU_X64_S is a good starting point for testing.
CREATE COMPUTE POOL CONNECTOR_TEST_POOL
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_S;

-- Check readiness
DESCRIBE COMPUTE POOL CONNECTOR_TEST_POOL;
```

Once this compute pool is ready, import the appropriate notebook into the account and follow it.

## EAI Notebook Usage
Each Notebook should roughly follow this structure:

1. User Inputs for connecting to the Source in question
2. Connectivity Test cells
3. EAI Setup cells

The user should follow these steps:

1. Provide connectivity information that mirrors what is used in the Openflow or other Connector
2. Run the connectivity test
3. If the test fails, follow the steps to implement the reference EAI or other networking setup
4. Re-run the test to validate connectivity

## Support
Please ask for help in the Slack channel #ask-openflow-team

If there is a particular scenario that needs covering, please also reach out to Dan Chaffelson or the DE AFE team.

## Contributing
Additional Notebooks are very welcome, particularly addressing complex edge cases.
