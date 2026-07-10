import { computed, onMounted, ref } from 'vue'
import type { Session } from '@supabase/supabase-js'
import { isSupabaseConfigured, requireSupabase } from '../lib/supabase'

const session = ref<Session | null>(null)
const loading = ref(isSupabaseConfigured)
let initialized = false

export function useSession() {
  const initialize = () => {
    if (!isSupabaseConfigured || initialized) {
      loading.value = false
      return
    }
    initialized = true
    const client = requireSupabase()
    client.auth.getSession().then(({ data }) => {
      session.value = data.session
      loading.value = false
    })
    client.auth.onAuthStateChange((_event, nextSession) => {
      session.value = nextSession
      loading.value = false
    })
  }

  const signIn = async (email: string, password: string) => {
    const { error } = await requireSupabase().auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  const signOut = async () => {
    const { error } = await requireSupabase().auth.signOut()
    if (error) throw error
  }

  return { session, loading, configured: computed(() => isSupabaseConfigured), initialize, signIn, signOut }
}
