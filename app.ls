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
  req.pgparam = {session}
  next!

lfrest = require \./lib
<- lfrest.bootstrap plx

require! cors
cols <- mount-default plx, 'pgrest', with-prefix prefix, (path, r) ->
  args = [pgparam, r]
  args.unshift cors! if argv.cors
  args.unshift path
  app.all ...args

app.listen port, host
console.log "Available collections:\n#{ cols.sort! * ' ' }"
console.log "Serving `#conString` on http://#host:#port#prefix"
