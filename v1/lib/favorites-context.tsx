"use client"

import type React from "react"

import { createContext, useContext, useState, useEffect, useCallback } from "react"

interface FavoritesContextType {
  favorites: Set<string>
  addFavorite: (strongNumber: string) => void
  removeFavorite: (strongNumber: string) => void
  isFavorite: (strongNumber: string) => boolean
  history: Array<{ strongNumber: string; timestamp: number }>
  addToHistory: (strongNumber: string) => void
}

const FavoritesContext = createContext<FavoritesContextType | undefined>(undefined)

export function FavoritesProvider({ children }: { children: React.ReactNode }) {
  const [favorites, setFavorites] = useState<Set<string>>(new Set())
  const [history, setHistory] = useState<Array<{ strongNumber: string; timestamp: number }>>([])
  const [isLoaded, setIsLoaded] = useState(false)

  // Load from localStorage
  useEffect(() => {
    const savedFavorites = localStorage.getItem("bible-favorites")
    const savedHistory = localStorage.getItem("bible-history")

    if (savedFavorites) {
      setFavorites(new Set(JSON.parse(savedFavorites)))
    }
    if (savedHistory) {
      setHistory(JSON.parse(savedHistory))
    }
    setIsLoaded(true)
  }, [])

  // Save to localStorage
  useEffect(() => {
    if (isLoaded) {
      localStorage.setItem("bible-favorites", JSON.stringify(Array.from(favorites)))
      localStorage.setItem("bible-history", JSON.stringify(history))
    }
  }, [favorites, history, isLoaded])

  const addFavorite = useCallback((strongNumber: string) => {
    setFavorites((prev) => new Set([...prev, strongNumber]))
  }, [])

  const removeFavorite = useCallback((strongNumber: string) => {
    setFavorites((prev) => {
      const newSet = new Set(prev)
      newSet.delete(strongNumber)
      return newSet
    })
  }, [])

  const isFavorite = useCallback((strongNumber: string) => favorites.has(strongNumber), [favorites])

  const addToHistory = useCallback((strongNumber: string) => {
    setHistory((prev) => {
      if (prev.length > 0 && prev[0].strongNumber === strongNumber) return prev
      return [{ strongNumber, timestamp: Date.now() }, ...prev.slice(0, 19)]
    })
  }, [])

  return (
    <FavoritesContext.Provider value={{ favorites, addFavorite, removeFavorite, isFavorite, history, addToHistory }}>
      {children}
    </FavoritesContext.Provider>
  )
}

export function useFavorites() {
  const context = useContext(FavoritesContext)
  if (!context) {
    throw new Error("useFavorites must be used within FavoritesProvider")
  }
  return context
}
