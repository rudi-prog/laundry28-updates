import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  // FIX: tambahkan apikey & x-client-info, ini yang otomatis dikirim
  // oleh supabase.functions.invoke() dari client — tanpa ini, request
  // dari WEB akan diblokir browser saat preflight (tidak relevan untuk
  // mobile, tapi tetap baik untuk dibenerin supaya web juga jalan nanti).
  "Access-Control-Allow-Headers":
    "content-type, authorization, apikey, x-client-info",
};

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

interface CreateStaffRequest {
  full_name: string;
  username: string;
  pin_hash: string;
  // PIN asli (plaintext, 4-6 digit) — dipakai SEKALI di sini sebagai
  // password Supabase Auth untuk akun karyawan ini. Tidak disimpan di
  // mana pun sebagai plaintext; Supabase Auth akan hash sendiri secara
  // internal saat createUser dipanggil. `pin_hash` (di atas) tetap
  // dipakai terpisah untuk kolom staff.pin_hash (verifikasi manual di
  // AuthRepository.loginByPin).
  pin: string;
}

// FIX: helper terpisah supaya kita bisa lihat PERSIS apa yang dibalikin
// PostgREST — status code, dan body mentahnya — bukan cuma nebak dari
// data.length yang bisa salah kalau body-nya bukan array (misal object
// error seperti {"message": "Invalid API key"} saat service role key
// salah/kedaluwarsa).
async function queryStaff(
  label: string,
  url: string,
  apiHeaders: Record<string, string>,
): Promise<{ id: number; role: string; laundry_id: number | null } | null> {
  try {
    const resp = await fetch(url, { headers: apiHeaders });
    const rawText = await resp.text();

    console.log(
      `[create-staff] Query "${label}" -> status=${resp.status}, body=${rawText.slice(0, 500)}`,
    );

    if (!resp.ok) {
      // Ini kasus penting yang sebelumnya ketutup: kalau PostgREST
      // menolak request (401/403/dll), kita HARUS tahu, bukan diam-diam
      // dianggap "tidak ketemu".
      console.error(
        `[create-staff] Query "${label}" FAILED with status ${resp.status}: ${rawText}`,
      );
      return null;
    }

    let data: unknown;
    try {
      data = JSON.parse(rawText);
    } catch (parseErr) {
      console.error(
        `[create-staff] Query "${label}" returned non-JSON body: ${rawText}`,
      );
      return null;
    }

    if (Array.isArray(data) && data.length > 0) {
      console.log(`[create-staff] Query "${label}" found match: id=${(data[0] as any).id}`);
      return data[0] as { id: number; role: string; laundry_id: number | null };
    }

    console.log(`[create-staff] Query "${label}" — no match found (empty array).`);
    return null;
  } catch (e: unknown) {
    console.error(`[create-staff] Query "${label}" threw exception:`, e);
    return null;
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    // FIX: validasi env vars di awal, supaya kalau ada yang kosong/salah
    // kita dapat error yang JELAS, bukan error nyasar di tengah jalan.
    if (!supabaseUrl || !supabaseServiceRoleKey) {
      console.error(
        `[create-staff] Missing env vars: SUPABASE_URL=${!!supabaseUrl}, SUPABASE_SERVICE_ROLE_KEY=${!!supabaseServiceRoleKey}`,
      );
      return json({ error: "Server misconfiguration: missing env vars" }, 500);
    }

    const authHeader = req.headers.get("Authorization");
    const callerJwt = authHeader?.replace("Bearer ", "").trim();

    if (!callerJwt) {
      console.error("[create-staff] Missing Authorization header");
      return json({ error: "Missing Authorization header" }, 401);
    }

    const { data: callerAuth, error: callerAuthError } =
      await supabase.auth.getUser(callerJwt);

    if (callerAuthError || !callerAuth.user) {
      console.error(
        "[create-staff] Invalid caller token: " +
          (callerAuthError?.message ?? "unknown"),
      );
      return json({ error: "Invalid or expired session" }, 401);
    }

    const callerUserId = callerAuth.user.id;
    const callerEmail = callerAuth.user.email;
    console.log(
      "[create-staff] Caller user_id=" + callerUserId + ", email=" + callerEmail,
    );

    const apiHeaders = {
      "apikey": supabaseServiceRoleKey,
      "Authorization": "Bearer " + supabaseServiceRoleKey,
      "Content-Type": "application/json",
      "Prefer": "return=representation",
    };

    // FIX: pakai helper queryStaff supaya semua percobaan ke-log dengan
    // status code & body mentahnya, tidak ada lagi yang "gagal diam-diam".
    let callerStaff = await queryStaff(
      "auth_user_id",
      supabaseUrl +
        "/rest/v1/staff?auth_user_id=eq." +
        encodeURIComponent(callerUserId) +
        "&select=id,role,laundry_id&limit=1",
      apiHeaders,
    );

    if (!callerStaff && callerEmail) {
      callerStaff = await queryStaff(
        "email",
        supabaseUrl +
          "/rest/v1/staff?email=ilike." +
          encodeURIComponent(callerEmail.toLowerCase()) +
          "&select=id,role,laundry_id&limit=1",
        apiHeaders,
      );
    }

    if (!callerStaff && callerEmail) {
      const username = callerEmail.split("@")[0].toLowerCase();
      callerStaff = await queryStaff(
        "username",
        supabaseUrl +
          "/rest/v1/staff?username=ilike." +
          encodeURIComponent(username) +
          "&select=id,role,laundry_id&limit=1",
        apiHeaders,
      );
    }

    if (!callerStaff) {
      console.error(
        "[create-staff] Caller " +
          callerUserId +
          " (" +
          callerEmail +
          ") has no staff record after all 3 lookup attempts",
      );
      return json(
        {
          error: "Caller is not a registered staff member",
          debug: { callerUserId, callerEmail },
        },
        403,
      );
    }

    if (callerStaff.role !== "owner") {
      console.warn(
        "[create-staff] Caller is not an owner (role=" + callerStaff.role + ")",
      );
      return json({ error: "Only owners can create staff members" }, 403);
    }

    if (!callerStaff.laundry_id) {
      console.error("[create-staff] Caller has no laundry_id assigned");
      return json({ error: "Owner laundry not configured" }, 403);
    }

    const body: CreateStaffRequest = await req.json();
    const { full_name, username, pin_hash, pin } = body;

    if (!full_name || !username || !pin_hash || !pin) {
      return json(
        { error: "Missing required fields: full_name, username, pin_hash, pin" },
        400,
      );
    }

    // FIX: PIN karyawan (bukan string hardcode "changeme123") dipakai
    // sebagai password Supabase Auth, supaya loginByPin() di Flutter
    // (yang signInWithPassword pakai PIN asli) bisa berhasil.
    if (pin.length < 4 || pin.length > 6) {
      return json({ error: "PIN harus 4-6 digit" }, 400);
    }

    const staffEmail = username + "@laundry28.com";

    const { data: authUser, error: authError } =
      await supabase.auth.admin.createUser({
        email: staffEmail,
        password: pin,
        email_confirm: true,
      });

    if (authError || !authUser.user) {
      console.error(
        "[create-staff] Failed to create auth user: " +
          (authError?.message ?? "unknown"),
      );
      return json(
        { error: "Failed to create auth account", details: authError?.message },
        500,
      );
    }

    const authUserId = authUser.user.id;
    console.log("[create-staff] Auth user created: " + authUserId);

    const { data: staffRecord, error: staffError } = await supabase
      .from("staff")
      .insert({
        full_name: full_name.trim(),
        username: username.trim().toLowerCase(),
        email: staffEmail,
        role: "employee",
        pin_hash: pin_hash,
        laundry_id: callerStaff.laundry_id,
        auth_user_id: authUserId,
        failed_pin_attempts: 0,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (staffError || !staffRecord) {
      console.error(
        "[create-staff] Failed to create staff record: " +
          (staffError?.message ?? "unknown"),
      );
      await supabase.auth.admin.deleteUser(authUserId);
      return json(
        { error: "Failed to create staff record", details: staffError?.message },
        500,
      );
    }

    console.log(
      "[create-staff] Staff created: id=" +
        staffRecord.id +
        ", name=" +
        staffRecord.full_name,
    );

    return json(
      {
        success: true,
        staff: {
          id: staffRecord.id,
          full_name: staffRecord.full_name,
          username: staffRecord.username,
          email: staffRecord.email,
          role: staffRecord.role,
          laundry_id: staffRecord.laundry_id,
          auth_user_id: staffRecord.auth_user_id,
          created_at: staffRecord.created_at,
        },
      },
      200,
    );
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("[create-staff] Unexpected error: " + errorMessage);
    return json({ error: "Internal server error", details: errorMessage }, 500);
  }
});