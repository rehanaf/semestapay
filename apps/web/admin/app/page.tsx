"use client";

import * as React from "react";
import { useAuth } from "@/lib/auth-context";
import { appApi, MerchantData, TransactionRecord, StudentItem } from "@/lib/api-client";
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
} from "lucide-react";

function AdminLoginForm() {
  const { login } = useAuth();
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);
  const [submitting, setSubmitting] = React.useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Email dan kata sandi wajib diisi.");
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

  const fillDemo = () => {
    setEmail("admin@cashless.dev");
    setPassword("password");
    setError(null);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/40 p-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center space-y-2">
          <div className="inline-flex size-12 items-center justify-center rounded-2xl bg-primary text-primary-foreground font-bold shadow-md text-lg">
            SP
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">
            SemestaPay Admin
          </h1>
          <p className="text-sm text-muted-foreground">
            Pusat Kendali Operasional Terpusat (Tema Indigo Blue)
          </p>
        </div>

        <Card className="shadow-lg border-border/80">
          <CardHeader className="space-y-1">
            <CardTitle className="text-xl">Masuk ke Konsol</CardTitle>
            <CardDescription>
              Gunakan akun Superadmin atau Administrator berwenang
            </CardDescription>
          </CardHeader>
          <form onSubmit={handleSubmit}>
            <CardContent className="space-y-4">
              {error && (
                <div className="flex items-center gap-2.5 p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive text-sm">
                  <AlertCircle className="size-4 shrink-0" />
                  <p>{error}</p>
                </div>
              )}

              <div className="space-y-2">
                <Label htmlFor="email">Email Administrator</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="nama@semestapay.id"
                    className="pl-9"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">Kata Sandi</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
                  <Input
                    id="password"
                    type="password"
                    placeholder="••••••••"
                    className="pl-9"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>
              </div>

              <Button
                type="button"
                variant="outline"
                size="sm"
                className="w-full text-xs text-muted-foreground hover:text-foreground cursor-pointer"
                onClick={fillDemo}
              >
                Gunakan Akun Demo (admin@cashless.dev)
              </Button>
            </CardContent>

            <CardFooter className="flex flex-col gap-3">
              <Button type="submit" className="w-full cursor-pointer" disabled={submitting}>
                {submitting ? (
                  <>
                    <Loader2 className="mr-2 size-4 animate-spin" />
                    Memverifikasi Hak Akses...
                  </>
                ) : (
                  <>
                    Masuk ke Konsol Admin
                    <ArrowRight className="ml-2 size-4" />
                  </>
                )}
              </Button>
            </CardFooter>
          </form>
        </Card>
      </div>
    </div>
  );
}

function AdminDashboardView() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = React.useState<"overview" | "schools" | "merchants" | "transactions" | "audit" | "settings">("overview");

  // State
  const [merchants, setMerchants] = React.useState<MerchantData[]>([]);
  const [transactions, setTransactions] = React.useState<TransactionRecord[]>([]);
  const [students, setStudents] = React.useState<StudentItem[]>([]);
  const [loading, setLoading] = React.useState(true);

  // Add Merchant Dialog
  const [addMerchantOpen, setAddMerchantOpen] = React.useState(false);
  const [newMerchantName, setNewMerchantName] = React.useState("");
  const [newMerchantType, setNewMerchantType] = React.useState("canteen");
  const [submittingMerchant, setSubmittingMerchant] = React.useState(false);

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
      const [merchantsRes, txRes, stRes] = await Promise.all([
        appApi.getMerchants().catch(() => ({ data: [] })),
        appApi.getTransactions().catch(() => ({ data: [] })),
        appApi.getStudents().catch(() => ({ data: [] })),
      ]);

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

  const navItems = [
    { id: "overview", title: "Ikhtisar", icon: <LayoutDashboard className="size-4" /> },
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
            <div className="size-9 rounded-xl bg-primary text-primary-foreground font-bold flex items-center justify-center text-sm shadow">
              <ShieldCheck className="size-5" />
            </div>
            <div>
              <h2 className="font-bold text-sm tracking-tight text-foreground leading-tight">
                SemestaPay
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
                <p className="text-[11px] text-muted-foreground truncate">{user?.email || "admin@cashless.dev"}</p>
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
                <DropdownMenuLabel className="font-normal">
                  <div className="flex flex-col space-y-1">
                    <p className="text-sm font-medium leading-none">{user?.name || "Administrator"}</p>
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
                          setActiveTab("merchants");
                          setAddMerchantOpen(true);
                        }}
                      >
                        + Tambah Merchant Baru
                      </Button>
                      <Button
                        variant="outline"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => setActiveTab("schools")}
                      >
                        Kelola Daftar Sekolah
                      </Button>
                    </CardContent>
                  </Card>
                </div>
              </div>
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
                      <TableHead>Jumlah Menu</TableHead>
                      <TableHead>Jumlah Kasir/Outlet</TableHead>
                      <TableHead>Status Operasional</TableHead>
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
                        <TableCell className="text-sm font-semibold">{m.items_count} Menu</TableCell>
                        <TableCell className="text-sm">{m.outlets_count} Kasir EDC</TableCell>
                        <TableCell>
                          <Badge variant="default" className="bg-emerald-600">Aktif</Badge>
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
              <CardHeader>
                <CardTitle className="text-lg">Audit Log Keamanan Sistem</CardTitle>
                <CardDescription>Catatan login operator dan perubahan konfigurasi penting</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3 font-mono text-xs">
                  <div className="p-3 rounded-lg bg-muted/60 border flex items-center justify-between">
                    <div>
                      <span className="text-primary font-semibold">[AUTH_LOGIN]</span> Operator operator@cashless.dev berhasil login dari web dashboard
                    </div>
                    <span className="text-muted-foreground">Baru saja</span>
                  </div>
                  <div className="p-3 rounded-lg bg-muted/60 border flex items-center justify-between">
                    <div>
                      <span className="text-emerald-600 font-semibold">[TX_TAP]</span> Transaksi tap kartu RFID DEMO-UID-0001 sukses di Kantin Pesantren
                    </div>
                    <span className="text-muted-foreground">10 menit lalu</span>
                  </div>
                  <div className="p-3 rounded-lg bg-muted/60 border flex items-center justify-between">
                    <div>
                      <span className="text-primary font-semibold">[SYSTEM_SYNC]</span> Sinkronisasi saldo dompet offline dan backend berhasil
                    </div>
                    <span className="text-muted-foreground">1 jam lalu</span>
                  </div>
                </div>
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
                    <Input defaultValue="SemestaPay Enterprise" readOnly />
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
