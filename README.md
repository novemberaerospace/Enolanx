# Documentation Technique : Turbines ACME — Architectures NDT-LERF & SHAFT

&gt; **Framework** : ACME (Advanced Computational Manufacturing Engine)  
&gt; **Noyau géométrique** : PicoGK (transposition Swift)  
&gt; **Classification** : Systèmes LERF (Large Electric Rotor Fan) & SHAFT (Schauberger Hydraulic Axial Flux Turbine)  
&gt; **Date** : Mars 2026

---

## Table des matières

1. [Taxonomie ACME](#taxonomie-acme)
2. [ME-1 : Série NDT-LERF](#me-1--série-ndt-lerf)
   - [ME-1A : Turbine Muller (Périphérique)](#me-1a--turbine-muller-périphérique)
   - [ME-1B : Turbine Wardell-Nelis (Centrale)](#me-1b--turbine-wardell-nelis-centrale)
3. [ME-2 : Série SHAFT](#me-2--série-shaft)
   - [ME-2A : Morland (Vertical/Hydro)](#me-2a--morland-verticalhydro)
   - [ME-2B : Markov (Horizontal/Nucléaire)](#me-2b--markov-horizontalnucléaire)
4. [Méthodologie de conception](#méthodologie-de-conception)
5. [Spécifications d'impression 3D](#spécifications-dimpression-3d)

---

## Taxonomie ACME

| Code | Désignation | Architecture | Configuration | Application |
|------|-------------|--------------|---------------|-------------|
| **ME-1A** | Muller | NDT-LERF (I \|\| O) | Roulements périphériques | Ventilation forcée, propulsion électrique distribuée |
| **ME-1B** | Wardell-Nelis | NDT-LERF (I \|\| O) | Roulements centraux | Turbocompresseur, propulsion hybride |
| **ME-2A** | Morland | SHAFT | Vertical, syphon central | Micro-hydro, production électrique basse chute |
| **ME-2B** | Markov | SHAFT | Horizontal, flux axial | Conversion énergie nucléaire (secondaire) |

**Légende NDT-LERF :** Neodymium Ducted Tape Large Electric Rotor Fan  
**Légende SHAFT :** Schauberger Hydraulic Axial Flux Turbine

---

## ME-1 : Série NDT-LERF

### Concept général

Les turbines NDT-LERF constituent une famille de machines électromagnétiques intégrées où le rotor constitue simultanément :
- L'élément aérodynamique (aubes/flux)
- L'inducteur magnétique (NdFeB)
- La structure portante (bande ductile)

L'architecture **(I \|\| O)** — *Internal or External* — désigne la position relative du stator électrique par rapport au rotor aérodynamique.

┌─────────────────────────────────────────┐
│           NDT-LERF (I || O)             │
│                                         │
│    ┌─────────────────────────────┐      │
│    │      Duct externe (O)       │      │
│    │    ┌─────────────────┐      │      │
│    │    │   Rotor NdFeB   │◄─────┼──────┤── Bande ductile
│    │    │   (aubes intégrées)    │      │      intégrée
│    │    └─────────────────┘      │      │
│    │         ▲                   │      │
│    │    Stator interne (I)       │      │
│    └─────────────────────────────┘      │
│                                         │
└─────────────────────────────────────────┘




### ME-1A : Turbine Muller (Périphérique)

#### Architecture des roulements

La **Muller** inverse la configuration classique : les paliers sont positionnés en **périphérie** du rotor, créant une géométrie de type *rim-driven*.


╔═══════════════════════════════════════╗
║  ◄──── Roulement magnétique périph.   ║
║  ┌─────────────────────────────────┐  ║
║  │      ╔═══════════════════╗      │  ║
║  │      ║   ROTOR NdFeB     ║      │  ║
║  │      ║   (Aubes intégrées)      │  ║
║  │      ║                   ║      │  ║
║  │      ╚═══════════════════╝      │  ║
║  │            ▲                    │  ║
║  │      STATOR CENTRAL (I)         │  ║
║  │      (Bobinages Cu)             │  ║
║  └─────────────────────────────────┘  ║
║  ◄──── Roulement magnétique périph.   ║
╚═══════════════════════════════════════╝
     ▲                              ▲
     └──── Duct de guidage flux ────┘



#### Caractéristiques distinctives

| Paramètre | Spécification | Avantage |
|-----------|---------------|----------|
| **Diamètre rotor** | 200-800mm | Grande inertie pour régularisation |
| **Roulements** | Magnétiques passifs, position périphérique | Élimination du moyeu central (flux libre) |
| **Bande ductile** | Composite NdFeB + Ti (imprimé) | Induction radiale maximale |
| **Configuration élec.** | Stator interne (I), rotor externe (O) | Refroidissement naturel par flux traversant |
| **Vitesse** | 500-3000 RPM | Couple élevé, bruit réduit |

#### Applications

- **Ventilation industrielle** : Grand débit, faible pression, sans transmission mécanique
- **Propulsion navale** : Rim-driven thruster, haute efficience (pas d'hélice centrale)
- **Aérorefroidissement** : Tours de refroidissement avec moteurs intégrés dans le diffuseur

---

### ME-1B : Turbine Wardell-Nelis (Centrale)

#### Architecture des roulements

La **Wardell-Nelis** conserve une configuration plus conventionnelle avec roulements **centraux**, mais avec une innovation majeure : le rotor constitue une cloche creuse en néodymium avec aubes intégrées en une seule pièce imprimée.


    ┌──────────────────────────────┐
    │        Duct de sortie        │
    └──────────────┬───────────────┘
                   │
┌──────────────────┼──────────────────┐
│   ┌──────────────┴──────────────┐   │
│   │      Roulement central      │   │
│   │      (Magnetique+mécanique) │   │
│   └──────────────┬──────────────┘   │
│                  │                   │
│   ╔══════════════╧══════════════╗   │
│   ║    ROTOR CLOCHE NdFeB       ║   │
│   ║   ┌─────────────────────┐   ║   │
│   ║   │   Moyeu central     │   ║   │
│   ║   │   (Aimanté)         │   ║   │
│   ║   └─────────────────────┘   ║   │
│   ║   │ Aube 1 │ Aube 2 │ ...   ║   │
│   ║   │ Intégrées dans bande    ║   │
│   ║   │ ductile périphérique    ║   │
│   ╚══════════════════════════════╝   │
│                  ▲                   │
│      STATOR ANNULAIRE EXTERNE (O)    │
│      (Enroulements dans duct)        │
└──────────────────────────────────────┘



#### Caractéristiques distinctives

| Paramètre | Spécification | Avantage |
|-----------|---------------|----------|
| **Forme rotor** | Cloche/nappe hyperboloïde | Rigidité aéro-élastique optimale |
| **Roulements** | Hybrides centraux (2 paliers) | Compacité axiale, maintenance simplifiée |
| **Bande ductile** | Profil variable d'épaisseur | Adaptation contraintes centrifuges |
| **Configuration élec.** | Stator externe (O), rotor interne (I) | Grande surface d'entrefer active |
| **Vitesse** | 5000-15000 RPM | Haute puissance massique |

#### Applications

- **Turbocompresseur électrique** : Suralimentation moteurs thermiques avec récupération énergie
- **Propulsion aéronautique hybride** : Soufflante ductée à vitesse variable
- **Systèmes de conditionnement** : Compresseurs sans huile pour gaz critiques

---

## ME-2 : Série TAT (Jourquain)

Les turbines **TAT** (Tesla Axial Turbine)
 
## ME-3 : Série SHAFT (Morland)

### Concept général

Les turbines **SHAFT** (Schauberger Hydraulic Axial Flux Turbine) reprennent les principes biomimétiques de Viktor Schauberger — mouvement spiralé naturel, vortex d'aspiration — couplés à une architecture de générateur à **flux axial** (disque plat, aimantation axiale).

Le cœur du système est un **moyeu hydroponique** : une chambre centrale où le fluide (eau ou caloporteur) s'engouffre par effet de syphon, entraînant le rotor par réaction.

Principe SHAFT :


Entrée fluide
    │
    ▼
┌─────────────┐
│   MOYEU     │◄── Chambre hydroponique
│  HYDRO-     │    (Effet venturi interne)
│  PONIQUE    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   ROTOR     │◄── Aubes réaction + aimants axiaux
│   DISQUE    │
│   (NdFeB)   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   STATOR    │◄── Bobinages face-à-face
│   DISQUE    │
└─────────────┘



#### Caractéristiques hydrauliques

| Paramètre | Spécification | Principe Schauberger |
|-----------|---------------|----------------------|
| **Entrée** | Cône d'accélération logarithmique | Spiral naturel sans turbulence |
| **Moyeu** | Diamètre variable (effet Venturi) | Augmentation vitesse par réduction section |
| **Aubes rotor** | Profil hélicoïdal inverse | Entraînement par réaction (pas de contact) |
| **Sortie** | Diffuseur annulaire | Récupération pression cinétique |
| **Orientation** | Verticale (arbre ↑↓) | Alignement gravité/écoulement |

#### Génération électrique

- **Flux axial** : Aimants NdFeB montés en surface du disque rotor, polarité axiale (N↑S↓)
- **Stator** : Bobinages trifásés en disque face au rotor, entrefer 1-2mm
- **Régulation** : Pas de vanne — contrôle par variation de la hauteur de chute dans le moyeu

#### Applications

- **Micro-centrales** : 1-100 kW, chutes < 10m
- **Aqueducs urbains** : Récupération énergie sur réseaux existants
- **Irrigation** : Pompe-turbine intégrée (mode moteur/pompage reversible)

---

### ME-3B : Markov (Horizontal/Nucléaire)

#### Configuration

La **Markov** adapte l'architecture SHAFT à un contexte **horizontal** pour l'extraction d'énergie thermique dans des systèmes nucléaires (boucles de refroidissement secondaire).


Entrée caloporteur chaud
          │
          ▼
┌─────────────────────────┐
│   ┌─────────────────┐   │
│   │   MOYEU         │   │◄── Chambre d'accélération
│   │   HYDROPO-      │   │    (forme toroïdale)
│   │   NIQUE         │   │
│   └────────┬────────┘   │
│            │            │
│   ╔════════╧════════╗   │
│   ║   ROTOR DISQUE  ║   │◄── Flux axial horizontal
│   ║   (Aimants →)   ║   │    Aimantation radiale-axiale
│   ╚════════╤════════╝   │
│            │            │
│   ┌────────┴────────┐   │
│   │   STATOR DISQUE │   │
│   │   (Bobinages)   │   │
│   └─────────────────┘   │
│            │            │
└────────────┼────────────┘
             ▼
     Sortie caloporteur froid



#### Spécificités nucléaires

| Paramètre | Spécification | Contrainte nucléaire |
|-----------|---------------|----------------------|
| **Caloporteur** | Eau lourde, sels fondus, ou sodium | Compatibilité matériaux |
| **Température** | 300-550°C | Matériaux haute température (Inconel) |
| **Pression** | 15-160 bar | Enceinte blindée intégrée |
| **Étanchéité** | Double barrierre, joints métalliques | Pas de fuite vers environnement |
| **Maintenance** | Remplacement sans ouverture enceinte | Conception modulaire |

#### Architecture du rotor Markov

┌─────────────────────────────┐
│   Couche 1 : Inconel 718    │◄── Peau chaude (corrosion)
│   ┌─────────────────────┐   │
│   │  Lattice TPMS       │   │◄── Structure interne 
│   │  (Gyroid)           │   │    (refroidissement + rigidité)
│   │                     │   │
│   │  Canaux de          │   │
│   │  caloporteur        │   │
│   └─────────────────────┘   │
│   Couche 2 : NdFeB segmenté │◄── Aimants résistants température
│   Couche 3 : Inconel 718    │◄── Peau froide (aimantation)
└─────────────────────────────┘




#### Génération électrique

- **Flux axial horizontal** : Lignes de champ parallèles à l'axe de rotation, perpendiculaires au flux de fluide
- **Refroidissement rotor** : Circuit secondaire interne dans le lattice (échange thermique direct)
- **Stator** : Isolé thermiquement, refroidi par air ou eau indépendante

#### Applications

- **Réacteurs modulaires SMR** : Conversion directe énergie thermique → électrique
- **Boucles de refroidissement** : Circulateurs autonomes (pas de motorisation externe)
- **Systèmes de sûreté** : Pompe de secours passifs (fonctionnement par convection naturelle)

---

## Méthodologie de conception

### Génération PicoGK pour NDT-LERF

```swift
// ME-1A : Muller (Roulements périphériques)
struct MullerTurbine: NDT_LERF_Protocol {
    let outerDuct: DuctGeometry
    let peripheralBearings: [MagneticBearing] // Position périphérique
    let rotorRing: NdFeBTapeRing              // Bande ductile
    let innerStator: StatorWindings           // Stator central
    
    func generate() -> VoxelGeometry {
        // Rotor = bande NdFeB avec aubes intégrées
        let rotor = rotorRing
            .extrudeProfile(airfoilProfile)
            .applyTwist(angle: 30°)
            .magnetize(direction: .radial)
        
        // Assemblage avec roulements en couronne
        return outerDuct
            .subtract(peripheralBearings.housings)
            .union(rotor)
            .union(innerStator.coils)
    }
}

// ME-1B : Wardell-Nelis (Roulements centraux)
struct WardellNelisTurbine: NDT_LERF_Protocol {
    let centralBearings: HybridBearing      // Paliers centraux
    let bellRotor: BellShapedRotor          // Cloche NdFeB
    let outerStator: AnnularStator          // Stator périphérique
    
    func generate() -> VoxelGeometry {
        // Cloche hyperboloïde avec aubes monolithiques
        let rotor = bellRotor
            .generateHyperboloid(a: 100mm, b: 50mm)
            .integrateBlades(count: 11, height: 80%)
            .magnetize(direction: .axial)
        
        return outerStator.housing
            .union(centralBearings.supports)
            .union(rotor)
    }
}


// ME-2A : Morland (Vertical/Hydro)
struct MorlandTurbine: SHAFT_Protocol {
    let schaubergerCone: LogarithmicSpiral  // Cône d'entrée
    let hydroponicHub: VenturiChamber       // Moyeu accélérateur
    let diskRotor: AxialFluxRotor           // Disque aimanté
    let statorDisk: AxialFluxStator         // Stator face-à-face
    
    func generate() -> VoxelGeometry {
        // Effet de syphon par géométrie Venturi
        let hub = hydroponicHub
            .generateVenturi(inlet: 200mm, throat: 80mm, outlet: 150mm)
            .addSpiralRibs(pitch: 45°)      // Ribs Schauberger
        
        let rotor = diskRotor
            .generateBladedDisk(diameter: 300mm)
            .embedMagnets(polarity: .axial, segments: 16)
            .addHydraulicBlades(profile: .schauberger)
        
        return schaubergerCone
            .union(hub)
            .union(rotor)
            .union(statorDisk.at(offset: 2mm))
    }
}

// ME-2B : Markov (Horizontal/Nuclear)
struct MarkovTurbine: SHAFT_Protocol {
    let toroidalHub: ToroidalChamber        // Chambre toroïdale
    let sandwichRotor: CompositeDisk        // Disque sandwich Inconel/NdFeB
    let safetyCasing: PressureVessel        // Enceinte blindée
    
    func generate() -> VoxelGeometry {
        let rotor = sandwichRotor
            .generateLayer(material: .inconel, thickness: 3mm)      // Peau chaude
            .addLattice(structure: .gyroid, density: 0.4)            // Refroidissement
            .addMagnetLayer(material: .ndfebHT, segments: 24)       // Couche aimant
            .sealLayer(material: .inconel, thickness: 2mm)          // Peau froide
        
        return safetyCasing
            .subtract(toroidalHub.volume)
            .union(toroidalHub)
            .union(rotor.centered)
    }
}


| Composant      | Muller            | Wardell-Nelis      | Morland          | Markov      |
| -------------- | ----------------- | ------------------ | ---------------- | ----------- |
| **Structure**  | Ti-6Al-4V         | Inconel 718        | AlSi10Mg         | Inconel 718 |
| **Aimants**    | NdFeB + liant     | NdFeB segmenté     | Ferrite polymère | NdFeB HT    |
| **Bobinages**  | Cu (enrobage)     | Cu (enrobage)      | Cu pur           | CuCrZr      |
| **Roulements** | SmCo (magnétique) | Hybrides céramique | Ferrite          | Non inclus  |



Contraintes spécifiques

NDT-LERF

Bande ductile : Épaisseur minimale 2mm pour induction optimale
Entrefer : Tolérance ±0.05mm (impact direct sur couple)
Aimantation : Post-traitement sous champ magnétique orienté
SHAFT

Moyeu hydroponique : Surface interne Ra < 3.2µm (réduction cavitation)
Étanchéité disque : Soudage par friction des couches sandwich (Markov)
Résistance corrosion : Passivation des surfaces Inconel (Markov)
Références & Brevets

Inspirations scientifiques

Schauberger, V. (1958). The Water Wizard. Implosion vs Explosion principles.
Reypens, N. (réf. conceptuelle). Axial Flux Machines for Harsh Environments.
Wardell. & Nelis, Æ. (réf. conceptuelle). Integrated Electric Ducted Fans.
Technologies clés

LEAP 71 (2024). PicoGK Geometry Kernel. github.com/leap71/PicoGK
ACME Framework (2026). Swift-based Computational Manufacturing Engine.
Classification brevetaire suggérée

F03D : Éoliennes (adaptable NDT-LERF)
F03B : Machines hydrauliques (SHAFT-Morland)
G21D : Réacteurs nucléaires (SHAFT-Markov)
H02K : Machines dynamiques électriques (toutes architectures)

Document maintenu par l'équipe ACME. Dernière mise à jour : Mars 2026



