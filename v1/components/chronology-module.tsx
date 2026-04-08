export function ChronologyModule() {
  return (
    <div className="min-h-screen pb-20 md:pb-0 bg-background">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-16">
        <div className="mb-12 animate-in fade-in slide-in-from-bottom-4 duration-500">
          <h1 className="text-4xl sm:text-5xl font-light tracking-tight text-balance text-foreground mb-3">
            Chronologie Biblique
          </h1>
          <p className="text-muted-foreground">
            Visualisez les événements et les personnages dans leur contexte temporel.
          </p>
        </div>

        <div className="bg-card border border-border rounded-lg p-12 hover:border-primary/50 transition-colors duration-300">
          <div className="h-96 flex items-center justify-center text-muted-foreground">
            Timeline interactive à venir
          </div>
        </div>
      </div>
    </div>
  )
}
