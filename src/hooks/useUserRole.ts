import { useEffect, useState } from "react";
import { auth as api } from "@/lib/api";

export type AppRole = "admin" | "accountant" | "booking" | "cms" | "viewer" | null;

export function useUserRole() {
  const [role, setRole] = useState<AppRole>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchRole = async () => {
      const { data: { session } } = await api.getSession();
      if (!session) { setLoading(false); return; }

      // Get user from local storage which includes roles from login
      const { data: { user } } = await api.getUser();
      const roles: string[] = user?.roles || [];

      if (roles.includes("admin")) setRole("admin");
      else if (roles.includes("accountant")) setRole("accountant");
      else if (roles.includes("booking")) setRole("booking");
      else if (roles.includes("cms")) setRole("cms");
      else if (roles.includes("viewer")) setRole("viewer");

      setLoading(false);
    };
    fetchRole();
  }, []);

  return { role, loading };
}
