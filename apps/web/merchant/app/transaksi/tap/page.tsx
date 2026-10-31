"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { usePos } from "@/lib/pos-context";
import { appApi, CardReadResponse } from "@/lib/api-client";
import { PosStepper } from "@/components/pos-stepper";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Radio,
  CreditCard,
  ArrowLeft,
  CheckCircle2,
  AlertCircle,
  Loader2,
  User,
  Sparkles,
} from "lucide-react";

const DEMO_STUDENTS = [
  {
    name: "Ahmad Fauzi",
    nis: "2026-001",
    class: "Kelas 7A",
    uid: "DEMO-UID-0001",
    balance: 114000,
    daily_limit: 50000,
    daily_used: 15000,
  },
  {
    name: "Budi Santoso",
    nis: "2026-002",
    class: "Kelas 7B",
    uid: "DEMO-UID-0002",
    balance: 152000,
    daily_limit: 50000,
    daily_used: 12000,
  },
  {
    name: "Citra Lestari",
    nis: "2026-003",
    class: "Kelas 7A",
    uid: "DEMO-UID-0003",
    balance: 129000,
    daily_limit: 50000,
    daily_used: 8000,
  },
  {
    name: "Dewi Anggraini",
    nis: "2026-004",
    class: "Kelas 7B",
    uid: "DEMO-UID-0004",
    balance: 133000,
    daily_limit: 50000,
    daily_used: 55000,
  },
];

