---
created: 2025-05-04 05:31:26
author: Cong Le
version: "1.0"
license(s): MIT, CC BY 4.0
copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
---


# A Diagrammatic Guide 
> **Disclaimer:**
>
> This document contains my personal notes on the topic,
> compiled from publicly available documentation and various cited sources.
> The materials are intended for educational purposes, personal study, and reference.
> The content is dual-licensed:
> 1. **MIT License:** Applies to all code implementations (Swift, Mermaid, and other programming languages).
> 2. **Creative Commons Attribution 4.0 International License (CC BY 4.0):** Applies to all non-code content, including text, explanations, diagrams, and illustrations.
---

# Overview

The provided code implements a dynamic, interactive visual effect using a Metal shader integrated into a SwiftUI view.

1.  **`HarmonicShaders.metal`**: Defines the GPU-side logic. It calculates multiple layers of harmonic (sine/cosine-like) waves, applies a glow effect, and colors them based on various parameters including time and an interaction coefficient.
2.  **`ContentView.swift`**: Defines the SwiftUI view that displays the shader effect. It sets up the shader, provides interactive controls (press and hold), manages animation timing, and passes necessary data (like time, amplitude, interaction state) to the shader.

Let's break down the components and interactions visually.

---


# 1. High-Level Architecture: SwiftUI & Metal Integration

This diagram shows the main components and how they connect.

```mermaid
---
title: "High-Level Architecture: SwiftUI & Metal Integration"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': true, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D53',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
graph TD
    subgraph SwiftUI_Layer["SwiftUI Application"]
    direction LR
        CV("ContentView") -- "manages state &<br/> interaction" --> TV("TimelineView")
        TV -- "provides time ticks" --> CV
        CV -- "contains" --> ZS("ZStack")
        ZS -- "layers" --> BG("Background:<br/>Color.clear + Shader")
        ZS -- "layers" --> FG("Foreground:<br/>VStack - Text, Image")
        BG -- "uses" --> RECT("Rectangle Geometry")
        RECT -- "applies effect" --> CE("colorEffect Modifier")
        CE -- "invokes" --> SL("ShaderLibrary.default.harmonicColorEffect")
    end

    subgraph Metal_Layer["Metal Shader Execution<br/>(GPU)"]
    direction LR
        SL -- "loads &<br/> compiles" --> HS("harmonicColorEffect")
        HS -- "uses helpers" --> HF("Helper Functions:<br/>harmonicSDF,
        glow, getColor")
        HS -- "calculates" --> PixelColor("Final Pixel Color")
    end

    CV -- "passes data<br/>(Time, Amplitude, MixCoeff, Bounds, WaveCount)" --> SL
    CE -- "receives geometry &<br/> data" --> HS
    PixelColor -- "returns color" --> CE
    CE -- Renders --> BG

    style SwiftUI_Layer fill:#e799f,stroke:#0050b3,stroke-width:2px
    style Metal_Layer fill:#e122,stroke:#d4b106,stroke-width:2px
    
```


**Explanation:**

*   The **SwiftUI Layer** manages the application's UI, state, and interaction. `ContentView` orchestrates this.
*   `TimelineView` drives the animation by providing regular time updates.
*   A `ZStack` layers a clear background (which hosts the shader via `.colorEffect` on a `Rectangle`) and the non-interactive foreground UI.
*   The `.colorEffect` modifier bridges SwiftUI and Metal, invoking the `harmonicColorEffect` shader function from the `ShaderLibrary`.
*   Crucially, `ContentView` passes dynamic data (elapsed time, interaction state formatted as `mixCoeff`, amplitude, etc.) to the shader on each render pass.
*   The **Metal Layer** executes the `harmonicColorEffect` shader function on the GPU, using helper functions to calculate the final color for each pixel based on the input data.
*   The resulting color is sent back to the `.colorEffect` modifier to be displayed in the background layer.

----

# 2. Metal Shader (`HarmonicShaders.metal`) Breakdown

## 2.1. Shader Function Call Hierarchy

This shows how the main `harmonicColorEffect` relies on helper functions.

