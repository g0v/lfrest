{pgrest_param_get, pgrest_param_set} = require \pgrest

export function bootstrap(plx, cb)
  next <- plx.import-bundle-funcs \lfrest require.resolve \../package.json

  # XXX: make plv8x /sql define-schema reusable
  <- plx.query """
  DO $$
  BEGIN
      IF NOT EXISTS(
          SELECT schema_name
            FROM information_schema.schemata
            WHERE schema_name = 'pgrest'
        )
      THEN
        EXECUTE 'CREATE SCHEMA pgrest';
      END IF;
  END
  $$;

  CREATE OR REPLACE VIEW pgrest.info AS
    SELECT
     (select string from liquid_feedback_version) as core_version,
     (select member_ttl from system_setting);

  CREATE OR REPLACE VIEW pgrest.member_count AS
    SELECT * from member_count;

  CREATE OR REPLACE VIEW pgrest.contingent AS
    SELECT * from contingent;

  CREATE OR REPLACE VIEW pgrest.issue AS
    SELECT *,
      (SELECT COALESCE(ARRAY_TO_JSON(ARRAY_AGG(_)), '[]') FROM (SELECT * FROM initiative
          WHERE initiative.issue_id = issue.id) AS _) AS initiatives
    FROM issue;
  CREATE OR REPLACE VIEW pgrest.initiative AS
    SELECT *
    FROM initiative;
  """
  next ->
    <- plx.query """
    CREATE OR REPLACE VIEW pgrest.contingent_left AS
      WITH auth as (select ensure_member() as member_id)
        SELECT * from member_contingent_left
          WHERE member_contingent_left.member_id = (select member_id from auth);
    """
    cb!

export function ensure_member
  throw "no session" unless session = pgrest_param_get \session
  [res]? = plv8.execute "select member_id from session where ident = $1", [session]
  if res
    pgrest_param_set \member_id res.member_id
  else
    throw "not logged in"

  res.member_id

ensure_member.$plv8x = '():int'
