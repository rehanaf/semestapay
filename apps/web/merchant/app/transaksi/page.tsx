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
} from "lucide-react";

const ADD_SHORTCUTS = [500, 1000, 2000, 5000, 10000, 20000, 50000];

export default function PosStep1Page() {
  const router = useRouter();
  const { state, setManualAmount, totalAmount } = usePos();

  const [amountStr, setAmountStr] = React.useState(
    state.manualAmount > 0 ? state.manualAmount.toString() : ""
  );

  const inputRef = React.useRef<HTMLInputElement | null>(null);

  // Auto focus input on load
  React.useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const syncAmount = (str: string) => {
    const num = parseInt(str.replace(/\D/g, ""), 10) || 0;
    setManualAmount(num);
  };

  const handleDigit = (digit: string) => {
    const input = inputRef.current;
    const start = input ? input.selectionStart ?? amountStr.length : amountStr.length;
    const end = input ? input.selectionEnd ?? amountStr.length : amountStr.length;

    if (amountStr.length + digit.length > 9) return; // Prevent overflow

    const nextStr = amountStr.slice(0, start) + digit + amountStr.slice(end);
    setAmountStr(nextStr);
    syncAmount(nextStr);

    const nextPos = start + digit.length;
    requestAnimationFrame(() => {
      if (input) {
        input.focus();
        input.setSelectionRange(nextPos, nextPos);
      }
    });
  };

  const handleBackspace = () => {
    const input = inputRef.current;
    if (amountStr.length === 0) return;
    const start = input ? input.selectionStart ?? amountStr.length : amountStr.length;
    const end = input ? input.selectionEnd ?? amountStr.length : amountStr.length;

    let nextStr = amountStr;
    let nextPos = start;

    if (start !== end) {
      nextStr = amountStr.slice(0, start) + amountStr.slice(end);
    } else if (start > 0) {
      nextStr = amountStr.slice(0, start - 1) + amountStr.slice(start);
      nextPos = start - 1;
    }

    setAmountStr(nextStr);
    syncAmount(nextStr);

    requestAnimationFrame(() => {
      if (input) {
        input.focus();
        input.setSelectionRange(nextPos, nextPos);
      }
    });
  };

  const handleClear = () => {
    setAmountStr("");
    syncAmount("");
    requestAnimationFrame(() => {
      inputRef.current?.focus();
    });
  };

  const handleAddAmount = (addVal: number) => {
    const current = parseInt(amountStr.replace(/\D/g, ""), 10) || 0;
    const nextVal = current + addVal;
    const nextStr = nextVal.toString();
    setAmountStr(nextStr);
    syncAmount(nextStr);

    requestAnimationFrame(() => {
      if (inputRef.current) {
        inputRef.current.focus();
        inputRef.current.setSelectionRange(nextStr.length, nextStr.length);
      }
    });
  };

  // Keyboard shortcut listener (supports physical numpad / numbers too)
  React.useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      // If user typing on input, let native input or handle key
      if (/^[0-9]$/.test(e.key)) {
        e.preventDefault();
        handleDigit(e.key);
      } else if (e.key === "Backspace") {
        e.preventDefault();
        handleBackspace();
      } else if (e.key === "Escape" || e.key.toLowerCase() === "c") {
        e.preventDefault();
        handleClear();
      } else if (e.key === "Enter" && totalAmount > 0) {
        e.preventDefault();
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

      <main className="flex-1 max-w-md w-full mx-auto p-4 sm:p-5 flex flex-col justify-between">
        {/* TOP SECTION: Header, Caret Display, Additive Chips */}
        <div className="space-y-3">
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
                Reset
              </button>
            )}
          </div>

          {/* EDC Display Card with Caret / Cursor */}
          <Card
            className="bg-slate-950 text-white border-slate-800 shadow-xl overflow-hidden rounded-2xl cursor-text"
            onClick={() => inputRef.current?.focus()}
          >
            <CardContent className="p-5 text-center space-y-2">
              <p className="text-[10px] sm:text-[11px] font-semibold text-slate-400 uppercase tracking-widest">
                Nominal Pembayaran Transaksi
              </p>
              <div className="h-14 flex items-center justify-center">
                <span className="font-extrabold text-2xl sm:text-3xl text-slate-400 select-none mr-1 font-mono">
                  Rp
                </span>
                <input
                  ref={inputRef}
                  type="text"
                  inputMode="none" // disables virtual OS keyboard on mobile/tablets while keeping cursor alive
                  value={amountStr}
                  onChange={(e) => {
                    const clean = e.target.value.replace(/\D/g, "");
                    setAmountStr(clean);
                    syncAmount(clean);
                  }}
                  placeholder="0"
                  className="font-extrabold text-3xl sm:text-4xl tracking-tight text-white font-mono bg-transparent outline-none border-none text-left w-auto max-w-[240px] placeholder:text-slate-600 caret-amber-400"
                  style={{
                    width: amountStr.length > 0 ? `${amountStr.length + 0.5}ch` : "1.5ch",
                  }}
                />
              </div>
              <p className="text-[11px] text-amber-400/90 font-medium">
                Klik pada angka untuk memindahkan kursor input
              </p>
            </CardContent>
          </Card>

          {/* Additive Shortcut Chips (+500, +1.000, +2.000, ...) */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 pt-1 no-scrollbar">
            {ADD_SHORTCUTS.map((amt) => {
              return (
                <button
                  key={amt}
                  type="button"
                  onClick={() => handleAddAmount(amt)}
                  className="py-1.5 px-2.5 text-center rounded-xl text-xs font-bold border border-border/80 bg-card hover:bg-primary/10 hover:border-primary/40 text-foreground transition-all cursor-pointer whitespace-nowrap active:scale-95 shadow-2xs"
                >
                  +{amt.toLocaleString("id-ID")}
                </button>
              );
            })}
          </div>
        </div>

        {/* BOTTOM SECTION: Numpad directly above the Lanjut Button */}
        <div className="space-y-3 pt-4">
          {/* Custom On-Screen Numpad with "000" */}
          <Card className="border-border/80 shadow-md rounded-2xl bg-card">
            <CardContent className="p-3.5 sm:p-4">
              <div className="grid grid-cols-3 gap-2 sm:gap-2.5 max-w-sm mx-auto">
                {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((key) => (
                  <button
                    key={key}
                    type="button"
                    onClick={() => handleDigit(key)}
                    className="h-13 sm:h-15 rounded-xl border border-border/70 bg-card hover:bg-muted/70 font-bold text-xl sm:text-2xl text-foreground transition-all active:scale-95 cursor-pointer shadow-xs hover:border-primary/40 flex items-center justify-center select-none"
                  >
                    {key}
                  </button>
                ))}

                {/* Bottom Row: 000, 0, Backspace */}
                <button
                  type="button"
                  onClick={() => handleDigit("000")}
                  className="h-13 sm:h-15 rounded-xl border border-border/70 bg-card hover:bg-muted/70 font-bold text-base sm:text-lg text-foreground transition-all active:scale-95 cursor-pointer shadow-xs flex items-center justify-center select-none"
                >
                  000
                </button>
                <button
                  type="button"
                  onClick={() => handleDigit("0")}
                  className="h-13 sm:h-15 rounded-xl border border-border/70 bg-card hover:bg-muted/70 font-bold text-xl sm:text-2xl text-foreground transition-all active:scale-95 cursor-pointer shadow-xs hover:border-primary/40 flex items-center justify-center select-none"
                >
                  0
                </button>
                <button
                  type="button"
                  onClick={handleBackspace}
                  className="h-13 sm:h-15 rounded-xl border border-border/70 bg-muted/40 hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-all active:scale-95 cursor-pointer shadow-xs flex items-center justify-center select-none"
                  title="Hapus Digit"
                >
                  <Delete className="size-5 sm:size-6" />
                </button>
              </div>
            </CardContent>
          </Card>

          {/* Action Button: Lanjut ke Tap Kartu (Directly beneath Numpad) */}
          <Button
            size="lg"
            className="w-full h-12 sm:h-13 text-sm sm:text-base font-bold rounded-2xl gap-2 shadow-lg shadow-primary/20 cursor-pointer transition-all"
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
