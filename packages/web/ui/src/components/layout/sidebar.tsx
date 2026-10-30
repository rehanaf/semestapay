"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "../../lib/utils";
import { Badge } from "../ui/badge";
import { Button } from "../ui/button";
import { Avatar, AvatarFallback } from "../ui/avatar";
import { LogOut } from "lucide-react";
import { useAuth } from "../auth/auth-context";

export interface NavItem {
  title: string;
  href: string;
  icon: React.ReactNode;
  badge?: string | number;
}

export interface SidebarProps {
  appTitle: string;
  appSubtitle: string;
  portalBadge?: string;
  navItems: NavItem[];
  className?: string;
}

export function Sidebar({
  appTitle,
  appSubtitle,
  portalBadge,
  navItems,
  className,
}: SidebarProps) {
  const pathname = usePathname();
  const { user, logout } = useAuth();

  const initials = user?.name
    ? user.name
        .split(" ")
        .map((n) => n[0])
        .slice(0, 2)
        .join("")
        .toUpperCase()
    : "SP";

  return (
    <aside
      className={cn(
        "flex flex-col w-64 border-r bg-card/60 backdrop-blur-sm h-screen sticky top-0",
        className
      )}
    >
      {/* Brand Header */}
      <div className="p-5 border-b flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 rounded-xl bg-primary flex items-center justify-center font-bold text-primary-foreground shadow-sm">
            SP
          </div>
          <div>
            <h2 className="font-bold text-sm tracking-tight text-foreground leading-tight">
              {appTitle}
            </h2>
            <p className="text-xs text-muted-foreground">{appSubtitle}</p>
          </div>
        </div>
        {portalBadge && (
          <Badge variant="secondary" className="text-[10px] font-semibold uppercase tracking-wider">
            {portalBadge}
          </Badge>
        )}
      </div>

      {/* Nav Menu */}
      <nav className="flex-1 overflow-y-auto p-3 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center justify-between px-3 py-2 rounded-lg text-sm font-medium transition-colors",
                isActive
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground"
              )}
            >
              <div className="flex items-center gap-3">
                <span className="h-4 w-4 shrink-0">{item.icon}</span>
                <span>{item.title}</span>
              </div>
              {item.badge !== undefined && (
                <span
                  className={cn(
                    "text-[10px] font-semibold px-1.5 py-0.5 rounded-full",
                    isActive
                      ? "bg-primary-foreground/20 text-primary-foreground"
                      : "bg-muted text-foreground"
                  )}
                >
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* User Card & Logout */}
      <div className="p-3 border-t bg-muted/20">
        <div className="flex items-center justify-between p-2 rounded-lg bg-card border">
          <div className="flex items-center gap-2.5 overflow-hidden">
            <Avatar className="h-8 w-8 shrink-0">
              <AvatarFallback className="bg-primary/10 text-primary font-bold text-xs">
                {initials}
              </AvatarFallback>
            </Avatar>
            <div className="overflow-hidden">
              <p className="text-xs font-semibold truncate text-foreground">
                {user?.name || "Pengguna"}
              </p>
              <p className="text-[11px] text-muted-foreground truncate">
                {user?.email || user?.phone || "Operator"}
              </p>
            </div>
          </div>
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 text-muted-foreground hover:text-destructive"
            onClick={() => logout()}
            title="Keluar"
          >
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </aside>
  );
}
