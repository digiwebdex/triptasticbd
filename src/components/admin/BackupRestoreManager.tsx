import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { Database, Download, Upload, Trash2, RefreshCw, Shield, AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

interface BackupFile {
  name: string;
  id: string;
  created_at: string;
  metadata: Record<string, any> | null;
}

export default function BackupRestoreManager() {
  const [backups, setBackups] = useState<BackupFile[]>([]);
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);
  const [restoring, setRestoring] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);

  const fetchBackups = async () => {
    setLoading(true);
    const { data, error } = await supabase.storage.from("site-backups").list("", {
      sortBy: { column: "created_at", order: "desc" },
    });
    if (error) { toast.error("ব্যাকআপ লোড ব্যর্থ"); console.error(error); }
    else setBackups((data || []).filter(f => f.name.endsWith(".json")) as BackupFile[]);
    setLoading(false);
  };

  useEffect(() => { fetchBackups(); }, []);

  const createBackup = async () => {
    setCreating(true);
    setProgress(10);
    try {
      const interval = setInterval(() => setProgress(p => Math.min(p + 8, 90)), 500);

      const { data, error } = await supabase.functions.invoke("site-backup");
      clearInterval(interval);

      if (error) throw error;
      if (data?.error) throw new Error(data.error);

      setProgress(100);
      toast.success(`ব্যাকআপ সফল! ${data.stats?.length || 0} টেবিল সংরক্ষিত`);
      fetchBackups();
    } catch (e: any) {
      toast.error(`ব্যাকআপ ব্যর্থ: ${e.message}`);
    } finally {
      setCreating(false);
      setTimeout(() => setProgress(0), 1500);
    }
  };

  const restoreBackup = async (fileName: string, mode: "full" | "merge") => {
    setRestoring(fileName);
    setProgress(10);
    try {
      const interval = setInterval(() => setProgress(p => Math.min(p + 5, 90)), 800);

      const { data, error } = await supabase.functions.invoke("site-restore", {
        body: { fileName, mode },
      });
      clearInterval(interval);

      if (error) throw error;
      if (data?.error) throw new Error(data.error);

      setProgress(100);
      const restored = data.results?.filter((r: any) => r.status === "restored").length || 0;
      toast.success(`রিস্টোর সফল! ${restored} টেবিল পুনরুদ্ধার করা হয়েছে`);
    } catch (e: any) {
      toast.error(`রিস্টোর ব্যর্থ: ${e.message}`);
    } finally {
      setRestoring(null);
      setTimeout(() => setProgress(0), 1500);
    }
  };

  const deleteBackup = async (fileName: string) => {
    const { error } = await supabase.storage.from("site-backups").remove([fileName]);
    if (error) { toast.error("ডিলিট ব্যর্থ"); return; }
    toast.success("ব্যাকআপ ডিলিট হয়েছে");
    fetchBackups();
  };

  const downloadBackup = async (fileName: string) => {
    const { data, error } = await supabase.storage.from("site-backups").download(fileName);
    if (error || !data) { toast.error("ডাউনলোড ব্যর্থ"); return; }
    const url = URL.createObjectURL(data);
    const a = document.createElement("a");
    a.href = url;
    a.download = fileName;
    a.click();
    URL.revokeObjectURL(url);
  };

  const formatSize = (bytes: number) => {
    if (!bytes || bytes <= 0) return "N/A";
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / 1048576).toFixed(1)} MB`;
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleString("bn-BD", {
      year: "numeric", month: "short", day: "numeric",
      hour: "2-digit", minute: "2-digit",
    });
  };

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Database className="h-5 w-5 text-primary" />
          <h3 className="font-heading text-lg font-bold">ব্যাকআপ ও রিস্টোর</h3>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={fetchBackups} disabled={loading}>
            <RefreshCw className={`h-4 w-4 mr-1 ${loading ? "animate-spin" : ""}`} /> রিফ্রেশ
          </Button>
          <Button size="sm" onClick={createBackup} disabled={creating}>
            {creating ? (
              <><RefreshCw className="h-4 w-4 mr-1 animate-spin" /> ব্যাকআপ চলছে...</>
            ) : (
              <><Shield className="h-4 w-4 mr-1" /> নতুন ব্যাকআপ</>
            )}
          </Button>
        </div>
      </div>

      {/* Progress */}
      {progress > 0 && (
        <div className="space-y-1">
          <Progress value={progress} className="h-2" />
          <p className="text-xs text-muted-foreground text-center">
            {creating ? "ব্যাকআপ তৈরি হচ্ছে..." : restoring ? "রিস্টোর চলছে..." : "সম্পন্ন!"}
          </p>
        </div>
      )}

      {/* Warning */}
      <div className="bg-destructive/10 border border-destructive/30 rounded-lg p-3 flex items-start gap-2 text-sm text-destructive">
        <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
        <p><strong>সতর্কতা:</strong> "Full Restore" সমস্ত ডেটা মুছে নতুন করে ব্যাকআপ থেকে লোড করবে। "Merge" শুধুমাত্র নতুন/আপডেট ডেটা যোগ করবে।</p>
      </div>

      {/* Backup List */}
      <div className="space-y-2">
        {backups.length === 0 && !loading && (
          <p className="text-center text-muted-foreground py-12">কোনো ব্যাকআপ নেই। উপরে "নতুন ব্যাকআপ" বাটনে ক্লিক করুন।</p>
        )}
        {loading && <p className="text-center text-muted-foreground py-8">লোড হচ্ছে...</p>}

        {backups.map((b) => (
          <div key={b.name} className="bg-card border border-border rounded-lg p-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="min-w-0">
                <p className="font-medium text-sm truncate">{b.name}</p>
                <p className="text-xs text-muted-foreground mt-0.5">
                  {formatDate(b.created_at)} • {formatSize(b.metadata?.size)}
                </p>
              </div>
              <div className="flex items-center gap-2 shrink-0 flex-wrap">
                {/* Download */}
                <Button variant="outline" size="sm" onClick={() => downloadBackup(b.name)}>
                  <Download className="h-3.5 w-3.5 mr-1" /> ডাউনলোড
                </Button>

                {/* Merge Restore */}
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button variant="outline" size="sm" disabled={!!restoring}>
                      <Upload className="h-3.5 w-3.5 mr-1" /> Merge
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Merge রিস্টোর নিশ্চিত করুন</AlertDialogTitle>
                      <AlertDialogDescription>
                        এটি বিদ্যমান ডেটার সাথে ব্যাকআপের ডেটা মার্জ করবে। কোনো ডেটা মুছে যাবে না, শুধু আপডেট/যোগ হবে।
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>বাতিল</AlertDialogCancel>
                      <AlertDialogAction onClick={() => restoreBackup(b.name, "merge")}>
                        Merge রিস্টোর
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>

                {/* Full Restore */}
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button variant="destructive" size="sm" disabled={!!restoring}>
                      <Upload className="h-3.5 w-3.5 mr-1" /> Full Restore
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>⚠️ Full Restore নিশ্চিত করুন</AlertDialogTitle>
                      <AlertDialogDescription>
                        <strong className="text-destructive">এটি সমস্ত বর্তমান ডেটা মুছে ফেলবে</strong> এবং ব্যাকআপ থেকে নতুন করে লোড করবে। এই কাজটি undo করা যাবে না!
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>বাতিল</AlertDialogCancel>
                      <AlertDialogAction
                        className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                        onClick={() => restoreBackup(b.name, "full")}
                      >
                        হ্যাঁ, Full Restore করুন
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>

                {/* Delete */}
                <AlertDialog>
                  <AlertDialogTrigger asChild>
                    <Button variant="ghost" size="sm" className="text-destructive hover:text-destructive">
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>ব্যাকআপ ডিলিট করুন</AlertDialogTitle>
                      <AlertDialogDescription>
                        "{b.name}" ব্যাকআপটি স্থায়ীভাবে মুছে ফেলা হবে।
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>বাতিল</AlertDialogCancel>
                      <AlertDialogAction
                        className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                        onClick={() => deleteBackup(b.name)}
                      >
                        ডিলিট
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
