"use client";

import * as React from "react";
import { Sidebar, NavItem } from "./sidebar";
import { Header } from "./header";
import { AuthGuard } from "../auth/auth-guard";
import { cn } from "../../lib/utils";

export interface DashboardShellProps {
  appTitle: string;
  appSubtitle: string;
  portalBadge?: string;
  navItems: NavItem[];
  pageTitle?: string;
  pageSubtitle?: string;
  requiredRoles?: string[];
  children: React.ReactNode;
  className?: string;
}

export function DashboardShell({
  appTitle,
  appSubtitle,
  portalBadge,
  navItems,
  pageTitle,
  pageSubtitle,
  requiredRoles,
  children,
  className,
}: DashboardShellProps) {
  return (
    <AuthGuard requiredRoles={requiredRoles}>
      <div className="flex min-h-screen bg-background">
        <Sidebar
          appTitle={appTitle}
          appSubtitle={appSubtitle}
          portalBadge={portalBadge}
          navItems={navItems}
        />
        <div className="flex-1 flex flex-col min-w-0">
          <Header
            title={pageTitle}
            subtitle={pageSubtitle}
            portalBadge={portalBadge}
          />
          <main className={cn("flex-1 p-6 lg:p-8 space-y-6", className)}>
            {children}
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}
