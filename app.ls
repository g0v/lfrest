require! {optimist}
{argv} = optimist
conString = argv.db or process.env['PLV8XCONN'] or process.env['PLV8XDB'] or process.env.TESTDBNAME or process.argv?2
unless conString
  console.log "ERROR: Please set the PLV8XDB environment variable, or pass in a connection string as an argument"
  process.exit!
{pgsock} = argv

require! pgrest
plx <- pgrest .new conString, meta: do
  'pgrest.info': {+fo}
  'pgrest.member_count': {+fo}
  'pgrest.contingent': {}
  'pgrest.issue': do
    as: 'public.issue'
  'pgrest.initiative': do
    as: 'public.initiative'

{mount-default,with-prefix} = pgrest.routes!

process.exit 0 if argv.boot
{port=3000, prefix="/collections", host="127.0.0.1"} = argv
express = try require \express
throw "express required for starting server" unless express
app = express!

app.use express.cookieParser!
app.use express.json!

pgparam = (req, res, next) ->
  session = req.cookies.liquid_feedback_session
  plx.query "select pgrest_param($1::json)" [{session}], next!

<- plx.import-bundle \lfrest require.resolve \./package.json

lfrest = require \./lib
for name, f of lfrest
  if f.$plv8x
    plx.mk-user-func "#name#that" "lfrest:#name", ->

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


<- plx.mk-user-func "pgrest_param():json" ':~> plv8x.context'
<- plx.mk-user-func "pgrest_param(text):int" ':~> plv8x.context?[it]'
<- plx.mk-user-func "pgrest_param(text):text" ':~> plv8x.context?[it]'
<- plx.mk-user-func "pgrest_param(json):json" ':~> plv8x.context = it'

<- plx.query '''select pgrest_param('{}'::json)'''
<- plx.query """
CREATE OR REPLACE VIEW pgrest.contingent_left AS
  WITH auth as (select ensure_member() as member_id)
    SELECT * from member_contingent_left
      WHERE member_contingent_left.member_id = (select member_id from auth);
"""

require! cors
cols <- mount-default plx, 'pgrest', with-prefix prefix, (path, r) ->
  args = [path, r]
  args.splice 1, 0, cors! if argv.cors
  app.all ...args

app.listen port, host
console.log "Available collections:\n#{ cols.sort! * ' ' }"
console.log "Serving `#conString` on http://#host:#port#prefix"
