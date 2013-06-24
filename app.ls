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

{mount-default}:routes = pgrest.routes!

process.exit 0 if argv.boot
{port=3000, prefix="/collections", host="127.0.0.1"} = argv
express = try require \express
throw "express required for starting server" unless express
app = express!

app.use express.json!

route = (path, fn) ->
  fullpath = "#{
      switch path.0
      | void => prefix
      | '/'  => ''
      | _    => "#prefix/"
    }#path"
  app.all fullpath, routes.route path, fn

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
"""


<- plx.mk-user-func "pgrest_param():json" ':~> plv8x.context'
<- plx.mk-user-func "pgrest_param(text):int" ':~> plv8x.context?[it]'
<- plx.mk-user-func "pgrest_param(text):text" ':~> plv8x.context?[it]'
<- plx.mk-user-func "pgrest_param(json):json" ':~> plv8x.context = it'

<- plx.query """
CREATE OR REPLACE VIEW pgrest.contingent_left AS
  WITH auth as (select ensure_member() as member_id)
    SELECT * from member_contingent_left
      WHERE member_contingent_left.member_id = (select member_id from auth);
"""

cols <- mount-default plx, 'pgrest', route

app.listen port, host
console.log "Available collections:\n#{ cols.sort! * ' ' }"
console.log "Serving `#conString` on http://#host:#port#prefix"
