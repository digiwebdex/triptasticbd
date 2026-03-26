import { useEffect, useState } from "react";
import { supabase } from "@/lib/api";
import AdminHotelManager from "@/components/AdminHotelManager";

export default function AdminHotelsPage() {
  const [hotels, setHotels] = useState<any[]>([]);

  const fetch = () => supabase.from("hotels").select("*").order("created_at", { ascending: false }).then(({ data }) => setHotels(data || []));
  useEffect(() => { fetch(); }, []);

  return <AdminHotelManager hotels={hotels} onRefresh={fetch} />;
}