```mermaid
---
title: "Shader Function Call Hierarchy"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D5F5E3',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
graph TD
    HCE["harmonicColorEffect"] --> NORM["Step 1:<br/>Coordinate Normalization"]
    HCE --> MOD["Step 2:<br/>Calculate Modulated Parameters<br/>(a, offset)"]
    HCE --> INTERP["Step 3:<br/>Interpolate Parameters<br/>(frequency, glow, color)"]
    INTERP --> MIXF["mix()"]

    HCE --> LOOP["Step 4:<br/>Loop Through Wave Layers"]
    LOOP -- "for each wave" --> PHASE["Calculate Phase"]
    LOOP -- "for each wave" --> CALL_SDF("Call harmonicSDF")
    CALL_SDF --> SDF["harmonicSDF(...)"]
    SDF --> COS["cos()"]

    LOOP -- "for each wave" --> CALL_GLOW("Call glow")
    CALL_GLOW --> GLW["glow(...)"]
    GLW --> POW["pow()"]
    GLW --> ABS["abs()"]

    LOOP -- "for each wave" --> CALL_COLOR("Determine Wave Color")
    CALL_COLOR --> MIXC["mix()"]
    MIXC --> GC["getColor(...)"]
    GC --> ROUND["round()"]
    GC --> INT["int()"]

    LOOP -- "for each wave" --> ACCUM["Accumulate finalColor"]

    HCE --> FINAL["Step 5:<br/>Finalize and Return Color"]
    FINAL --> CLAMP["clamp()"]

    style HCE fill:#F11,stroke:#333,stroke-width:2px
    style SDF fill:#6fb,stroke:#006d75,stroke-width:1px
    style GLW fill:#efb,stroke:#006d75,stroke-width:1px
    style GC fill:#6fb,stroke:#006d75,stroke-width:1px
    style MIXF fill:#ff6,stroke:#c41d7f,stroke-width:1px
    style MIXC fill:#f22,stroke:#c41d7f,stroke-width:1px
    
```

**Explanation:**

*   The main shader (`harmonicColorEffect`) orchestrates the process.
*   It calls standard Metal functions like `mix`, `cos`, `pow`, `abs`, `clamp`, `round`, `int`.
*   It heavily relies on the custom helper functions:
    *   `harmonicSDF`: To calculate the distance to each wave.
    *   `glow`: To determine the brightness based on distance.
    *   `getColor`: To select a color for each wave layer (when interacting).

## 2.2. `harmonicColorEffect` Logic Flow
## TODO: Break down this section into small parts to further explain the math equation using LaTex syntax
This flowchart details the steps inside the main shader function.

```mermaid
---
title: "`harmonicColorEffect` Logic Flow"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'graph': { 'htmlLabels': true, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D5F5E3',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
flowchart TD
    Start["Start harmonicColorEffect"] --> GetInputs("Receive Inputs:<br/> pos, color, bounds, wavesCount, time, amplitude, mixCoeff")
    GetInputs --> NormCoords["Step 1:<br/>Normalize Coordinates <br/> 'uv = (pos / bounds.zw) - 0.5'"]
    NormCoords --> ModParams["Step 2:<br/>Calculate Modulated Params <br/> 'a = cos(uv.x * 3) * amplitude * 0.2' <br/> 'offset = sin(uv.x * 12 + time) * a * 0.1'"]
    ModParams --> InterpParams["Step 3:<br/>Interpolate Params via mixCoeff <br/> 'frequency = mix(3, 12, mixCoeff)' <br/> 'glowWidth = mix(0.6, 0.9, mixCoeff)' <br/> 'glowIntensity = mix(0.02, 0.01, mixCoeff)'"]
    InterpParams --> InitColor["Initialize 'finalColor = float3(0.0)'"]

    InitColor --> LoopStart("Step 4:<br/>Loop 'i' from 0 to 'wavesCount'")
    LoopStart --> CalcPhase["'phase = time + i * PI / wavesCount'"]
    CalcPhase --> CalcSDF["'sdfDist = harmonicSDF(uv, a, offset, frequency, phase)'"]
    CalcSDF --> CalcGlow["'glowDist = glow(sdfDist, glowWidth, glowIntensity)'"]
    CalcGlow --> DetColor["'waveColor = mix(white, getColor(i), mixCoeff)'"]
    DetColor --> AccumColor["'finalColor += waveColor * glowDist'"]
    AccumColor --> LoopEnd("End Loop?")

    LoopEnd -- No --> LoopStart
    LoopEnd -- Yes --> ClampColor["Step 5:<br/>Clamp Final Color <br/> 'finalColor = clamp(finalColor, 0.0, 1.0)'"]
    ClampColor --> ReturnColor["Return 'half4(half3(finalColor), 1.0h)'"]
    ReturnColor --> End["End"]

    style Start fill:#2FF9,stroke:#155724
    style End fill:#f22a,stroke:#721c24
    
```

**Explanation:**

