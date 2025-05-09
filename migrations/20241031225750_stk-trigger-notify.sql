

-- set session to show stk_superuser as the actor performing all the tasks
SET stk.session = '{\"psql_user\": \"stk_superuser\"}';

-- create pg_notify messages
CREATE OR REPLACE FUNCTION private.t80100_stk_notify()
RETURNS trigger AS $$
DECLARE
    payload_v jsonb;
    channel_name_v text;
BEGIN

    --
    channel_name_v := TG_TABLE_NAME || '_notify';

    IF TG_OP = 'INSERT' THEN
        payload_v = jsonb_build_object(
            'operation', 'INSERT',
            'table', TG_TABLE_NAME,
            'schema', TG_TABLE_SCHEMA,
            'data', row_to_json(NEW)
        );
    ELSIF TG_OP = 'UPDATE' THEN
        payload_v = jsonb_build_object(
            'operation', 'UPDATE',
            'table', TG_TABLE_NAME,
            'schema', TG_TABLE_SCHEMA,
            'old_data', row_to_json(OLD),
            'new_data', row_to_json(NEW)
        );
    ELSIF TG_OP = 'DELETE' THEN
        payload_v = jsonb_build_object(
            'operation', 'DELETE',
            'table', TG_TABLE_NAME,
            'schema', TG_TABLE_SCHEMA,
            'data', row_to_json(OLD)
        );
    END IF;

    PERFORM pg_notify(
        channel_name_v,
        payload_v::text
    );

    RETURN NULL;

END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION private.t80100_stk_notify() IS 'Create pg_notify messages for changes to records';

--only apply to specific tables
insert into private.stk_trigger_mgt (function_name_prefix,function_name_root,function_event,is_include,table_name) values (80100,'stk_notify','AFTER INSERT OR UPDATE OR DELETE',true,ARRAY['stk_async','stk_async_type']);

select private.stk_trigger_create();

-- see xxx_stk-async.sql for demo instructions
