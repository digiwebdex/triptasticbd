import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer,
} from "recharts";
import {
  TrendingUp, TrendingDown, DollarSign, Package,
  Users, Wallet, FileText, CreditCard, ArrowUpRight, ArrowDownRight, UserCheck,
} from "lucide-react";
import { format, startOfMonth, subMonths } from "date-fns";

interface Props {
  bookings: any[];
  payments: any[];
  expenses?: any[];
  accounts?: any[];
  financialSummary?: any;
  moallemPayments?: any[];
  supplierPayments?: any[];
  commissionPayments?: any[];
  moallems?: any[];
  supplierAgents?: any[];
  onMarkPaid: (id: string) => void;
}

const fmt = (n: number) => `৳${n.toLocaleString()}`;
const ttStyle = { backgroundColor: "hsl(220, 18%, 14%)", border: "1px solid hsl(220, 15%, 20%)", borderRadius: "8px", color: "hsl(40, 20%, 92%)", fontSize: "12px" };

const AdminDashboardCharts = ({
  bookings, payments, expenses = [], accounts = [], financialSummary,
  moallemPayments = [], supplierPayments = [], commissionPayments = [],
  moallems = [], supplierAgents = [], onMarkPaid
}: Props) => {
  const navigate = useNavigate();

  // ── KPIs ──
  const totalSales = bookings.reduce((s, b) => s + Number(b.total_amount || 0), 0);
  const totalHajji = bookings.reduce((s, b) => s + Number(b.num_travelers || 0), 0);
  const totalIncome = financialSummary ? Number(financialSummary.total_income) : payments.filter(p => p.status === "completed").reduce((s, p) => s + Number(p.amount), 0);
  const totalExpensesPaid = financialSummary ? Number(financialSummary.total_expense) : expenses.reduce((s, e) => s + Number(e.amount), 0);
  const netProfit = financialSummary ? Number(financialSummary.net_profit) : totalIncome - totalExpensesPaid;
  const walletAccounts = accounts.filter(a => a.type === "asset");
  const cashBank = walletAccounts.reduce((s, a) => s + Number(a.balance || 0), 0);

  // Receivable & Payable
  const moallemDue = bookings.filter(b => b.moallem_id).reduce((s, b) => s + Number(b.moallem_due || 0), 0);
  const customerDue = bookings.reduce((s, b) => s + Number(b.due_amount || 0), 0);
  const supplierDue = bookings.reduce((s, b) => s + Number(b.supplier_due || 0), 0);
  const commissionDue = bookings.reduce((s, b) => s + Number(b.commission_due || 0), 0);

  // Monthly chart
  const monthlyData = useMemo(() => {
    const months: Record<string, { revenue: number; profit: number }> = {};
    for (let i = 5; i >= 0; i--) {
      months[format(startOfMonth(subMonths(new Date(), i)), "MMM yy")] = { revenue: 0, profit: 0 };
    }
    bookings.forEach(b => {
      const key = format(new Date(b.created_at), "MMM yy");
      if (months[key]) {
        months[key].revenue += Number(b.total_amount || 0);
        months[key].profit += Number(b.profit_amount || 0);
      }
    });
    return Object.entries(months).map(([month, d]) => ({ month, ...d }));
  }, [bookings]);

  const recentBookings = bookings.slice(0, 5);
  const recentPayments = payments.filter(p => p.status === "completed").slice(0, 5);

  return (
    <div className="space-y-5">
      {/* ═══ TOP KPI CARDS ═══ */}
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-3">
        {[
          { label: "মোট বিক্রয়", value: fmt(totalSales), icon: DollarSign, color: "text-primary" },
          { label: "আয় প্রাপ্ত", value: fmt(totalIncome), icon: ArrowUpRight, color: "text-emerald" },
          { label: "নিট লাভ", value: fmt(netProfit), icon: TrendingUp, color: netProfit >= 0 ? "text-emerald" : "text-destructive" },
          { label: "ক্যাশ ব্যালেন্স", value: fmt(cashBank), icon: Wallet, color: "text-primary" },
          { label: "মোট বুকিং", value: bookings.length, icon: Package, color: "text-foreground" },
          { label: "মোট হাজী", value: totalHajji, icon: Users, color: "text-foreground" },
          { label: "কাস্টমার বকেয়া", value: fmt(customerDue), icon: UserCheck, color: customerDue > 0 ? "text-yellow-500" : "text-emerald" },
        ].map(k => (
          <div key={k.label} className="bg-card border border-border rounded-xl p-4">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[11px] text-muted-foreground uppercase tracking-wider">{k.label}</p>
              <k.icon className={`h-4 w-4 ${k.color}`} />
            </div>
            <p className={`text-lg font-heading font-bold ${k.color}`}>{k.value}</p>
          </div>
        ))}
      </div>

      {/* ═══ RECEIVABLE & PAYABLE ═══ */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <h3 className="text-sm font-semibold flex items-center gap-2 mb-3">
            <ArrowUpRight className="h-4 w-4 text-primary" /> প্রাপ্য (Receivable)
          </h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between"><span className="text-muted-foreground">মোয়াল্লেম বকেয়া</span><span className="font-bold text-yellow-600">{fmt(moallemDue)}</span></div>
            <div className="flex justify-between"><span className="text-muted-foreground">কাস্টমার বকেয়া</span><span className="font-bold text-yellow-600">{fmt(customerDue)}</span></div>
            <div className="border-t border-border pt-2 flex justify-between font-bold"><span>মোট</span><span className="text-primary">{fmt(moallemDue + customerDue)}</span></div>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <h3 className="text-sm font-semibold flex items-center gap-2 mb-3">
            <ArrowDownRight className="h-4 w-4 text-destructive" /> প্রদেয় (Payable)
          </h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between"><span className="text-muted-foreground">সাপ্লায়ার বকেয়া</span><span className="font-bold text-destructive">{fmt(supplierDue)}</span></div>
            <div className="flex justify-between"><span className="text-muted-foreground">কমিশন বকেয়া</span><span className="font-bold text-destructive">{fmt(commissionDue)}</span></div>
            <div className="border-t border-border pt-2 flex justify-between font-bold"><span>মোট</span><span className="text-destructive">{fmt(supplierDue + commissionDue)}</span></div>
          </div>
        </div>
      </div>

      {/* ═══ MONTHLY CHART ═══ */}
      <div className="bg-card border border-border rounded-xl p-5">
        <h3 className="text-sm font-semibold flex items-center gap-2 mb-3">
          <TrendingUp className="h-4 w-4 text-primary" /> মাসিক বিক্রয় ও লাভ
        </h3>
        <div className="h-56">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={monthlyData}>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(220, 15%, 20%)" />
              <XAxis dataKey="month" tick={{ fontSize: 10, fill: "hsl(220, 10%, 55%)" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 10, fill: "hsl(220, 10%, 55%)" }} axisLine={false} tickLine={false} tickFormatter={v => `৳${(v / 1000).toFixed(0)}k`} />
              <Tooltip contentStyle={ttStyle} formatter={(v: number) => fmt(v)} />
              <Bar dataKey="revenue" fill="hsl(40, 65%, 48%)" radius={[4, 4, 0, 0]} name="বিক্রয়" />
              <Bar dataKey="profit" fill="hsl(160, 50%, 40%)" radius={[4, 4, 0, 0]} name="লাভ" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* ═══ RECENT ACTIVITY ═══ */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold flex items-center gap-2">
              <FileText className="h-4 w-4 text-primary" /> সাম্প্রতিক বুকিং
            </h3>
            <button onClick={() => navigate("/admin/bookings")} className="text-xs text-primary hover:underline">সব দেখুন</button>
          </div>
          {recentBookings.length > 0 ? (
            <div className="space-y-2">
              {recentBookings.map(b => (
                <div key={b.id} className="flex items-center justify-between bg-secondary/30 rounded-lg p-3">
                  <div>
                    <p className="text-sm font-medium">{b.guest_name || "N/A"}</p>
                    <p className="text-[10px] text-muted-foreground">{b.tracking_id} · {b.packages?.name || ""}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-primary">{fmt(Number(b.total_amount))}</p>
                    <span className={`text-[10px] px-1.5 py-0.5 rounded-full capitalize ${b.status === "completed" ? "bg-emerald/10 text-emerald" : "bg-primary/10 text-primary"}`}>{b.status}</span>
                  </div>
                </div>
              ))}
            </div>
          ) : <p className="text-sm text-muted-foreground text-center py-8">কোনো বুকিং নেই</p>}
        </div>

        <div className="bg-card border border-border rounded-xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold flex items-center gap-2">
              <CreditCard className="h-4 w-4 text-primary" /> সাম্প্রতিক পেমেন্ট
            </h3>
            <button onClick={() => navigate("/admin/payments")} className="text-xs text-primary hover:underline">সব দেখুন</button>
          </div>
          {recentPayments.length > 0 ? (
            <div className="space-y-2">
              {recentPayments.map(p => (
                <div key={p.id} className="flex items-center justify-between bg-secondary/30 rounded-lg p-3">
                  <div>
                    <p className="text-sm font-medium">{p.bookings?.tracking_id || p.booking_id?.slice(0, 8)}</p>
                    <p className="text-[10px] text-muted-foreground">#{p.installment_number || "—"} · {p.payment_method || "manual"}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-emerald">{fmt(Number(p.amount))}</p>
                    <p className="text-[10px] text-muted-foreground">{p.paid_at ? format(new Date(p.paid_at), "dd MMM yy") : ""}</p>
                  </div>
                </div>
              ))}
            </div>
          ) : <p className="text-sm text-muted-foreground text-center py-8">কোনো পেমেন্ট নেই</p>}
        </div>
      </div>
    </div>
  );
};

export default AdminDashboardCharts;
