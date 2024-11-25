

CREATE OR REPLACE FUNCTION private.stk_table_type_create(table_name_p text)
RETURNS void AS $$
DECLARE
    type_table_name_v text;
    enum_name_v text;
    enum_type_v text;
    enum_value_record_v record;
BEGIN
    -- Construct the type table name
    type_table_name_v := 'private.' || table_name_p;
    RAISE NOTICE 'type_table_name_v:  %', type_table_name_v;

    -- Construct the type table name
    enum_type_v := 'private.' || table_name_p || '_enum';
    RAISE NOTICE 'enum_type_v:  %', enum_type_v;

    -- derive enum name from the table name
    enum_name_v := table_name_p || '_enum';
    RAISE NOTICE 'enum_name_v:  %', enum_name_v;

    -- TODO: need to check to see if table exists - otherwise raise exception

    -- Iterate through matching enum values
    FOR enum_value_record_v IN
        SELECT * FROM api.enum_value
        WHERE enum_name = enum_name_v
    LOOP
        -- Construct and execute the INSERT statement
        EXECUTE format(
            'INSERT INTO %s (
                name,
                description,
                %I
            ) VALUES (
                $1, $2, $3::%s
            )',
            type_table_name_v,
            enum_name_v,
            enum_type_v
        ) USING
            enum_value_record_v.enum_value,
            enum_value_record_v.comment,
            enum_value_record_v.enum_value;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
comment on FUNCTION private.stk_table_type_create(text) IS 'Populates type records from its associated enum values' 
