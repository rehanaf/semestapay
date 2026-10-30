"use client";

import * as React from "react";
import { MenuItem, CardReadResponse, TapPaymentResponse } from "@/lib/api-client";

export interface BasketItem {
  item: MenuItem;
  quantity: number;
}

export interface PosState {
  basket: BasketItem[];
  manualAmount: number;
  note: string;
  studentCard: CardReadResponse | null;
  lastReceipt: TapPaymentResponse | null;
}

interface PosContextType {
  state: PosState;
  addItem: (item: MenuItem) => void;
  removeItem: (itemId: number) => void;
  updateQuantity: (itemId: number, quantity: number) => void;
  clearBasket: () => void;
  setManualAmount: (amount: number) => void;
  setNote: (note: string) => void;
  setStudentCard: (card: CardReadResponse | null) => void;
  setLastReceipt: (receipt: TapPaymentResponse | null) => void;
  totalAmount: number;
  totalQuantity: number;
  resetAll: () => void;
}

const STORAGE_KEY = "semestapay_pos_state";

const defaultState: PosState = {
  basket: [],
  manualAmount: 0,
  note: "",
  studentCard: null,
  lastReceipt: null,
};

const PosContext = React.createContext<PosContextType | undefined>(undefined);

export function PosProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = React.useState<PosState>(() => {
    if (typeof window !== "undefined") {
      try {
        const saved = sessionStorage.getItem(STORAGE_KEY);
        if (saved) {
          return JSON.parse(saved);
        }
      } catch {
        // ignore
      }
    }
    return defaultState;
  });

  React.useEffect(() => {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // ignore
    }
  }, [state]);

  const addItem = React.useCallback((item: MenuItem) => {
    setState((prev) => {
      const idx = prev.basket.findIndex((b) => b.item.id === item.id);
      if (idx >= 0) {
        const nextBasket = [...prev.basket];
        nextBasket[idx] = {
          ...nextBasket[idx],
          quantity: nextBasket[idx].quantity + 1,
        };
        return { ...prev, basket: nextBasket };
      }
      return {
        ...prev,
        basket: [...prev.basket, { item, quantity: 1 }],
      };
    });
  }, []);

  const removeItem = React.useCallback((itemId: number) => {
    setState((prev) => ({
      ...prev,
      basket: prev.basket.filter((b) => b.item.id !== itemId),
    }));
  }, []);

  const updateQuantity = React.useCallback((itemId: number, quantity: number) => {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    setState((prev) => ({
      ...prev,
      basket: prev.basket.map((b) =>
        b.item.id === itemId ? { ...b, quantity } : b
      ),
    }));
  }, [removeItem]);

  const clearBasket = React.useCallback(() => {
    setState((prev) => ({ ...prev, basket: [], manualAmount: 0 }));
  }, []);

  const setManualAmount = React.useCallback((amount: number) => {
    setState((prev) => ({ ...prev, manualAmount: amount }));
  }, []);

  const setNote = React.useCallback((note: string) => {
    setState((prev) => ({ ...prev, note }));
  }, []);

  const setStudentCard = React.useCallback((studentCard: CardReadResponse | null) => {
    setState((prev) => ({ ...prev, studentCard }));
  }, []);

  const setLastReceipt = React.useCallback((lastReceipt: TapPaymentResponse | null) => {
    setState((prev) => ({ ...prev, lastReceipt }));
  }, []);

  const resetAll = React.useCallback(() => {
    setState(defaultState);
    try {
      sessionStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignore
    }
  }, []);

  const totalAmount = React.useMemo(() => {
    const productsSum = state.basket.reduce(
      (acc, b) => acc + b.item.price * b.quantity,
      0
    );
    return productsSum + (state.manualAmount > 0 ? state.manualAmount : 0);
  }, [state.basket, state.manualAmount]);

  const totalQuantity = React.useMemo(() => {
    return state.basket.reduce((acc, b) => acc + b.quantity, 0) + (state.manualAmount > 0 ? 1 : 0);
  }, [state.basket, state.manualAmount]);

  return (
    <PosContext.Provider
      value={{
        state,
        addItem,
        removeItem,
        updateQuantity,
        clearBasket,
        setManualAmount,
        setNote,
        setStudentCard,
        setLastReceipt,
        totalAmount,
        totalQuantity,
        resetAll,
      }}
    >
      {children}
    </PosContext.Provider>
  );
}

export function usePos() {
  const context = React.useContext(PosContext);
  if (!context) {
    throw new Error("usePos must be used within a PosProvider");
  }
  return context;
}
