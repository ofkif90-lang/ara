import { createClient } from "npm:@supabase/supabase-js@2.58.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anonKey = req.headers.get("Authorization")?.replace("Bearer ", "") ?? "";

    // Verify caller is authenticated and is an admin
    const callerClient = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false },
    });
    const { data: { user } } = await callerClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "غير مصرح" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: profile } = await callerClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    if (profile?.role !== "admin") {
      return new Response(JSON.stringify({ error: "صلاحيات الإدارة مطلوبة" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { userId, newPassword } = await req.json();
    if (!userId || !newPassword || newPassword.length < 6) {
      return new Response(JSON.stringify({ error: "كلمة المرور يجب أن تكون 6 أحرف على الأقل" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Use service role to update the target user's password
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { error: updateError } = await adminClient.auth.admin.updateUserById(
      userId,
      { password: newPassword }
    );

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Set must_change_password flag so user is prompted to change it on next login
    await adminClient
      .from("profiles")
      .update({ must_change_password: true })
      .eq("id", userId);

    // Log the activity
    await adminClient.from("activity_log").insert({
      admin_id: user.id,
      action: "إعادة تعيين كلمة مرور مستخدم",
      target: userId,
    });

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "حدث خطأ" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
