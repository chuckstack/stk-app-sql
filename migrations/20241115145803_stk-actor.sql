

CREATE TYPE private.actor_type AS ENUM (
    'NONE'
);
COMMENT ON TYPE private.actor_type IS 'Enum used in code to automate and validate actor types.';

INSERT INTO private.enum_comment (enum_type, enum_value, comment) VALUES
('actor_type', 'NONE', 'General purpose with no automation or validation')
;

CREATE TABLE private.stk_actor_type (
  stk_actor_type_uu UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created TIMESTAMPTZ NOT NULL DEFAULT now(),
  --created_by_uu uuid NOT NULL,
  --CONSTRAINT fk_some_table_createdby FOREIGN KEY (created_by_uu) REFERENCES stk_actor(stk_actor_uu),
  updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  --updated_by_uu uuid NOT NULL,
  --CONSTRAINT fk_some_table_updatedby FOREIGN KEY (updated_by_uu) REFERENCES stk_actor(stk_actor_uu),
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_default BOOLEAN NOT NULL DEFAULT false,
  actor_type private.actor_type NOT NULL,
  search_key TEXT NOT NULL DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT
);
COMMENT ON TABLE private.stk_actor_type IS 'Holds the types of stk_actor records. To see a list of all actor_type enums and their comments, select from api.enum_value where enum_name is actor_type.';

CREATE VIEW api.stk_actor_type AS SELECT * FROM private.stk_actor_type;
COMMENT ON VIEW api.stk_actor_type IS 'Holds the types of stk_actor records.';

CREATE TABLE private.stk_actor (
  stk_actor_uu UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created TIMESTAMPTZ NOT NULL DEFAULT now(),
  --created_by_uu uuid NOT NULL,
  --CONSTRAINT fk_some_table_createdby FOREIGN KEY (created_by_uu) REFERENCES stk_actor(stk_actor_uu),
  updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  --updated_by_uu uuid NOT NULL,
  --CONSTRAINT fk_some_table_updatedby FOREIGN KEY (updated_by_uu) REFERENCES stk_actor(stk_actor_uu),
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_template BOOLEAN NOT NULL DEFAULT false,
  is_valid BOOLEAN NOT NULL DEFAULT true,
  stk_actor_type_uu UUID NOT NULL,
  CONSTRAINT fk_stk_actor_type FOREIGN KEY (stk_actor_type_uu) REFERENCES private.stk_actor_type(stk_actor_type_uu),
  stk_actor_parent_uu UUID,
  CONSTRAINT fk_stk_actor_parent FOREIGN KEY (stk_actor_parent_uu) REFERENCES private.stk_actor(stk_actor_uu),
  search_key TEXT NOT NULL DEFAULT gen_random_uuid(),
  name TEXT,
  name_first TEXT,
  name_middle TEXT,
  name_last TEXT,
  description TEXT,
  psql_user TEXT
);
COMMENT ON TABLE private.stk_actor IS 'Holds actor records';

-- do not allow multiple users to share the same psql user reference
CREATE UNIQUE INDEX stk_actor_psql_user_uidx ON private.stk_actor (lower(psql_user)) WHERE psql_user IS NOT NULL;

CREATE VIEW api.stk_actor AS SELECT * FROM private.stk_actor;
COMMENT ON VIEW api.stk_actor IS 'Holds actor records';

select private.stk_table_trigger_create();

INSERT INTO private.stk_actor_type (
    actor_type, name
) VALUES (
    'NONE', 'NONE'
);

INSERT INTO private.stk_actor (
    stk_actor_type_uu, name, psql_user
) VALUES (
    (SELECT stk_actor_type_uu FROM private.stk_actor_type LIMIT 1), 'stk_login', 'stk_login'
);
