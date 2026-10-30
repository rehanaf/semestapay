"use client";

import * as React from "react";
import { Badge } from "../ui/badge";
import { Button } from "../ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "../ui/dropdown-menu";
import { Avatar, AvatarFallback } from "../ui/avatar";
import { Bell, LogOut, ShieldCheck, User } from "lucide-react";
import { useAuth } from "../auth/auth-context";

export interface HeaderProps {
  title?: string;
  subtitle?: string;
  portalBadge?: string;
}

export function Header({ title, subtitle, portalBadge }: HeaderProps) {
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
    <header className="h-16 border-b bg-card/60 backdrop-blur-sm px-6 flex items-center justify-between sticky top-0 z-10">
      <div>
        {title && (
          <h1 className="text-lg font-bold tracking-tight text-foreground">
            {title}
          </h1>
        )}
        {subtitle && <p className="text-xs text-muted-foreground">{subtitle}</p>}
      </div>

      <div className="flex items-center gap-3">
        {portalBadge && (
          <Badge variant="outline" className="hidden sm:inline-flex gap-1.5 py-1">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
            <span className="font-medium text-xs">{portalBadge}</span>
          </Badge>
        )}

        <Button variant="ghost" size="icon" className="h-9 w-9 text-muted-foreground relative">
          <Bell className="h-4 w-4" />
          <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-primary" />
        </Button>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="relative h-9 w-9 rounded-full p-0">
              <Avatar className="h-9 w-9 border border-border">
                <AvatarFallback className="bg-primary/10 text-primary font-bold text-xs">
                  {initials}
                </AvatarFallback>
              </Avatar>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent className="w-56" align="end" forceMount>
            <DropdownMenuLabel className="font-normal">
              <div className="flex flex-col space-y-1">
                <p className="text-sm font-medium leading-none">{user?.name || "Pengguna"}</p>
                <p className="text-xs leading-none text-muted-foreground">
                  {user?.email || user?.phone || ""}
                </p>
                <div className="pt-1 flex flex-wrap gap-1">
                  {user?.roles?.map((role) => (
                    <Badge key={role} variant="secondary" className="text-[10px] py-0 px-1.5">
                      {role}
                    </Badge>
                  ))}
                </div>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem className="gap-2">
              <User className="h-4 w-4" />
              <span>Profil Pengguna</span>
            </DropdownMenuItem>
            <DropdownMenuItem className="gap-2">
              <ShieldCheck className="h-4 w-4" />
              <span>Keamanan & Sandi</span>
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              className="gap-2 text-destructive focus:text-destructive"
              onClick={() => logout()}
            >
              <LogOut className="h-4 w-4" />
              <span>Keluar Sesi</span>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