*   The shader takes input parameters from SwiftUI.
*   Coordinates are normalized to a standard [-0.5, 0.5] range centered at (0,0).
*   Base wave amplitude (`a`) and vertical offset (`offset`) are calculated based on the pixel's horizontal position (`uv.x`), creating inherent spatial variation.
*   Key visual parameters (`frequency`, `glowWidth`, `glowIntensity`) are interpolated between two states (e.g., 'released' vs 'pressed') using the `mixCoeff` provided by SwiftUI.
*   The core logic iterates through the specified number of `wavesCount`.
*   Inside the loop:
    *   Each wave gets a unique `phase` based on time and its layer index `i`, making them distinct and animated.
    *   `harmonicSDF` calculates the distance to the wave.
    *   `glow` converts distance into brightness.
    *   The wave's color is determined, interpolating between white and a palette color based on `mixCoeff`.
    *   The glowing color is added to the `finalColor`.
*   Finally, the accumulated color is clamped and returned as a `half4`.

## 2.3. `harmonicSDF` Function Logic

```mermaid
---
title: "`harmonicSDF` Function Logic"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': true, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D5F5E3',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
graph LR
    subgraph harmonic_SDF["harmonicSDF<br/>Input:<br/> uv, a, offset, f, ϕ"]
        A["uv.y"] --> Diff("Difference")
        B["offset"] --> Diff
        C["uv.x"] --> FreqMult("Multiply by f")
        FreqMult --> PhaseAdd("Add ϕ")
        PhaseAdd --> Cosine["cos(...)"]
        Cosine --> AmpMult("Multiply by a")
        AmpMult --> AddToDiff("Add to Difference")
        Diff --> AddToDiff
        AddToDiff --> Absolute["abs(...)"]
    end
    Absolute --> Output["Return Distance"]

    style harmonic_SDF fill:#f2d2,stroke:#b8860b
    
```

**Explanation:** This calculates `abs((uv.y - offset) + cos(uv.x * f + phi) * a)`. It finds the vertical difference between the pixel's y-position (`uv.y`) and the wave's calculated y-position at that x (`offset - cos(...) * a`). The `abs` gives the shortest distance to the wave curve.

## 2.4. `glow` Function Logic

```mermaid
---
title: "`glow` Function Logic"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D5F5E3',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
graph LR
    subgraph glow["glow<br/>Input:<br/> x (distance),<br/> str (strength),<br/> dist (intensity)"]
        A[x] --> Absolute["abs(x)"]
        Absolute --> Power["pow(abs(x), str)"]
        B[dist] --> Division["dist / pow(...)"]
        Power --> Division
    end
    Division --> Output["Return Glow Intensity"]

    style glow fill:#a2d2,stroke:#b8860b
    
```

**Explanation:** This calculates `dist / pow(abs(x), str)`. Intensity decreases inversely with the distance (`x`) raised to the power of `str`. Higher `str` means faster falloff (tighter glow).

## 2.5. `getColor` Function Logic

```mermaid
---
title: "`getColor` Function Logic"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D5F5E3',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
graph LR
    subgraph getColor["getColor<br/>Input:<br/> t (index)"]
        A[t] --> Round["round(t)"]
        Round --> CastToInt["int(...)"]
        CastToInt --> Index("index")
        Index -- == 0 --> Color0("Teal-ish")
        Index -- == 1 --> Color1("Purple-ish")
        Index -- == 2 --> Color2("Red-pink")
        Index -- == 3 --> Color3("Blue")
        Index -- == 4 --> Color4("Cyan")
        Index -- == 5 --> Color5("Brown-ish")
        Index -- else --> ColorDefault("White")

        Color0 --> Output["Return float3 Color"]
        Color1 --> Output
        Color2 --> Output
        Color3 --> Output
        Color4 --> Output
        Color5 --> Output
        ColorDefault --> Output
    end
    
    style getColor fill:#a2d2,stroke:#b8860b
    
```

**Explanation:** This function acts as a simple lookup table, mapping an integer index (derived from the float input `t`) to a specific hardcoded `float3` RGB color. It includes a default white fallback.

---

# 3. SwiftUI (`ContentView.swift`) Breakdown

## 3.1. View Hierarchy

