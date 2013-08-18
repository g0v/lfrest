meta = do
  'pgrest.info': {+fo}
  'pgrest.member_count': {+fo}
  'pgrest.contingent': {}
  'pgrest.issue': do
    as: 'public.issue'
  'pgrest.initiative': do
    as: 'public.initiative'

require! pgrest

pgparam = (req, res, next) ->
  session = req.cookies.liquid_feedback_session
  req.pgparam = {session}
  next!

app <- pgrest.cli! {meta}, <[cookieParser]>, [pgparam], require \./lib
