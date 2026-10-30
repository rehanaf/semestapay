"use client";

import * as React from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Mail,
  Lock,
  Eye,
  EyeOff,
  ArrowRight,
  ShieldCheck,
  Sparkles,
  AlertCircle,
  Loader2,
  CheckCircle2,
  Radio,
  Zap,
  CreditCard,
  Building2,
  Check,
} from "lucide-react";

export default function TestUiLoginPage() {
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [showPassword, setShowPassword] = React.useState(false);
  const [rememberMe, setRememberMe] = React.useState(true);
  const [submitting, setSubmitting] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const [success, setSuccess] = React.useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Silakan lengkapi email dan kata sandi Anda.");
      return;
    }

    setError(null);
    setSubmitting(true);

    // Simulate login API call
    setTimeout(() => {
      setSubmitting(false);
      setSuccess(true);
    }, 1200);
  };

  const fillDemo = (roleEmail: string) => {
    setEmail(roleEmail);
    setPassword("password");
    setError(null);
  };

  return (
    <div className="min-h-screen w-full flex flex-col lg:flex-row bg-background">
      {/* ======================================================== */}
      {/* SISI KIRI (Desktop) / SISI ATAS (Mobile): BANNER VISUAL   */}
      {/* ======================================================== */}
      <div className="relative w-full lg:w-1/2 xl:w-5/12 bg-slate-950 text-white flex flex-col justify-between p-6 sm:p-10 lg:p-12 overflow-hidden border-b lg:border-b-0 lg:border-r border-slate-800">
        {/* Ambient Glows */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
          <div className="absolute -top-24 -left-24 w-96 h-96 bg-indigo-600/30 blur-[120px] rounded-full" />
          <div className="absolute top-1/2 -right-20 w-80 h-80 bg-blue-500/20 blur-[100px] rounded-full" />
          <div className="absolute -bottom-24 left-1/3 w-96 h-96 bg-emerald-500/15 blur-[120px] rounded-full" />
          {/* Subtle Grid Lines */}
          <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:32px_32px]" />
        </div>

        {/* Banner Top: Brand Logo */}
        <div className="relative z-10 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="size-10 sm:size-11 rounded-xl bg-gradient-to-tr from-indigo-500 to-blue-500 flex items-center justify-center font-bold text-white shadow-lg shadow-indigo-500/30 ring-2 ring-white/20">
              <ShieldCheck className="size-6 stroke-[2.2]" />
            </div>
            <div>
              <span className="font-extrabold text-lg sm:text-xl tracking-tight text-white">
                SemestaPay
              </span>
              <p className="text-[11px] text-slate-400 font-medium hidden sm:block">
                Digital Islamic School Payment Ecosystem
              </p>
            </div>
          </div>

          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-semibold bg-emerald-500/10 border border-emerald-500/30 text-emerald-400">
            <span className="size-2 rounded-full bg-emerald-400 animate-pulse" />
            Sistem Aktif
          </div>
        </div>

        {/* Banner Center: Mockup Kartu RFID & Headline */}
        <div className="relative z-10 py-8 lg:py-12 space-y-6">
          <div className="space-y-3 max-w-lg">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-indigo-500/10 border border-indigo-500/30 text-indigo-300">
              <Sparkles className="size-3.5 text-indigo-400" />
              Solusi Cashless Terpadu Pesantren
            </div>
            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold tracking-tight text-white leading-tight">
              Satu Kartu Pintar untuk Seluruh Transaksi Santri
            </h1>
            <p className="text-xs sm:text-sm text-slate-300 leading-relaxed max-w-md hidden sm:block">
              Kelola pembayaran SPP, kasir kantin & koperasi santri, hingga batas belanja harian dengan aman dan transparan.
            </p>
          </div>

          {/* Visual Mockup: Kartu RFID Pintar SemestaPay (Desktop & Tablet) */}
          <div className="relative pt-2 max-w-md mx-auto lg:mx-0">
            {/* Kartu Utama */}
            <div className="relative rounded-2xl bg-gradient-to-tr from-slate-900 via-indigo-950 to-slate-900 p-5 sm:p-6 border border-indigo-500/40 shadow-2xl shadow-indigo-950/60 backdrop-blur-md">
              <div className="flex items-center justify-between pb-6">
                <div className="flex items-center gap-2">
                  <div className="size-7 rounded-lg bg-indigo-500/20 border border-indigo-400/40 flex items-center justify-center">
                    <Radio className="size-4 text-indigo-300 animate-pulse" />
                  </div>
                  <span className="text-xs font-bold tracking-widest text-indigo-200 uppercase">
                    RFID SMART CARD
                  </span>
                </div>
                <span className="text-[11px] font-mono font-semibold px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                  AKTIF
                </span>
              </div>

              {/* Chip & Contactless */}
              <div className="flex items-center gap-3 my-2">
                <div className="w-10 h-8 rounded-md bg-gradient-to-br from-amber-200 to-amber-500 shadow-inner border border-amber-300/40 flex items-center justify-center">
                  <div className="w-6 h-5 border border-amber-700/30 rounded-[3px]" />
                </div>
                <Radio className="size-5 text-indigo-300/80 -rotate-90" />
              </div>

              {/* Detail Kartu */}
              <div className="pt-4 flex items-end justify-between">
                <div>
                  <p className="text-[10px] uppercase tracking-wider text-slate-400 font-mono">
                    Santri Binaan
                  </p>
                  <p className="text-sm font-bold text-white tracking-wide">
                    AHMAD FAUZI
                  </p>
                  <p className="text-[11px] text-indigo-300 font-mono">
                    NIS: 2026-001 • Kelas 7A
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-[10px] uppercase tracking-wider text-slate-400 font-mono">
                    Saldo Dompet
                  </p>
                  <p className="text-sm sm:text-base font-extrabold text-emerald-400 font-mono">
                    Rp 114.000
                  </p>
                </div>
              </div>
            </div>

            {/* Floating Glass Badge 1 */}
            <div className="absolute -bottom-3 -right-2 sm:-right-4 px-3 py-1.5 rounded-xl bg-slate-900/90 border border-slate-700 shadow-lg backdrop-blur-md flex items-center gap-2 text-xs">
              <div className="size-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
                <Zap className="size-3" />
              </div>
              <span className="font-semibold text-slate-200 text-[11px]">Tap Kasir &lt; 1 Detik</span>
            </div>
          </div>
        </div>

        {/* Banner Bottom: Footer Info */}
        <div className="relative z-10 pt-4 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
          <p>© 2026 SemestaPay. Hak Cipta Dilindungi.</p>
          <span className="hidden sm:inline-block">Konsol Sentral V2.4</span>
        </div>
      </div>

      {/* ======================================================== */}
      {/* SISI KANAN (Desktop) / SISI BAWAH (Mobile): FORM LOGIN    */}
      {/* ======================================================== */}
      <div className="flex-1 flex items-center justify-center p-6 sm:p-10 lg:p-14 relative">
        <div className="w-full max-w-[440px] space-y-6">
          {/* Header Form */}
          <div className="space-y-1.5">
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-foreground">
              Masuk ke Konsol
            </h2>
            <p className="text-sm text-muted-foreground">
              Gunakan akun Administrator, Pengelola Sekolah, atau Kasir
            </p>
          </div>

          {/* Card Form */}
          <div className="rounded-2xl border border-border/80 bg-card p-6 sm:p-8 shadow-xl space-y-5">
            {success ? (
              <div className="py-6 text-center space-y-4">
                <div className="size-16 rounded-full bg-emerald-500/10 text-emerald-600 flex items-center justify-center mx-auto border border-emerald-500/20 animate-bounce">
                  <CheckCircle2 className="size-8" />
                </div>
                <div className="space-y-1">
                  <h3 className="text-lg font-bold text-foreground">Login Berhasil!</h3>
                  <p className="text-xs text-muted-foreground">
                    Sesi Anda telah terverifikasi. Mengarahkan ke Dashboard...
                  </p>
                </div>
                <Button
                  type="button"
                  className="h-11 px-6 rounded-xl text-sm font-semibold cursor-pointer"
                  onClick={() => setSuccess(false)}
                >
                  Coba Login Ulang
                </Button>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                {error && (
                  <div className="flex items-start gap-3 p-3.5 rounded-xl bg-destructive/10 border border-destructive/20 text-destructive text-sm leading-snug">
                    <AlertCircle className="size-4 shrink-0 mt-0.5" />
                    <p>{error}</p>
                  </div>
                )}

                {/* Email Input - Standar Normal 44px (h-11) */}
                <div className="space-y-1.5">
                  <Label htmlFor="email" className="text-sm font-medium text-foreground">
                    Email Pengguna
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
                      className="h-11 pl-10 text-sm rounded-xl border-border/80 bg-background/60 focus:bg-background transition-all shadow-xs"
                    />
                  </div>
                </div>

                {/* Password Input - Standar Normal 44px (h-11) */}
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between">
                    <Label htmlFor="password" className="text-sm font-medium text-foreground">
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
                      className="h-11 pl-10 pr-11 text-sm rounded-xl border-border/80 bg-background/60 focus:bg-background transition-all shadow-xs font-mono"
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
                <div className="flex items-center gap-2.5 pt-1">
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

                {/* Submit Button - Standar Normal 44px (h-11) */}
                <Button
                  type="submit"
                  disabled={submitting}
                  className="w-full h-11 text-sm font-semibold rounded-xl shadow-md shadow-primary/20 hover:shadow-lg hover:shadow-primary/30 transition-all cursor-pointer gap-2 mt-2"
                >
                  {submitting ? (
                    <>
                      <Loader2 className="size-4 animate-spin" />
                      Memverifikasi Akun...
                    </>
                  ) : (
                    <>
                      Masuk ke Sistem
                      <ArrowRight className="size-4" />
                    </>
                  )}
                </Button>

                {/* Divider Akun Demo */}
                <div className="relative py-2">
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
                    onClick={() => fillDemo("admin@cashless.dev")}
                  >
                    <Sparkles className="size-3.5 text-amber-500" />
                    Superadmin
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                    onClick={() => fillDemo("operator@cashless.dev")}
                  >
                    <Sparkles className="size-3.5 text-emerald-500" />
                    Operator Sekolah
                  </Button>
                </div>
              </form>
            )}
          </div>

          {/* Footer Navigation Link */}
          <div className="flex items-center justify-between text-xs text-muted-foreground px-1">
            <Link href="/" className="hover:text-foreground transition-colors flex items-center gap-1">
              ← Kembali ke Dashboard
            </Link>
            <span className="flex items-center gap-1">
              <ShieldCheck className="size-3.5 text-emerald-600" />
              Koneksi Terenkripsi SSL
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