```mermaid
---
title: "SwiftUI View Hierarchy"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D5F5E3',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
graph TD
    Root["ContentView"] --> TLV["TimelineView"]
    TLV --> ZS["ZStack"]

    subgraph ZStack_Layers["ZStack Layers"]
        ZS --> BG["Background Layer:<br/> Color.clear"]
        BG -- "modifier" --> BGMod1["'.ignoresSafeArea()'"]
        BGMod1 -- "modifier" --> BGMod2["'.background { Rectangle() ... }'"]
        BGMod2 -- "modifier" --> BGMod3["'.colorEffect(...)'"]
        BGMod3 -- "modifier" --> BGMod4["'.gesture(DragGesture(...))'"]
        BGMod4 -- "modifier" --> BGMod5["'.onChange(of: context.date)'"]
        BGMod5 -- "modifier" --> BGMod6["'.sensoryFeedback(...)'"]

        ZS --> FG["Foreground Layer:<br/> VStack"]
        FG -- "contains" --> SP["Spacer"]
        FG -- "contains" --> TXT["Text"]
        FG -- "contains" --> IMG["Image"]
        FG -- "modifier" --> FGPadding["'.padding()'"]
        FGPadding -- "modifier" --> FGHitTest["'.allowsHitTesting(false)'"]
    end

    style Root fill:#df22,stroke:#0050b3
    style ZStack_Layers fill:#22Ef,stroke:#69c0ff
    style BG fill:#a16, stroke:#4682b4
    style FG fill:#a12, stroke:#4682b4
    
```

**Explanation:**

*   The core is a `TimelineView` driving updates.
*   A `ZStack` manages layering:
    *   **Background:** An invisible `Color.clear` fills the screen. It has modifiers to:
        *   Ignore safe areas.
        *   Draw the `Rectangle` with the `.colorEffect` shader in its background.
        *   Attach the `DragGesture` for interaction.
        *   Observe time changes (`.onChange`).
        *   Provide haptic feedback (`.sensoryFeedback`).
    *   **Foreground:** A `VStack` containing the visible elements (`Text`, `Image`). Crucially, `.allowsHitTesting(false)` ensures touches pass through to the background gesture recognizer.

## 3.2. State Management and Interaction Flow

This sequence diagram illustrates the press-and-hold interaction.

```mermaid
---
title: "State Management and Interaction Flow"
author: "Cong Le"
version: "0.1"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%{
  init: {
    'sequence': { 'mirrorActors': true, 'showSequenceNumbers': true },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#2BB8',
      'primaryBorderColor': '#7C0000',
      'lineColor': '#F8B229',
      'secondaryColor': '#6122',
      'tertiaryColor': '#fff',
      'fontSize': '15px',
      'textColor': '#F8B229',
      'actorTextColor': '#E2E',
      'fontSize': '25px',
      'stroke':'#033',
      'stroke-width': '0.2px'
    }
  }
}%%
sequenceDiagram
    actor User
	
	box rgb(202, 12, 22, 0.1) The App System
	    participant CV as ContentView <br/> (UI)
	    participant GS as Gesture State
	    participant SS as Shader State <br/>(amplitude, mixCoeff, speedMultiplier)
	    participant TLV as TimelineView
	    participant Shader as harmonicColorEffect
    end

    User->>+CV: Touch Down
    CV->>GS: DragGesture.onChanged <br/> (start)
    Note over GS, SS: if !isInteracting
    GS->>SS: isInteracting = true
    SS->>CV: Trigger .spring animation <br/>(Up)
    Note over SS: amplitude = 2.0, speedMultiplier = 2.0
    CV->>User: Haptic Feedback <br/>(.sensoryFeedback / .impactOccurred)
    CV-->>-User: UI Updates <br/> (Text changes, Shader animates faster/higher)

    loop Animation Loop
	    rect rgb(20, 150, 150,0.1)
	        TLV->>CV: context.date tick<br>(based on speedMultiplier)
	        CV->>SS: elapsedTime += updateInterval * speedMultiplier
	        CV->>Shader: Invoke .colorEffect <br/>(Pass updated elapsedTime, amplitude=2.0, mixCoeff=1.0, etc.)
	        Shader->>CV: Return calculated pixel color
	        CV->>User: Render updated frame
	    end
    end

    User->>+CV: Touch Up
    CV->>GS: DragGesture.onEnded
    Note over GS, SS: if isInteracting
    GS->>SS: isInteracting = false
    SS->>CV: Trigger .spring animation <br/>(Down)
    Note over SS: amplitude = 0.5, speedMultiplier = 1.0
    CV-->>-User: UI Updates <br/>(Text changes, Shader animates slower/lower)

    loop Animation Loop <br/>(Continues)
	    rect rgb(20, 150, 150,0.1)
	        TLV->>CV: context.date tick <br/>(based on speedMultiplier=1.0)
	        CV->>SS: elapsedTime += updateInterval * speedMultiplier
	        CV->>Shader: Invoke .colorEffect <br/>(Pass updated elapsedTime, amplitude=0.5, mixCoeff=0.0, etc.)
	        Shader->>CV: Return calculated pixel color
	        CV->>User: Render updated frame
        end
    end
    
```


