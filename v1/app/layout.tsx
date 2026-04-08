import type React from "react"
import type { Metadata } from "next"
import { Geist, Geist_Mono } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
import { NavigationProvider } from "@/lib/navigation-context"
import { FavoritesProvider } from "@/lib/favorites-context"
import { ThemeProvider } from "@/lib/theme-context"
import { SidebarNavigation } from "@/components/sidebar-navigation"
import { SearchBar } from "@/components/search-bar"
import { Suspense } from "react"
import "./globals.css"

const _geist = Geist({ subsets: ["latin"] })
const _geistMono = Geist_Mono({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Bible Study Tool",
  description: "Modern Bible study interface",
  generator: "v0.app",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="fr" className="dark" suppressHydrationWarning>
      <body className="font-sans antialiased">
        <ThemeProvider>
        <FavoritesProvider>
          <NavigationProvider>
            <div className="flex min-h-screen flex-col bg-background md:h-screen md:flex-row md:overflow-hidden">
              {/* Sidebar - visible on desktop, bottom nav on mobile */}
              <Suspense fallback={<div>Loading...</div>}>
                <SidebarNavigation />
              </Suspense>

              <main className="flex flex-1 flex-col md:min-h-0">
                {/* Sticky Search Bar */}
                <div className="sticky top-0 z-40 border-b border-border bg-gradient-to-b from-card to-background/80 backdrop-blur-sm md:top-0">
                  <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4">
                    <Suspense fallback={<div>Loading...</div>}>
                      <SearchBar />
                    </Suspense>
                  </div>
                </div>

                {/* Main content area with proper spacing for bottom nav on mobile */}
                <div className="flex-1 overflow-y-auto pb-20 md:min-h-0 md:pb-0">{children}</div>
              </main>
            </div>
          </NavigationProvider>
        </FavoritesProvider>
        </ThemeProvider>
        <Analytics />
      </body>
    </html>
  )
}
