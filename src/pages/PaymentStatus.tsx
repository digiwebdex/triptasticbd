import { useEffect, useState } from "react";
import { useParams, useSearchParams, Link } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { CheckCircle2, XCircle, AlertCircle, Loader2 } from "lucide-react";

const API_BASE = import.meta.env.VITE_API_URL || "";

const PaymentStatus = () => {
  const { status = "fail" } = useParams<{ status: string }>();
  const [params] = useSearchParams();
  const tran = params.get("tran");
  const reason = params.get("reason");
  const [session, setSession] = useState<any>(null);
  const [loading, setLoading] = useState(!!tran);

  useEffect(() => {
    if (!tran) return;
    fetch(`${API_BASE}/api/payments/online/session/${encodeURIComponent(tran)}`)
      .then((r) => r.json()).then(setSession).finally(() => setLoading(false));
  }, [tran]);

  const isSuccess = status === "success";
  const isCancel = status === "cancel";
  const Icon = isSuccess ? CheckCircle2 : isCancel ? AlertCircle : XCircle;
  const color = isSuccess ? "text-green-600" : isCancel ? "text-amber-600" : "text-destructive";
  const title = isSuccess ? "Payment Successful" : isCancel ? "Payment Cancelled" : "Payment Failed";

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-muted/30">
      <Card className="max-w-md w-full">
        <CardHeader className="text-center">
          <Icon className={`h-16 w-16 mx-auto ${color}`} />
          <CardTitle className="mt-4">{title}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {loading ? (
            <div className="flex justify-center"><Loader2 className="h-6 w-6 animate-spin" /></div>
          ) : session ? (
            <div className="space-y-2 text-sm">
              <div className="flex justify-between"><span className="text-muted-foreground">Tracking ID</span><span className="font-mono font-semibold">{session.tracking_id}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Amount</span><span className="font-semibold">৳{Number(session.amount).toLocaleString("en-IN")}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Transaction</span><span className="font-mono text-xs">{session.tran_id}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Status</span><span className={`font-semibold uppercase ${color}`}>{session.status}</span></div>
            </div>
          ) : reason ? (
            <p className="text-sm text-center text-muted-foreground">Reason: {reason}</p>
          ) : null}

          <div className="flex gap-2 pt-2">
            <Button asChild variant="outline" className="flex-1"><Link to="/">Home</Link></Button>
            <Button asChild className="flex-1"><Link to="/dashboard">My Bookings</Link></Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default PaymentStatus;
