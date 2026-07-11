export interface Env {
  SUPABASE_URL: string
  SUPABASE_ANON_KEY: string
  GITHUB_TOKEN: string
  GITHUB_OWNER: string
  GITHUB_REPO: string
  ALLOWED_ORIGIN: string
}

const cors = (request: Request, env: Env) => ({
  'Access-Control-Allow-Origin': env.ALLOWED_ORIGIN,
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
})

const json = (request: Request, env: Env, body: Record<string, unknown>, status = 200) => new Response(JSON.stringify(body), { status, headers: { ...cors(request, env), 'Content-Type': 'application/json' } })

async function verifiedUser(request: Request, env: Env): Promise<{ id: string } | null> {
  const authorization = request.headers.get('Authorization')
  if (!authorization?.startsWith('Bearer ')) return null
  const response = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, { headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: authorization } })
  if (!response.ok) return null
  const user = await response.json() as { id: string }
  return user.id ? user : null
}

async function hasDeployRole(authorization: string, env: Env): Promise<boolean> {
  const response = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/can_manage`, {
    method: 'POST',
    headers: {
      apikey: env.SUPABASE_ANON_KEY,
      Authorization: authorization,
      'Content-Type': 'application/json',
    },
    body: '{}',
  })
  if (!response.ok) return false
  return Boolean(await response.json())
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get('Origin')
    if (origin && origin !== env.ALLOWED_ORIGIN) return json(request, env, { error: 'Origin not allowed' }, 403)
    if (request.method === 'OPTIONS') return new Response(null, { headers: cors(request, env) })
    if (request.method !== 'POST' || new URL(request.url).pathname !== '/deploy-landing') return json(request, env, { error: 'Not found' }, 404)
    const authorization = request.headers.get('Authorization')
    const user = await verifiedUser(request, env)
    if (!user) return json(request, env, { error: 'Unauthenticated' }, 401)
    if (!await hasDeployRole(authorization!, env)) return json(request, env, { error: 'Forbidden' }, 403)

    const response = await fetch(`https://api.github.com/repos/${env.GITHUB_OWNER}/${env.GITHUB_REPO}/dispatches`, {
      method: 'POST',
      headers: {
        Accept: 'application/vnd.github+json',
        Authorization: `Bearer ${env.GITHUB_TOKEN}`,
        'User-Agent': 'chilling-admin-deploy-worker',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      body: JSON.stringify({ event_type: 'landing_content_changed', client_payload: { requested_by: user.id } }),
    })

    if (!response.ok) return json(request, env, { error: 'GitHub deployment dispatch failed' }, 502)
    return json(request, env, { ok: true })
  },
}
