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
    <div className="min-h-screen w-full flex items-center justify-center p-4 sm:p-6 lg:p-8 bg-muted/40 relative overflow-x-hidden">
      {/* Background ambient lighting */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden -z-10">
        <div className="absolute -top-40 left-1/2 -translate-x-1/2 w-[700px] h-[400px] bg-primary/10 blur-[130px] rounded-full" />
        <div className="absolute -bottom-40 right-10 w-[500px] h-[350px] bg-primary/10 blur-[120px] rounded-full" />
      </div>

      <div className="w-full max-w-md lg:max-w-4xl xl:max-w-5xl">
        {/* ======================================================== */}
        {/* MOBILE ONLY: BANNER GAMBAR DI LUAR CARD                  */}
        {/* ======================================================== */}
        <div className="lg:hidden mb-4 w-full h-44 sm:h-52 rounded-2xl overflow-hidden border border-border/80 shadow-md bg-slate-950">
          <img
            src="/login-banner.svg"
            alt="SemestaPay Banner"
            className="w-full h-full object-cover"
          />
        </div>

        {/* ======================================================== */}
        {/* CARD UTAMA                                               */}
        {/* Desktop: Banner gambar (kiri) & login (kanan) di DALAM card */}
        {/* Mobile: Hanya membungkus form login                       */}
        {/* ======================================================== */}
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
            {/* Top Brand Header & Greeting - Rapat & Proporsional */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between pb-1">
                <div className="flex items-center gap-2.5">
                  <div className="size-8 rounded-lg bg-primary text-primary-foreground font-bold flex items-center justify-center text-xs shadow-sm">
                    <ShieldCheck className="size-4" />
                  </div>
                  <div>
                    <span className="font-extrabold text-sm tracking-tight text-foreground leading-none">
                      SemestaPay
                    </span>
                    <p className="text-[10px] text-muted-foreground">Admin Console</p>
                  </div>
                </div>

                <Badge variant="secondary" className="text-[10px] font-semibold uppercase">
                  V2.4
                </Badge>
              </div>

              <div>
                <h2 className="text-xl sm:text-2xl font-extrabold tracking-tight text-foreground">
                  Selamat Datang
                </h2>
                <p className="text-xs sm:text-sm text-muted-foreground mt-0.5">
                  Masuk dengan akun berwenang untuk mengakses konsol
                </p>
              </div>
            </div>

            {/* Form Section */}
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
              <form onSubmit={handleSubmit} className="space-y-3.5">
                {error && (
                  <div className="flex items-start gap-3 p-3 rounded-xl bg-destructive/10 border border-destructive/20 text-destructive text-sm leading-snug">
                    <AlertCircle className="size-4 shrink-0 mt-0.5" />
                    <p>{error}</p>
                  </div>
                )}

                {/* Email Input - Normal 44px (h-11) */}
                <div className="space-y-1">
                  <Label htmlFor="email" className="text-xs sm:text-sm font-medium text-foreground">
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
                      className="h-11 pl-10 text-sm rounded-xl border-border/80 bg-background focus:bg-background transition-all shadow-xs"
                    />
                  </div>
                </div>

                {/* Password Input - Normal 44px (h-11) */}
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

                {/* Submit Button - Normal 44px (h-11) */}
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
                      Masuk ke Sistem
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

                {/* Demo Quick-Fill Buttons - Normal 40px (h-10) */}
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
                    Operator
                  </Button>
                </div>
              </form>
            )}

            {/* Footer Navigation Link - Dekat & Menyatu Rapi */}
            <div className="flex items-center justify-between text-xs text-muted-foreground pt-3 border-t border-border/60">
              <Link href="/" className="hover:text-foreground transition-colors flex items-center gap-1">
                ← Kembali ke Beranda
              </Link>
              <span className="flex items-center gap-1 text-[11px]">
                <ShieldCheck className="size-3 text-emerald-600" />
                TLS 1.3 Aktif
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
