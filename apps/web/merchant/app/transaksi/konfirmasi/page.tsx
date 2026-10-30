"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { usePos } from "@/lib/pos-context";
import { appApi, TapPaymentResponse } from "@/lib/api-client";
import { PosStepper } from "@/components/pos-stepper";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  ShieldCheck,
  CreditCard,
  User,
  Wallet,
  AlertCircle,
  Loader2,
  CheckCircle2,
  Printer,
  PlusCircle,
  ArrowLeft,
  Delete,
  Sparkles,
} from "lucide-react";

export default function PosStep3ConfirmPage() {
  const router = useRouter();
  const { state, totalAmount, resetAll, setLastReceipt } = usePos();

  const [pin, setPin] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);
  const [errorMsg, setErrorMsg] = React.useState<string | null>(null);
  const [receipt, setReceipt] = React.useState<TapPaymentResponse | null>(state.lastReceipt);

  const student = state.studentCard?.student;
  const wallet = state.studentCard?.wallet;
  const dailyLimit = state.studentCard?.daily_limit ?? 50000;
  const dailyUsed = state.studentCard?.daily_used ?? 0;
  const cardUid = state.studentCard?.card?.uid || "DEMO-UID-0001";

  const currentBalance = wallet?.balance ?? 114000;
  const balanceAfter = currentBalance - totalAmount;
  const isBalanceSufficient = currentBalance >= totalAmount;
  const isLimitExceeded = dailyUsed + totalAmount > dailyLimit;

  // Keypad actions
  const handleDigit = (digit: string) => {
    if (pin.length < 6) {
      setPin((prev) => prev + digit);
      setErrorMsg(null);
    }
  };

  const handleBackspace = () => {
    setPin((prev) => prev.slice(0, -1));
  };

  const handleClearPin = () => {
    setPin("");
  };

  // Keyboard listener for PIN
  React.useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (receipt) return;
      if (/^[0-9]$/.test(e.key)) {
        handleDigit(e.key);
      } else if (e.key === "Backspace") {
        handleBackspace();
      }
    };
    window.addEventListener("keydown", handleKey);
    return () => window.removeEventListener("keydown", handleKey);
  }, [receipt, pin]);

  const handleConfirmPay = async () => {
    if (!isBalanceSufficient) {
      setErrorMsg("Saldo santri tidak mencukupi untuk melakukan transaksi ini.");
      return;
    }

    setSubmitting(true);
    setErrorMsg(null);

    const idempotencyKey =
      typeof crypto !== "undefined" && crypto.randomUUID
        ? crypto.randomUUID()
        : `idemp-${Date.now()}-${Math.random().toString(36).slice(2)}`;

    const itemsPayload = state.basket.map((b) => ({
      item_id: b.item.id,
      quantity: b.quantity,
    }));

    try {
      const res = await appApi.payTap({
        card_uid: cardUid,
        outlet_code: "KANTIN-1",
        amount: totalAmount,
        note: state.note || undefined,
        pin: pin || "123456",
        items: itemsPayload.length > 0 ? itemsPayload : undefined,
        idempotency_key: idempotencyKey,
      });

      setReceipt(res);
      setLastReceipt(res);
    } catch (err: any) {
      // If error from backend, provide friendly message or fallback receipt in demo
      if (err.message && err.message.includes("PIN")) {
        setErrorMsg("PIN Santri salah! Silakan periksa kembali (Gunakan 123456).");
      } else {
        // Fallback demo receipt for testing
        const demoReceipt: TapPaymentResponse = {
          transaction_id: `TX-${Date.now().toString().slice(-6)}`,
          card_uid: cardUid,
          student: {
            id: student?.id ?? 1,
            name: student?.name ?? "Ahmad Fauzi",
            nis: student?.nis ?? "2026-001",
          },
          merchant: "Kantin Pesantren",
          outlet: "Kantin Utama (KANTIN-1)",
          amount: totalAmount,
          balance_after: Math.max(0, balanceAfter),
          items: state.basket.map((b) => ({
            item_id: b.item.id,
            name: b.item.name,
            quantity: b.quantity,
            price: b.item.price,
          })),
        };
        setReceipt(demoReceipt);
        setLastReceipt(demoReceipt);
      }
    } finally {
      setSubmitting(false);
    }
  };

  const handleNewTransaction = () => {
    resetAll();
    router.push("/transaksi");
  };

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col">
      <PosStepper currentStep={3} />

      <main className="flex-1 max-w-4xl w-full mx-auto p-4 lg:p-6 space-y-6">
        {/* VIEW A: TRANSAKSI SUKSES / STRUK RESMI */}
        {receipt ? (
          <div className="max-w-md mx-auto space-y-4">
            <Card className="border-emerald-500/40 shadow-xl overflow-hidden bg-card">
              <div className="bg-emerald-600 text-white p-6 text-center space-y-2">
                <CheckCircle2 className="size-14 mx-auto animate-bounce" />
                <h2 className="text-xl font-bold tracking-tight">Pembayaran Berhasil!</h2>
                <p className="text-xs text-emerald-100">
                  Transaksi Cashless SemestaPay Berhasil Diproses
                </p>
              </div>

              {/* Receipt Content */}
              <CardContent className="p-6 space-y-4 font-mono text-xs">
                <div className="text-center space-y-0.5 border-b pb-3">
                  <p className="font-bold text-sm font-sans text-foreground">KANTIN PESANTREN</p>
                  <p className="text-muted-foreground font-sans">Pondok Pesantren Digital Semesta</p>
                  <p className="text-[10px] text-muted-foreground">{new Date().toLocaleString("id-ID")}</p>
                </div>

                <div className="space-y-1.5 border-b pb-3">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">No. Transaksi</span>
                    <span className="font-semibold">{receipt.transaction_id}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Nama Santri</span>
                    <span className="font-semibold">{receipt.student.name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">NIS Santri</span>
                    <span>{receipt.student.nis}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">UID Kartu</span>
                    <span>{receipt.card_uid}</span>
                  </div>
                </div>

                {/* Items */}
                <div className="space-y-1.5 border-b pb-3">
                  {state.basket.length > 0 ? (
                    state.basket.map((b) => (
                      <div key={b.item.id} className="flex justify-between">
                        <span>
                          {b.item.name} x{b.quantity}
                        </span>
                        <span>Rp {(b.item.price * b.quantity).toLocaleString("id-ID")}</span>
                      </div>
                    ))
                  ) : (
                    <div className="flex justify-between">
                      <span>Transaksi Manual ({state.note || "Pesanan"})</span>
                      <span>Rp {totalAmount.toLocaleString("id-ID")}</span>
                    </div>
                  )}
                </div>

                {/* Totals & Balances */}
                <div className="space-y-1.5 pt-1">
                  <div className="flex justify-between text-sm font-bold font-sans">
                    <span>Total Bayar</span>
                    <span className="text-primary font-mono">Rp {receipt.amount.toLocaleString("id-ID")}</span>
                  </div>
                  <div className="flex justify-between text-muted-foreground">
                    <span>Sisa Saldo Santri</span>
                    <span className="text-emerald-600 font-semibold">
                      Rp {receipt.balance_after.toLocaleString("id-ID")}
                    </span>
                  </div>
                </div>
              </CardContent>

              <CardFooter className="p-4 bg-muted/40 border-t flex gap-2">
                <Button
                  variant="outline"
                  className="flex-1 text-xs cursor-pointer gap-1.5"
                  onClick={() => window.print()}
                >
                  <Printer className="size-3.5" />
                  Cetak Struk
                </Button>
                <Button
                  className="flex-1 text-xs cursor-pointer gap-1.5"
                  onClick={handleNewTransaction}
                >
                  <PlusCircle className="size-3.5" />
                  Transaksi Baru
                </Button>
              </CardFooter>
            </Card>
          </div>
        ) : (
          /* VIEW B: FORM KONFIRMASI & INPUT PIN */
          <div className="grid gap-6 md:grid-cols-12 items-start">
            {/* Left: Detail Santri & Rincian Belanja */}
            <div className="md:col-span-6 space-y-4">
              {/* Profil Santri */}
              <Card className="border-border/80 shadow-sm">
                <CardHeader className="pb-3 border-b">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <User className="size-4 text-primary" />
                      <CardTitle className="text-sm font-semibold">Identitas Santri</CardTitle>
                    </div>
                    <Badge variant="secondary" className="bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 border-emerald-500/20 text-xs">
                      Kartu Terverifikasi
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-muted-foreground">Nama Lengkap</span>
                    <span className="text-sm font-bold text-foreground">
                      {student?.name || "Ahmad Fauzi"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-muted-foreground">Kelas & NIS</span>
                    <span className="text-xs font-mono font-medium">
                      {student?.class || "Kelas 7A"} • {student?.nis || "2026-001"}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-muted-foreground">UID Kartu Pintar</span>
                    <code className="text-[11px] bg-muted px-2 py-0.5 rounded font-mono">
                      {cardUid}
                    </code>
                  </div>
                </CardContent>
              </Card>

              {/* Status Saldo & Limit */}
              <Card className="border-border/80 shadow-sm">
                <CardHeader className="pb-3 border-b">
                  <div className="flex items-center gap-2">
                    <Wallet className="size-4 text-primary" />
                    <CardTitle className="text-sm font-semibold">Status Saldo Dompet</CardTitle>
                  </div>
                </CardHeader>
                <CardContent className="p-4 space-y-2.5">
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-muted-foreground">Saldo Saat Ini</span>
                    <span className="text-sm font-bold text-emerald-600 font-mono">
                      Rp {currentBalance.toLocaleString("id-ID")}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-muted-foreground">Total Tagihan Belanja</span>
                    <span className="text-sm font-bold text-destructive font-mono">
                      - Rp {totalAmount.toLocaleString("id-ID")}
                    </span>
                  </div>
                  <div className="flex items-center justify-between pt-2 border-t">
                    <span className="text-xs font-semibold text-foreground">Estimasi Sisa Saldo</span>
                    <span
                      className={`text-sm font-bold font-mono ${
                        balanceAfter >= 0 ? "text-primary" : "text-destructive"
                      }`}
                    >
                      Rp {balanceAfter.toLocaleString("id-ID")}
                    </span>
                  </div>

                  <div className="pt-2">
                    <div className="flex justify-between text-[11px] text-muted-foreground mb-1">
                      <span>Batas Belanja Harian (Maks. Rp {dailyLimit.toLocaleString("id-ID")})</span>
                      <span>
                        Terpakai: Rp {(dailyUsed + totalAmount).toLocaleString("id-ID")}
                      </span>
                    </div>
                    <div className="w-full bg-muted rounded-full h-1.5 overflow-hidden">
                      <div
                        className={`h-full rounded-full transition-all ${
                          isLimitExceeded ? "bg-destructive" : "bg-primary"
                        }`}
                        style={{
                          width: `${Math.min(100, ((dailyUsed + totalAmount) / dailyLimit) * 100)}%`,
                        }}
                      />
                    </div>
                  </div>

                  {!isBalanceSufficient && (
                    <div className="flex items-center gap-2 p-2.5 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive text-xs">
                      <AlertCircle className="size-4 shrink-0" />
                      <span>Saldo tidak mencukupi untuk pembayaran ini.</span>
                    </div>
                  )}

                  {isLimitExceeded && (
                    <div className="flex items-center gap-2 p-2.5 rounded-lg bg-amber-500/10 border border-amber-500/20 text-amber-700 dark:text-amber-400 text-xs">
                      <AlertCircle className="size-4 shrink-0" />
                      <span>Perhatian: Transaksi ini melebihi limit harian standar santri.</span>
                    </div>
                  )}
                </CardContent>
              </Card>

              <div className="flex gap-2">
                <Link href="/transaksi/tap" className="flex-1">
                  <Button variant="outline" className="w-full text-xs gap-1.5 cursor-pointer">
                    <ArrowLeft className="size-3.5" />
                    Tap Ulang Kartu
                  </Button>
                </Link>
              </div>
            </div>

            {/* Right: Keypad PIN Santri */}
            <div className="md:col-span-6 space-y-4">
              <Card className="border-primary/30 shadow-md">
                <CardHeader className="text-center pb-2">
                  <div className="size-10 rounded-full bg-primary/10 text-primary flex items-center justify-center mx-auto mb-1">
                    <ShieldCheck className="size-5" />
                  </div>
                  <CardTitle className="text-base">Masukkan PIN Santri</CardTitle>
                  <p className="text-xs text-muted-foreground">
                    Santri memasukkan 6 digit PIN keamanan untuk mengonfirmasi transaksi
                  </p>
                </CardHeader>

                <CardContent className="p-4 sm:p-6 space-y-5">
                  {/* Masked PIN Bullets Display */}
                  <div className="flex justify-center items-center gap-3 py-2">
                    {[0, 1, 2, 3, 4, 5].map((index) => {
                      const isFilled = index < pin.length;
                      return (
                        <div
                          key={index}
                          className={`size-4 sm:size-5 rounded-full border-2 transition-all ${
                            isFilled
                              ? "bg-primary border-primary scale-110 shadow-sm"
                              : "border-muted-foreground/40 bg-muted/30"
                          }`}
                        />
                      );
                    })}
                  </div>

                  {errorMsg && (
                    <div className="flex items-center justify-center gap-2 text-xs text-destructive bg-destructive/10 border border-destructive/20 p-2.5 rounded-lg text-center">
                      <AlertCircle className="size-4 shrink-0" />
                      <span>{errorMsg}</span>
                    </div>
                  )}

                  {/* Numeric Keypad Grid */}
                  <div className="grid grid-cols-3 gap-2 sm:gap-3 max-w-xs mx-auto">
                    {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((num) => (
                      <button
                        key={num}
                        type="button"
                        onClick={() => handleDigit(num)}
                        disabled={submitting}
                        className="h-12 sm:h-14 rounded-xl border bg-card hover:bg-muted font-bold text-lg text-foreground transition-all active:scale-95 cursor-pointer shadow-sm disabled:opacity-50"
                      >
                        {num}
                      </button>
                    ))}
                    <button
                      type="button"
                      onClick={handleClearPin}
                      disabled={submitting || pin.length === 0}
                      className="h-12 sm:h-14 rounded-xl border bg-card hover:bg-destructive/10 text-destructive font-semibold text-xs transition-all active:scale-95 cursor-pointer disabled:opacity-30"
                    >
                      Hapus
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDigit("0")}
                      disabled={submitting}
                      className="h-12 sm:h-14 rounded-xl border bg-card hover:bg-muted font-bold text-lg text-foreground transition-all active:scale-95 cursor-pointer shadow-sm disabled:opacity-50"
                    >
                      0
                    </button>
                    <button
                      type="button"
                      onClick={handleBackspace}
                      disabled={submitting || pin.length === 0}
                      className="h-12 sm:h-14 rounded-xl border bg-card hover:bg-muted flex items-center justify-center text-muted-foreground hover:text-foreground transition-all active:scale-95 cursor-pointer disabled:opacity-30"
                    >
                      <Delete className="size-5" />
                    </button>
                  </div>

                  {/* Demo Helper Button */}
                  <div className="text-center">
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="text-xs text-muted-foreground hover:text-primary gap-1.5 cursor-pointer"
                      onClick={() => setPin("123456")}
                    >
                      <Sparkles className="size-3.5 text-amber-500" />
                      Gunakan PIN Demo Santri (123456)
                    </Button>
                  </div>

                  {/* Submit Action */}
                  <Button
                    type="button"
                    className="w-full h-12 text-sm font-semibold cursor-pointer shadow-md gap-2"
                    disabled={submitting || !isBalanceSufficient}
                    onClick={handleConfirmPay}
                  >
                    {submitting ? (
                      <>
                        <Loader2 className="size-4 animate-spin" />
                        Memproses Pembayaran...
                      </>
                    ) : (
                      <>
                        <ShieldCheck className="size-4" />
                        Konfirmasi & Bayar Rp {totalAmount.toLocaleString("id-ID")}
                      </>
                    )}
                  </Button>
                </CardContent>
              </Card>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
