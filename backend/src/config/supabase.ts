import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseServiceKey) {
    console.warn('⚠️ SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set — file uploads will fail.');
}

/**
 * Admin client using service role key.
 * Only used server-side; never expose this key to clients.
 */
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
    auth: { persistSession: false },
});
