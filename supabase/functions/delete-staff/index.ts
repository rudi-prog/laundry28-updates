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
  // FIX: tambahkan apikey & x-client-info yang otomatis dikirim
  // supabase.functions.invoke() dari client (perlu untuk web; tidak
  // masalah untuk mobile, tapi lebih aman disamakan dengan create-staff).
  "Access-Control-Allow-Headers":
    "content-type, authorization, apikey, x-client-info",
};

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

interface DeleteStaffRequest {
  staff_id: number;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    const callerJwt = authHeader?.replace("Bearer ", "").trim();

    if (!callerJwt) {
      console.error("[delete-staff] Missing Authorization header");
      return json({ error: "Missing Authorization header" }, 401);
    }

    const { data: callerAuth, error: callerAuthError } = await supabase.auth.getUser(callerJwt);

    if (callerAuthError || !callerAuth.user) {
      console.error("[delete-staff] Invalid caller token: " + (callerAuthError?.message ?? "unknown"));
      return json({ error: "Invalid or expired session" }, 401);
    }

    const callerUserId = callerAuth.user.id;
    const callerEmail = callerAuth.user.email;
    console.log("[delete-staff] Caller user_id=" + callerUserId + ", email=" + callerEmail);

    // Use raw PostgREST API to bypass Supabase JS client issues
    const headers = {
      "apikey": supabaseServiceRoleKey,
      "Authorization": "Bearer " + supabaseServiceRoleKey,
      "Content-Type": "application/json",
    };

    // Try 1: auth_user_id match
    let callerStaff: { id: number; role: string; laundry_id: number | null } | null = null;
    let staffRes = await fetch(
      supabaseUrl + "/rest/v1/staff?auth_user_id=eq." + callerUserId + "&select=id,role,laundry_id",
      { headers }
    );
    if (staffRes.ok) {
      const staffArr = await staffRes.json();
      if (staffArr && staffArr.length > 0) {
        callerStaff = staffArr[0];
        console.log("[delete-staff] Found caller by auth_user_id: id=" + callerStaff.id);
      }
    } else {
      // FIX: log yang jelas kalau PostgREST menolak request (misal
      // service_role belum punya GRANT ke tabel staff) — sebelumnya
      // kasus ini diam-diam ke-treat sama seperti "tidak ketemu".
      console.error(
        "[delete-staff] Query auth_user_id FAILED with status " + staffRes.status + ": " + (await staffRes.text()),
      );
    }

    // Try 2: email match (case-insensitive) - fallback for Google OAuth users
    if (!callerStaff && callerEmail) {
      staffRes = await fetch(
        supabaseUrl + "/rest/v1/staff?email=ilike." + encodeURIComponent(callerEmail.toLowerCase()) + "&select=id,role,laundry_id",
        { headers }
      );
      if (staffRes.ok) {
        const staffArr = await staffRes.json();
        if (staffArr && staffArr.length > 0) {
          callerStaff = staffArr[0];
          console.log("[delete-staff] Found caller by email (ilike): id=" + callerStaff.id);
        }
      } else {
        console.error(
          "[delete-staff] Query email FAILED with status " + staffRes.status + ": " + (await staffRes.text()),
        );
      }
    }

    if (!callerStaff) {
      console.error("[delete-staff] Caller " + callerUserId + " (" + callerEmail + ") has no staff record");
      return json({ error: "Caller is not a registered staff member" }, 403);
    }

    if (callerStaff.role !== "owner") {
      console.warn("[delete-staff] Caller " + callerUserId + " is not an owner (role=" + callerStaff.role + ")");
      return json({ error: "Only owners can delete staff" }, 403);
    }

    if (!callerStaff.laundry_id) {
      console.error("[delete-staff] Caller has no laundry_id assigned");
      return json({ error: "Owner laundry not configured" }, 403);
    }


    // STEP 1: Validate request body
    const body: DeleteStaffRequest = await req.json();
    const { staff_id } = body;

    if (!staff_id || typeof staff_id !== "number") {
      return json({ error: "Missing or invalid staff_id" }, 400);
    }

    // STEP 2: Fetch target staff - must belong to the caller's laundry
    const { data: targetStaff, error: targetError } = await supabase
      .from("staff")
      .select("id, auth_user_id, role, laundry_id, full_name")
      .eq("id", staff_id)
      .maybeSingle();

    if (targetError || !targetStaff) {
      console.error("[delete-staff] Target staff not found: " + (targetError?.message ?? "unknown"));
      return json({ error: "Staff not found" }, 404);
    }

    if (targetStaff.laundry_id !== callerStaff.laundry_id) {
      console.warn("[delete-staff] Caller laundry_id=" + callerStaff.laundry_id + " tried to delete staff from laundry_id=" + targetStaff.laundry_id);
      return json({ error: "Staff does not belong to your laundry" }, 403);
    }

    // Prevent an owner from deleting themself
    if (targetStaff.id === callerStaff.id) {
      return json({ error: "Cannot delete your own account" }, 400);
    }

    console.log("[delete-staff] Deleting staff id=" + staff_id + " (" + targetStaff.full_name + ")");


    // STEP 3: Delete the staff row first
    const { error: deleteRowError } = await supabase
      .from("staff")
      .delete()
      .eq("id", staff_id);

    if (deleteRowError) {
      console.error("[delete-staff] Failed to delete staff row: " + deleteRowError.message);
      return json({
        error: "Failed to delete staff record",
        details: deleteRowError.message,
      }, 500);
    }

    // STEP 4: Delete the auth user (Admin API)
    // FIX: parameter kedua HARUS false (atau dihilangkan) untuk hard
    // delete. Sebelumnya "true" berarti SOFT delete — user tidak
    // benar-benar dihapus, cuma dinonaktifkan, sehingga email
    // (username@laundry28.com) tetap dianggap "terpakai" dan tidak
    // bisa dipakai lagi untuk staff baru. Ini kontradiksi dengan
    // tujuan awal function ini (supaya username bisa dipakai ulang).
    if (targetStaff.auth_user_id) {
      const { error: deleteAuthError } = await supabase.auth.admin.deleteUser(
        targetStaff.auth_user_id,
        false, // hard delete — permanen, email jadi bisa dipakai ulang
      );

      if (deleteAuthError) {
        console.error(
          "[delete-staff] Staff row deleted but auth user cleanup failed for auth_user_id=" + targetStaff.auth_user_id + ": " + deleteAuthError.message
        );
        return json(
          {
            success: true,
            warning: "Staff record deleted, but auth account cleanup failed. Contact admin.",
            details: deleteAuthError.message,
          },
          200
        );
      }
    } else {
      console.warn("[delete-staff] Staff id=" + staff_id + " had no auth_user_id, skipped auth cleanup");
    }

    console.log("[delete-staff] Staff id=" + staff_id + " deleted successfully (row + auth user)");

    return json({ success: true }, 200);
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("[delete-staff] Unexpected error: " + errorMessage);
    return json({ error: "Internal server error", details: errorMessage }, 500);
  }
});