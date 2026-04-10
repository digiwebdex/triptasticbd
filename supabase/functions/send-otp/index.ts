import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { phone, action, code } = body;

    if (!phone || typeof phone !== "string" || phone.length < 10 || phone.length > 15) {
      return new Response(JSON.stringify({ error: "Invalid phone number" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const sanitizedPhone = phone.replace(/[^\d+]/g, "");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    if (action === "send") {
      // Check if there's a profile or guest booking with this phone
      const { data: profileCheck } = await supabase
        .from("profiles")
        .select("user_id")
        .eq("phone", sanitizedPhone)
        .limit(1)
        .maybeSingle();

      const { data: bookingCheck } = await supabase
        .from("bookings")
        .select("id")
        .eq("guest_phone", sanitizedPhone)
        .limit(1)
        .maybeSingle();

      if (!profileCheck && !bookingCheck) {
        return new Response(JSON.stringify({ error: "এই নম্বরে কোনো বুকিং পাওয়া যায়নি। আগে বুকিং করুন।" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Rate limit: max 3 OTPs per phone in last 5 minutes
      const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
      const { count } = await supabase
        .from("otp_codes")
        .select("*", { count: "exact", head: true })
        .eq("phone", sanitizedPhone)
        .gte("created_at", fiveMinAgo);

      if ((count || 0) >= 3) {
        return new Response(JSON.stringify({ error: "অনেক বেশি OTP অনুরোধ। ৫ মিনিট অপেক্ষা করুন।" }), {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const otpCode = String(Math.floor(100000 + Math.random() * 900000));
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

      await supabase.from("otp_codes").insert({
        phone: sanitizedPhone,
        code: otpCode,
        expires_at: expiresAt,
      });

      // Send SMS
      const smsApiKey = Deno.env.get("BULKSMSBD_API_KEY");
      const smsSenderId = Deno.env.get("BULKSMSBD_SENDER_ID");

      if (!smsApiKey) {
        return new Response(JSON.stringify({ error: "SMS service not configured" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Ensure phone has 88 country code for BulkSMSBD
      let smsNumber = sanitizedPhone;
      if (smsNumber.startsWith("0")) {
        smsNumber = "88" + smsNumber;
      } else if (!smsNumber.startsWith("88")) {
        smsNumber = "88" + smsNumber;
      }

      const message = `Manasik Travel Hub OTP is ${otpCode}`;
      const smsUrl = `http://bulksmsbd.net/api/smsapi?api_key=${encodeURIComponent(smsApiKey)}&type=text&number=${encodeURIComponent(smsNumber)}&senderid=${encodeURIComponent(smsSenderId || "")}&message=${encodeURIComponent(message)}`;

      const smsRes = await fetch(smsUrl);
      console.log("SMS result:", await smsRes.text());

      return new Response(JSON.stringify({ success: true, message: "OTP sent successfully" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    } else if (action === "verify") {
      if (!code || typeof code !== "string" || code.length !== 6) {
        return new Response(JSON.stringify({ error: "Invalid OTP code" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Find valid OTP
      const { data: otpRecord } = await supabase
        .from("otp_codes")
        .select("*")
        .eq("phone", sanitizedPhone)
        .eq("code", code)
        .eq("verified", false)
        .gte("expires_at", new Date().toISOString())
        .order("created_at", { ascending: false })
        .limit(1)
        .single();

      if (!otpRecord) {
        return new Response(JSON.stringify({ error: "ভুল বা মেয়াদোত্তীর্ণ OTP" }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Mark as verified
      await supabase.from("otp_codes").update({ verified: true }).eq("id", otpRecord.id);

      // Find user by phone in profiles
      const { data: profile } = await supabase
        .from("profiles")
        .select("user_id")
        .eq("phone", sanitizedPhone)
        .maybeSingle();

      let userId = profile?.user_id;

      // If no profile found, auto-create auth user from guest booking data
      if (!userId) {
        // Find the latest guest booking with this phone
        const { data: guestBooking } = await supabase
          .from("bookings")
          .select("id, guest_name, guest_phone, guest_email, guest_address, guest_passport")
          .eq("guest_phone", sanitizedPhone)
          .order("created_at", { ascending: false })
          .limit(1)
          .single();

        if (!guestBooking) {
          return new Response(JSON.stringify({ error: "এই নম্বরে কোনো অ্যাকাউন্ট বা বুকিং পাওয়া যায়নি।" }), {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        // Create auth user with a random password (they'll use OTP to login)
        const tempEmail = `${sanitizedPhone.replace(/\+/g, "")}@phone.manasiktravelhub.com`;
        const tempPassword = crypto.randomUUID() + "Aa1!";

        const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
          email: guestBooking.guest_email || tempEmail,
          password: tempPassword,
          email_confirm: true,
          user_metadata: {
            full_name: guestBooking.guest_name || "",
            phone: sanitizedPhone,
          },
        });

        if (createError) {
          console.error("User creation error:", createError);
          // If email already exists, try to find the user
          if (createError.message?.includes("already") || createError.message?.includes("exists")) {
            const { data: existingUsers } = await supabase.auth.admin.listUsers();
            const existingUser = existingUsers?.users?.find(
              (u) => u.email === (guestBooking.guest_email || tempEmail)
            );
            if (existingUser) {
              userId = existingUser.id;
              // Update profile phone if needed
              await supabase.from("profiles").upsert({
                user_id: existingUser.id,
                phone: sanitizedPhone,
                full_name: guestBooking.guest_name || existingUser.user_metadata?.full_name || "",
              }, { onConflict: "user_id" });
            } else {
              return new Response(JSON.stringify({ error: "অ্যাকাউন্ট তৈরি করতে সমস্যা হয়েছে।" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
              });
            }
          } else {
            return new Response(JSON.stringify({ error: "অ্যাকাউন্ট তৈরি করতে সমস্যা হয়েছে।" }), {
              status: 500,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
          }
        } else if (newUser?.user) {
          userId = newUser.user.id;

          // Create profile
          await supabase.from("profiles").insert({
            user_id: newUser.user.id,
            full_name: guestBooking.guest_name || "",
            phone: sanitizedPhone,
            email: guestBooking.guest_email || null,
            address: guestBooking.guest_address || null,
            passport_number: guestBooking.guest_passport || null,
          });

          // Assign 'user' role
          await supabase.from("user_roles").insert({
            user_id: newUser.user.id,
            role: "user",
          });
        }

        // Link all guest bookings with this phone to the new user
        if (userId) {
          await supabase
            .from("bookings")
            .update({ user_id: userId })
            .eq("guest_phone", sanitizedPhone)
            .is("user_id", null);

          // Also link payments
          const { data: userBookings } = await supabase
            .from("bookings")
            .select("id")
            .eq("user_id", userId);

          if (userBookings?.length) {
            const bookingIds = userBookings.map((b) => b.id);
            await supabase
              .from("payments")
              .update({ user_id: userId })
              .in("booking_id", bookingIds)
              .eq("user_id", "00000000-0000-0000-0000-000000000000");
          }
        }
      }

      if (!userId) {
        return new Response(JSON.stringify({ error: "Authentication failed" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Get user email for magic link
      const { data: authUser } = await supabase.auth.admin.getUserById(userId);

      if (!authUser?.user?.email) {
        return new Response(JSON.stringify({ error: "User account issue. Please contact support." }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Generate magic link tokens
      const { data: magicLink, error: magicError } = await supabase.auth.admin.generateLink({
        type: "magiclink",
        email: authUser.user.email,
      });

      if (magicError) {
        console.error("Magic link error:", magicError);
        return new Response(JSON.stringify({ error: "Authentication failed" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({
        success: true,
        access_token: magicLink.properties?.access_token,
        refresh_token: magicLink.properties?.refresh_token,
        user_id: userId,
      }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Invalid action. Use 'send' or 'verify'." }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("OTP error:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
