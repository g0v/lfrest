export function ensure_member
  throw "no session " unless session = plv8x.context.session
  [res]? = plv8.execute "select member_id from session where ident = $1", [session]
  if res
    plv8x.context.member_id = res.member_id
  else
    throw "not logged in"

ensure_member.$plv8x = '():int'
