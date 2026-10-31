"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { usePos } from "@/lib/pos-context";
import { PosStepper } from "@/components/pos-stepper";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  ArrowRight,
  Delete,
  RotateCcw,
  Store,
  Sparkles,
} from "lucide-react";

const PRESET_AMOUNTS = [5000, 10000, 15000, 20000, 50000, 100000];

export default function PosStep1Page() {
  const router = useRouter();
  const { state, setManualAmount, totalAmount } = usePos();

  const [amountStr, setAmountStr] = React.useState(
    state.manualAmount > 0 ? state.manualAmount.toString() : ""
  );

  const syncAmount = (str: string) => {
    const num = parseInt(str.replace(/\D/g, ""), 10) || 0;
    setManualAmount(num);
  };

  const handleDigit = (digit: string) => {
    if (amountStr.length >= 8) return; // limit to tens of millions
    let nextStr = amountStr;
    if (nextStr === "" || nextStr === "0") {
      if (digit !== "0" && digit !== "00") {
        nextStr = digit;
      }
    } else {
      nextStr += digit;
    }
    setAmountStr(nextStr);
    syncAmount(nextStr);
  };

  const handleBackspace = () => {
    if (amountStr.length === 0) return;
    const nextStr = amountStr.slice(0, -1);
    setAmountStr(nextStr);
    syncAmount(nextStr);
  };

  const handleClear = () => {
    setAmountStr("");
    syncAmount("");
  };

  const handlePreset = (amount: number) => {
    const str = amount.toString();
    setAmountStr(str);
    syncAmount(str);
  };

  // Keyboard shortcut listener (supports physical numpad / numbers too)
  React.useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (/^[0-9]$/.test(e.key)) {
        handleDigit(e.key);
      } else if (e.key === "Backspace") {
        handleBackspace();
      } else if (e.key === "Escape" || e.key.toLowerCase() === "c") {
        handleClear();
      } else if (e.key === "Enter" && totalAmount > 0) {
        router.push("/transaksi/tap");
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [amountStr, totalAmount]);

  const handleProceed = () => {
    if (totalAmount <= 0) return;
    router.push("/transaksi/tap");
  };

  const formattedCurrency = (val: number) => {
    return `Rp ${val.toLocaleString("id-ID")}`;
  };

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col">
      <PosStepper currentStep={1} />

      <main className="flex-1 max-w-xl w-full mx-auto p-4 sm:p-6 flex flex-col justify-center">
        <div className="space-y-4">
          {/* Top Brand / Outlet Indicator */}
          <div className="flex items-center justify-between text-xs text-muted-foreground px-1">
            <div className="flex items-center gap-1.5 font-medium">
              <Store className="size-3.5 text-primary" />
              <span>Outlet: Kantin Utama (KANTIN-1)</span>
            </div>
            {amountStr.length > 0 && (
              <button
                type="button"
                onClick={handleClear}
                className="text-destructive font-semibold hover:underline flex items-center gap-1 text-[11px] cursor-pointer"
              >
                <RotateCcw className="size-3" />
                Reset Nominal
              </button>
            )}
          </div>

          {/* EDC Display Card (Fixed, never breaks or drops text down) */}
          <Card className="bg-slate-950 text-white border-slate-800 shadow-xl overflow-hidden rounded-2xl">
            <CardContent className="p-6 text-center space-y-2">
              <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-widest">
                Nominal Pembayaran Transaksi
              </p>
              <div className="h-14 flex items-center justify-center overflow-hidden">
                <span className="font-extrabold text-3xl sm:text-4xl tracking-tight text-white whitespace-nowrap font-mono">
                  {formattedCurrency(totalAmount)}
                </span>
              </div>
              <p className="text-[11px] text-amber-400/90 font-medium">
                Gunakan keypad layar di bawah atau keyboard angka
              </p>
            </CardContent>
          </Card>

          {/* Quick Preset Amount Chips */}
          <div className="grid grid-cols-3 sm:grid-cols-6 gap-1.5">
            {PRESET_AMOUNTS.map((amt) => {
              const isSelected = totalAmount === amt;
              return (
                <button
                  key={amt}
                  type="button"
                  onClick={() => handlePreset(amt)}
                  className={`py-2 px-1 text-center rounded-xl text-xs font-bold border transition-all cursor-pointer whitespace-nowrap ${
                    isSelected
                      ? "bg-primary text-primary-foreground border-primary shadow-sm"
                      : "bg-card text-foreground border-border/80 hover:bg-muted"
                  }`}
                >
                  {formattedCurrency(amt)}
                </button>
              );
            })}
          </div>

          {/* Custom On-Screen Numpad */}
          <Card className="border-border/80 shadow-md rounded-2xl bg-card">
            <CardContent className="p-4 sm:p-5">
              <div className="grid grid-cols-3 gap-2.5 sm:gap-3 max-w-sm mx-auto">
                {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((key) => (
                  <button
                    key={key}
                    type="button"
                    onClick={() => handleDigit(key)}
                    className="h-14 sm:h-16 rounded-2xl border border-border/70 bg-card hover:bg-muted/70 font-bold text-xl sm:text-2xl text-foreground transition-all active:scale-95 cursor-pointer shadow-xs hover:border-primary/40 flex items-center justify-center select-none"
                  >
                    {key}
                  </button>
                ))}

                {/* Bottom Row: 00, 0, Backspace */}
                <button
                  type="button"
                  onClick={() => handleDigit("00")}
                  className="h-14 sm:h-16 rounded-2xl border border-border/70 bg-card hover:bg-muted/70 font-bold text-base sm:text-lg text-foreground transition-all active:scale-95 cursor-pointer shadow-xs flex items-center justify-center select-none"
                >
                  00
                </button>
                <button
                  type="button"
                  onClick={() => handleDigit("0")}
                  className="h-14 sm:h-16 rounded-2xl border border-border/70 bg-card hover:bg-muted/70 font-bold text-xl sm:text-2xl text-foreground transition-all active:scale-95 cursor-pointer shadow-xs hover:border-primary/40 flex items-center justify-center select-none"
                >
                  0
                </button>
                <button
                  type="button"
                  onClick={handleBackspace}
                  className="h-14 sm:h-16 rounded-2xl border border-border/70 bg-muted/30 hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-all active:scale-95 cursor-pointer shadow-xs flex items-center justify-center select-none"
                  title="Hapus Digit"
                >
                  <Delete className="size-6" />
                </button>
              </div>
            </CardContent>
          </Card>

          {/* Action Button: Lanjut ke Tap Kartu */}
          <Button
            size="lg"
            className="w-full h-12 sm:h-14 text-sm sm:text-base font-bold rounded-2xl gap-2 shadow-lg shadow-primary/20 cursor-pointer transition-all"
            disabled={totalAmount <= 0}
            onClick={handleProceed}
          >
            <span className="whitespace-nowrap">Lanjut ke Tap Kartu</span>
            <span className="font-mono font-semibold whitespace-nowrap opacity-90">
              ({formattedCurrency(totalAmount)})
            </span>
            <ArrowRight className="size-5 shrink-0 ml-auto" />
          </Button>
        </div>
      </main>
    </div>
  );
}
