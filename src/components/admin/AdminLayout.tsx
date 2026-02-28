import { createContext, useContext } from "react";
import { useEffect, useState } from "react";
import { useNavigate, Outlet } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { useSessionTimeout } from "@/hooks/useSessionTimeout";
import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AdminSidebar } from "./AdminSidebar";
import { Eye } from "lucide-react";
import type { AppRole } from "@/hooks/useUserRole";

// Role context so child components can access the current admin role
const AdminRoleContext = createContext<AppRole>(null);
export const useAdminRole = () => useContext(AdminRoleContext);
export const useIsViewer = () => useContext(AdminRoleContext) === "viewer";
/** Only admin, manager, accountant can modify financial data */
export const useCanModifyFinancials = () => {
  const role = useContext(AdminRoleContext);
  return role === "admin" || role === "manager" || role === "accountant";
};

export default function AdminLayout() {
  useSessionTimeout();
  const navigate = useNavigate();
  const [role, setRole] = useState<AppRole>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAccess = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { navigate("/auth"); return; }

      const { data } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", session.user.id);

      if (!data || data.length === 0) {
        toast.error("Access denied");
        navigate("/dashboard");
        return;
      }

      const roles = data.map((r: any) => r.role as string);
      if (roles.includes("admin")) setRole("admin");
      else if (roles.includes("manager")) setRole("manager");
      else if (roles.includes("accountant")) setRole("accountant");
      else if (roles.includes("staff")) setRole("staff");
      else if (roles.includes("viewer")) setRole("viewer");
      else { toast.error("Access denied"); navigate("/dashboard"); return; }

      setLoading(false);
    };
    checkAccess();
  }, [navigate]);

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center text-muted-foreground">
        Loading...
      </div>
    );
  }

  return (
    <AdminRoleContext.Provider value={role}>
      <SidebarProvider>
        <div className="min-h-screen flex w-full">
          <AdminSidebar role={role} />
          <main className="flex-1 flex flex-col min-w-0">
            <header className="h-14 border-b border-border flex items-center px-4 sticky top-0 bg-background z-40">
              <SidebarTrigger />
              <span className="ml-auto text-xs text-muted-foreground capitalize bg-primary/10 text-primary px-2 py-0.5 rounded-full font-semibold">{role}</span>
            </header>
            {role === "viewer" && (
              <div className="bg-amber-500/10 border-b border-amber-500/30 px-4 py-2 flex items-center gap-2 text-amber-700 text-sm">
                <Eye className="h-4 w-4" />
                <span className="font-medium">Read-Only Mode</span> — আপনি শুধুমাত্র দেখতে পারবেন, কোনো পরিবর্তন করতে পারবেন না।
              </div>
            )}
            <div className="flex-1 p-6 overflow-auto">
              <Outlet />
            </div>
          </main>
        </div>
      </SidebarProvider>
    </AdminRoleContext.Provider>
  );
}
