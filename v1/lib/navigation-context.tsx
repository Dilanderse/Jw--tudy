"use client"

import type React from "react"

import { createContext, useContext, useState } from "react"

type Module = "bible" | "chronology" | "atlas" | "favorites"

interface NavigationContextType {
  activeModule: Module
  setActiveModule: (module: Module) => void
  sidebarOpen: boolean
  setSidebarOpen: (open: boolean) => void
}

const NavigationContext = createContext<NavigationContextType | undefined>(undefined)

export function NavigationProvider({ children }: { children: React.ReactNode }) {
  const [activeModule, setActiveModule] = useState<Module>("bible")
  const [sidebarOpen, setSidebarOpen] = useState(true)

  return (
    <NavigationContext.Provider value={{ activeModule, setActiveModule, sidebarOpen, setSidebarOpen }}>
      {children}
    </NavigationContext.Provider>
  )
}

export function useNavigation() {
  const context = useContext(NavigationContext)
  if (!context) throw new Error("useNavigation must be used within NavigationProvider")
  return context
}
