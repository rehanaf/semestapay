import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { AuthProvider } from "@/lib/auth-context";
import { PosProvider } from "@/lib/pos-context";
import { cn } from "@/lib/utils";

const geist = Geist({ subsets: ["latin"], variable: "--font-sans" });

const fontMono = Geist_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: "SemestaPay — Merchant Portal",
  description: "Portal Pengelola Toko & Kantin Pesantren SemestaPay",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="id"
      suppressHydrationWarning
      className={cn("antialiased", fontMono.variable, "font-sans", geist.variable)}
    >
      <body className="min-h-screen bg-background text-foreground antialiased">
        <ThemeProvider>
          <AuthProvider>
            <PosProvider>{children}</PosProvider>
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
