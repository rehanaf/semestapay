"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "./auth-context";

interface AuthGuardProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
  requiredRoles?: string[];
  loginPath?: string;
}

export function AuthGuard({
  children,
  fallback,
  requiredRoles,
  loginPath = "/login",
}: AuthGuardProps) {
  const router = useRouter();
  const { isAuthenticated, isLoading, user, hasRole } = useAuth();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  React.useEffect(() => {
    if (mounted && !isLoading && !isAuthenticated) {
      router.replace(loginPath);
    }
  }, [mounted, isLoading, isAuthenticated, loginPath, router]);

  if (!mounted || isLoading || !isAuthenticated) {
    return (
      fallback || (
        <div className="min-h-screen flex items-center justify-center bg-background">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      )
    );
  }

  if (requiredRoles && requiredRoles.length > 0 && !hasRole(requiredRoles)) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background p-6">
        <div className="max-w-md text-center space-y-4">
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10 text-destructive text-xl font-bold">
            !
          </div>
          <h2 className="text-xl font-bold text-foreground">Akses Dibatasi</h2>
          <p className="text-sm text-muted-foreground">
            Akun Anda ({user?.email || user?.name}) tidak memiliki izin untuk
            mengakses portal ini (Role yang dibutuhkan: {requiredRoles.join(", ")}).
          </p>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
