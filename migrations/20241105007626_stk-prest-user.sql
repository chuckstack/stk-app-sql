
--create a PostgREST user and grant access to the already created stk_api_role

CREATE ROLE postgrest NOINHERIT LOGIN ;
COMMENT ON ROLE postgrest IS 'PostgREST login role for PostgREST that has no priviledges';
GRANT stk_api_role TO postgrest;
