import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { ShieldCheck, Smartphone, KeyRound, AlertTriangle, Send, Loader2 } from "lucide-react";
import { toast } from "sonner";

const API_URL = import.meta.env.VITE_API_URL || "/api";

const authHeaders = () => {
  const token = localStorage.getItem("rk_access_token");
  return { Authorization: `Bearer ${token}`, "Content-Type": "application/json" };
};

interface Status {
  sms_enabled: boolean;
  sms_phone: string | null;
  totp_enabled: boolean;
  has_pending_totp: boolean;
}

export default function AdminSecurityPage() {
  const [status, setStatus] = useState<Status | null>(null);
  const [phone, setPhone] = useState("");
  const [totpQr, setTotpQr] = useState<string | null>(null);
  const [totpSecret, setTotpSecret] = useState<string | null>(null);
  const [totpToken, setTotpToken] = useState("");
  const [loading, setLoading] = useState(false);
  const [reminderRunning, setReminderRunning] = useState(false);

  const load = async () => {
    const res = await fetch(`${API_URL}/2fa/status`, { headers: authHeaders() });
    if (res.ok) {
      const data = await res.json();
      setStatus(data);
      if (data.sms_phone) setPhone(data.sms_phone);
    }
  };
  useEffect(() => { load(); }, []);

  const enableSms = async () => {
    if (!phone.trim()) { toast.error("Phone নম্বর দিন"); return; }
    setLoading(true);
    const res = await fetch(`${API_URL}/2fa/sms/enable`, {
      method: "POST", headers: authHeaders(),
      body: JSON.stringify({ phone: phone.trim() }),
    });
    setLoading(false);
    if (res.ok) { toast.success("SMS 2FA enabled"); load(); }
    else toast.error("Enable করতে ব্যর্থ");
  };

  const disableSms = async () => {
    setLoading(true);
    const res = await fetch(`${API_URL}/2fa/sms/disable`, { method: "POST", headers: authHeaders() });
    setLoading(false);
    if (res.ok) { toast.success("SMS 2FA disabled"); load(); }
  };

  const startTotp = async () => {
    setLoading(true);
    const res = await fetch(`${API_URL}/2fa/totp/setup`, { method: "POST", headers: authHeaders() });
    setLoading(false);
    if (res.ok) {
      const d = await res.json();
      setTotpQr(d.qr); setTotpSecret(d.secret);
    } else toast.error("Setup ব্যর্থ");
  };

  const confirmTotp = async () => {
    if (totpToken.length !== 6) { toast.error("6-digit code দিন"); return; }
    setLoading(true);
    const res = await fetch(`${API_URL}/2fa/totp/confirm`, {
      method: "POST", headers: authHeaders(),
      body: JSON.stringify({ token: totpToken }),
    });
    setLoading(false);
    if (res.ok) {
      toast.success("TOTP enabled!"); setTotpQr(null); setTotpSecret(null); setTotpToken(""); load();
    } else toast.error("ভুল code");
  };

  const disableTotp = async () => {
    setLoading(true);
    const res = await fetch(`${API_URL}/2fa/totp/disable`, { method: "POST", headers: authHeaders() });
    setLoading(false);
    if (res.ok) { toast.success("TOTP disabled"); load(); }
  };

  const runDueReminder = async () => {
    setReminderRunning(true);
    const res = await fetch(`${API_URL}/due-reminder/run`, { method: "POST", headers: authHeaders() });
    setReminderRunning(false);
    if (res.ok) {
      const d = await res.json();
      toast.success(`Due reminder: sent=${d.sent}, skipped=${d.skipped}, failed=${d.failed}`);
    } else toast.error("Run করতে ব্যর্থ");
  };

  return (
    <div className="space-y-6 p-4 md:p-6 max-w-4xl">
      <div className="flex items-center gap-3">
        <ShieldCheck className="h-7 w-7 text-primary" />
        <div>
          <h1 className="text-2xl font-bold">Security & Automation</h1>
          <p className="text-sm text-muted-foreground">Admin 2FA এবং auto-reminder settings</p>
        </div>
      </div>

      {/* SMS 2FA */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Smartphone className="h-5 w-5" /> SMS OTP 2FA
            {status?.sms_enabled && <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100">Enabled</Badge>}
          </CardTitle>
          <CardDescription>Login-এ ফোনে 6-digit OTP যাবে। দ্রুত setup, কিন্তু SMS cost লাগে।</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="space-y-2">
            <Label>Phone (e.g. 01XXXXXXXXX)</Label>
            <Input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="01712345678" />
          </div>
          <div className="flex gap-2">
            <Button onClick={enableSms} disabled={loading}>
              {status?.sms_enabled ? "Update Phone" : "Enable SMS 2FA"}
            </Button>
            {status?.sms_enabled && (
              <Button variant="outline" onClick={disableSms} disabled={loading}>Disable</Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* TOTP 2FA */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <KeyRound className="h-5 w-5" /> Authenticator App (TOTP)
            {status?.totp_enabled && <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100">Enabled</Badge>}
          </CardTitle>
          <CardDescription>Google Authenticator / Authy / Microsoft Authenticator — সর্বোচ্চ secure, কোনো SMS cost নেই।</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {!status?.totp_enabled && !totpQr && (
            <Button onClick={startTotp} disabled={loading}>Setup Authenticator App</Button>
          )}
          {totpQr && (
            <div className="space-y-3 p-4 border rounded-md bg-muted/30">
              <p className="text-sm">App-এ এই QR scan করুন:</p>
              <img src={totpQr} alt="TOTP QR" className="bg-white p-2 rounded w-48 h-48" />
              <p className="text-xs text-muted-foreground break-all">
                Manual entry: <code className="bg-background px-1">{totpSecret}</code>
              </p>
              <div className="flex gap-2 items-end">
                <div className="space-y-1 flex-1">
                  <Label>App-এর 6-digit code</Label>
                  <Input value={totpToken} onChange={(e) => setTotpToken(e.target.value.replace(/\D/g, "").slice(0, 6))} maxLength={6} placeholder="123456" />
                </div>
                <Button onClick={confirmTotp} disabled={loading || totpToken.length !== 6}>Confirm & Enable</Button>
              </div>
            </div>
          )}
          {status?.totp_enabled && (
            <Button variant="outline" onClick={disableTotp} disabled={loading}>Disable TOTP</Button>
          )}
        </CardContent>
      </Card>

      {/* Auto Due Reminder */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Send className="h-5 w-5" /> Auto Due Reminder
          </CardTitle>
          <CardDescription>
            প্রতিদিন <strong>09:30 AM (Asia/Dhaka)</strong>-এ স্বয়ংক্রিয়ভাবে SMS reminder পাঠায়:
            due-এর 3 দিন আগে, due-date-এ, এবং 3 ও 7 দিন overdue হলে।
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={runDueReminder} disabled={reminderRunning} variant="secondary">
            {reminderRunning ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <Send className="h-4 w-4 mr-2" />}
            এখনই Run করুন (Test)
          </Button>
          <p className="text-xs text-muted-foreground mt-2">
            <AlertTriangle className="inline h-3 w-3 mr-1" />
            একই (booking + bucket) দিনে দ্বিতীয়বার SMS যাবে না।
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
