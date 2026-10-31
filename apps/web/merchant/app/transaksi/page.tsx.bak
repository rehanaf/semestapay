"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { usePos } from "@/lib/pos-context";
import { appApi, MenuItem } from "@/lib/api-client";
import { PosStepper } from "@/components/pos-stepper";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Search,
  Plus,
  Minus,
  Trash2,
  ArrowRight,
  UtensilsCrossed,
  Calculator,
  ShoppingBag,
  Coins,
  FileText,
} from "lucide-react";

export default function PosStep1Page() {
  const router = useRouter();
  const {
    state,
    addItem,
    removeItem,
    updateQuantity,
    clearBasket,
    setManualAmount,
    setNote,
    totalAmount,
    totalQuantity,
  } = usePos();

  const [activeMode, setActiveMode] = React.useState<"products" | "manual">("products");
  const [items, setItems] = React.useState<MenuItem[]>([]);
  const [search, setSearch] = React.useState("");
  const [selectedCategory, setSelectedCategory] = React.useState<string>("all");
  const [manualInput, setManualInput] = React.useState(
    state.manualAmount > 0 ? state.manualAmount.toString() : ""
  );

  React.useEffect(() => {
    appApi
      .getItems()
      .then((res) => {
        if (res.data && res.data.length > 0) {
          setItems(res.data);
        } else {
          setItems([
            { id: 1, merchant_id: 1, merchant_name: "Kantin", name: "Nasi Goreng Spesial", price: 10000, status: "active" },
            { id: 2, merchant_id: 1, merchant_name: "Kantin", name: "Nasi Uduk Ayam", price: 8000, status: "active" },
            { id: 3, merchant_id: 1, merchant_name: "Kantin", name: "Indomie Goreng + Telur", price: 7000, status: "active" },
            { id: 4, merchant_id: 1, merchant_name: "Kantin", name: "Es Teh Manis", price: 3000, status: "active" },
            { id: 5, merchant_id: 1, merchant_name: "Kantin", name: "Air Mineral Botol", price: 2000, status: "active" },
            { id: 6, merchant_id: 2, merchant_name: "Koperasi", name: "Pensil 2B & Penghapus", price: 3000, status: "active" },
            { id: 7, merchant_id: 2, merchant_name: "Koperasi", name: "Buku Tulis Santri", price: 5000, status: "active" },
            { id: 8, merchant_id: 2, merchant_name: "Koperasi", name: "Kitab Kuning Saku", price: 15000, status: "active" },
          ]);
        }
      })
      .catch(() => {});
  }, []);

  const handleManualChange = (val: string) => {
    const num = parseInt(val.replace(/\D/g, ""), 10) || 0;
    setManualInput(num > 0 ? num.toString() : "");
    setManualAmount(num);
  };

  const addManualQuick = (amount: number) => {
    const current = parseInt(manualInput.replace(/\D/g, ""), 10) || 0;
    const nextVal = current + amount;
    setManualInput(nextVal.toString());
    setManualAmount(nextVal);
  };

  const filteredItems = items.filter((item) => {
    const matchesSearch = item.name.toLowerCase().includes(search.toLowerCase());
    if (selectedCategory === "all") return matchesSearch;
    if (selectedCategory === "canteen") return matchesSearch && item.merchant_id === 1;
    if (selectedCategory === "coop") return matchesSearch && item.merchant_id === 2;
    return matchesSearch;
  });

  const getItemCountInBasket = (itemId: number) => {
    const found = state.basket.find((b) => b.item.id === itemId);
    return found ? found.quantity : 0;
  };

  const handleProceed = () => {
    if (totalAmount <= 0) return;
    router.push("/transaksi/tap");
  };

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col">
      <PosStepper currentStep={1} />

      <main className="flex-1 max-w-6xl w-full mx-auto p-4 lg:p-6 grid gap-6 lg:grid-cols-12 items-start">
        {/* Left Section: Product Grid or Manual Input */}
        <div className="lg:col-span-7 xl:col-span-8 space-y-4">
          {/* Mode Tabs */}
          <div className="flex items-center gap-2 p-1 rounded-xl bg-muted/80 border max-w-md">
            <button
              onClick={() => setActiveMode("products")}
              className={`flex-1 flex items-center justify-center gap-2 py-2 px-3 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeMode === "products"
                  ? "bg-card text-foreground shadow-sm"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <UtensilsCrossed className="size-4" />
              Pilih dari Katalog Menu
            </button>
            <button
              onClick={() => setActiveMode("manual")}
              className={`flex-1 flex items-center justify-center gap-2 py-2 px-3 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeMode === "manual"
                  ? "bg-card text-foreground shadow-sm"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <Calculator className="size-4" />
              Input Nominal Manual
            </button>
          </div>

          {/* Mode 1: Product Catalog */}
          {activeMode === "products" && (
            <div className="space-y-4">
              <div className="flex flex-col sm:flex-row gap-2 sm:items-center justify-between">
                <div className="relative flex-1 max-w-sm">
                  <Search className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
                  <Input
                    placeholder="Cari makanan, minuman, barang..."
                    className="pl-9 text-xs"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                  />
                </div>

                <div className="flex items-center gap-1.5 overflow-x-auto pb-1">
                  <Button
                    variant={selectedCategory === "all" ? "default" : "outline"}
                    size="sm"
                    className="text-xs h-8 cursor-pointer"
                    onClick={() => setSelectedCategory("all")}
                  >
                    Semua
                  </Button>
                  <Button
                    variant={selectedCategory === "canteen" ? "default" : "outline"}
                    size="sm"
                    className="text-xs h-8 cursor-pointer"
                    onClick={() => setSelectedCategory("canteen")}
                  >
                    Kantin Makanan
                  </Button>
                  <Button
                    variant={selectedCategory === "coop" ? "default" : "outline"}
                    size="sm"
                    className="text-xs h-8 cursor-pointer"
                    onClick={() => setSelectedCategory("coop")}
                  >
                    Koperasi
                  </Button>
                </div>
              </div>

              {/* Products Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3">
                {filteredItems.map((item) => {
                  const qty = getItemCountInBasket(item.id);
                  return (
                    <button
                      key={item.id}
                      onClick={() => addItem(item)}
                      className={`relative flex flex-col justify-between p-3.5 rounded-xl border text-left transition-all cursor-pointer group hover:border-primary/50 hover:shadow-md ${
                        qty > 0
                          ? "bg-primary/5 border-primary/40 ring-1 ring-primary/30"
                          : "bg-card border-border/80"
                      }`}
                    >
                      {qty > 0 && (
                        <span className="absolute top-2 right-2 size-5 rounded-full bg-primary text-primary-foreground font-bold text-[11px] flex items-center justify-center shadow">
                          {qty}
                        </span>
                      )}
                      <div>
                        <Badge
                          variant="secondary"
                          className="text-[9px] px-1.5 py-0 mb-1.5 uppercase tracking-wider"
                        >
                          {item.merchant_name}
                        </Badge>
                        <p className="font-semibold text-xs sm:text-sm line-clamp-2 text-foreground group-hover:text-primary transition-colors">
                          {item.name}
                        </p>
                      </div>
                      <div className="mt-3 pt-2 border-t flex items-center justify-between">
                        <span className="font-bold text-xs sm:text-sm text-foreground">
                          Rp {item.price.toLocaleString("id-ID")}
                        </span>
                        <div className="size-6 rounded-md bg-muted flex items-center justify-center text-muted-foreground group-hover:bg-primary group-hover:text-primary-foreground transition-colors">
                          <Plus className="size-3.5" />
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Mode 2: Manual Calculator / Keypad */}
          {activeMode === "manual" && (
            <Card className="p-6 space-y-6">
              <div>
                <CardTitle className="text-base">Input Nominal Belanja Bebas</CardTitle>
                <p className="text-xs text-muted-foreground mt-1">
                  Gunakan mode ini bila santri membeli item non-katalog atau rincian kustom
                </p>
              </div>

              <div className="space-y-3">
                <div className="relative">
                  <span className="absolute left-4 top-3 text-lg font-bold text-muted-foreground">
                    Rp
                  </span>
                  <Input
                    type="text"
                    placeholder="0"
                    className="pl-12 text-2xl font-bold h-14 font-mono tracking-tight"
                    value={
                      manualInput
                        ? parseInt(manualInput, 10).toLocaleString("id-ID")
                        : ""
                    }
                    onChange={(e) => handleManualChange(e.target.value)}
                  />
                </div>

                {/* Quick Add Chips */}
                <div className="flex flex-wrap gap-2">
                  {[2000, 5000, 10000, 15000, 20000, 50000].map((amt) => (
                    <Button
                      key={amt}
                      type="button"
                      variant="outline"
                      size="sm"
                      className="text-xs cursor-pointer"
                      onClick={() => addManualQuick(amt)}
                    >
                      +Rp {amt.toLocaleString("id-ID")}
                    </Button>
                  ))}
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="text-xs text-destructive cursor-pointer"
                    onClick={() => {
                      setManualInput("");
                      setManualAmount(0);
                    }}
                  >
                    Reset Nominal
                  </Button>
                </div>
              </div>

              <div className="space-y-1.5 pt-2 border-t">
                <label className="text-xs font-medium text-foreground flex items-center gap-1.5">
                  <FileText className="size-3.5 text-muted-foreground" />
                  Catatan Transaksi (Opsional)
                </label>
                <Input
                  placeholder="Contoh: Paket sarapan khusus & teh manis"
                  value={state.note}
                  onChange={(e) => setNote(e.target.value)}
                  className="text-xs"
                />
              </div>
            </Card>
          )}
        </div>

        {/* Right Section: Cart / Basket Summary */}
        <div className="lg:col-span-5 xl:col-span-4 sticky top-20">
          <Card className="shadow-md border-border/80">
            <CardHeader className="pb-3 border-b flex flex-row items-center justify-between">
              <div className="flex items-center gap-2">
                <ShoppingBag className="size-4 text-primary" />
                <CardTitle className="text-sm font-semibold">Keranjang Belanja</CardTitle>
              </div>
              {totalQuantity > 0 && (
                <Button
                  variant="ghost"
                  size="sm"
                  className="text-[11px] h-7 text-muted-foreground hover:text-destructive cursor-pointer"
                  onClick={clearBasket}
                >
                  Kosongkan
                </Button>
              )}
            </CardHeader>

            <CardContent className="p-4 space-y-4">
              {/* Basket Items List */}
              <div className="max-h-72 overflow-y-auto divide-y space-y-2">
                {state.basket.length === 0 && state.manualAmount <= 0 ? (
                  <div className="text-center py-8 text-muted-foreground space-y-1">
                    <Coins className="size-8 mx-auto opacity-30 stroke-[1.5]" />
                    <p className="text-xs font-medium">Belum ada item dipilih</p>
                    <p className="text-[11px]">Pilih produk dari katalog atau masukkan nominal manual</p>
                  </div>
                ) : (
                  <>
                    {state.basket.map((b) => (
                      <div key={b.item.id} className="pt-2 first:pt-0 flex items-center justify-between gap-2">
                        <div className="min-w-0 flex-1">
                          <p className="text-xs font-semibold text-foreground truncate">{b.item.name}</p>
                          <p className="text-[11px] text-muted-foreground">
                            @ Rp {b.item.price.toLocaleString("id-ID")}
                          </p>
                        </div>

                        {/* Quantity Counter */}
                        <div className="flex items-center gap-1.5 shrink-0">
                          <Button
                            variant="outline"
                            size="icon"
                            className="size-6 text-xs cursor-pointer"
                            onClick={() => updateQuantity(b.item.id, b.quantity - 1)}
                          >
                            <Minus className="size-3" />
                          </Button>
                          <span className="w-5 text-center text-xs font-bold font-mono">
                            {b.quantity}
                          </span>
                          <Button
                            variant="outline"
                            size="icon"
                            className="size-6 text-xs cursor-pointer"
                            onClick={() => updateQuantity(b.item.id, b.quantity + 1)}
                          >
                            <Plus className="size-3" />
                          </Button>
                          <span className="w-16 text-right text-xs font-bold font-mono">
                            Rp {(b.item.price * b.quantity).toLocaleString("id-ID")}
                          </span>
                        </div>
                      </div>
                    ))}

                    {state.manualAmount > 0 && (
                      <div className="pt-2 flex items-center justify-between">
                        <div>
                          <p className="text-xs font-semibold">Nominal Manual</p>
                          <p className="text-[11px] text-muted-foreground truncate max-w-[150px]">
                            {state.note || "Transaksi Bebas"}
                          </p>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold font-mono text-primary">
                            Rp {state.manualAmount.toLocaleString("id-ID")}
                          </span>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="size-6 text-destructive cursor-pointer"
                            onClick={() => {
                              setManualInput("");
                              setManualAmount(0);
                            }}
                          >
                            <Trash2 className="size-3" />
                          </Button>
                        </div>
                      </div>
                    )}
                  </>
                )}
              </div>

              {/* Total & Action */}
              <div className="border-t pt-3 space-y-3">
                <div className="flex items-baseline justify-between">
                  <span className="text-xs font-medium text-muted-foreground">
                    Total Pembayaran ({totalQuantity} item)
                  </span>
                  <span className="text-xl font-bold tracking-tight text-primary font-mono">
                    Rp {totalAmount.toLocaleString("id-ID")}
                  </span>
                </div>

                <Button
                  className="w-full h-11 text-sm font-semibold cursor-pointer shadow-md gap-2"
                  disabled={totalAmount <= 0}
                  onClick={handleProceed}
                >
                  Lanjut ke Langkah 2: Tap Kartu
                  <ArrowRight className="size-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
}
