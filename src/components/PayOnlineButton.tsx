import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { CreditCard, Loader2 } from "lucide-react";
import { toast } from "sonner";

interface Props {
  bookingId?: string;
  trackingId?: string;
  dueAmount: number;
  customerName?: string;
  customerPhone?: string;
  customerEmail?: string;
  size?: "sm" | "default" | "lg";
  variant?: "default" | "outline" | "secondary";
  className?: string;
  label?: string;
}

const API_BASE = import.meta.env.VITE_API_URL || "";

export const PayOnlineButton = ({
  bookingId, trackingId, dueAmount, customerName, customerPhone, customerEmail,
  size = "default", variant = "default", className, label = "Pay Online",
}: Props) => {
  const [open, setOpen] = useState(false);
  const [amount, setAmount] = useState<string>(String(dueAmount || 0));
  const [phone, setPhone] = useState(customerPhone || "");
  const [name, setName] = useState(customerName || "");
  const [email, setEmail] = useState(customerEmail || "");
  const [loading, setLoading] = useState(false);

  const handlePay = async () => {
    const amt = Number(amount);
    if (!amt || amt <= 0) return toast.error("Enter a valid amount");
    if (amt > Number(dueAmount) + 0.01) return toast.error(`Max ৳${dueAmount}`);
    if (!phone) return toast.error("Phone number required");

    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/payments/online/initiate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          booking_id: bookingId,
          tracking_id: trackingId,
          amount: amt,
          customer: { name, phone, email },
        }),
      });
      const data = await res.json();
      if (!res.ok || !data.gateway_url) throw new Error(data.error || "Failed to start payment");
      window.location.href = data.gateway_url;
    } catch (e: any) {
      toast.error(e.message);
      setLoading(false);
    }
  };

  if (Number(dueAmount) <= 0) return null;

  return (
    <>
      <Button size={size} variant={variant} className={className} onClick={() => setOpen(true)}>
        <CreditCard className="h-4 w-4 mr-2" /> {label}
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Pay Online</DialogTitle>
            <DialogDescription>
              bKash, Nagad, Rocket, Card — সব accept করি (SSLCommerz secure gateway)।
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3">
            <div>
              <Label>Amount (৳)</Label>
              <Input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} max={dueAmount} />
              <p className="text-xs text-muted-foreground mt-1">Due: ৳{Number(dueAmount).toLocaleString("en-IN")}</p>
            </div>
            <div>
              <Label>Name</Label>
              <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="Customer name" />
            </div>
            <div>
              <Label>Phone *</Label>
              <Input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="01XXXXXXXXX" />
            </div>
            <div>
              <Label>Email</Label>
              <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="optional" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setOpen(false)} disabled={loading}>Cancel</Button>
            <Button onClick={handlePay} disabled={loading}>
              {loading ? <><Loader2 className="h-4 w-4 mr-2 animate-spin" /> Redirecting...</> : `Pay ৳${amount}`}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
};
