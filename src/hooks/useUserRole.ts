import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

export type AppRole = "admin" | "manager" | "accountant" | "staff" | "viewer" | null;

export function useUserRole() {
  const [role, setRole] = useState<AppRole>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchRole = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { setLoading(false); return; }

      const { data } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", session.user.id);

      if (data && data.length > 0) {
        // Priority: admin > manager > staff
        const roles = data.map((r: any) => r.role as string);
        if (roles.includes("admin")) setRole("admin");
        else if (roles.includes("manager")) setRole("manager");
        else if (roles.includes("accountant")) setRole("accountant");
        else if (roles.includes("staff")) setRole("staff");
        else if (roles.includes("viewer")) setRole("viewer");
      }
      setLoading(false);
    };
    fetchRole();
  }, []);

  return { role, loading };
}