**Explanation:**

1.  **Touch Down:** User presses the screen. The `DragGesture`'s `onChanged` fires.
2.  **State Change (Press):** `isInteracting` becomes `true`. A spring animation starts, increasing `amplitude` and `speedMultiplier`. Haptic feedback occurs.
3.  **Animation Loop (Pressed):** `TimelineView` provides ticks more frequently (due to `speedMultiplier=2.0`). `elapsedTime` increases faster. The shader receives `amplitude=2.0` and `mixCoeff=1.0`, resulting in the "active" visual state (higher frequency, different color mix, tighter glow).
4.  **Touch Up:** User releases the screen. The `DragGesture`'s `onEnded` fires.
5.  **State Change (Release):** `isInteracting` becomes `false`. A spring animation starts, decreasing `amplitude` and `speedMultiplier` back to baseline.
6.  **Animation Loop (Released):** `TimelineView` ticks at the normal rate (`speedMultiplier=1.0`). `elapsedTime` increases normally. The shader receives `amplitude=0.5` and `mixCoeff=0.0`, resulting in the "resting" visual state (lower frequency, white waves, wider glow).

## 3.3. Data Flow: SwiftUI State to Shader Parameters

```mermaid
---
title: "Data Flow: SwiftUI State to Shader Parameters"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': false, 'curve': 'linear' },
    'fontFamily': 'Monaco',
    'themeVariables': {
      'primaryColor': '#D5F5E3',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD',
      'fontSize': '15px'
    }
  }
}%%
graph LR
    subgraph SwiftUI_State["SwiftUI State"]
        S1["elapsedTime: Double"]
        S2["amplitude: Float"]
        S3["isInteracting: Bool"]
        S4["speedMultiplier: Double"] --> S1
    end

    subgraph Constants_View_Data["Constants/View Data"]
        C1["wavesCount = 6.0 : Float"]
        C2["bounds: float4"]
    end

    subgraph Shader_Parameters["Shader Parameters:<br/>harmonicColorEffect(...)"]
        P1("time: float")
        P2("amplitude: float")
        P3("mixCoeff: float")
        P4("wavesCount: float")
        P5("bounds: float4")
    end

    S1 --> P1
    S2 --> P2
    S3 -- "? 1.0 : 0.0" --> P3
    C1 --> P4
    C2 --> P5

    style SwiftUI_State fill:#e222,stroke:#0050b3
    style Constants_View_Data fill:#f2dd,stroke:#8c8c8c
    style Shader_Parameters fill:#F22F,stroke:#d4b106
    
```

**Explanation:**

*   SwiftUI state variables (`elapsedTime`, `amplitude`, `isInteracting`) directly influence the parameters passed to the `harmonicColorEffect` shader.
*   `speedMultiplier` indirectly affects the `time` parameter by controlling how fast `elapsedTime` increases.
*   The boolean `isInteracting` is converted to a float `mixCoeff` (0.0 or 1.0) for use in the shader's `mix` functions.
*   The number of waves is passed as a constant float.
*   The view's bounding rectangle (`bounds`) is provided for coordinate normalization within the shader.




----




```mermaid
---
title: "CongLeSolutionX"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%{
  init: {
    'flowchart': { 'htmlLabels': false },
    'fontFamily': 'Brush Script MT',
    'themeVariables': {
      'primaryColor': '#fc82',
      'primaryTextColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#81c784',
      'secondaryTextColor': '#6C3483',
      'lineColor': '#F8B229',
      'fontSize': '20px'
    }
  }
}%%
flowchart LR
    My_Meme@{ img: "https://github.com/CongLeSolutionX/MY_GRAPHIC_ASSETS/blob/Designing_graphic_syntax/MY_MEME_ICONS/Orange-Cloud-Search-Icon-Base-Color-Black-1024x1024.png?raw=true", label: "Ăn uống gì chưa ngừi đẹp?", pos: "b", w: 200, h: 150, constraint: "on" }

    Closing_quote@{ shape: braces, label: "Math and code work together to bring interactive art to life!" }

Closing_quote --- My_Meme

```




---
**Licenses:**

- **MIT License:**  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) - Full text in [LICENSE](LICENSE) file.
- **Creative Commons Attribution 4.0 International:** [![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY) - Legal details in [LICENSE-CC-BY](LICENSE-CC-BY) and at [Creative Commons official site](http://creativecommons.org/licenses/by/4.0/).

---