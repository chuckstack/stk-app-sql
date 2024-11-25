

CREATE OR REPLACE FUNCTION private.t1010_created_updated()
RETURNS TRIGGER AS $$
DECLARE
    current_user_v uuid;
    psql_user_v text;
BEGIN

    BEGIN
        SELECT current_setting('stk.session', true)::json->>'psql_user' INTO psql_user_v;
    EXCEPTION
        WHEN OTHERS THEN
            psql_user_v := 'unknown';
    END;

    SELECT stk_actor_uu
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
COMMENT ON FUNCTION private.t1010_created_updated() IS 'manages automatic updates to created,updated,created_by_uu and updated_by_uu';

insert into private.stk_trigger_mgt (function_name_prefix,function_name_root,function_event) values (1010,'created_updated','BEFORE INSERT OR UPDATE OR DELETE');

select private.stk_trigger_create();
