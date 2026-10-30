"use client";

import * as React from "react";
import {
  authApi,
  getStoredToken,
  getStoredUser,
  UserProfile,
  ApiError,
} from "../../lib/api-client";

interface AuthContextType {
  user: UserProfile | null;
  token: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (
    email: string,
    pass: string,
    deviceName?: string
  ) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  hasRole: (roleOrRoles: string | string[]) => boolean;
  refreshUser: () => Promise<void>;
}

const AuthContext = React.createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = React.useState<UserProfile | null>(null);
  const [token, setToken] = React.useState<string | null>(null);
  const [isLoading, setIsLoading] = React.useState(true);

  React.useEffect(() => {
    // Restore from localStorage
    const savedToken = getStoredToken();
    const savedUser = getStoredUser();

    if (savedToken && savedUser) {
      setToken(savedToken);
      setUser(savedUser);
      // Verify token in background
      authApi
        .me()
        .then((res) => {
          setUser(res.user);
        })
        .catch(() => {
          // Token is invalid/expired
          authApi.logout();
          setToken(null);
          setUser(null);
        })
        .finally(() => {
          setIsLoading(false);
        });
    } else {
      setIsLoading(false);
    }
  }, []);

  const login = async (
    email: string,
    password: string,
    deviceName?: string
  ): Promise<{ success: boolean; error?: string }> => {
    setIsLoading(true);
    try {
      const res = await authApi.login({ email, password, device_name: deviceName });
      setToken(res.token);
      setUser(res.user);
      return { success: true };
    } catch (err) {
      const msg =
        err instanceof ApiError
          ? err.message
          : err instanceof Error
          ? err.message
          : "Gagal masuk ke sistem. Silakan coba lagi.";
      return { success: false, error: msg };
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    setIsLoading(true);
    try {
      await authApi.logout();
    } finally {
      setToken(null);
      setUser(null);
      setIsLoading(false);
    }
  };

  const hasRole = (roleOrRoles: string | string[]): boolean => {
    if (!user || !user.roles) return false;
    const checkRoles = Array.isArray(roleOrRoles) ? roleOrRoles : [roleOrRoles];
    return user.roles.some((r) => checkRoles.includes(r));
  };

  const refreshUser = async () => {
    if (!token) return;
    try {
      const res = await authApi.me();
      setUser(res.user);
    } catch {
      // Ignore
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isLoading,
        isAuthenticated: !!token && !!user,
        login,
        logout,
        hasRole,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = React.useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
