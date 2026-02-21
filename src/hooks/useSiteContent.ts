import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";

export function useSiteContent(sectionKey: string) {
  return useQuery({
    queryKey: ["site_content", sectionKey],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("site_content" as any)
        .select("content")
        .eq("section_key", sectionKey)
        .maybeSingle();
      if (error) throw error;
      return (data as any)?.content || null;
    },
    staleTime: 1000 * 60 * 5,
  });
}

export function useAllSiteContent() {
  return useQuery({
    queryKey: ["site_content", "all"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("site_content" as any)
        .select("*")
        .order("section_key");
      if (error) throw error;
      const map: Record<string, any> = {};
      (data as any[])?.forEach((row: any) => {
        map[row.section_key] = row.content;
      });
      return map;
    },
    staleTime: 1000 * 60 * 5,
  });
}

export function useUpdateSiteContent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ sectionKey, content }: { sectionKey: string; content: any }) => {
      const { data: { session } } = await supabase.auth.getSession();
      const userId = session?.user?.id || null;

      // Save version history before updating
      const { data: current } = await supabase
        .from("site_content" as any)
        .select("content")
        .eq("section_key", sectionKey)
        .maybeSingle();

      if ((current as any)?.content) {
        await supabase.from("cms_versions" as any).insert({
          section_key: sectionKey,
          content: (current as any).content,
          updated_by: userId,
          note: `Auto-saved before update`,
        } as any);
      }

      // Update the content
      const { error } = await supabase
        .from("site_content" as any)
        .update({ content, updated_by: userId } as any)
        .eq("section_key", sectionKey);
      if (error) throw error;
    },
    onSuccess: (_, { sectionKey }) => {
      queryClient.invalidateQueries({ queryKey: ["site_content"] });
      queryClient.invalidateQueries({ queryKey: ["cms_versions"] });
      toast.success(`${sectionKey} content updated`);
    },
    onError: (error: any) => {
      toast.error(error.message || "Failed to update content");
    },
  });
}

export function useCmsVersions(sectionKey?: string) {
  return useQuery({
    queryKey: ["cms_versions", sectionKey],
    queryFn: async () => {
      let query = supabase.from("cms_versions" as any).select("*").order("created_at", { ascending: false }).limit(50);
      if (sectionKey) {
        query = query.eq("section_key", sectionKey);
      }
      const { data, error } = await query;
      if (error) throw error;
      return (data as any[]) || [];
    },
    staleTime: 1000 * 60 * 2,
  });
}
