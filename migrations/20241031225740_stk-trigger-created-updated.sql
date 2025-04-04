

CREATE OR REPLACE FUNCTION private.t10110_stk_created_updated()
RETURNS TRIGGER AS $$
DECLARE
    current_user_v UUID;
    psql_user_v TEXT;
    has_column_v BOOLEAN;
BEGIN

    -- Check if the table has the correct columns
    -- asssumes that if it does not have created, then it also does not have created_by_uu, updated, ...
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = TG_TABLE_SCHEMA
        AND table_name = TG_TABLE_NAME
        AND column_name = 'created'
    ) INTO has_column_v;

    -- If the table doesn't have the correct columns, return
    IF NOT has_column_v THEN
        RETURN NEW;
    END IF;

    BEGIN
        --SELECT current_setting('stk.session', true)::json->>'psql_user' INTO psql_user_v; --stk.session
        --SELECT current_setting('request.headers', true)::json INTO psql_user_v; --postgrest header
        --SELECT current_setting('role', true) INTO psql_user_v; --https://docs.postgrest.org/en/v12/references/transactions.html
        --SELECT current_user INTO psql_user_v; --shows current role
        SELECT session_user INTO psql_user_v; --shows original user at login
    EXCEPTION
        WHEN OTHERS THEN
            psql_user_v := 'unknown';
    END;

    -- Add RAISE WARNING statements here
    --RAISE WARNING 'psql_user_v: %', psql_user_v;

    SELECT uu
    FROM private.stk_actor
    WHERE psql_user = psql_user_v
    INTO current_user_v;

    IF current_user_v IS NULL THEN 
        RAISE EXCEPTION 'no user found in session - current_user_v';
    END IF;

    IF TG_OP = 'INSERT' THEN
        NEW.created = now();
        NEW.updated = now();
        NEW.created_by_uu = current_user_v;
        NEW.updated_by_uu = current_user_v;
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.created = OLD.created;
        NEW.updated = now();
        NEW.created_by_uu = OLD.created_by_uu;
        NEW.updated_by_uu = current_user_v;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;
COMMENT ON FUNCTION private.t10110_stk_created_updated() IS 'manages automatic updates to created,updated,created_by_uu and updated_by_uu';

insert into private.stk_trigger_mgt (function_name_prefix,function_name_root,function_event) values (10110,'stk_created_updated','BEFORE INSERT OR UPDATE');

select private.stk_trigger_create();
