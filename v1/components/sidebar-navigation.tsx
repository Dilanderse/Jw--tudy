"use client"

import { useNavigation } from "@/lib/navigation-context"
import { useTheme } from "@/lib/theme-context"
import { BookMarked, Calendar, Map, Heart, ChevronLeft, Sun, Moon } from "lucide-react"

const modules = [
  { id: "bible", name: "Étude Biblique", icon: BookMarked },
  { id: "chronology", name: "Chronologie", icon: Calendar },
  { id: "atlas", name: "Atlas Biblique", icon: Map },
  { id: "favorites", name: "Favoris", icon: Heart },
] as const

export function SidebarNavigation() {
  const { activeModule, setActiveModule, sidebarOpen, setSidebarOpen } = useNavigation()
  const { theme, toggleTheme } = useTheme()

  return (
    <>
      {/* PC Sidebar - Always Visible */}
      <aside
        className={`hidden md:sticky md:top-0 md:flex md:h-screen md:shrink-0 flex-col bg-card border-r border-border transition-all duration-300 ease-in-out ${
          sidebarOpen ? "w-64" : "w-20"
        }`}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-border">
          {sidebarOpen && <h2 className="text-lg font-semibold text-foreground">Outils</h2>}
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="ml-auto p-1.5 hover:bg-secondary rounded-lg transition-colors"
            aria-label="Toggle sidebar"
          >
            <ChevronLeft className={`w-4 h-4 transition-transform duration-300 ${!sidebarOpen ? "rotate-180" : ""}`} />
          </button>
        </div>

        {/* Navigation Items */}
        <nav className="flex-1 overflow-y-auto p-3 space-y-2">
          {modules.map((module) => {
            const Icon = module.icon
            const isActive = activeModule === module.id
            return (
              <button
                key={module.id}
                onClick={() => setActiveModule(module.id as any)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-300 ${
                  isActive ? "bg-primary text-primary-foreground shadow-lg" : "text-foreground hover:bg-secondary"
                }`}
              >
                <Icon className="w-5 h-5 flex-shrink-0" />
                {sidebarOpen && <span className="text-sm font-medium">{module.name}</span>}
              </button>
            )
          })}
        </nav>

        {/* Theme Toggle */}
        <div className="p-3 border-t border-border">
          <button
            onClick={toggleTheme}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-foreground hover:bg-secondary transition-all duration-300"
            aria-label={theme === "dark" ? "Passer en mode clair" : "Passer en mode sombre"}
          >
            {theme === "dark" ? (
              <Sun className="w-5 h-5 flex-shrink-0" />
            ) : (
              <Moon className="w-5 h-5 flex-shrink-0" />
            )}
            {sidebarOpen && (
              <span className="text-sm font-medium">
                {theme === "dark" ? "Mode clair" : "Mode sombre"}
              </span>
            )}
          </button>
        </div>
      </aside>

      {/* Mobile Bottom Navigation - Fixed at bottom */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-card border-t border-border flex z-50">
        {modules.map((module) => {
          const Icon = module.icon
          const isActive = activeModule === module.id
          return (
            <button
              key={module.id}
              onClick={() => setActiveModule(module.id as any)}
              className={`flex-1 flex flex-col items-center gap-1 py-3 transition-all duration-300 ${
                isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <Icon className={`w-5 h-5 transition-all duration-300 ${isActive ? "scale-110" : ""}`} />
              <span className="text-xs font-medium text-center line-clamp-1">{module.name.split(" ")[0]}</span>
            </button>
          )
        })}
        <button
          onClick={toggleTheme}
          className="flex-1 flex flex-col items-center gap-1 py-3 text-muted-foreground hover:text-foreground transition-all duration-300"
          aria-label={theme === "dark" ? "Mode clair" : "Mode sombre"}
        >
          {theme === "dark" ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
          <span className="text-xs font-medium">
            {theme === "dark" ? "Clair" : "Sombre"}
          </span>
        </button>
      </nav>
    </>
  )
}
