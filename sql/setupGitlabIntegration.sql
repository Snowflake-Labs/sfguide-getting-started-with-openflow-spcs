-- set context
USE DATABASE OPENFLOW;
USE SCHEMA OPENFLOW;

-- Create secret for Gitlab
-- Scopes: read_reposiory, write_repository

CREATE OR REPLACE SECRET snowflakeGitlabPAT
  TYPE = password
  USERNAME = 'gitlab_username'
  PASSWORD = 'gitlab_personal_access_token';

-- Create gitlab API integration
CREATE OR REPLACE API INTEGRATION snowflakeGitlabIntegration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://gitlab_instance_url/')
  ALLOWED_AUTHENTICATION_SECRETS = ALL
  ENABLED = TRUE;

  -- Create integration
  CREATE OR REPLACE GIT REPOSITORY spcsNotebooks
    API_INTEGRATION = snowflakeGitlabIntegration
    GIT_CREDENTIALS = snowflakeGitlabPAT
    ORIGIN = 'https://gitlab_instance_url/gitlab_username/gitlab_repo_name.git';
