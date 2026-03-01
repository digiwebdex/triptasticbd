import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  ArrowLeft, Users, FileText, CreditCard, TrendingUp, TrendingDown,
  Phone, MapPin, CalendarDays, Hash,
} from "lucide-react";
import { format } from "date-fns";

const fmt = (n: number) => `৳${Number(n || 0).toLocaleString()}`;

export default function AdminMoallemProfilePage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [moallem, setMoallem] = useState<any>(null);
  const [bookings, setBookings] = useState<any[]>([]);
  const [payments, setPayments] = useState<any[]>([]);
  const [expenses, setExpenses] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    const load = async () => {
      setLoading(true);

      // Load moallem details
      const { data: m } = await supabase
        .from("moallems")
        .select("*")
        .eq("id", id)
        .maybeSingle();
      setMoallem(m);

      // Load bookings linked to this moallem
      const { data: bks } = await supabase
        .from("bookings")
        .select("*, packages(name, type, price)")
        .eq("moallem_id", id)
        .order("created_at", { ascending: false });
      setBookings(bks || []);

      // Load payments for these bookings
      const bookingIds = (bks || []).map((b: any) => b.id);
      if (bookingIds.length > 0) {
        const { data: pays } = await supabase
          .from("payments")
          .select("*")
          .in("booking_id", bookingIds)
          .order("created_at", { ascending: false });
        setPayments(pays || []);

        const { data: exps } = await supabase
          .from("expenses")
          .select("*")
          .in("booking_id", bookingIds)
          .order("date", { ascending: false });
        setExpenses(exps || []);
      } else {
        setPayments([]);
        setExpenses([]);
      }

      setLoading(false);
    };
    load();
  }, [id]);

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!moallem) {
    return (
      <div className="text-center py-20 text-muted-foreground">
        মোয়াল্লেম পাওয়া যায়নি
      </div>
    );
  }

  // Calculate stats
  const totalHajji = bookings.reduce((s, b) => s + Number(b.num_travelers || 0), 0);
  const totalBookings = bookings.length;
  const totalPackageAmount = bookings.reduce((s, b) => s + Number(b.total_amount || 0), 0);
  const totalPaid = bookings.reduce((s, b) => s + Number(b.paid_amount || 0), 0);
  const totalDue = bookings.reduce((s, b) => s + Number(b.due_amount || 0), 0);
  const totalExpenses = expenses.reduce((s, e) => s + Number(e.amount || 0), 0);
  const profit = totalPaid - totalExpenses;

  // Unique customers (hajji list)
  const hajjiMap = new Map<string, any>();
  bookings.forEach((b) => {
    const key = b.guest_phone || b.guest_name || b.id;
    if (!hajjiMap.has(key)) {
      hajjiMap.set(key, {
        name: b.guest_name || "Unknown",
        phone: b.guest_phone || "—",
        passport: b.guest_passport || "—",
        travelers: b.num_travelers,
        bookingCount: 1,
        totalAmount: Number(b.total_amount || 0),
        paidAmount: Number(b.paid_amount || 0),
      });
    } else {
      const existing = hajjiMap.get(key);
      existing.travelers += b.num_travelers;
      existing.bookingCount += 1;
      existing.totalAmount += Number(b.total_amount || 0);
      existing.paidAmount += Number(b.paid_amount || 0);
    }
  });
  const hajjiList = Array.from(hajjiMap.values());

  const completedPayments = payments.filter((p) => p.status === "completed");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => navigate("/admin/moallems")} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-foreground">{moallem.name}</h1>
          <p className="text-sm text-muted-foreground">মোয়াল্লেম প্রোফাইল ড্যাশবোর্ড</p>
        </div>
        <Badge variant={moallem.status === "active" ? "default" : "secondary"} className="text-sm">
          {moallem.status === "active" ? "সক্রিয়" : "নিষ্ক্রিয়"}
        </Badge>
      </div>

      {/* Moallem Info */}
      <Card>
        <CardContent className="pt-5">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
            <div className="flex items-center gap-2">
              <Phone className="h-4 w-4 text-muted-foreground" />
              <span>{moallem.phone || "—"}</span>
            </div>
            <div className="flex items-center gap-2">
              <MapPin className="h-4 w-4 text-muted-foreground" />
              <span>{moallem.address || "—"}</span>
            </div>
            <div className="flex items-center gap-2">
              <Hash className="h-4 w-4 text-muted-foreground" />
              <span>NID: {moallem.nid_number || "—"}</span>
            </div>
            <div className="flex items-center gap-2">
              <CalendarDays className="h-4 w-4 text-muted-foreground" />
              <span>চুক্তি: {moallem.contract_date || "—"}</span>
            </div>
          </div>
          {moallem.notes && <p className="text-sm text-muted-foreground mt-3 border-t border-border pt-3">{moallem.notes}</p>}
        </CardContent>
      </Card>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
        <Card>
          <CardContent className="pt-4 pb-4 text-center">
            <Users className="h-5 w-5 mx-auto text-primary mb-1" />
            <p className="text-2xl font-bold text-foreground">{totalHajji}</p>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wide">মোট হাজী</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4 text-center">
            <FileText className="h-5 w-5 mx-auto text-primary mb-1" />
            <p className="text-2xl font-bold text-foreground">{totalBookings}</p>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wide">মোট বুকিং</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4 text-center">
            <CreditCard className="h-5 w-5 mx-auto text-primary mb-1" />
            <p className="text-xl font-bold text-foreground">{fmt(totalPackageAmount)}</p>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wide">মোট প্যাকেজ মূল্য</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4 text-center">
            <TrendingUp className="h-5 w-5 mx-auto text-emerald-500 mb-1" />
            <p className="text-xl font-bold text-emerald-500">{fmt(totalPaid)}</p>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wide">মোট পরিশোধিত</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4 text-center">
            <TrendingDown className="h-5 w-5 mx-auto text-destructive mb-1" />
            <p className="text-xl font-bold text-destructive">{fmt(totalDue)}</p>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wide">মোট বকেয়া</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4 text-center">
            {profit >= 0 ? <TrendingUp className="h-5 w-5 mx-auto text-emerald-500 mb-1" /> : <TrendingDown className="h-5 w-5 mx-auto text-destructive mb-1" />}
            <p className={`text-xl font-bold ${profit >= 0 ? "text-emerald-500" : "text-destructive"}`}>{fmt(profit)}</p>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wide">লাভ</p>
          </CardContent>
        </Card>
      </div>

      {/* Hajji List */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <Users className="h-4 w-4 text-primary" /> হাজী তালিকা ({hajjiList.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {hajjiList.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-6">কোনো হাজী পাওয়া যায়নি</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left text-muted-foreground text-xs">
                    <th className="pb-2 pr-3">নাম</th>
                    <th className="pb-2 pr-3">ফোন</th>
                    <th className="pb-2 pr-3">পাসপোর্ট</th>
                    <th className="pb-2 pr-3">যাত্রী</th>
                    <th className="pb-2 pr-3">মোট</th>
                    <th className="pb-2">পরিশোধিত</th>
                  </tr>
                </thead>
                <tbody>
                  {hajjiList.map((h, i) => (
                    <tr key={i} className="border-b border-border/30">
                      <td className="py-2 pr-3 font-medium">{h.name}</td>
                      <td className="py-2 pr-3">{h.phone}</td>
                      <td className="py-2 pr-3">{h.passport}</td>
                      <td className="py-2 pr-3">{h.travelers}</td>
                      <td className="py-2 pr-3">{fmt(h.totalAmount)}</td>
                      <td className="py-2 text-emerald-500 font-medium">{fmt(h.paidAmount)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Bookings List */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <FileText className="h-4 w-4 text-primary" /> বুকিং তালিকা ({bookings.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {bookings.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-6">কোনো বুকিং পাওয়া যায়নি</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left text-muted-foreground text-xs">
                    <th className="pb-2 pr-3">ট্র্যাকিং</th>
                    <th className="pb-2 pr-3">কাস্টমার</th>
                    <th className="pb-2 pr-3">প্যাকেজ</th>
                    <th className="pb-2 pr-3">যাত্রী</th>
                    <th className="pb-2 pr-3">মোট</th>
                    <th className="pb-2 pr-3">পরিশোধিত</th>
                    <th className="pb-2 pr-3">বকেয়া</th>
                    <th className="pb-2 pr-3">স্ট্যাটাস</th>
                    <th className="pb-2">তারিখ</th>
                  </tr>
                </thead>
                <tbody>
                  {bookings.map((b) => (
                    <tr
                      key={b.id}
                      className="border-b border-border/30 cursor-pointer hover:bg-muted/30 transition-colors"
                      onClick={() => navigate(`/admin/bookings`)}
                    >
                      <td className="py-2 pr-3 font-mono text-primary font-medium text-xs">{b.tracking_id}</td>
                      <td className="py-2 pr-3">{b.guest_name || "—"}</td>
                      <td className="py-2 pr-3">{b.packages?.name || "—"}</td>
                      <td className="py-2 pr-3">{b.num_travelers}</td>
                      <td className="py-2 pr-3 font-medium">{fmt(b.total_amount)}</td>
                      <td className="py-2 pr-3 text-emerald-500">{fmt(b.paid_amount)}</td>
                      <td className="py-2 pr-3 text-destructive">{fmt(b.due_amount)}</td>
                      <td className="py-2 pr-3">
                        <Badge
                          variant={b.status === "completed" ? "default" : "secondary"}
                          className="text-[10px] capitalize"
                        >
                          {b.status}
                        </Badge>
                      </td>
                      <td className="py-2 text-xs text-muted-foreground">
                        {format(new Date(b.created_at), "dd MMM yyyy")}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Payment History */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <CreditCard className="h-4 w-4 text-primary" /> পেমেন্ট হিস্ট্রি ({completedPayments.length}/{payments.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {payments.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-6">কোনো পেমেন্ট পাওয়া যায়নি</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left text-muted-foreground text-xs">
                    <th className="pb-2 pr-3">#</th>
                    <th className="pb-2 pr-3">পরিমাণ</th>
                    <th className="pb-2 pr-3">পদ্ধতি</th>
                    <th className="pb-2 pr-3">নির্ধারিত তারিখ</th>
                    <th className="pb-2 pr-3">পরিশোধের তারিখ</th>
                    <th className="pb-2">স্ট্যাটাস</th>
                  </tr>
                </thead>
                <tbody>
                  {payments.map((p) => (
                    <tr key={p.id} className="border-b border-border/30">
                      <td className="py-2 pr-3 font-medium">{p.installment_number || "—"}</td>
                      <td className="py-2 pr-3 font-medium">{fmt(p.amount)}</td>
                      <td className="py-2 pr-3 capitalize">{p.payment_method || "—"}</td>
                      <td className="py-2 pr-3 text-xs">{p.due_date ? format(new Date(p.due_date), "dd MMM yyyy") : "—"}</td>
                      <td className="py-2 pr-3 text-xs">{p.paid_at ? format(new Date(p.paid_at), "dd MMM yyyy") : "—"}</td>
                      <td className="py-2">
                        <Badge variant={p.status === "completed" ? "default" : "secondary"} className="text-[10px] capitalize">
                          {p.status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Financial Summary */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            <TrendingUp className="h-4 w-4 text-primary" /> আর্থিক সারসংক্ষেপ
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div className="bg-secondary/50 rounded-lg p-4">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">মোট প্যাকেজ মূল্য</p>
              <p className="font-heading font-bold text-lg text-foreground">{fmt(totalPackageAmount)}</p>
            </div>
            <div className="bg-secondary/50 rounded-lg p-4">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">মোট আয় (পেমেন্ট)</p>
              <p className="font-heading font-bold text-lg text-emerald-500">{fmt(totalPaid)}</p>
            </div>
            <div className="bg-secondary/50 rounded-lg p-4">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">মোট খরচ</p>
              <p className="font-heading font-bold text-lg text-destructive">{fmt(totalExpenses)}</p>
            </div>
            <div className="bg-secondary/50 rounded-lg p-4">
              <p className="text-[10px] text-muted-foreground uppercase tracking-wide mb-1">নিট লাভ</p>
              <p className={`font-heading font-bold text-lg ${profit >= 0 ? "text-emerald-500" : "text-destructive"}`}>
                {fmt(profit)}
              </p>
            </div>
          </div>
          <div className="mt-4 grid grid-cols-3 gap-4 text-center text-sm">
            <div>
              <p className="text-muted-foreground text-xs">সংগ্রহের হার</p>
              <p className="font-bold text-foreground">
                {totalPackageAmount > 0 ? `${((totalPaid / totalPackageAmount) * 100).toFixed(1)}%` : "0%"}
              </p>
            </div>
            <div>
              <p className="text-muted-foreground text-xs">গড় বুকিং মূল্য</p>
              <p className="font-bold text-foreground">
                {totalBookings > 0 ? fmt(totalPackageAmount / totalBookings) : "৳0"}
              </p>
            </div>
            <div>
              <p className="text-muted-foreground text-xs">প্রতি হাজী গড়</p>
              <p className="font-bold text-foreground">
                {totalHajji > 0 ? fmt(totalPackageAmount / totalHajji) : "৳0"}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
