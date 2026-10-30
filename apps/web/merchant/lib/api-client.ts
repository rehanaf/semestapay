export interface UserProfile {
  id: number;
  name: string;
  email: string | null;
  phone: string | null;
  roles: string[];
}

export interface AuthLoginResponse {
  token: string;
  user: UserProfile;
}

export interface ApiErrorResponse {
  message: string;
  errors?: Record<string, string[]>;
  code?: string;
}

export class ApiError extends Error {
  status: number;
  code?: string;
  errors?: Record<string, string[]>;

  constructor(status: number, message: string, code?: string, errors?: Record<string, string[]>) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.errors = errors;
  }
}

const TOKEN_KEY = "semestapay_token";
const USER_KEY = "semestapay_user";

export function getStoredToken(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setStoredToken(token: string): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(TOKEN_KEY, token);
  } catch {}
}

export function removeStoredToken(): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.removeItem(TOKEN_KEY);
  } catch {}
}

export function getStoredUser(): UserProfile | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as UserProfile) : null;
  } catch {
    return null;
  }
}

export function setStoredUser(user: UserProfile): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  } catch {}
}

export function removeStoredUser(): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.removeItem(USER_KEY);
  } catch {}
}

export function getBaseApiUrl(): string {
  if (typeof window !== "undefined") {
    if ((window as any).__SEMESTA_API_URL__) {
      return (window as any).__SEMESTA_API_URL__;
    }
    if (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1") {
      return "http://localhost:8000/api/v1";
    }
    return "https://pay-api.zet.web.id/api/v1";
  }
  return process.env.NEXT_PUBLIC_API_URL || "https://pay-api.zet.web.id/api/v1";
}

export async function apiFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const baseUrl = getBaseApiUrl();
  const cleanEndpoint = endpoint.startsWith("/") ? endpoint : `/${endpoint}`;
  const url = `${baseUrl}${cleanEndpoint}`;

  const token = getStoredToken();

  const headers: Record<string, string> = {
    Accept: "application/json",
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string> || {}),
  };

  if (token && !headers["Authorization"]) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  const isJson = response.headers.get("content-type")?.includes("application/json");
  const data = isJson ? await response.json() : null;

  if (!response.ok) {
    const message =
      (data as ApiErrorResponse)?.message ||
      (data?.errors ? Object.values(data.errors).flat().join(", ") : null) ||
      `HTTP ${response.status}: ${response.statusText}`;

    throw new ApiError(
      response.status,
      message,
      (data as ApiErrorResponse)?.code,
      (data as ApiErrorResponse)?.errors
    );
  }

  return data as T;
}

export const authApi = {
  async login(credentials: {
    email: string;
    password: string;
    device_name?: string;
  }): Promise<AuthLoginResponse> {
    const res = await apiFetch<AuthLoginResponse>("/auth/login", {
      method: "POST",
      body: JSON.stringify(credentials),
    });

    setStoredToken(res.token);
    setStoredUser(res.user);

    return res;
  },

  async me(): Promise<{ user: UserProfile }> {
    return apiFetch<{ user: UserProfile }>("/auth/me", {
      method: "POST",
    });
  },

  async logout(): Promise<void> {
    try {
      await apiFetch("/auth/logout", {
        method: "POST",
      });
    } finally {
      removeStoredToken();
      removeStoredUser();
    }
  },

  getToken: getStoredToken,
  getUser: getStoredUser,
};

export interface MenuItem {
  id: number;
  merchant_id: number;
  merchant_name: string;
  name: string;
  price: number;
  status: string;
}

export interface TransactionRecord {
  id: string;
  created_at: string;
  type: string;
  amount: number;
  status: string;
  student_name: string;
  student_nis?: string;
  merchant_name: string;
  note?: string;
}

export const appApi = {
  async getItems(search?: string): Promise<{ data: MenuItem[] }> {
    const q = search ? `?search=${encodeURIComponent(search)}` : "";
    return apiFetch<{ data: MenuItem[] }>(`/items${q}`);
  },

  async createItem(payload: {
    name: string;
    price: number;
    merchant_id?: number;
    status?: string;
  }): Promise<{ message: string; data: MenuItem }> {
    return apiFetch("/items", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  async updateItem(id: number, payload: Partial<MenuItem>): Promise<{ message: string; data: MenuItem }> {
    return apiFetch(`/items/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  },

  async getTransactions(): Promise<{ data: TransactionRecord[] }> {
    return apiFetch<{ data: TransactionRecord[] }>("/transactions");
  },
};