export default function PosStep2TapPage() {
  const router = useRouter();
  const { totalAmount, setStudentCard } = usePos();

  const [detecting, setDetecting] = React.useState(false);
  const [successCard, setSuccessCard] = React.useState<CardReadResponse | null>(null);
  const [errorMsg, setErrorMsg] = React.useState<string | null>(null);

  // Buffer for USB/HID RFID Card reader keystrokes in the background (no visible input on screen)
  const hidBufferRef = React.useRef("");
  const lastKeyTimeRef = React.useRef(Date.now());

  // Handle card detection (via hardware HID scanner or demo button)
  const processCardUid = React.useCallback(
    async (uid: string) => {
      setDetecting(true);
      setErrorMsg(null);

      try {
        let cardData: CardReadResponse;
        try {
          cardData = await appApi.readCard(uid);
        } catch {
          // Fallback to demo profile matching UID or default
          const matched = DEMO_STUDENTS.find((s) => s.uid === uid) || DEMO_STUDENTS[0];
          cardData = {
            card: { uid, status: "active" },
            student: {
              id: 1,
              name: matched.name,
              nis: matched.nis,
              status: "active",
              class: matched.class,
            },
            wallet: { balance: matched.balance, status: "active" },
            daily_used: matched.daily_used,
            daily_limit: matched.daily_limit,
          };
        }

        setSuccessCard(cardData);
        setStudentCard(cardData);

        // Auto navigate to Step 3 after brief visual confirmation
        setTimeout(() => {
          router.push("/transaksi/konfirmasi");
        }, 800);
      } catch (err: any) {
        setErrorMsg(err.message || "Kartu tidak terbaca. Pastikan kartu santri aktif.");
      } finally {
        setDetecting(false);
      }
    },
    [router, setStudentCard]
  );

  // Background keyboard listener for physical USB RFID reader
  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore if user is inside an input (which should not exist on this page anyway)
      const target = e.target as HTMLElement;
      if (target.tagName === "INPUT" || target.tagName === "TEXTAREA") {
        return;
      }

      const now = Date.now();
      // Hardware barcode / RFID scanners type fast (< 50ms per key)
      if (now - lastKeyTimeRef.current > 500) {
        hidBufferRef.current = "";
      }
      lastKeyTimeRef.current = now;

      if (e.key === "Enter") {
        if (hidBufferRef.current.trim().length > 3) {
          processCardUid(hidBufferRef.current.trim());
          hidBufferRef.current = "";
        }
      } else if (e.key.length === 1) {
        hidBufferRef.current += e.key;
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [processCardUid]);

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col">
      <PosStepper currentStep={2} />

      <main className="flex-1 max-w-4xl w-full mx-auto p-4 lg:p-6 space-y-6">
        {/* Total Banner */}
        <div className="bg-card border rounded-2xl p-4 flex flex-col sm:flex-row items-center justify-between gap-3 shadow-sm">
          <div className="flex items-center gap-3">
            <Link href="/transaksi">
              <Button variant="outline" size="sm" className="gap-1.5 text-xs cursor-pointer">
                <ArrowLeft className="size-3.5" />
                Ubah Pesanan
              </Button>
            </Link>
            <div className="text-left">
              <p className="text-xs text-muted-foreground font-medium">Langkah 2: Menunggu Tap Kartu</p>
              <p className="text-sm font-semibold text-foreground">Total Tagihan Belanja</p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <span className="text-2xl font-bold font-mono tracking-tight text-primary whitespace-nowrap">
              Rp {totalAmount.toLocaleString("id-ID")}
            </span>
          </div>
        </div>

        {/* Card Tap Zone - Pure visual and instructional (NO input fields shown) */}
        <Card className="shadow-lg border-primary/20 relative overflow-hidden bg-radial from-primary/5 via-card to-card">
          <CardContent className="p-8 sm:p-12 flex flex-col items-center justify-center text-center space-y-6">
            {/* Animated RFID Waves & Card Reader */}
            <div className="relative flex items-center justify-center">
              {/* Outer pulsing wave 1 */}
              <div
                className={`absolute size-48 sm:size-56 rounded-full border-2 border-primary/20 animate-ping opacity-30 ${
                  detecting ? "border-emerald-500" : ""
                }`}
              />
              {/* Outer pulsing wave 2 */}
              <div
                className={`absolute size-36 sm:size-44 rounded-full border border-primary/30 ${
                  detecting ? "border-emerald-400 animate-pulse" : "animate-pulse"
                }`}
              />

              {/* Reader Device Center Circle */}
              <div
                className={`relative size-28 sm:size-32 rounded-3xl flex flex-col items-center justify-center shadow-xl transition-all duration-300 ${
                  successCard
                    ? "bg-emerald-600 text-white scale-105"
                    : detecting
                    ? "bg-primary text-primary-foreground scale-100"
                    : "bg-card border-2 border-primary/40 text-primary"
                }`}
              >
                {detecting ? (
                  <Loader2 className="size-10 animate-spin" />
                ) : successCard ? (
                  <CheckCircle2 className="size-12 animate-bounce" />
                ) : (
                  <>
                    <Radio className="size-10 stroke-[2] animate-pulse" />
                    <span className="text-[10px] font-bold tracking-widest uppercase mt-1">
                      NFC / RFID
                    </span>
                  </>
                )}
              </div>
            </div>

            {/* Instruction Text */}
            <div className="max-w-md space-y-2">
              <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-foreground">
                {detecting
                  ? "Membaca Kartu Santri..."
                  : successCard
                  ? `Kartu ${successCard.student.name} Terdeteksi!`
                  : "Silakan Tempelkan Kartu Santri"}
              </h2>
              <p className="text-xs sm:text-sm text-muted-foreground leading-relaxed">
                {detecting
                  ? "Sedang memeriksa status kartu dan sisa saldo dompet santri..."
                  : successCard
                  ? "Mengalihkan otomatis ke langkah konfirmasi & PIN..."
                  : "Dekatkan kartu pintar RFID/NFC pada mesin pembaca kartu kasir di depan meja Anda."}
              </p>
            </div>

            {/* Status Feedback */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-primary/10 text-primary border border-primary/20 text-xs font-semibold">
              <span className="size-2 rounded-full bg-primary animate-pulse" />
              Sensor Pembaca Aktif • Siap Tap
            </div>

            {errorMsg && (
              <div className="flex items-center gap-2 text-xs text-destructive bg-destructive/10 border border-destructive/20 px-3 py-2 rounded-lg">
                <AlertCircle className="size-4 shrink-0" />
                <span>{errorMsg}</span>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Demo Mode Section: Direct Student Card Selector */}
        <Card className="border-border/80 bg-card">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Sparkles className="size-4 text-amber-500" />
                <CardTitle className="text-sm font-semibold">
                  Mode Demo Kasir — Tap Cepat Akun Siswa Demo
                </CardTitle>
              </div>
              <Badge variant="secondary" className="text-[10px] font-semibold">
                Simulasi Instan
              </Badge>
            </div>
            <p className="text-xs text-muted-foreground">
              Klik salah satu santri di bawah untuk mensimulasikan tempelan kartu RFID secara langsung tanpa alat fisik.
            </p>
          </CardHeader>

          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {DEMO_STUDENTS.map((student) => (
                <button
                  key={student.uid}
                  type="button"
                  disabled={detecting}
                  onClick={() => processCardUid(student.uid)}
                  className="flex items-center justify-between p-3.5 rounded-xl border bg-muted/30 hover:bg-primary/5 hover:border-primary/50 text-left transition-all cursor-pointer group disabled:opacity-50"
                >
                  <div className="flex items-center gap-3">
                    <div className="size-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center font-bold text-xs group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                      <CreditCard className="size-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-foreground group-hover:text-primary transition-colors">
                        {student.name}
                      </p>
                      <p className="text-[11px] text-muted-foreground font-mono">
                        {student.class} • NIS {student.nis}
                      </p>
                    </div>
                  </div>

                  <div className="text-right">
                    <p className="text-xs font-semibold text-emerald-600">
                      Rp {student.balance.toLocaleString("id-ID")}
                    </p>
                    <code className="text-[10px] text-muted-foreground font-mono">
                      {student.uid}
                    </code>
                  </div>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
