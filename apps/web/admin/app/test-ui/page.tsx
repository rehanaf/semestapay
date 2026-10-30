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
    <div className="min-h-screen w-full relative flex items-center justify-center p-4 sm:p-6 overflow-hidden bg-background">
      {/* Ambient background glow & grid pattern */}
      <div className="absolute inset-0 pointer-events-none -z-10 overflow-hidden">
        <div className="absolute -top-40 left-1/2 -translate-x-1/2 w-[650px] h-[450px] bg-primary/15 blur-[120px] rounded-full" />
        <div className="absolute -bottom-40 right-10 w-[450px] h-[350px] bg-primary/10 blur-[100px] rounded-full" />
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#8080800a_1px,transparent_1px),linear-gradient(to_bottom,#8080800a_1px,transparent_1px)] bg-[size:24px_24px]" />
      </div>

      <div className="w-full max-w-[460px] space-y-6 relative z-10">
        {/* Brand Header */}
        <div className="text-center space-y-2">
          <div className="inline-flex size-14 items-center justify-center rounded-2xl bg-gradient-to-tr from-primary to-primary/80 text-primary-foreground shadow-lg shadow-primary/25 ring-4 ring-primary/10">
            <ShieldCheck className="size-8 stroke-[2.2]" />
          </div>
          <div className="space-y-1">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-primary/10 text-primary border border-primary/20">
              <span className="size-2 rounded-full bg-primary animate-pulse" />
              Test UI Modern V2
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-foreground">
              SemestaPay Console
            </h1>
            <p className="text-sm text-muted-foreground max-w-sm mx-auto">
              Masuk ke pusat kendali sistem pembayaran non-tunai pesantren
            </p>
          </div>
        </div>

        {/* Main Modern Login Card */}
        <div className="rounded-2xl border border-border/70 bg-card/85 backdrop-blur-xl shadow-2xl p-6 sm:p-8 space-y-6">
          {success ? (
            <div className="py-8 text-center space-y-4">
              <div className="size-16 rounded-full bg-emerald-500/10 text-emerald-600 flex items-center justify-center mx-auto border border-emerald-500/20 animate-bounce">
                <CheckCircle2 className="size-8" />
              </div>
              <div className="space-y-1">
                <h3 className="text-lg font-bold text-foreground">Autentikasi Berhasil!</h3>
                <p className="text-xs text-muted-foreground">
                  Selamat datang kembali, sesi login Anda sedang disiapkan...
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
            <form onSubmit={handleSubmit} className="space-y-5">
              {error && (
                <div className="flex items-start gap-3 p-3.5 rounded-xl bg-destructive/10 border border-destructive/20 text-destructive text-sm leading-snug animate-in fade-in-50">
                  <AlertCircle className="size-4 shrink-0 mt-0.5" />
                  <p>{error}</p>
                </div>
              )}

              {/* Email / Username field */}
              <div className="space-y-2">
                <Label htmlFor="email" className="text-sm font-medium text-foreground">
                  Email Akun
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

              {/* Password field with toggle view */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label htmlFor="password" className="text-sm font-medium text-foreground">
                    Kata Sandi
                  </Label>
                  <a
                    href="#forgot"
                    onClick={(e) => {
                      e.preventDefault();
                      alert("Silakan hubungi Superadmin untuk reset kata sandi.");
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
                    {showPassword ? (
                      <EyeOff className="size-4" />
                    ) : (
                      <Eye className="size-4" />
                    )}
                  </button>
                </div>
              </div>

              {/* Remember Me Checkbox */}
              <div className="flex items-center gap-2.5 pt-1">
                <input
                  type="checkbox"
                  id="remember"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="size-4 rounded-md border-border text-primary focus:ring-primary cursor-pointer accent-primary"
                />
                <Label htmlFor="remember" className="text-xs text-muted-foreground cursor-pointer font-normal select-none">
                  Ingat sesi masuk di perangkat ini selama 30 hari
                </Label>
              </div>

              {/* Main Login Button - Standard Normal Size (h-11 = 44px) */}
              <Button
                type="submit"
                disabled={submitting}
                className="w-full h-11 text-sm font-semibold rounded-xl shadow-md shadow-primary/20 hover:shadow-lg hover:shadow-primary/30 transition-all cursor-pointer gap-2"
              >
                {submitting ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Memverifikasi Kredensial...
                  </>
                ) : (
                  <>
                    Masuk ke Konsol
                    <ArrowRight className="size-4" />
                  </>
                )}
              </Button>

              {/* Divider */}
              <div className="relative py-1">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-border/60" />
                </div>
                <div className="relative flex justify-center text-xs uppercase">
                  <span className="bg-card px-3 text-muted-foreground font-medium">
                    Akses Uji Coba Cepat
                  </span>
                </div>
              </div>

              {/* Demo Account Pills */}
              <div className="space-y-2">
                <p className="text-[11px] text-muted-foreground text-center">
                  Klik tombol di bawah untuk mengisi akun otomatis:
                </p>
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                    onClick={() => fillDemo("admin@cashless.dev")}
                  >
                    <Sparkles className="size-3.5 text-amber-500" />
                    Super Admin
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    className="h-10 text-xs font-semibold rounded-xl border-border/80 hover:bg-primary/5 hover:border-primary/40 cursor-pointer gap-1.5"
                    onClick={() => fillDemo("operator@cashless.dev")}
                  >
                    <Sparkles className="size-3.5 text-emerald-500" />
                    Operator Pondok
                  </Button>
                </div>
              </div>
            </form>
          )}
        </div>

        {/* Security & Info Footer */}
        <div className="flex items-center justify-center gap-4 text-xs text-muted-foreground">
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="size-3.5 text-emerald-500" />
            <span>Enkripsi TLS 1.3 Aktif</span>
          </div>
          <span>•</span>
          <Link href="/" className="hover:text-foreground transition-colors">
            Kembali ke Beranda
          </Link>
        </div>
      </div>
    </div>
  );
}
