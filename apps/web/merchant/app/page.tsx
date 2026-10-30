"use client";

import * as React from "react";
import { useAuth } from "@/lib/auth-context";
import { appApi, MenuItem, TransactionRecord } from "@/lib/api-client";
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
  Store,
  Lock,
  Mail,
  ArrowRight,
  AlertCircle,
  Loader2,
  UtensilsCrossed,
  LayoutDashboard,
  Receipt,
  Clock,
  BarChart3,
  Settings,
  Plus,
  Coins,
  CheckCircle2,
  Bell,
  LogOut,
  User as UserIcon,
  Search,
  RefreshCw,
  Edit2,
  Check,
  X,
  CreditCard,
  DollarSign,
} from "lucide-react";

function MerchantLoginForm() {
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
      const res = await login(email, password, "merchant-pos");
      if (!res.success) {
        setError(res.error || "Gagal masuk ke sistem kasir/merchant.");
      }
    } catch {
      setError("Terjadi kesalahan jaringan.");
    } finally {
      setSubmitting(false);
    }
  };

  const fillDemo = () => {
    setEmail("kasir@cashless.dev");
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
            SemestaPay Merchant
          </h1>
          <p className="text-sm text-muted-foreground">
            Sistem Kasir Kantin & Koperasi (Tema Warm Amber)
          </p>
        </div>

        <Card className="shadow-lg border-border/80">
          <CardHeader className="space-y-1">
            <CardTitle className="text-xl">Masuk Konsol Merchant</CardTitle>
            <CardDescription>
              Masuk dengan akun Kasir Kantin atau Pengelola Koperasi
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
                <Label htmlFor="email">Email / ID Kasir</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="kasir@semestapay.id"
                    className="pl-9"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">PIN / Kata Sandi</Label>
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
                Gunakan Akun Demo (kasir@cashless.dev)
              </Button>
            </CardContent>

            <CardFooter className="flex flex-col gap-3">
              <Button type="submit" className="w-full cursor-pointer" disabled={submitting}>
                {submitting ? (
                  <>
                    <Loader2 className="mr-2 size-4 animate-spin" />
                    Menghubungkan Mesin...
                  </>
                ) : (
                  <>
                    Buka Kasir Merchant
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

function MerchantDashboardView() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = React.useState<"overview" | "menu" | "transactions" | "shift" | "reports">("overview");

  // State
  const [items, setItems] = React.useState<MenuItem[]>([]);
  const [transactions, setTransactions] = React.useState<TransactionRecord[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [searchQuery, setSearchQuery] = React.useState("");

  // Add Item Dialog
  const [addOpen, setAddOpen] = React.useState(false);
  const [newItemName, setNewItemName] = React.useState("");
  const [newItemPrice, setNewItemPrice] = React.useState("10000");
  const [submittingAdd, setSubmittingAdd] = React.useState(false);

  // Edit Item Dialog
  const [editOpen, setEditOpen] = React.useState(false);
  const [selectedItem, setSelectedItem] = React.useState<MenuItem | null>(null);
  const [editItemPrice, setEditItemPrice] = React.useState("");
  const [submittingEdit, setSubmittingEdit] = React.useState(false);

  // Shift State
  const [shiftOpen, setShiftOpen] = React.useState(true);
  const [shiftStartTime] = React.useState("07:00 WIB");
  const [modalAwal] = React.useState(150000);

  const initials = (user?.name || "KS")
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

  const loadData = React.useCallback(async () => {
    setLoading(true);
    try {
      const [itemsRes, txRes] = await Promise.all([
        appApi.getItems().catch(() => ({ data: [] })),
        appApi.getTransactions().catch(() => ({ data: [] })),
      ]);

      if (itemsRes.data && itemsRes.data.length > 0) {
        setItems(itemsRes.data);
      } else {
        setItems([
          { id: 1, merchant_id: 1, merchant_name: "Kantin Pesantren", name: "Nasi Goreng Spesial", price: 10000, status: "active" },
          { id: 2, merchant_id: 1, merchant_name: "Kantin Pesantren", name: "Nasi Uduk Ayam", price: 8000, status: "active" },
          { id: 3, merchant_id: 1, merchant_name: "Kantin Pesantren", name: "Indomie Goreng + Telur", price: 7000, status: "active" },
          { id: 4, merchant_id: 1, merchant_name: "Kantin Pesantren", name: "Es Teh Manis", price: 3000, status: "active" },
          { id: 5, merchant_id: 1, merchant_name: "Kantin Pesantren", name: "Air Mineral Botol", price: 2000, status: "active" },
          { id: 6, merchant_id: 2, merchant_name: "Koperasi", name: "Pensil 2B & Penghapus", price: 3000, status: "active" },
          { id: 7, merchant_id: 2, merchant_name: "Koperasi", name: "Buku Tulis Santri", price: 5000, status: "active" },
        ]);
      }

      if (txRes.data && txRes.data.length > 0) {
        setTransactions(txRes.data);
      } else {
        setTransactions([
          { id: "TX-9901", created_at: "2026-10-30T12:45:00Z", type: "payment", amount: 15000, status: "success", student_name: "Ahmad Fauzi", student_nis: "2026-001", merchant_name: "Kantin", note: "Nasi Goreng + Es Teh" },
          { id: "TX-9902", created_at: "2026-10-30T12:41:00Z", type: "payment", amount: 8000, status: "success", student_name: "Citra Lestari", student_nis: "2026-003", merchant_name: "Kantin", note: "Nasi Uduk" },
          { id: "TX-9903", created_at: "2026-10-30T12:38:00Z", type: "payment", amount: 12000, status: "success", student_name: "Budi Santoso", student_nis: "2026-002", merchant_name: "Kantin", note: "Indomie + Teh" },
          { id: "TX-9904", created_at: "2026-10-30T12:30:00Z", type: "payment", amount: 55000, status: "failed", student_name: "Dewi Anggraini", student_nis: "2026-004", merchant_name: "Kantin", note: "Batas Limit Harian Tercapai" },
        ]);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    loadData();
  }, [loadData]);

  const handleAddItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newItemName || !newItemPrice) return;
    setSubmittingAdd(true);
    try {
      await appApi.createItem({
        name: newItemName,
        price: parseFloat(newItemPrice) || 0,
        merchant_id: 1,
        status: "active",
      });
      await loadData();
      setAddOpen(false);
      setNewItemName("");
      setNewItemPrice("10000");
    } catch {
      const newItem: MenuItem = {
        id: Date.now(),
        merchant_id: 1,
        merchant_name: "Kantin Pesantren",
        name: newItemName,
        price: parseFloat(newItemPrice) || 0,
        status: "active",
      };
      setItems((prev) => [newItem, ...prev]);
      setAddOpen(false);
    } finally {
      setSubmittingAdd(false);
    }
  };

  const handleSaveEditPrice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedItem) return;
    setSubmittingEdit(true);
    try {
      const priceVal = parseFloat(editItemPrice);
      await appApi.updateItem(selectedItem.id, { price: priceVal });
      setItems((prev) =>
        prev.map((i) => (i.id === selectedItem.id ? { ...i, price: priceVal } : i))
      );
      setEditOpen(false);
    } catch {
      const priceVal = parseFloat(editItemPrice);
      setItems((prev) =>
        prev.map((i) => (i.id === selectedItem.id ? { ...i, price: priceVal } : i))
      );
      setEditOpen(false);
    } finally {
      setSubmittingEdit(false);
    }
  };

  const toggleItemStatus = async (item: MenuItem) => {
    const nextStatus = item.status === "active" ? "inactive" : "active";
    try {
      await appApi.updateItem(item.id, { status: nextStatus });
    } catch {
      // optimistic update
    }
    setItems((prev) =>
      prev.map((i) => (i.id === item.id ? { ...i, status: nextStatus } : i))
    );
  };

  const filteredItems = items.filter((i) =>
    i.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalOmzetCashless = transactions
    .filter((t) => t.status === "success")
    .reduce((acc, t) => acc + t.amount, 0);

  const navItems = [
    { id: "overview", title: "Ikhtisar", icon: <LayoutDashboard className="size-4" /> },
    { id: "menu", title: "Katalog & Menu", icon: <UtensilsCrossed className="size-4" />, badge: `${items.length} Menu` },
    { id: "transactions", title: "Transaksi Tap", icon: <Receipt className="size-4" />, badge: "Hari Ini" },
    { id: "shift", title: "Shift Kasir", icon: <Clock className="size-4" /> },
    { id: "reports", title: "Laporan Penjualan", icon: <BarChart3 className="size-4" /> },
  ];

  return (
    <div className="flex min-h-screen bg-background text-foreground">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r bg-card flex flex-col shrink-0">
        <div className="h-16 border-b px-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="size-9 rounded-xl bg-primary text-primary-foreground font-bold flex items-center justify-center text-sm shadow">
              <Store className="size-5" />
            </div>
            <div>
              <h2 className="font-bold text-sm tracking-tight text-foreground leading-tight">
                SemestaPay
              </h2>
              <p className="text-xs text-muted-foreground">Kantin & Koperasi</p>
            </div>
          </div>
          <Badge variant="secondary" className="text-[10px] font-semibold uppercase tracking-wider">
            MERCHANT
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
                <p className="text-xs font-semibold truncate text-foreground">{user?.name || "Kasir Kantin"}</p>
                <p className="text-[11px] text-muted-foreground truncate">{user?.email || "kasir@cashless.dev"}</p>
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
              {activeTab === "overview" && "Dashboard Kasir Kantin & Koperasi"}
              {activeTab === "menu" && "Daftar Menu & Katalog Makanan"}
              {activeTab === "transactions" && "Log Transaksi Tap Kartu RFID"}
              {activeTab === "shift" && "Pengelolaan Shift & Setoran Kasir"}
              {activeTab === "reports" && "Ringkasan Laporan & Settlement Omzet"}
            </h1>
            <p className="text-xs text-muted-foreground">Kantin Utama Pesantren • Tema Warm Amber</p>
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
              <span className="font-medium text-xs">KASIR AKTIF</span>
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
                    <p className="text-sm font-medium leading-none">{user?.name || "Kasir"}</p>
                    <p className="text-xs leading-none text-muted-foreground">{user?.email || ""}</p>
                  </div>
                </DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  className="gap-2 text-destructive focus:text-destructive cursor-pointer"
                  onClick={() => logout()}
                >
                  <LogOut className="size-4" />
                  <span>Keluar Shift</span>
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
                      <p className="text-sm font-medium text-muted-foreground">Omzet Tap Hari Ini</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Coins className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">
                        Rp {totalOmzetCashless.toLocaleString("id-ID")}
                      </span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Semua transaksi sukses</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Frekuensi Transaksi</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Receipt className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">
                        {transactions.length} Tap
                      </span>
                      <span className="text-xs font-semibold text-emerald-600">3 Sukses</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Rata-rata 1.5 detik per tap</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Katalog Menu Aktif</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <UtensilsCrossed className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">
                        {items.filter((i) => i.status === "active").length} Menu
                      </span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Siap dijual di kasir</p>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-muted-foreground">Status Shift</p>
                      <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
                        <Clock className="size-5" />
                      </div>
                    </div>
                    <div className="mt-3 flex items-baseline gap-2">
                      <span className="text-2xl font-bold tracking-tight text-foreground">Shift Pagi</span>
                      <span className="text-xs font-semibold text-emerald-600">Terbuka</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Dimulai {shiftStartTime}</p>
                  </CardContent>
                </Card>
              </div>

              <div className="grid gap-6 lg:grid-cols-3">
                <Card className="lg:col-span-2">
                  <CardHeader className="flex flex-row items-center justify-between pb-2">
                    <div>
                      <CardTitle className="text-base font-semibold">Transaksi Tap Terkini</CardTitle>
                      <CardDescription>Pembayaran santri melalui kartu pintar RFID</CardDescription>
                    </div>
                    <Button
                      size="sm"
                      className="gap-1 text-xs cursor-pointer"
                      onClick={() => setActiveTab("transactions")}
                    >
                      Buka Semua Log
                    </Button>
                  </CardHeader>
                  <CardContent>
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Jam / ID</TableHead>
                          <TableHead>Santri</TableHead>
                          <TableHead>Rincian Pesanan</TableHead>
                          <TableHead>Nominal</TableHead>
                          <TableHead>Status</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {transactions.map((tx) => (
                          <TableRow key={tx.id}>
                            <TableCell className="font-mono text-xs">{tx.id}</TableCell>
                            <TableCell className="font-medium text-sm">{tx.student_name}</TableCell>
                            <TableCell className="text-xs text-muted-foreground">{tx.note || "-"}</TableCell>
                            <TableCell className="font-semibold text-sm">
                              Rp {tx.amount.toLocaleString("id-ID")}
                            </TableCell>
                            <TableCell>
                              <Badge
                                variant={tx.status === "success" ? "default" : "destructive"}
                                className={tx.status === "success" ? "bg-emerald-600" : ""}
                              >
                                {tx.status === "success" ? "Berhasil" : "Batas Limit"}
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
                      <CardTitle className="text-sm font-semibold">Tindakan Cepat Kasir</CardTitle>
                      <CardDescription>Pintasan transaksi & menu</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      <Button
                        variant="default"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => {
                          setActiveTab("menu");
                          setAddOpen(true);
                        }}
                      >
                        + Tambah Menu Baru
                      </Button>
                      <Button
                        variant="outline"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => setActiveTab("shift")}
                      >
                        Kelola Rekap Shift Kasir
                      </Button>
                      <Button
                        variant="secondary"
                        className="w-full justify-start text-xs cursor-pointer"
                        onClick={() => setActiveTab("reports")}
                      >
                        Laporan Rekonsiliasi Omzet
                      </Button>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="pb-3">
                      <CardTitle className="text-sm font-semibold">Status Terminal Kasir</CardTitle>
                      <CardDescription>Konektivitas mesin EDC & Reader NFC</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div className="flex items-center justify-between p-2.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-700 dark:text-emerald-400">
                        <span className="flex items-center gap-1.5 font-medium">
                          <CheckCircle2 className="size-3.5" />
                          Reader NFC ACR122U
                        </span>
                        <span className="font-semibold">SIAP TAP</span>
                      </div>
                      <div className="flex items-center justify-between p-2.5 rounded-lg bg-muted/50 border text-xs">
                        <span className="text-muted-foreground">Mode Transaksi</span>
                        <span className="font-medium text-primary">Otomatis / Offline Safe</span>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: MENU & KATALOG */}
          {activeTab === "menu" && (
            <Card>
              <CardHeader className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4">
                <div>
                  <CardTitle className="text-lg">Katalog Menu & Harga Kasir</CardTitle>
                  <CardDescription>
                    Atur ketersediaan menu makanan/minuman dan barang koperasi
                  </CardDescription>
                </div>

                <div className="flex items-center gap-3">
                  <div className="relative w-64">
                    <Search className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
                    <Input
                      placeholder="Cari menu..."
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
                    Tambah Menu
                  </Button>
                </div>
              </CardHeader>

              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nama Menu</TableHead>
                      <TableHead>Unit / Merchant</TableHead>
                      <TableHead>Harga Jual</TableHead>
                      <TableHead>Ketersediaan</TableHead>
                      <TableHead className="text-right">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredItems.map((item) => (
                      <TableRow key={item.id}>
                        <TableCell className="font-medium text-sm">{item.name}</TableCell>
                        <TableCell>
                          <Badge variant="secondary" className="text-xs">
                            {item.merchant_name}
                          </Badge>
                        </TableCell>
                        <TableCell className="font-semibold text-sm">
                          Rp {item.price.toLocaleString("id-ID")}
                        </TableCell>
                        <TableCell>
                          <button
                            onClick={() => toggleItemStatus(item)}
                            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold cursor-pointer transition-colors ${
                              item.status === "active"
                                ? "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 border border-emerald-500/20"
                                : "bg-destructive/10 text-destructive border border-destructive/20"
                            }`}
                          >
                            {item.status === "active" ? (
                              <>
                                <Check className="size-3" />
                                Tersedia
                              </>
                            ) : (
                              <>
                                <X className="size-3" />
                                Habis
                              </>
                            )}
                          </button>
                        </TableCell>
                        <TableCell className="text-right">
                          <Button
                            variant="outline"
                            size="sm"
                            className="gap-1 text-xs cursor-pointer h-7 px-2"
                            onClick={() => {
                              setSelectedItem(item);
                              setEditItemPrice(item.price.toString());
                              setEditOpen(true);
                            }}
                          >
                            <Edit2 className="size-3" />
                            Ubah Harga
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB 3: TRANSAKSI TAP */}
          {activeTab === "transactions" && (
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <div>
                  <CardTitle className="text-lg">Log Lengkap Transaksi Tap</CardTitle>
                  <CardDescription>
                    Histori pembayaran instan via kartu RFID santri hari ini
                  </CardDescription>
                </div>
                <Badge variant="outline" className="text-xs">
                  {transactions.length} Transaksi Terdeteksi
                </Badge>
              </CardHeader>
              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>ID Transaksi</TableHead>
                      <TableHead>Nama Santri</TableHead>
                      <TableHead>NIS</TableHead>
                      <TableHead>Nominal</TableHead>
                      <TableHead>Catatan / Rincian</TableHead>
                      <TableHead>Status Pembayaran</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {transactions.map((tx) => (
                      <TableRow key={tx.id}>
                        <TableCell className="font-mono text-xs font-semibold">{tx.id}</TableCell>
                        <TableCell className="font-medium text-sm">{tx.student_name}</TableCell>
                        <TableCell className="font-mono text-xs text-muted-foreground">{tx.student_nis || "-"}</TableCell>
                        <TableCell className="font-semibold text-sm">
                          Rp {tx.amount.toLocaleString("id-ID")}
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">{tx.note || "Transaksi Jajan"}</TableCell>
                        <TableCell>
                          <Badge
                            variant={tx.status === "success" ? "default" : "destructive"}
                            className={tx.status === "success" ? "bg-emerald-600" : ""}
                          >
                            {tx.status === "success" ? "Berhasil" : "Gagal Limit"}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {/* TAB 4: SHIFT KASIR */}
          {activeTab === "shift" && (
            <div className="grid gap-6 lg:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base font-semibold">Status Shift Kasir Saat Ini</CardTitle>
                  <CardDescription>Shift aktif bertanggung jawab atas uang fisik dan rekap tap</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="p-4 rounded-lg bg-muted/60 border space-y-3">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">Petugas Kasir</span>
                      <span className="font-semibold">{user?.name || "Kasir Kantin"}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">Waktu Buka Shift</span>
                      <span className="font-medium">{shiftStartTime}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">Modal Awal Kas</span>
                      <span className="font-semibold">Rp {modalAwal.toLocaleString("id-ID")}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm pt-2 border-t">
                      <span className="text-muted-foreground">Total Transaksi Tap RFID</span>
                      <span className="font-bold text-primary">Rp {totalOmzetCashless.toLocaleString("id-ID")}</span>
                    </div>
                  </div>

                  <div className="flex gap-3">
                    <Button
                      variant="destructive"
                      className="w-full cursor-pointer"
                      onClick={() => alert("Shift telah ditutup dan rekap berhasil dicetak.")}
                    >
                      Tutup Shift & Cetak Rekap
                    </Button>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base font-semibold">Panduan Kasir Tap RFID</CardTitle>
                  <CardDescription>Standar operasional pelayanan jajan cashless</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3 text-xs text-muted-foreground leading-relaxed">
                  <p>1. Masukkan total pesanan santri pada tombol kasir atau scan barcode menu.</p>
                  <p>2. Minta santri menempelkan kartu pintar RFID pada alat reader yang bercahaya biru.</p>
                  <p>3. Jika saldo cukup dan dalam batas limit, lampu hijau akan berbunyi *bip* satu kali dan struk tercetak.</p>
                  <p>4. Jika limit santri sudah tercapai, sarankan santri meminta persetujuan wali santri via aplikasi mobile.</p>
                </CardContent>
              </Card>
            </div>
          )}

          {/* TAB 5: LAPORAN PENJUALAN */}
          {activeTab === "reports" && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Laporan Rekonsiliasi & Settlement</CardTitle>
                <CardDescription>Omzet merchant otomatis disetorkan ke rekening kantin harian</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid gap-4 sm:grid-cols-3">
                  <div className="p-4 rounded-lg bg-muted border">
                    <p className="text-xs text-muted-foreground">Pendapatan Hari Ini</p>
                    <p className="text-xl font-bold mt-1">Rp {totalOmzetCashless.toLocaleString("id-ID")}</p>
                  </div>
                  <div className="p-4 rounded-lg bg-muted border">
                    <p className="text-xs text-muted-foreground">Biaya Pemeliharaan Sistem (MDR 0%)</p>
                    <p className="text-xl font-bold mt-1">Rp 0</p>
                  </div>
                  <div className="p-4 rounded-lg bg-emerald-500/10 border border-emerald-500/20">
                    <p className="text-xs text-emerald-800 dark:text-emerald-300">Siap Ditransfer ke Rekening</p>
                    <p className="text-xl font-bold text-emerald-700 dark:text-emerald-400 mt-1">
                      Rp {totalOmzetCashless.toLocaleString("id-ID")}
                    </p>
                  </div>
                </div>

                <div className="border-t pt-4 flex justify-end">
                  <Button variant="outline" className="cursor-pointer">
                    Unduh Excel Rekap
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </main>
      </div>

      {/* Dialog Add Menu */}
      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Tambah Menu Baru</DialogTitle>
            <DialogDescription>
              Tambahkan menu makanan atau barang baru ke dalam katalog kasir
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleAddItem} className="space-y-4 py-2">
            <div className="space-y-1.5">
              <Label htmlFor="item-name">Nama Makanan / Barang</Label>
              <Input
                id="item-name"
                placeholder="Contoh: Roti Bakar Coklat"
                value={newItemName}
                onChange={(e) => setNewItemName(e.target.value)}
                required
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="item-price">Harga Satuan (Rp)</Label>
              <Input
                id="item-price"
                type="number"
                value={newItemPrice}
                onChange={(e) => setNewItemPrice(e.target.value)}
                required
              />
            </div>

            <DialogFooter className="pt-4">
              <Button type="button" variant="outline" onClick={() => setAddOpen(false)}>
                Batal
              </Button>
              <Button type="submit" disabled={submittingAdd}>
                {submittingAdd ? "Menyimpan..." : "Simpan Menu"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Dialog Edit Price */}
      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Ubah Harga Menu</DialogTitle>
            <DialogDescription>
              Ubah harga jual untuk menu {selectedItem?.name}
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSaveEditPrice} className="space-y-4 py-2">
            <div className="space-y-1.5">
              <Label htmlFor="price-val">Harga Baru (Rp)</Label>
              <Input
                id="price-val"
                type="number"
                value={editItemPrice}
                onChange={(e) => setEditItemPrice(e.target.value)}
                required
              />
            </div>

            <DialogFooter className="pt-4">
              <Button type="button" variant="outline" onClick={() => setEditOpen(false)}>
                Batal
              </Button>
              <Button type="submit" disabled={submittingEdit}>
                {submittingEdit ? "Menyimpan..." : "Simpan Perubahan"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}

export default function MerchantPage() {
  const { isAuthenticated } = useAuth();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted || !isAuthenticated) {
    return <MerchantLoginForm />;
  }

  return <MerchantDashboardView />;
}
