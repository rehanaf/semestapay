"use client";

import * as React from "react";
import { useAuth } from "@/lib/auth-context";
import { appApi, StudentItem, BillItem } from "@/lib/api-client";
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
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogTrigger,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  School,
  Lock,
  Mail,
  ArrowRight,
  AlertCircle,
  Loader2,
  LayoutDashboard,
  Users,
  GraduationCap,
  ReceiptText,
  Sliders,
  Wallet,
  Settings,
  Plus,
  CreditCard,
  Bell,
  LogOut,
  User as UserIcon,
  Search,
  CheckCircle2,
  RefreshCw,
  Edit2,
  Phone,
  Eye,
  EyeOff,
  Sparkles,
  ShieldCheck,
} from "lucide-react";

function SchoolLoginForm() {
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
      const res = await login(email, password, "school-portal");
      if (!res.success) {
        setError(res.error || "Gagal masuk ke sistem sekolah.");
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
                  <div className="size-8 rounded-lg bg-primary text-primary-foreground font-bold flex items-center justify-center text-xs shadow-sm">
                    <GraduationCap className="size-4" />
                  </div>
                  <div>
                    <span className="font-extrabold text-sm tracking-tight text-foreground leading-none">
                      SemestaPay
                    </span>
                    <p className="text-[10px] text-muted-foreground">Portal Pesantren</p>
                  </div>
                </div>

                <Badge variant="secondary" className="text-[10px] font-semibold uppercase">
                  SEKOLAH
                </Badge>
              </div>

              <div>
                <h2 className="text-xl sm:text-2xl font-extrabold tracking-tight text-foreground">
                  Portal Pesantren
                </h2>
                <p className="text-xs sm:text-sm text-muted-foreground mt-0.5">
                  Masuk dengan akun operator atau bendahara pondok
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

              {/* Email Input */}
              <div className="space-y-1">
                <Label htmlFor="email" className="text-xs sm:text-sm font-medium text-foreground">
                  Email Operator / Bendahara
                </Label>
                <div className="relative">
                  <Mail className="absolute left-3.5 top-3.5 size-4 text-muted-foreground pointer-events-none" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="operator@pesantren.sch.id"
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
                    Memverifikasi Akun...
                  </>
                ) : (
                  <>
                    Masuk ke Portal Sekolah
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
              <div className="grid grid-cols-2 gap-2">
                <Button
                  type="button"
                  variant="outline"
                  className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                  onClick={() => fillDemo("operator@cashless.dev")}
                >
                  <Sparkles className="size-3.5 text-emerald-500" />
                  Operator Pondok
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                  onClick={() => fillDemo("admin@cashless.dev")}
                >
                  <Sparkles className="size-3.5 text-amber-500" />
                  Admin Pusat
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

function SchoolDashboardView() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = React.useState<"overview" | "students" | "bills" | "limits" | "settings">("overview");

  // State Data
  const [students, setStudents] = React.useState<StudentItem[]>([]);
  const [bills, setBills] = React.useState<BillItem[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [searchQuery, setSearchQuery] = React.useState("");

  // Add Student Form State
  const [addOpen, setAddOpen] = React.useState(false);
  const [newNis, setNewNis] = React.useState("");
  const [newName, setNewName] = React.useState("");
  const [newCardUid, setNewCardUid] = React.useState("");
  const [newBalance, setNewBalance] = React.useState("100000");
  const [newLimit, setNewLimit] = React.useState("50000");
  const [newPhone, setNewPhone] = React.useState("");
  const [submittingAdd, setSubmittingAdd] = React.useState(false);

  // Edit Limit Form State
  const [editLimitOpen, setEditLimitOpen] = React.useState(false);
  const [selectedStudent, setSelectedStudent] = React.useState<StudentItem | null>(null);
  const [editLimitValue, setEditLimitValue] = React.useState("50000");
  const [submittingLimit, setSubmittingLimit] = React.useState(false);

  const initials = (user?.name || "OP")
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  const loadData = React.useCallback(async () => {
    setLoading(true);
    try {
      const [studentsRes, billsRes] = await Promise.all([
        appApi.getStudents().catch(() => ({ data: [] })),
        appApi.getBills().catch(() => ({ data: [] })),
      ]);
      if (studentsRes.data && studentsRes.data.length > 0) {
        setStudents(studentsRes.data);
      } else {
        // Fallback default demo data
        setStudents([
          { id: 1, nis: "2026-001", name: "Ahmad Fauzi", class_name: "Kelas 7A", card_uid: "DEMO-UID-0001", card_status: "active", balance: 114000, daily_limit: 50000, status: "active", phone_parent: "081312000010" },
          { id: 2, nis: "2026-002", name: "Budi Santoso", class_name: "Kelas 7B", card_uid: "DEMO-UID-0002", card_status: "active", balance: 152000, daily_limit: 50000, status: "active", phone_parent: "081312000011" },
          { id: 3, nis: "2026-003", name: "Citra Lestari", class_name: "Kelas 7A", card_uid: "DEMO-UID-0003", card_status: "active", balance: 129000, daily_limit: 50000, status: "active", phone_parent: "081312000012" },
          { id: 4, nis: "2026-004", name: "Dewi Anggraini", class_name: "Kelas 7B", card_uid: "DEMO-UID-0004", card_status: "active", balance: 133000, daily_limit: 50000, status: "active", phone_parent: "081312000013" },
          { id: 5, nis: "2026-005", name: "Eka Prasetyo", class_name: "Kelas 7A", card_uid: "DEMO-UID-0005", card_status: "active", balance: 149000, daily_limit: 50000, status: "active", phone_parent: "081312000014" },
        ]);
      }

      if (billsRes.data && billsRes.data.length > 0) {
        setBills(billsRes.data);
      } else {
        setBills([
          { id: 101, type: "spp", period: "Oktober 2026", description: "SPP Syahriah & Asrama Bulan Oktober 2026", amount: 400000, paid_amount: 0, due_date: "2026-10-15", status: "pending" },
          { id: 102, type: "spp", period: "Oktober 2026", description: "SPP Syahriah & Asrama Bulan Oktober 2026", amount: 400000, paid_amount: 0, due_date: "2026-10-15", status: "pending" },
        ]);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    loadData();
  }, [loadData]);

  const handleAddStudent = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newNis || !newName) return;
    setSubmittingAdd(true);
    try {
      await appApi.createStudent({
        nis: newNis,
        name: newName,
        card_uid: newCardUid || undefined,
        balance: parseFloat(newBalance) || 0,
        daily_limit: parseFloat(newLimit) || 50000,
        phone_parent: newPhone || undefined,
      });
      await loadData();
      setAddOpen(false);
      setNewNis("");
      setNewName("");
      setNewCardUid("");
      setNewPhone("");
    } catch {
      // Local optimistic update
      const newSt: StudentItem = {
        id: Date.now(),
        nis: newNis,
        name: newName,
        class_name: "Kelas 7A",
        card_uid: newCardUid || `UID-${Date.now().toString().slice(-4)}`,
        card_status: "active",
        balance: parseFloat(newBalance) || 0,
        daily_limit: parseFloat(newLimit) || 50000,
        status: "active",
        phone_parent: newPhone,
      };
      setStudents((prev) => [newSt, ...prev]);
      setAddOpen(false);
    } finally {
      setSubmittingAdd(false);
    }
  };

  const handleSaveLimit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStudent) return;
    setSubmittingLimit(true);
    try {
      const val = parseFloat(editLimitValue);
      await appApi.updateStudent(selectedStudent.id, { daily_limit: val });
      setStudents((prev) =>
        prev.map((s) => (s.id === selectedStudent.id ? { ...s, daily_limit: val } : s))
      );
      setEditLimitOpen(false);
    } catch {
      const val = parseFloat(editLimitValue);
      setStudents((prev) =>
        prev.map((s) => (s.id === selectedStudent.id ? { ...s, daily_limit: val } : s))
      );
      setEditLimitOpen(false);
    } finally {
      setSubmittingLimit(false);
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
    { id: "students", title: "Data Santri", icon: <Users className="size-4" />, badge: `${totalSantri}` },
    { id: "bills", title: "Tagihan SPP", icon: <ReceiptText className="size-4" />, badge: `${bills.length} Tertunggak` },
    { id: "limits", title: "Batas Belanja Harian", icon: <Sliders className="size-4" /> },
    { id: "settings", title: "Pengaturan Lembaga", icon: <Settings className="size-4" /> },
  ];

  return (
    <div className="flex min-h-screen bg-background text-foreground">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r bg-card flex flex-col shrink-0">
        <div className="h-16 border-b px-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="size-9 rounded-xl bg-primary text-primary-foreground font-bold flex items-center justify-center text-sm shadow">
              <School className="size-5" />
            </div>
            <div>
              <h2 className="font-bold text-sm tracking-tight text-foreground leading-tight">
                SemestaPay
              </h2>
              <p className="text-xs text-muted-foreground">Portal Pesantren</p>
            </div>
          </div>
          <Badge variant="secondary" className="text-[10px] font-semibold uppercase tracking-wider">
            SEKOLAH
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
                <p className="text-xs font-semibold truncate text-foreground">{user?.name || "Operator"}</p>
                <p className="text-[11px] text-muted-foreground truncate">{user?.email || "operator@cashless.dev"}</p>
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
          <div className="flex items-center gap-3">
            <div>
              <h1 className="text-lg font-bold tracking-tight text-foreground">
                {activeTab === "overview" && "Dashboard Pengelola Sekolah"}
                {activeTab === "students" && "Manajemen Data Santri & Kartu RFID"}
                {activeTab === "bills" && "Tagihan SPP & Pembayaran"}
                {activeTab === "limits" && "Batas Belanja & Proteksi Harian"}
                {activeTab === "settings" && "Pengaturan Profil Lembaga"}
              </h1>
              <p className="text-xs text-muted-foreground">
                Pesantren Digital Semesta • Tema Emerald Green
              </p>
            </div>
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
              <span className="font-medium text-xs">ONLINE</span>
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
                <DropdownMenuLabel className="font-normal">
                  <div className="flex flex-col space-y-1">
                    <p className="text-sm font-medium leading-none">{user?.name || "Operator"}</p>
                    <p className="text-xs leading-none text-muted-foreground">{user?.email || ""}</p>
                  </div>
                </DropdownMenuLabel>
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
                      <p className="text-sm font-medium text-muted-foreground">Santri Terdaftar</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Users className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">{totalSantri} Santri</span>
                      <span className="text-xs font-semibold text-emerald-600">100% Aktif</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Kelas 7A & 7B</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Tagihan SPP Tertunggak</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <ReceiptText className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">Rp 800.000</span>
                      <span className="text-xs font-semibold text-rose-600">2 Tagihan</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Bulan berjalan</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Rata-rata Saldo</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Wallet className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">
                        Rp {avgSaldo.toLocaleString("id-ID")}
                      </span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Batas: Rp 50.000/hari</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Kartu RFID Terbit</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <CreditCard className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">{activeCards} Kartu</span>
                      <span className="text-xs font-semibold text-emerald-600">Terhubung</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Semua kartu status aktif</p>
                  </CardContent>
                </Card>
              </div>

              <div className="grid gap-6 lg:grid-cols-3">
                <Card className="lg:col-span-2">
                  <CardHeader className="flex flex-row items-center justify-between pb-2">
                    <div>
                      <CardTitle className="text-base font-semibold">Daftar Santri & Saldo Kartu</CardTitle>
                      <CardDescription>Data santri terhubung dengan kartu pintar RFID</CardDescription>
                    </div>
                    <Button
                      size="sm"
                      className="gap-1 text-xs cursor-pointer"
                      onClick={() => setActiveTab("students")}
                    >
                      Buka Semua Santri
                    </Button>
                  </CardHeader>
                  <CardContent>
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>NIS</TableHead>
                          <TableHead>Nama Santri</TableHead>
                          <TableHead>Kelas</TableHead>
                          <TableHead>Saldo</TableHead>
                          <TableHead>Kartu RFID</TableHead>
                          <TableHead>Status</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {students.slice(0, 5).map((s) => (
                          <TableRow key={s.id}>
                            <TableCell className="font-mono text-xs">{s.nis}</TableCell>
                            <TableCell className="font-medium text-sm">{s.name}</TableCell>
                            <TableCell className="text-sm">{s.class_name}</TableCell>
                            <TableCell className="font-semibold text-sm">
                              Rp {s.balance.toLocaleString("id-ID")}
                            </TableCell>
                            <TableCell>
                              <code className="text-xs bg-muted px-1.5 py-0.5 rounded font-mono">
                                {s.card_uid || "Belum Terhubung"}
                              </code>
                            </TableCell>
                            <TableCell>
                              <Badge variant="default" className="bg-emerald-600">
                                {s.status === "active" ? "Aktif" : s.status}
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
                      <CardTitle className="text-sm font-semibold">Tindakan Cepat Pengelola</CardTitle>
                      <CardDescription>Pintasan fungsi harian operasional</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      <Button
                        variant="default"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => {
                          setActiveTab("students");
                          setAddOpen(true);
                        }}
                      >
                        + Daftarkan Santri Baru
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
                        Atur Limit Belanja Santri
                      </Button>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="pb-3">
                      <CardTitle className="text-sm font-semibold">Status Sambungan Pembaca RFID</CardTitle>
                      <CardDescription>Integrasi terminal NFC/RFID di pos gerbang</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div className="flex items-center justify-between p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-700 dark:text-emerald-400">
                        <span className="flex items-center gap-1.5 font-medium">
                          <CheckCircle2 className="size-3.5" />
                          Terminal Gerbang Utama
                        </span>
                        <span className="font-semibold">ONLINE</span>
                      </div>
                      <div className="flex items-center justify-between p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-700 dark:text-emerald-400">
                        <span className="flex items-center gap-1.5 font-medium">
                          <CheckCircle2 className="size-3.5" />
                          Kantin & Koperasi
                        </span>
                        <span className="font-semibold">ONLINE</span>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: DATA SANTRI */}
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
                    onClick={() => setAddOpen(true)}
                  >
                    <Plus className="size-4" />
                    Tambah Santri
                  </Button>

                  <Dialog open={addOpen} onOpenChange={setAddOpen}>
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
                            onClick={() => setAddOpen(false)}
                          >
                            Batal
                          </Button>
                          <Button type="submit" disabled={submittingAdd}>
                            {submittingAdd ? "Menyimpan..." : "Simpan Santri"}
                          </Button>
                        </DialogFooter>
                      </form>
                    </DialogContent>
                  </Dialog>
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
                      <TableHead className="text-right">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredStudents.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={8} className="text-center py-8 text-muted-foreground">
                          Tidak ada data santri ditemukan.
                        </TableCell>
                      </TableRow>
                    ) : (
                      filteredStudents.map((s) => (
                        <TableRow key={s.id}>
                          <TableCell className="font-mono text-xs font-semibold">{s.nis}</TableCell>
                          <TableCell className="font-medium">{s.name}</TableCell>
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
                          <TableCell className="text-right">
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
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB 3: TAGIHAN SPP */}
          {activeTab === "bills" && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="text-lg">Daftar Tagihan SPP & Syahriah</CardTitle>
                  <CardDescription>
                    Kelola tagihan bulanan santri dan pantau status pembayaran auto-debet
                  </CardDescription>
                </div>
                <Badge variant="outline" className="text-xs">
                  Periode Aktif: Oktober 2026
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

          {/* TAB 4: BATAS BELANJA HARIAN */}
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
                  {students.slice(0, 4).map((s) => (
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

          {/* TAB 5: PENGATURAN LEMBAGA */}
          {activeTab === "settings" && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Profil & Konfigurasi Lembaga</CardTitle>
                <CardDescription>Identitas sekolah dan pengaturan integrasi cashless SemestaPay</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="space-y-2">
                    <Label>Nama Pesantren / Sekolah</Label>
                    <Input defaultValue="Pondok Pesantren Digital Semesta" />
                  </div>
                  <div className="space-y-2">
                    <Label>Nomor Statistik Pesantren (NSPN/NSPP)</Label>
                    <Input defaultValue="510032010999" />
                  </div>
                  <div className="space-y-2">
                    <Label>Alamat Lembaga</Label>
                    <Input defaultValue="Jl. Raya Semesta No. 88, Cibinong, Bogor" />
                  </div>
                  <div className="space-y-2">
                    <Label>Kontak Hotline Admin</Label>
                    <Input defaultValue="0813-1200-0001" />
                  </div>
                </div>

                <div className="border-t pt-4 flex justify-end">
                  <Button className="cursor-pointer">Simpan Perubahan</Button>
                </div>
              </CardContent>
            </Card>
          )}
        </main>
      </div>

      {/* Dialog Edit Limit */}
      <Dialog open={editLimitOpen} onOpenChange={setEditLimitOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Ubah Limit Harian Santri</DialogTitle>
            <DialogDescription>
              Atur batas maksimal belanja per hari untuk {selectedStudent?.name} ({selectedStudent?.nis})
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSaveLimit} className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="limit-val">Batas Harian (Rupiah)</Label>
              <Input
                id="limit-val"
                type="number"
                value={editLimitValue}
                onChange={(e) => setEditLimitValue(e.target.value)}
                required
              />
              <p className="text-xs text-muted-foreground">
                Setiap pergantian tanggal pukul 00:00 WIB kuota harian akan direset penuh.
              </p>
            </div>

            <DialogFooter className="pt-4">
              <Button type="button" variant="outline" onClick={() => setEditLimitOpen(false)}>
                Batal
              </Button>
              <Button type="submit" disabled={submittingLimit}>
                {submittingLimit ? "Menyimpan..." : "Simpan Limit"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}

export default function SchoolPage() {
  const { isAuthenticated } = useAuth();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || !isAuthenticated) {
    return <SchoolLoginForm />;
  }

  return <SchoolDashboardView />;
}
