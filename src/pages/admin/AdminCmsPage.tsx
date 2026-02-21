import { useState } from "react";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import AdminCmsEditor from "@/components/AdminCmsEditor";
import CmsBlogManager from "@/components/admin/CmsBlogManager";
import CmsVersionHistory from "@/components/admin/CmsVersionHistory";

export default function AdminCmsPage() {
  return (
    <div>
      <h2 className="font-heading text-xl font-bold mb-4">Content Management System</h2>
      <Tabs defaultValue="pages">
        <TabsList className="mb-4">
          <TabsTrigger value="pages">Site Content</TabsTrigger>
          <TabsTrigger value="blog">Blog Posts</TabsTrigger>
          <TabsTrigger value="history">Version History</TabsTrigger>
        </TabsList>
        <TabsContent value="pages">
          <AdminCmsEditor />
        </TabsContent>
        <TabsContent value="blog">
          <CmsBlogManager />
        </TabsContent>
        <TabsContent value="history">
          <CmsVersionHistory />
        </TabsContent>
      </Tabs>
    </div>
  );
}
