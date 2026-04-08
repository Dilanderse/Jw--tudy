"use client"

import { Suspense } from "react"
import { useNavigation } from "@/lib/navigation-context"
import { BibleModule } from "@/components/bible-module"
import { ChronologyModule } from "@/components/chronology-module"
import { AtlasModule } from "@/components/atlas-module"
import { FavoritesModule } from "@/components/favorites-module"

function PageContent() {
  const { activeModule } = useNavigation()

  return (
    <>
      {activeModule === "bible" && <BibleModule />}
      {activeModule === "chronology" && <ChronologyModule />}
      {activeModule === "atlas" && <AtlasModule />}
      {activeModule === "favorites" && <FavoritesModule />}
    </>
  )
}

export default function Home() {
  return (
    <Suspense fallback={null}>
      <PageContent />
    </Suspense>
  )
}
