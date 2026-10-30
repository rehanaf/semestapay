"use client";

import * as React from "react";
import Link from "next/link";
import { Check, ShoppingBag, Radio, ShieldCheck, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";

interface PosStepperProps {
  currentStep: 1 | 2 | 3;
}

export function PosStepper({ currentStep }: PosStepperProps) {
  const steps = [
    { num: 1, title: "Pilih Produk / Nominal", icon: ShoppingBag, href: "/transaksi" },
    { num: 2, title: "Tap Kartu Pintar", icon: Radio, href: "/transaksi/tap" },
    { num: 3, title: "Konfirmasi & PIN", icon: ShieldCheck, href: "/transaksi/konfirmasi" },
  ];

  return (
    <header className="border-b bg-card/80 backdrop-blur-md sticky top-0 z-20">
      <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Link href="/">
            <Button variant="ghost" size="sm" className="gap-1.5 text-xs">
              <ArrowLeft className="size-4" />
              <span className="hidden sm:inline">Dashboard Kasir</span>
            </Button>
          </Link>
          <div className="h-6 w-px bg-border hidden sm:block" />
          <div>
            <h1 className="text-sm font-bold tracking-tight text-foreground flex items-center gap-1.5">
              <span className="size-2 rounded-full bg-primary animate-pulse" />
              Kasir Transaksi Tap SemestaPay
            </h1>
            <p className="text-[11px] text-muted-foreground hidden sm:block">Kantin Utama • Outlet KANTIN-1</p>
          </div>
        </div>

        {/* Stepper Wizard */}
        <div className="flex items-center gap-2 sm:gap-4">
          {steps.map((step, idx) => {
            const Icon = step.icon;
            const isDone = step.num < currentStep;
            const isCurrent = step.num === currentStep;

            return (
              <React.Fragment key={step.num}>
                {idx > 0 && (
                  <div
                    className={`h-0.5 w-4 sm:w-8 transition-colors ${
                      isDone ? "bg-primary" : "bg-muted"
                    }`}
                  />
                )}
                <div
                  className={`flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-medium transition-all ${
                    isCurrent
                      ? "bg-primary text-primary-foreground shadow-sm ring-2 ring-primary/20"
                      : isDone
                      ? "bg-primary/10 text-primary"
                      : "text-muted-foreground bg-muted/50"
                  }`}
                >
                  <div
                    className={`size-5 rounded-full flex items-center justify-center text-[10px] font-bold ${
                      isCurrent
                        ? "bg-primary-foreground text-primary"
                        : isDone
                        ? "bg-primary text-primary-foreground"
                        : "bg-muted-foreground/20 text-muted-foreground"
                    }`}
                  >
                    {isDone ? <Check className="size-3 stroke-[3]" /> : step.num}
                  </div>
                  <span className="hidden md:inline">{step.title}</span>
                </div>
              </React.Fragment>
            );
          })}
        </div>
      </div>
    </header>
  );
}
