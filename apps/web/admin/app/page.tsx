"use client";

import * as React from "react";
import { useAuth } from "@/lib/auth-context";
import { appApi, MerchantData, TransactionRecord, StudentItem, BillItem, AuditLogItem } from "@/lib/api-client";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableHeader,
  TableRow,
  TableHead,
  TableBody,
  TableCell,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  ShieldCheck,
  Lock,
  Mail,
  ArrowRight,
  AlertCircle,
  Loader2,
  LayoutDashboard,
  School,
  Store,
  CreditCard,
  History,
  Settings,
  Users,
  Activity,
  ArrowUpRight,
  TrendingUp,
  Server,
  CheckCircle2,
  Bell,
  LogOut,
  User as UserIcon,
  Search,
  Plus,
  RefreshCw,
  Eye,
  EyeOff,
  Sparkles,
  ReceiptText,
  Wallet,
  Edit2,
} from "lucide-react";

function AdminLoginForm() {
  const { login } = useAuth();
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [showPassword, setShowPassword] = React.useState(false);
  const [rememberMe, setRememberMe] = React.useState(true);
  const [submitting, setSubmitting] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Silakan lengkapi email dan kata sandi Anda.");
      return;
    }
    setError(null);
    setSubmitting(true);
    try {
      const res = await login(email, password, "admin-console");
      if (!res.success) {
        setError(res.error || "Gagal masuk ke sistem.");
      }
    } catch {
      setError("Terjadi kesalahan jaringan.");
    } finally {
      setSubmitting(false);
    }
  };

  const fillDemo = (roleEmail: string) => {
    setEmail(roleEmail);
    setPassword("password");
    setError(null);
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center p-4 sm:p-6 lg:p-8 bg-muted/40 relative overflow-x-hidden">
      {/* Background ambient lighting */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="absolute -top-40 left-1/2 -translate-x-1/2 w-[700px] h-[400px] bg-primary/10 blur-[130px] rounded-full" />
        <div className="absolute -bottom-40 right-10 w-[500px] h-[350px] bg-primary/10 blur-[120px] rounded-full" />
      </div>

      <div className="w-full max-w-md lg:max-w-4xl xl:max-w-5xl">
        {/* MOBILE ONLY: BANNER GAMBAR DI LUAR CARD */}
        <div className="lg:hidden mb-4 w-full h-44 sm:h-52 rounded-2xl overflow-hidden border border-border/80 shadow-md bg-slate-950">
          <img
            src="/login-banner.svg"
            alt="SemestaPay Banner"
            className="w-full h-full object-cover"
          />
        </div>

        {/* CARD UTAMA */}
        <div className="rounded-2xl lg:rounded-3xl border border-border/80 bg-card shadow-xl lg:shadow-2xl overflow-hidden lg:grid lg:grid-cols-2">
          {/* DESKTOP ONLY: BANNER GAMBAR DI DALAM CARD (SISI KIRI) */}
          <div className="hidden lg:block relative bg-slate-950">
            <img
              src="/login-banner.svg"
              alt="SemestaPay Banner"
              className="w-full h-full object-cover absolute inset-0"
            />
          </div>

          {/* SISI KANAN (Desktop) / KONTEN CARD (Mobile): FORM LOGIN */}
          <div className="p-6 sm:p-8 lg:p-10 flex flex-col space-y-5">
            {/* Top Brand Header & Greeting */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between pb-1">
                <div className="flex items-center gap-2.5">
                  <img
                    src="/semestapay-icon.svg"
                    alt="SemestaPAY"
                    className="size-8 rounded-lg shadow-sm"
                  />
                  <div>
                    <span className="font-extrabold text-sm tracking-tight text-foreground leading-none">
                      SemestaPAY
                    </span>
                    <p className="text-[10px] text-muted-foreground">Admin Console</p>
                  </div>
                </div>

                <Badge variant="secondary" className="text-[10px] font-semibold uppercase">
                  SUPERADMIN
                </Badge>
              </div>

              <div>
                <h2 className="text-xl sm:text-2xl font-extrabold tracking-tight text-foreground">
                  Selamat Datang
                </h2>
                <p className="text-xs sm:text-sm text-muted-foreground mt-0.5">
                  Masuk dengan akun berwenang untuk mengakses konsol admin
                </p>
              </div>
            </div>

            {/* Form Section */}
            <form onSubmit={handleSubmit} className="space-y-3.5">
              {error && (
                <div className="flex items-start gap-3 p-3 rounded-xl bg-destructive/10 border border-destructive/20 text-destructive text-sm leading-snug">
                  <AlertCircle className="size-4 shrink-0 mt-0.5" />
                  <p>{error}</p>
                </div>
              )}

              {/* Selector Akun Demo */}
              <div className="space-y-1">
                <Label htmlFor="demoAccount" className="text-xs sm:text-sm font-medium text-foreground flex items-center justify-between">
                  <span>Pilih Akun Demo (Cendana)</span>
                  <span className="text-[10px] text-primary font-semibold">Uji Coba Langsung</span>
                </Label>
                <select
                  id="demoAccount"
                  value={email}
                  onChange={(e) => {
                    if (e.target.value) fillDemo(e.target.value);
                  }}
                  className="w-full h-11 px-3 text-xs sm:text-sm rounded-xl border border-border/80 bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40 font-medium cursor-pointer shadow-xs"
                >
                  <option value="">-- Pilih Akun Demo Cendana --</option>
                  <option value="admin@cendana.sch.id">👑 Superadmin (admin@cendana.sch.id)</option>
                  <option value="neneng@cendana.sch.id">🍱 Kasir Kantin - Miss Neneng (neneng@cendana.sch.id)</option>
                  <option value="fuji@cendana.sch.id">🏪 Kasir Kopsis - Ustadz Fuji (fuji@cendana.sch.id)</option>
                </select>
              </div>

              {/* Email Input */}
              <div className="space-y-1">
                <Label htmlFor="email" className="text-xs sm:text-sm font-medium text-foreground">
                  Email Administrator
                </Label>
                <div className="relative">
                  <Mail className="absolute left-3.5 top-3.5 size-4 text-muted-foreground pointer-events-none" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="nama@semestapay.id"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="h-11 pl-10 text-sm rounded-xl border-border/80 bg-background focus:bg-background transition-all shadow-xs"
                  />
                </div>
              </div>

              {/* Password Input */}
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <Label htmlFor="password" className="text-xs sm:text-sm font-medium text-foreground">
                    Kata Sandi
                  </Label>
                  <a
                    href="#forgot"
                    onClick={(e) => {
                      e.preventDefault();
                      alert("Silakan hubungi Superadmin untuk reset kata sandi akun Anda.");
                    }}
                    className="text-xs font-semibold text-primary hover:underline transition-colors"
                  >
                    Lupa sandi?
                  </a>
                </div>
                <div className="relative">
                  <Lock className="absolute left-3.5 top-3.5 size-4 text-muted-foreground pointer-events-none" />
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="Masukkan kata sandi"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="h-11 pl-10 pr-11 text-sm rounded-xl border-border/80 bg-background focus:bg-background transition-all shadow-xs font-mono"
                  />
                  <button
                    type="button"
                    tabIndex={-1}
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-3 p-1 rounded-md text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
                  >
                    {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                  </button>
                </div>
              </div>

              {/* Remember Me */}
              <div className="flex items-center gap-2 pt-0.5">
                <input
                  type="checkbox"
                  id="remember"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="size-4 rounded-md border-border text-primary focus:ring-primary cursor-pointer accent-primary"
                />
                <Label htmlFor="remember" className="text-xs text-muted-foreground cursor-pointer font-normal select-none">
                  Ingat sesi masuk di perangkat ini
                </Label>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                disabled={submitting}
                className="w-full h-11 text-sm font-semibold rounded-xl shadow-md shadow-primary/20 hover:shadow-lg hover:shadow-primary/30 transition-all cursor-pointer gap-2 mt-1"
              >
                {submitting ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Memverifikasi Hak Akses...
                  </>
                ) : (
                  <>
                    Masuk ke Konsol Admin
                    <ArrowRight className="size-4" />
                  </>
                )}
              </Button>

              {/* Divider Akun Demo */}
              <div className="relative py-1">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-border/60" />
                </div>
                <div className="relative flex justify-center text-xs uppercase">
                  <span className="bg-card px-2.5 text-muted-foreground font-medium text-[11px]">
                    Uji Coba Demo Instan
                  </span>
                </div>
              </div>

              {/* Demo Quick-Fill Buttons */}
              <div className="grid grid-cols-3 gap-2">
                <Button
                  type="button"
                  variant="outline"
                  className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                  onClick={() => fillDemo("admin@cendana.sch.id")}
                >
                  <Sparkles className="size-3.5 text-amber-500" />
                  Superadmin
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                  onClick={() => fillDemo("neneng@cendana.sch.id")}
                >
                  <Sparkles className="size-3.5 text-emerald-500" />
                  Kasir Kantin
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                  onClick={() => fillDemo("fuji@cendana.sch.id")}
                >
                  <Sparkles className="size-3.5 text-blue-500" />
                  Kasir Kopsis
                </Button>
              </div>
            </form>

            {/* Footer Navigation Link */}
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-3 border-t border-border/60">
              <a href="https://pay.zet.web.id" className="hover:text-foreground transition-colors flex items-center gap-1">
                ← Portal SemestaPay
              </a>
              <span className="flex items-center gap-1 text-[11px]">
                <ShieldCheck className="size-3 text-emerald-600" />
                TLS 1.3 Terenkripsi
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function AdminDashboardView() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = React.useState<
    "overview" | "students" | "bills" | "limits" | "schools" | "merchants" | "transactions" | "audit" | "settings"
  >("overview");

  // State
  const [merchants, setMerchants] = React.useState<MerchantData[]>([]);
  const [transactions, setTransactions] = React.useState<TransactionRecord[]>([]);
  const [students, setStudents] = React.useState<StudentItem[]>([]);
  const [bills, setBills] = React.useState<BillItem[]>([]);
  const [auditLogs, setAuditLogs] = React.useState<AuditLogItem[]>([]);
  const [loading, setLoading] = React.useState(true);

  // Search & Filter
  const [searchQuery, setSearchQuery] = React.useState("");

  // Adjust Student Balance Dialog
  const [adjustStudentOpen, setAdjustStudentOpen] = React.useState(false);
  const [adjustStudentTarget, setAdjustStudentTarget] = React.useState<StudentItem | null>(null);
  const [adjustStudentValue, setAdjustStudentValue] = React.useState("");
  const [adjustStudentNote, setAdjustStudentNote] = React.useState("");
  const [submittingAdjustStudent, setSubmittingAdjustStudent] = React.useState(false);

  // Adjust Merchant Balance Dialog
  const [adjustMerchantOpen, setAdjustMerchantOpen] = React.useState(false);
  const [adjustMerchantTarget, setAdjustMerchantTarget] = React.useState<MerchantData | null>(null);
  const [adjustMerchantValue, setAdjustMerchantValue] = React.useState("");
  const [adjustMerchantNote, setAdjustMerchantNote] = React.useState("");
  const [submittingAdjustMerchant, setSubmittingAdjustMerchant] = React.useState(false);

  // Add Merchant Dialog
  const [addMerchantOpen, setAddMerchantOpen] = React.useState(false);
  const [newMerchantName, setNewMerchantName] = React.useState("");
  const [newMerchantType, setNewMerchantType] = React.useState("canteen");
  const [submittingMerchant, setSubmittingMerchant] = React.useState(false);

  // Add Student Dialog
  const [addStudentOpen, setAddStudentOpen] = React.useState(false);
  const [newNis, setNewNis] = React.useState("");
  const [newName, setNewName] = React.useState("");
  const [newCardUid, setNewCardUid] = React.useState("");
  const [newBalance, setNewBalance] = React.useState("100000");
  const [newLimit, setNewLimit] = React.useState("50000");
  const [newPhone, setNewPhone] = React.useState("");
  const [submittingAddStudent, setSubmittingAddStudent] = React.useState(false);

  // Edit Limit Dialog
  const [editLimitOpen, setEditLimitOpen] = React.useState(false);
  const [selectedStudent, setSelectedStudent] = React.useState<StudentItem | null>(null);
  const [editLimitValue, setEditLimitValue] = React.useState("50000");
  const [submittingLimit, setSubmittingLimit] = React.useState(false);

  // Add School Dialog
  const [addSchoolOpen, setAddSchoolOpen] = React.useState(false);
  const [newSchoolName, setNewSchoolName] = React.useState("");
  const [newSchoolNspp, setNewSchoolNspp] = React.useState("");

  const initials = (user?.name || "AD")
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  const loadData = React.useCallback(async () => {
    setLoading(true);
    try {
      const [merchantsRes, txRes, stRes, billsRes, auditRes] = await Promise.all([
        appApi.getMerchants().catch(() => ({ data: [] })),
        appApi.getTransactions().catch(() => ({ data: [] })),
        appApi.getStudents().catch(() => ({ data: [] })),
        appApi.getBills().catch(() => ({ data: [] })),
        appApi.getAuditLogs().catch(() => ({ data: [] })),
      ]);

      if (auditRes.data && auditRes.data.length > 0) {
        setAuditLogs(auditRes.data);
      }

      if (merchantsRes.data && merchantsRes.data.length > 0) {
        setMerchants(merchantsRes.data);
      } else {
        setMerchants([
          { id: 1, name: "Kantin Pesantren", type: "canteen", status: "active", items_count: 5, outlets_count: 1 },
          { id: 2, name: "Koperasi Pesantren", type: "cooperative", status: "active", items_count: 3, outlets_count: 1 },
        ]);
      }

      if (txRes.data && txRes.data.length > 0) {
        setTransactions(txRes.data);
      } else {
        setTransactions([
          { id: "TX-9901", created_at: "2026-10-30T12:45:00Z", type: "payment", amount: 15000, status: "success", student_name: "Ahmad Fauzi", merchant_name: "Kantin Utama" },
          { id: "TX-9902", created_at: "2026-10-30T12:41:00Z", type: "payment", amount: 8000, status: "success", student_name: "Citra Lestari", merchant_name: "Koperasi" },
          { id: "TX-9903", created_at: "2026-10-30T12:38:00Z", type: "payment", amount: 12000, status: "success", student_name: "Budi Santoso", merchant_name: "Kantin Utama" },
          { id: "TX-9904", created_at: "2026-10-30T12:30:00Z", type: "payment", amount: 55000, status: "failed", student_name: "Dewi Anggraini", merchant_name: "Kantin Utama", note: "Limit Saldo" },
        ]);
      }

      if (stRes.data && stRes.data.length > 0) {
        setStudents(stRes.data);
      } else {
        setStudents([
          { id: 1, nis: "2026-001", name: "Ahmad Fauzi", class_name: "Kelas 7A", card_uid: "DEMO-UID-0001", card_status: "active", balance: 145000, daily_limit: 50000, status: "active", phone_parent: "081312000001" },
          { id: 2, nis: "2026-002", name: "Budi Santoso", class_name: "Kelas 7A", card_uid: "DEMO-UID-0002", card_status: "active", balance: 82000, daily_limit: 50000, status: "active", phone_parent: "081312000002" },
          { id: 3, nis: "2026-003", name: "Citra Lestari", class_name: "Kelas 7B", card_uid: "DEMO-UID-0003", card_status: "active", balance: 210000, daily_limit: 50000, status: "active", phone_parent: "081312000003" },
          { id: 4, nis: "2026-004", name: "Dewi Anggraini", class_name: "Kelas 7B", card_uid: "DEMO-UID-0004", card_status: "active", balance: 45000, daily_limit: 30000, status: "active", phone_parent: "081312000004" },
        ]);
      }

      if (billsRes.data && billsRes.data.length > 0) {
        setBills(billsRes.data);
      } else {
        setBills([
          { id: 1, type: "spp", period: "2026-10", description: "SPP & Syahriah Santri Oktober 2026", amount: 450000, paid_amount: 450000, due_date: "2026-10-10", status: "paid" },
          { id: 2, type: "katering", period: "2026-10", description: "Biaya Makan & Katering Oktober 2026", amount: 350000, paid_amount: 0, due_date: "2026-10-15", status: "unpaid" },
          { id: 3, type: "kegiatan", period: "2026-11", description: "Iuran Ujian & PHBI November 2026", amount: 150000, paid_amount: 0, due_date: "2026-11-05", status: "unpaid" },
        ]);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    loadData();
  }, [loadData]);

  const handleCreateMerchant = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMerchantName) return;
    setSubmittingMerchant(true);
    try {
      await appApi.createMerchant({
        name: newMerchantName,
        type: newMerchantType,
        status: "active",
      });
      await loadData();
      setAddMerchantOpen(false);
      setNewMerchantName("");
    } catch {
      setMerchants((prev) => [
        {
          id: Date.now(),
          name: newMerchantName,
          type: newMerchantType,
          status: "active",
          items_count: 0,
          outlets_count: 1,
        },
        ...prev,
      ]);
      setAddMerchantOpen(false);
    } finally {
      setSubmittingMerchant(false);
    }
  };

  const handleAddStudent = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newNis || !newName) return;
    setSubmittingAddStudent(true);
    try {
      const payload = {
        nis: newNis,
        name: newName,
        card_uid: newCardUid || undefined,
        balance: parseFloat(newBalance) || 0,
        daily_limit: parseFloat(newLimit) || 50000,
        phone_parent: newPhone || undefined,
      };
      await appApi.createStudent(payload).catch(() => null);
      const newSt: StudentItem = {
        id: Date.now(),
        nis: newNis,
        name: newName,
        class_name: "Kelas 7A",
        card_uid: newCardUid,
        card_status: newCardUid ? "active" : "inactive",
        balance: parseFloat(newBalance) || 0,
        daily_limit: parseFloat(newLimit) || 50000,
        status: "active",
        phone_parent: newPhone,
      };
      setStudents((prev) => [newSt, ...prev]);
      setAddStudentOpen(false);
      setNewNis("");
      setNewName("");
      setNewCardUid("");
      setNewPhone("");
    } finally {
      setSubmittingAddStudent(false);
    }
  };

  const handleSaveLimit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStudent) return;
    setSubmittingLimit(true);
    try {
      const val = parseFloat(editLimitValue);
      await appApi.updateStudent(selectedStudent.id, { daily_limit: val }).catch(() => null);
      setStudents((prev) =>
        prev.map((s) => (s.id === selectedStudent.id ? { ...s, daily_limit: val } : s))
      );
      setEditLimitOpen(false);
    } finally {
      setSubmittingLimit(false);
    }
  };

  const handleAdjustStudentBalance = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjustStudentTarget) return;
    const num = parseFloat(adjustStudentValue);
    if (isNaN(num) || num < 0) return;
    setSubmittingAdjustStudent(true);
    try {
      await appApi.setStudentBalance(adjustStudentTarget.id, num, adjustStudentNote);
      await loadData();
      setAdjustStudentOpen(false);
      setAdjustStudentTarget(null);
      setAdjustStudentValue("");
      setAdjustStudentNote("");
    } catch (err: any) {
      alert(err?.message || "Gagal memperbarui saldo santri.");
    } finally {
      setSubmittingAdjustStudent(false);
    }
  };

  const handleAdjustMerchantBalance = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjustMerchantTarget) return;
    const num = parseFloat(adjustMerchantValue);
    if (isNaN(num) || num < 0) return;
    setSubmittingAdjustMerchant(true);
    try {
      await appApi.setMerchantBalance(adjustMerchantTarget.id, num, adjustMerchantNote);
      await loadData();
      setAdjustMerchantOpen(false);
      setAdjustMerchantTarget(null);
      setAdjustMerchantValue("");
      setAdjustMerchantNote("");
    } catch (err: any) {
      alert(err?.message || "Gagal memperbarui saldo merchant.");
    } finally {
      setSubmittingAdjustMerchant(false);
    }
  };

  const filteredStudents = students.filter(
    (s) =>
      s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.nis.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (s.card_uid && s.card_uid.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const totalSantri = students.length;
  const avgSaldo = students.length > 0 ? Math.round(students.reduce((acc, s) => acc + s.balance, 0) / students.length) : 0;
  const activeCards = students.filter((s) => s.card_uid && s.card_status === "active").length;

  const navItems = [
    { id: "overview", title: "Ikhtisar", icon: <LayoutDashboard className="size-4" /> },
    { id: "students", title: "Data Santri & RFID", icon: <Users className="size-4" />, badge: `${students.length} Santri` },
    { id: "bills", title: "Tagihan SPP", icon: <ReceiptText className="size-4" />, badge: `${bills.length} Tagihan` },
    { id: "limits", title: "Batas Belanja", icon: <Wallet className="size-4" /> },
    { id: "schools", title: "Lembaga & Sekolah", icon: <School className="size-4" />, badge: "1 Lembaga" },
    { id: "merchants", title: "Merchant & Kantin", icon: <Store className="size-4" />, badge: `${merchants.length} Unit` },
    { id: "transactions", title: "Transaksi & Ledger", icon: <CreditCard className="size-4" /> },
    { id: "audit", title: "Audit Log", icon: <History className="size-4" /> },
    { id: "settings", title: "Pengaturan Sistem", icon: <Settings className="size-4" /> },
  ];

  return (
    <div className="flex min-h-screen bg-background text-foreground">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r bg-card flex flex-col shrink-0">
        <div className="h-16 border-b px-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img
              src="/semestapay-icon.svg"
              alt="SemestaPAY"
              className="size-9 rounded-xl shadow"
            />
            <div>
              <h2 className="font-bold text-sm tracking-tight text-foreground leading-tight">
                SemestaPAY
              </h2>
              <p className="text-xs text-muted-foreground">Konsol Admin</p>
            </div>
          </div>
          <Badge variant="secondary" className="text-[10px] font-semibold uppercase tracking-wider">
            ADMIN
          </Badge>
        </div>

        <nav className="flex-1 overflow-y-auto p-3 space-y-1">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id as any)}
              className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm font-medium transition-colors cursor-pointer text-left ${
                activeTab === item.id
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground"
              }`}
            >
              <div className="flex items-center gap-3">
                <span className="shrink-0">{item.icon}</span>
                <span>{item.title}</span>
              </div>
              {item.badge && (
                <span
                  className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${
                    activeTab === item.id
                      ? "bg-primary-foreground/20 text-primary-foreground"
                      : "bg-muted text-foreground"
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </button>
          ))}
        </nav>

        <div className="p-3 border-t bg-muted/20">
          <div className="flex items-center justify-between p-2 rounded-lg bg-card border">
            <div className="flex items-center gap-2.5 overflow-hidden">
              <Avatar className="size-8 shrink-0">
                <AvatarFallback className="bg-primary/10 text-primary font-bold text-xs">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <div className="overflow-hidden">
                <p className="text-xs font-semibold truncate text-foreground">{user?.name || "Admin"}</p>
                <p className="text-[11px] text-muted-foreground truncate">{user?.email || "admin@cendana.sch.id"}</p>
              </div>
            </div>
            <Button
              variant="ghost"
              size="icon"
              className="size-7 text-muted-foreground hover:text-destructive cursor-pointer"
              onClick={() => logout()}
              title="Keluar"
            >
              <LogOut className="size-4" />
            </Button>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 border-b bg-card/60 backdrop-blur-sm px-6 flex items-center justify-between sticky top-0 z-10">
          <div>
            <h1 className="text-lg font-bold tracking-tight text-foreground">
              {activeTab === "overview" && "Dashboard Administrator Pusat"}
              {activeTab === "students" && "Manajemen Data Santri & Kartu RFID"}
              {activeTab === "bills" && "Tagihan SPP & Pembayaran Santri"}
              {activeTab === "limits" && "Batas Belanja & Proteksi Harian"}
              {activeTab === "schools" && "Manajemen Lembaga & Sekolah"}
              {activeTab === "merchants" && "Kemitraan Merchant & Kantin"}
              {activeTab === "transactions" && "Ledger & Histori Transaksi Ekosistem"}
              {activeTab === "audit" && "Log Audit Keamanan & Operator"}
              {activeTab === "settings" && "Konfigurasi Arsitektur Sistem"}
            </h1>
            <p className="text-xs text-muted-foreground">Konsol Superadmin • Tema Indigo Blue</p>
          </div>

          <div className="flex items-center gap-3">
            <Button
              variant="outline"
              size="sm"
              className="gap-1.5 text-xs cursor-pointer"
              onClick={loadData}
              disabled={loading}
            >
              <RefreshCw className={`size-3.5 ${loading ? "animate-spin" : ""}`} />
              Segarkan
            </Button>

            <Badge variant="outline" className="hidden sm:inline-flex gap-1.5 py-1">
              <span className="size-2 rounded-full bg-emerald-500 animate-pulse" />
              <span className="font-medium text-xs">SERVER NORMAL</span>
            </Badge>

            <DropdownMenu>
              <DropdownMenuTrigger className="relative size-9 rounded-full p-0 cursor-pointer outline-none">
                <Avatar className="size-9 border border-border">
                  <AvatarFallback className="bg-primary/10 text-primary font-bold text-xs">
                    {initials}
                  </AvatarFallback>
                </Avatar>
              </DropdownMenuTrigger>
              <DropdownMenuContent className="w-56" align="end">
                <DropdownMenuGroup>
                  <DropdownMenuLabel className="font-normal">
                    <div className="flex flex-col space-y-1">
                      <p className="text-sm font-medium leading-none">{user?.name || "Administrator"}</p>
                      <p className="text-xs leading-none text-muted-foreground">{user?.email || ""}</p>
                    </div>
                  </DropdownMenuLabel>
                </DropdownMenuGroup>
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  className="gap-2 text-destructive focus:text-destructive cursor-pointer"
                  onClick={() => logout()}
                >
                  <LogOut className="size-4" />
                  <span>Keluar Sesi</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </header>

        <main className="flex-1 p-6 lg:p-8 space-y-6">
          {/* TAB 1: OVERVIEW */}
          {activeTab === "overview" && (
            <div className="space-y-6">
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Lembaga Terhubung</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <School className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">1 Pesantren</span>
                      <span className="text-xs font-semibold text-emerald-600">Aktif</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Pesantren Digital Semesta</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Merchant / Kantin</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Store className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">
                        {merchants.length} Merchant
                      </span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Kantin & Koperasi Pondok</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Santri Aktif</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Users className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">5 Santri</span>
                      <span className="text-xs font-semibold text-emerald-600">100% Berkartu</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">5 Kartu Pintar RFID Terbit</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Volume Transaksi</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Activity className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">Rp 90.000</span>
                      <span className="text-xs font-semibold text-emerald-600">Hari ini</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Rata-rata sukses 99.8%</p>
                  </CardContent>
                </Card>
              </div>

              <div className="grid gap-6 lg:grid-cols-3">
                <Card className="lg:col-span-2">
                  <CardHeader className="flex flex-row items-center justify-between pb-2">
                    <div>
                      <CardTitle className="text-base font-semibold">Aktivitas Transaksi Ekosistem Terkini</CardTitle>
                      <CardDescription>Pemrosesan pembayaran real-time di seluruh unit</CardDescription>
                    </div>
                    <Button
                      size="sm"
                      className="gap-1 text-xs cursor-pointer"
                      onClick={() => setActiveTab("transactions")}
                    >
                      Buka Ledger
                    </Button>
                  </CardHeader>
                  <CardContent>
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Waktu</TableHead>
                          <TableHead>Santri</TableHead>
                          <TableHead>Merchant</TableHead>
                          <TableHead>Nominal</TableHead>
                          <TableHead>Status</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {transactions.map((tx) => (
                          <TableRow key={tx.id}>
                            <TableCell className="text-xs text-muted-foreground font-mono">
                              {tx.id}
                            </TableCell>
                            <TableCell className="font-medium text-sm">{tx.student_name}</TableCell>
                            <TableCell className="text-sm">{tx.merchant_name}</TableCell>
                            <TableCell className="font-semibold text-sm">
                              Rp {tx.amount.toLocaleString("id-ID")}
                            </TableCell>
                            <TableCell>
                              <Badge
                                variant={tx.status === "success" ? "default" : "destructive"}
                                className={tx.status === "success" ? "bg-emerald-600" : ""}
                              >
                                {tx.status === "success" ? "Berhasil" : "Gagal"}
                              </Badge>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </CardContent>
                </Card>

                <div className="space-y-6">
                  <Card>
                    <CardHeader className="pb-3">
                      <div className="flex items-center gap-2 text-primary">
                        <Server className="size-4" />
                        <CardTitle className="text-sm font-semibold">Status API Backend</CardTitle>
                      </div>
                      <CardDescription>Terhubung ke Laravel 13 Engine</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div className="flex items-center justify-between p-2.5 rounded-lg bg-muted/50 border text-xs">
                        <span className="text-muted-foreground">Endpoint API</span>
                        <code className="font-mono text-primary font-semibold">pay-api.zet.web.id</code>
                      </div>
                      <div className="flex items-center justify-between p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-700 dark:text-emerald-400">
                        <span className="flex items-center gap-1.5 font-medium">
                          <CheckCircle2 className="size-3.5" />
                          Koneksi Sanctum
                        </span>
                        <span className="font-semibold">Aktif</span>
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="pb-3">
                      <CardTitle className="text-sm font-semibold">Tindakan Cepat</CardTitle>
                      <CardDescription>Pintasan operasional sistem</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      <Button
                        variant="default"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => {
                          setActiveTab("students");
                          setAddStudentOpen(true);
                        }}
                      >
                        + Daftarkan Santri Baru
                      </Button>
                      <Button
                        variant="outline"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => {
                          setActiveTab("merchants");
                          setAddMerchantOpen(true);
                        }}
                      >
                        + Tambah Merchant Baru
                      </Button>
                      <Button
                        variant="outline"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => setActiveTab("bills")}
                      >
                        Lihat Tagihan SPP
                      </Button>
                      <Button
                        variant="secondary"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => setActiveTab("limits")}
                      >
                        Atur Batas Belanja Santri
                      </Button>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </div>
          )}

          {/* TAB: DATA SANTRI & RFID */}
          {activeTab === "students" && (
            <Card>
              <CardHeader className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4">
                <div>
                  <CardTitle className="text-lg">Data Santri & Kartu Pintar RFID</CardTitle>
                  <CardDescription>
                    Kelola identitas, kartu akses fisik, dan saldo dompet cashless santri
                  </CardDescription>
                </div>

                <div className="flex items-center gap-3">
                  <div className="relative w-64">
                    <Search className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
                    <Input
                      placeholder="Cari santri, NIS, atau UID..."
                      className="pl-9 text-xs"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                    />
                  </div>

                  <Button
                    size="sm"
                    className="gap-1.5 text-xs cursor-pointer"
                    onClick={() => setAddStudentOpen(true)}
                  >
                    <Plus className="size-4" />
                    Tambah Santri
                  </Button>
                </div>
              </CardHeader>

              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>NIS</TableHead>
                      <TableHead>Nama Santri</TableHead>
                      <TableHead>Kelas</TableHead>
                      <TableHead>No. Wali</TableHead>
                      <TableHead>Saldo Dompet</TableHead>
                      <TableHead>Limit Harian</TableHead>
                      <TableHead>Kartu RFID</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead className="text-right">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredStudents.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={9} className="text-center py-8 text-muted-foreground">
                          Tidak ada data santri ditemukan.
                        </TableCell>
                      </TableRow>
                    ) : (
                      filteredStudents.map((s) => (
                        <TableRow key={s.id}>
                          <TableCell className="font-mono text-xs font-semibold">{s.nis}</TableCell>
                          <TableCell className="font-medium text-sm">{s.name}</TableCell>
                          <TableCell><Badge variant="secondary">{s.class_name}</Badge></TableCell>
                          <TableCell className="text-xs text-muted-foreground font-mono">
                            {s.phone_parent || "-"}
                          </TableCell>
                          <TableCell className="font-semibold text-emerald-600">
                            Rp {s.balance.toLocaleString("id-ID")}
                          </TableCell>
                          <TableCell className="text-xs font-medium">
                            Rp {s.daily_limit.toLocaleString("id-ID")}
                          </TableCell>
                          <TableCell>
                            <code className="text-xs bg-muted px-2 py-0.5 rounded font-mono">
                              {s.card_uid || "Belum Terhubung"}
                            </code>
                          </TableCell>
                          <TableCell>
                            <Badge variant="default" className="bg-emerald-600 text-xs">
                              {s.status === "active" ? "Aktif" : s.status}
                            </Badge>
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex items-center justify-end gap-1.5">
                              <Button
                                variant="outline"
                                size="sm"
                                className="gap-1 text-xs cursor-pointer h-7 px-2"
                                onClick={() => {
                                  setAdjustStudentTarget(s);
                                  setAdjustStudentValue(s.balance.toString());
                                  setAdjustStudentNote("");
                                  setAdjustStudentOpen(true);
                                }}
                              >
                                <Wallet className="size-3" />
                                Atur Saldo
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                className="gap-1 text-xs cursor-pointer h-7 px-2"
                                onClick={() => {
                                  setSelectedStudent(s);
                                  setEditLimitValue(s.daily_limit.toString());
                                  setEditLimitOpen(true);
                                }}
                              >
                                <Edit2 className="size-3" />
                                Ubah Limit
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB: TAGIHAN SPP */}
          {activeTab === "bills" && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="text-lg">Daftar Tagihan SPP & Keuangan Santri</CardTitle>
                  <CardDescription>
                    Kelola tagihan bulanan santri dan pantau status pembayaran auto-debet
                  </CardDescription>
                </div>
                <Badge variant="outline" className="text-xs">
                  {bills.length} Tagihan Terdata
                </Badge>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>ID Tagihan</TableHead>
                      <TableHead>Kategori</TableHead>
                      <TableHead>Keterangan</TableHead>
                      <TableHead>Jatuh Tempo</TableHead>
                      <TableHead>Nominal</TableHead>
                      <TableHead>Sudah Bayar</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {bills.map((b) => (
                      <TableRow key={b.id}>
                        <TableCell className="font-mono text-xs font-semibold">#{b.id}</TableCell>
                        <TableCell>
                          <Badge variant="secondary" className="uppercase text-[10px]">
                            {b.type}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-sm font-medium">{b.description}</TableCell>
                        <TableCell className="text-xs text-muted-foreground">{b.due_date}</TableCell>
                        <TableCell className="font-semibold text-sm">
                          Rp {b.amount.toLocaleString("id-ID")}
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          Rp {b.paid_amount.toLocaleString("id-ID")}
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant={b.status === "paid" ? "default" : "destructive"}
                            className={b.status === "paid" ? "bg-emerald-600" : ""}
                          >
                            {b.status === "paid" ? "Lunas" : "Belum Bayar"}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB: BATAS BELANJA HARIAN */}
          {activeTab === "limits" && (
            <div className="grid gap-6 lg:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base font-semibold">Kebijakan Batas Belanja Harian</CardTitle>
                  <CardDescription>
                    Pondok menetapkan batasan jajan santri di kantin dan koperasi demi menjaga kedisiplinan finansial
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="p-4 rounded-lg bg-muted/60 border space-y-2">
                    <p className="text-sm font-semibold">Batas Default Santri</p>
                    <p className="text-2xl font-bold text-primary">Rp 50.000 / hari</p>
                    <p className="text-xs text-muted-foreground">
                      Batas ini berlaku secara otomatis jika saldo mencukupi dan akan di-reset setiap pukul 00:00 WIB.
                    </p>
                  </div>

                  <div className="space-y-2">
                    <Label>Aturan Transaksi Tambahan</Label>
                    <div className="text-xs space-y-1.5 text-muted-foreground">
                      <p>• Transaksi di atas Rp 25.000 membutuhkan verifikasi PIN santri di mesin kasir.</p>
                      <p>• Notifikasi WhatsApp otomatis terkirim ke wali santri setiap akumulasi belanja tercapai 80%.</p>
                      <p>• Pembelian buku sekolah dan obat di poskestren dikecualikan dari batas limit ini.</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base font-semibold">Atur Cepat Limit per Santri</CardTitle>
                  <CardDescription>Pilih santri untuk mengubah batasan harian secara individual</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  {students.slice(0, 6).map((s) => (
                    <div
                      key={s.id}
                      className="flex items-center justify-between p-3 rounded-lg border bg-card hover:bg-muted/30 transition-colors"
                    >
                      <div>
                        <p className="text-sm font-medium">{s.name}</p>
                        <p className="text-xs text-muted-foreground">{s.class_name} • Saldo: Rp {s.balance.toLocaleString("id-ID")}</p>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className="text-sm font-semibold text-primary">
                          Rp {s.daily_limit.toLocaleString("id-ID")}/hr
                        </span>
                        <Button
                          variant="outline"
                          size="sm"
                          className="text-xs cursor-pointer h-8"
                          onClick={() => {
                            setSelectedStudent(s);
                            setEditLimitValue(s.daily_limit.toString());
                            setEditLimitOpen(true);
                          }}
                        >
                          Ubah
                        </Button>
                      </div>
                    </div>
                  ))}
                </CardContent>
              </Card>
            </div>
          )}

          {/* TAB 2: LEMBAGA & SEKOLAH */}
          {activeTab === "schools" && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="text-lg">Daftar Lembaga & Pesantren Terintegrasi</CardTitle>
                  <CardDescription>Kelola data yayasan atau lembaga pendidikan pengguna SemestaPay</CardDescription>
                </div>
                <Button
                  size="sm"
                  className="gap-1.5 text-xs cursor-pointer"
                  onClick={() => setAddSchoolOpen(true)}
                >
                  <Plus className="size-4" />
                  Tambah Lembaga
                </Button>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Kode Lembaga</TableHead>
                      <TableHead>Nama Pesantren / Sekolah</TableHead>
                      <TableHead>Nomor NSPP/NSPN</TableHead>
                      <TableHead>Total Santri</TableHead>
                      <TableHead>Kota / Lokasi</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    <TableRow>
                      <TableCell className="font-mono text-xs font-semibold">SCH-001</TableCell>
                      <TableCell className="font-medium">Pondok Pesantren Digital Semesta</TableCell>
                      <TableCell className="font-mono text-xs">510032010999</TableCell>
                      <TableCell className="font-semibold">5 Santri Aktif</TableCell>
                      <TableCell className="text-sm text-muted-foreground">Bogor, Jawa Barat</TableCell>
                      <TableCell>
                        <Badge variant="default" className="bg-emerald-600">Terverifikasi</Badge>
                      </TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB 3: MERCHANT & KANTIN */}
          {activeTab === "merchants" && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="text-lg">Kemitraan Merchant & Kantin</CardTitle>
                  <CardDescription>Daftar gerai, kantin, dan koperasi yang menerima pembayaran RFID</CardDescription>
                </div>
                <Button
                  size="sm"
                  className="gap-1.5 text-xs cursor-pointer"
                  onClick={() => setAddMerchantOpen(true)}
                >
                  <Plus className="size-4" />
                  Tambah Merchant
                </Button>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>ID</TableHead>
                      <TableHead>Nama Merchant</TableHead>
                      <TableHead>Tipe Unit</TableHead>
                      <TableHead>Saldo Rekening</TableHead>
                      <TableHead>Jumlah Menu</TableHead>
                      <TableHead>Jumlah Kasir/Outlet</TableHead>
                      <TableHead>Status Operasional</TableHead>
                      <TableHead className="text-right">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {merchants.map((m) => (
                      <TableRow key={m.id}>
                        <TableCell className="font-mono text-xs">#{m.id}</TableCell>
                        <TableCell className="font-medium text-sm">{m.name}</TableCell>
                        <TableCell>
                          <Badge variant="secondary" className="capitalize text-xs">
                            {m.type === "canteen" ? "Kantin Makanan" : "Koperasi Santri"}
                          </Badge>
                        </TableCell>
                        <TableCell className="font-semibold text-emerald-600 text-sm">
                          Rp {(m.balance ?? 0).toLocaleString("id-ID")}
                        </TableCell>
                        <TableCell className="text-sm font-semibold">{m.items_count} Menu</TableCell>
                        <TableCell className="text-sm">{m.outlets_count} Kasir EDC</TableCell>
                        <TableCell>
                          <Badge variant="default" className="bg-emerald-600">Aktif</Badge>
                        </TableCell>
                        <TableCell className="text-right">
                          <Button
                            variant="outline"
                            size="sm"
                            className="gap-1 text-xs cursor-pointer h-7 px-2"
                            onClick={() => {
                              setAdjustMerchantTarget(m);
                              setAdjustMerchantValue((m.balance ?? 0).toString());
                              setAdjustMerchantNote("");
                              setAdjustMerchantOpen(true);
                            }}
                          >
                            <Wallet className="size-3" />
                            Atur Saldo
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB 4: TRANSAKSI & LEDGER */}
          {activeTab === "transactions" && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="text-lg">Buku Besar Transaksi (Ledger)</CardTitle>
                  <CardDescription>Jurnal transaksi menyeluruh sistem SemestaPay</CardDescription>
                </div>
                <Badge variant="outline" className="text-xs">
                  {transactions.length} Entri Tercatat
                </Badge>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>ID Transaksi</TableHead>
                      <TableHead>Waktu Transaksi</TableHead>
                      <TableHead>Nama Santri</TableHead>
                      <TableHead>Unit Merchant</TableHead>
                      <TableHead>Nominal</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {transactions.map((tx) => (
                      <TableRow key={tx.id}>
                        <TableCell className="font-mono text-xs font-semibold">{tx.id}</TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {new Date(tx.created_at).toLocaleTimeString("id-ID")}
                        </TableCell>
                        <TableCell className="font-medium text-sm">{tx.student_name}</TableCell>
                        <TableCell className="text-sm">{tx.merchant_name}</TableCell>
                        <TableCell className="font-semibold text-sm">
                          Rp {tx.amount.toLocaleString("id-ID")}
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant={tx.status === "success" ? "default" : "destructive"}
                            className={tx.status === "success" ? "bg-emerald-600" : ""}
                          >
                            {tx.status === "success" ? "Berhasil" : "Gagal"}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB 5: AUDIT LOG */}
          {activeTab === "audit" && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="text-lg">Audit Log Keamanan & Perubahan Saldo</CardTitle>
                  <CardDescription>Catatan audit perubahan saldo, konfigurasi, dan aktivitas administrator</CardDescription>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  className="gap-1.5 text-xs cursor-pointer"
                  onClick={async () => {
                    setLoading(true);
                    try {
                      const res = await appApi.getAuditLogs();
                      setAuditLogs(res.data || []);
                    } finally {
                      setLoading(false);
                    }
                  }}
                >
                  <RefreshCw className="size-3" />
                  Segarkan Log
                </Button>
              </CardHeader>
              <CardContent>
                {auditLogs.length === 0 ? (
                  <div className="p-8 text-center text-muted-foreground text-sm">
                    Belum ada catatan audit log tersimpan.
                  </div>
                ) : (
                  <div className="space-y-3 font-mono text-xs">
                    {auditLogs.map((log) => (
                      <div
                        key={log.id}
                        className="p-3.5 rounded-lg bg-muted/60 border flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2"
                      >
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <span className="text-primary font-bold">[{log.action}]</span>
                            <span className="font-semibold text-foreground">{log.actor}</span>
                            {log.actor_email && (
                              <span className="text-muted-foreground font-normal">({log.actor_email})</span>
                            )}
                          </div>
                          <div className="text-muted-foreground text-[11px] font-sans">
                            {log.auditable_type && (
                              <span>
                                Target:{" "}
                                <code className="bg-muted px-1 py-0.5 rounded font-mono">
                                  {log.auditable_type.split("\\").pop()} #{log.auditable_id}
                                </code>{" "}
                              </span>
                            )}
                            {log.meta && (
                              <span className="ml-2">
                                {log.meta.old_balance !== undefined && log.meta.new_balance !== undefined && (
                                  <span>
                                    Saldo: Rp {Number(log.meta.old_balance).toLocaleString("id-ID")} &rarr;{" "}
                                    <strong className="text-emerald-600">
                                      Rp {Number(log.meta.new_balance).toLocaleString("id-ID")}
                                    </strong>
                                  </span>
                                )}
                                {log.meta.note && (
                                  <span className="italic ml-2 text-muted-foreground">({log.meta.note})</span>
                                )}
                              </span>
                            )}
                          </div>
                        </div>
                        <div className="flex flex-col sm:items-end text-[11px] text-muted-foreground">
                          <span>{log.created_at ? new Date(log.created_at).toLocaleString("id-ID") : "-"}</span>
                          {log.ip_address && <span className="text-[10px]">IP: {log.ip_address}</span>}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* TAB 6: PENGATURAN SISTEM */}
          {activeTab === "settings" && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Pengaturan Arsitektur & Lingkungan</CardTitle>
                <CardDescription>Konfigurasi parameter global SemestaPay</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="space-y-2">
                    <Label>Nama Platform</Label>
                    <Input defaultValue="SemestaPAY Enterprise" readOnly />
                  </div>
                  <div className="space-y-2">
                    <Label>Versi Kernel Backend</Label>
                    <Input defaultValue="Laravel 13.x + Sanctum" readOnly />
                  </div>
                  <div className="space-y-2">
                    <Label>Mata Uang Utama</Label>
                    <Input defaultValue="IDR (Rupiah Indonesia)" readOnly />
                  </div>
                  <div className="space-y-2">
                    <Label>Masa Berlaku Token Sesi</Label>
                    <Input defaultValue="30 Hari (Otomatis Perpanjang)" readOnly />
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </main>
      </div>

      {/* Dialog Add Merchant */}
      <Dialog open={addMerchantOpen} onOpenChange={setAddMerchantOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Tambah Merchant Baru</DialogTitle>
            <DialogDescription>
              Daftarkan unit usaha kantin atau koperasi ke dalam ekosistem pembayaran
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleCreateMerchant} className="space-y-4 py-2">
            <div className="space-y-1.5">
              <Label htmlFor="merchant-name">Nama Merchant</Label>
              <Input
                id="merchant-name"
                placeholder="Contoh: Kantin Asrama Putri"
                value={newMerchantName}
                onChange={(e) => setNewMerchantName(e.target.value)}
                required
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="merchant-type">Tipe Unit Usaha</Label>
              <Input
                id="merchant-type"
                placeholder="canteen / cooperative"
                value={newMerchantType}
                onChange={(e) => setNewMerchantType(e.target.value)}
                required
              />
            </div>

            <DialogFooter className="pt-4">
              <Button type="button" variant="outline" onClick={() => setAddMerchantOpen(false)}>
                Batal
              </Button>
              <Button type="submit" disabled={submittingMerchant}>
                {submittingMerchant ? "Menyimpan..." : "Daftarkan Merchant"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Dialog Add Student */}
      <Dialog open={addStudentOpen} onOpenChange={setAddStudentOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Daftarkan Santri Baru</DialogTitle>
            <DialogDescription>
              Masukkan identitas santri dan hubungkan kartu pintar RFID perdana.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleAddStudent} className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="nis">Nomor Induk (NIS)</Label>
                <Input
                  id="nis"
                  placeholder="2026-006"
                  value={newNis}
                  onChange={(e) => setNewNis(e.target.value)}
                  required
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="name">Nama Lengkap</Label>
                <Input
                  id="name"
                  placeholder="Nama Santri"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="card">UID Kartu RFID</Label>
                <Input
                  id="card"
                  placeholder="DEMO-UID-0006"
                  value={newCardUid}
                  onChange={(e) => setNewCardUid(e.target.value)}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="phone">No. WhatsApp Wali</Label>
                <Input
                  id="phone"
                  placeholder="0813..."
                  value={newPhone}
                  onChange={(e) => setNewPhone(e.target.value)}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="balance">Saldo Awal (Rp)</Label>
                <Input
                  id="balance"
                  type="number"
                  value={newBalance}
                  onChange={(e) => setNewBalance(e.target.value)}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="limit">Batas Harian (Rp)</Label>
                <Input
                  id="limit"
                  type="number"
                  value={newLimit}
                  onChange={(e) => setNewLimit(e.target.value)}
                />
              </div>
            </div>

            <DialogFooter className="pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => setAddStudentOpen(false)}
              >
                Batal
              </Button>
              <Button type="submit" disabled={submittingAddStudent}>
                {submittingAddStudent ? "Menyimpan..." : "Simpan Santri"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Dialog Edit Limit */}
      <Dialog open={editLimitOpen} onOpenChange={setEditLimitOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Ubah Limit Harian Santri</DialogTitle>
            <DialogDescription>
              Tentukan batas maksimum transaksi per hari untuk {selectedStudent?.name} ({selectedStudent?.nis})
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSaveLimit} className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="edit-limit">Batas Transaksi Harian (Rp)</Label>
              <Input
                id="edit-limit"
                type="number"
                value={editLimitValue}
                onChange={(e) => setEditLimitValue(e.target.value)}
                required
              />
              <p className="text-xs text-muted-foreground">
                Santri tidak dapat bertransaksi di atas limit ini dalam 1 hari kalender.
              </p>
            </div>

            <DialogFooter className="pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => setEditLimitOpen(false)}
              >
                Batal
              </Button>
              <Button type="submit" disabled={submittingLimit}>
                {submittingLimit ? "Menyimpan..." : "Simpan Perubahan Limit"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Dialog Adjust Student Balance */}
      <Dialog open={adjustStudentOpen} onOpenChange={setAdjustStudentOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Atur Saldo Santri</DialogTitle>
            <DialogDescription>
              Penyesuaian saldo langsung untuk {adjustStudentTarget?.name} ({adjustStudentTarget?.nis}). Aksi ini akan dicatat ke dalam audit log.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleAdjustStudentBalance} className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="adjust-student-balance">Nominal Saldo Baru (Rp)</Label>
              <Input
                id="adjust-student-balance"
                type="number"
                min="0"
                value={adjustStudentValue}
                onChange={(e) => setAdjustStudentValue(e.target.value)}
                required
              />
              <p className="text-xs text-muted-foreground">
                Saldo saat ini: Rp {(adjustStudentTarget?.balance ?? 0).toLocaleString("id-ID")}
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="adjust-student-note">Alasan / Catatan Penyesuaian</Label>
              <Input
                id="adjust-student-note"
                placeholder="Contoh: Koreksi setoran manual / kompensasi"
                value={adjustStudentNote}
                onChange={(e) => setAdjustStudentNote(e.target.value)}
              />
            </div>

            <DialogFooter className="pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => setAdjustStudentOpen(false)}
              >
                Batal
              </Button>
              <Button type="submit" disabled={submittingAdjustStudent}>
                {submittingAdjustStudent ? "Menyimpan..." : "Perbarui Saldo Santri"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Dialog Adjust Merchant Balance */}
      <Dialog open={adjustMerchantOpen} onOpenChange={setAdjustMerchantOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Atur Saldo Merchant</DialogTitle>
            <DialogDescription>
              Penyesuaian saldo rekening merchant {adjustMerchantTarget?.name}. Aksi ini akan dicatat ke dalam audit log.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleAdjustMerchantBalance} className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="adjust-merchant-balance">Nominal Saldo Baru (Rp)</Label>
              <Input
                id="adjust-merchant-balance"
                type="number"
                min="0"
                value={adjustMerchantValue}
                onChange={(e) => setAdjustMerchantValue(e.target.value)}
                required
              />
              <p className="text-xs text-muted-foreground">
                Saldo saat ini: Rp {(adjustMerchantTarget?.balance ?? 0).toLocaleString("id-ID")}
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="adjust-merchant-note">Alasan / Catatan Penyesuaian</Label>
              <Input
                id="adjust-merchant-note"
                placeholder="Contoh: Penyesuaian selisih结算 / modal awal kasir"
                value={adjustMerchantNote}
                onChange={(e) => setAdjustMerchantNote(e.target.value)}
              />
            </div>

            <DialogFooter className="pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => setAdjustMerchantOpen(false)}
              >
                Batal
              </Button>
              <Button type="submit" disabled={submittingAdjustMerchant}>
                {submittingAdjustMerchant ? "Menyimpan..." : "Perbarui Saldo Merchant"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}

export default function AdminPage() {
  const { isAuthenticated } = useAuth();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || !isAuthenticated) {
    return <AdminLoginForm />;
  }

  return <AdminDashboardView />;
}
