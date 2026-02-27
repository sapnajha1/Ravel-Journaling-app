// Delete the authenticated user's account from Supabase Auth.
// Requires Authorization: Bearer <access_token>. Uses service_role to perform
// the actual deletion (admin API cannot be called from the client).

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing or invalid Authorization header" }, 401);
    }

    const token = authHeader.replace("Bearer ", "").trim();
    if (!token) {
      return json({ error: "Missing token" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
      console.error("Missing Supabase env vars");
      return json({ error: "Server configuration error" }, 500);
    }

    // Verify the token and get the user
    const supabase = createClient(supabaseUrl, supabaseAnonKey);
    const {
      data: { user },
      error: getUserError,
    } = await supabase.auth.getUser(token);

    if (getUserError || !user) {
      return json({ error: "Invalid or expired token" }, 401);
    }

    const userId = user.id;

    // Use service_role to delete the user (admin API)
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
    });

    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      userId
    );

    if (deleteError) {
      console.error("deleteUser failed:", deleteError);
      return json({ error: deleteError.message }, 400);
    }

    return json({ success: true });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});
