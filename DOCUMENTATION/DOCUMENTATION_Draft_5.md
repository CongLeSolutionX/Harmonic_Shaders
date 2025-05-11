---
created: 2025-05-07 05:31:26
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




## 1. Overview of the Dynamic Harmonic Shader

This project uses a Metal shader to render a dynamic, layered harmonic wave effect that is integrated into a SwiftUI view. In summary, the application’s responsibilities are:

• **SwiftUI Layer:**  
  - Manages user interaction (press & hold), state, and animation timing.  
  - Provides the geometry and state data to the shader via a custom `.colorEffect` modifier.

• **Metal Shader Layer:**  
  - Implements functions like `harmonicColorEffect`, which combines several helper functions (such as `harmonicSDF`, `glow`, and `getColor`) to compute the final pixel color.
  - Uses mathematical operations (e.g., cosine, absolute value, power functions, interpolation) to calculate the wave curves, glow intensities, and color lookup.

---

## 2. High-Level Architecture: SwiftUI & Metal Integration

The following Mermaid diagram visually explains the overall architecture and data flow between SwiftUI and the underlying Metal shader.

```mermaid
---
title: "High-Level Architecture: SwiftUI & Metal Integration"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: dagre
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
      'primaryColor': '#22BB',
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
%% High-Level Architecture: SwiftUI & Metal Integration
flowchart TD
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
      HS -- "uses helpers" --> HF("Helper Functions:<br/>harmonicSDF, glow, getColor")
      HS -- "calculates" --> PixelColor("Final Pixel Color")
    end

    CV -- "passes data<br/>(Time, Amplitude, MixCoeff,<br/> Bounds, WaveCount)" --> SL
    CE -- "receives geometry &<br/> data" --> HS
    PixelColor -- "returns color" --> CE
    CE -- "renders" --> BG

    style SwiftUI_Layer fill:#e2f,stroke:#0050b3,stroke-width:2px
    style Metal_Layer fill:#ffbe6,stroke:#d4b106,stroke-width:2px
```

### Explanation

1. **SwiftUI Layer:**  
   - The `ContentView` houses a `TimelineView` that drives the animation.
   - A `ZStack` is used to layer the background (which holds the shader via a `Rectangle` with a `.colorEffect` modifier) and a foreground containing UI elements (such as text and images).

2. **Metal Layer:**  
   - The shader function `harmonicColorEffect` is loaded and compiled.
   - Helper functions (like `harmonicSDF`, `glow`, and `getColor`) are used to build up the final pixel color that is then returned for display.

---

## 3. Shader Function Call Hierarchy

This diagram shows how the main shader function calls various helper functions to compute its result.

```mermaid
---
title: "Shader Function Call Hierarchy"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: dagre
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
      'primaryColor': '#22BB',
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
%% Shader Function Call Hierarchy
flowchart TD
    HCE["harmonicColorEffect"] --> NORM["Step 1:<br/>Coordinate Normalization"]
    HCE --> MOD["Step 2:<br/>Modulated Param Calculation<br/>(amplitude, offset)"]
    HCE --> INTERP["Step 3:<br/>Interpolate Parameters<br/>(frequency, glow, color)"]
    INTERP --> MIXF["mix()"]

    HCE --> LOOP["Step 4:<br/>For Each Wave Layer"]
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

    HCE --> FINAL["Step 5:<br/>Clamp and Return Color"]
    FINAL --> CLAMP["clamp()"]

    style HCE fill:#2FF9,stroke:#333,stroke-width:2px
    style SDF fill:#ef22,stroke:#006d75,stroke-width:1px
    style GLW fill:#e6f,stroke:#006d75,stroke-width:1px
    style GC fill:#FF29,stroke:#006d75,stroke-width:1px
    style MIXF fill:#f622,stroke:#c41d7f,stroke-width:1px
    style MIXC fill:#f6B3,stroke:#c41d7f,stroke-width:1px
```

### Explanation

- **Coordinate Normalization:**  
  The pixel coordinates are normalized to center around (0, 0).

- **Modulated Parameter Calculation:**  
  The amplitude and offset are computed based on the x-coordinate and time.

- **Interpolation:**  
  Linear interpolation of parameters (frequency, glow width/intensity) is done with a helper mix function.

- **Loop Through Waves:**  
  For each wave layer (depending on the number of waves), the shader:
  - Calculates a phase using the global time and the layer index.
  - Computes the distance to the wave using the custom `harmonicSDF`.
  - Applies a glow effect using the `glow` function.
  - Determines the wave’s color via the `getColor` lookup.
  - Finally, each layer’s color contribution is accumulated into the final color.

- **Finalization:**  
  All accumulated colors are clamped to ensure valid RGB values and returned as the final output.

---

## 4. Mathematical Equations and Notations

The shader logic relies on several mathematical operations. Here are the key equations with LaTeX explanations:

### 4.1. Harmonic Signed Distance Function (SDF)

The `harmonicSDF` function determines the distance from a given point (uv) to the wave curve:

$$
\text{sdf} = \left| \left( uv_y - \text{offset} \right) + a \times \cos\left( uv_x \times f + \phi \right) \right|
$$

Where:
- $uv_x, uv_y$ are the normalized coordinates.
- $a$ is the modulated amplitude.
- $\text{offset}$ is the vertical displacement.
- $f$ is the frequency of the wave.
- $\phi$ is the phase shift.

This equation provides the absolute (minimum) distance from the current pixel to the computed wave curve.

---

### 4.2. Glow Effect Calculation

The glow effect is computed based on the distance using a power law:

$$
\text{glow} = \frac{ \text{dist} }{ \left| x \right|^{\text{str}} }
$$

Where:
- $x$ is the distance computed (often the SDF value).
- $\text{str}$ is the strength parameter controlling the falloff (a higher $\text{str}$ gives a tighter glow).
- $\text{dist}$ is the base intensity.

This inverse relationship ensures a brighter glow for points near the wave surface.

---

### 4.3. Parameter Interpolation Using mix()

The shader uses linear interpolation to smoothly transition between two visual states (for example, released vs. pressed):

$$
\text{param} = (1 - \alpha) \cdot p_0 + \alpha \cdot p_1
$$

Where:
- $\alpha$ is the mix coefficient (0.0 when not interacting and 1.0 when interacting).
- $p_0$ and $p_1$ are the two end values (e.g., frequencies 3.0 and 12.0).

This is implemented using Metal’s built-in function `mix()`.

---

## 5. SwiftUI & Interaction Flow

The SwiftUI view uses a `TimelineView` for updating the shader parameters dynamically. The following sequence diagram describes the interaction flow when a user presses and releases the screen.

```mermaid
---
title: "SwiftUI & Interaction Flow"
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
%% State Management and Interaction Flow
sequenceDiagram
    actor User
	
	box rgb(202,12,22,0.1) The App System
	    participant CV as ContentView<br/>(UI)
	    participant GS as Gesture State
	    participant SS as Shader State<br/>(amplitude, mixCoeff, speedMultiplier)
	    participant TLV as TimelineView
	    participant Shader as harmonicColorEffect
    end

    User->>+CV: Touch Down
    CV->>GS: DragGesture.onChanged<br/>(start)
    
    Note over GS, SS: if !isInteracting
    
    GS->>SS: isInteracting = true
    SS->>CV: Trigger spring animation<br/>(amplitude ↑, speedMultiplier ↑)
    Note over SS: amplitude = 2.0,<br/>speedMultiplier = 2.0
    
    CV->>User: Haptic Feedback<br/>(impactOccurred)
    CV-->>-User: UI Updates<br/>(Text changes, faster shader)

    loop Animation Loop<br/>(Pressed)
	    rect rgb(200, 15, 255, 0.1)
		    TLV->>CV: Tick<br/>(increased speed)
		    CV->>SS: elapsedTime += updateInterval × speedMultiplier
		    CV->>Shader: Invoke .colorEffect<br/>(Pass updated parameters)
		    Shader->>CV: Return computed pixel color
		    CV->>User: Render updated frame
	    end
    end

    User->>+CV: Touch Up
    CV->>GS: DragGesture.onEnded
    Note over GS, SS: if isInteracting
    GS->>SS: isInteracting = false
    SS->>CV: Trigger spring animation<br/>(amplitude and speed reduced)
    
    Note over SS: amplitude = 0.5,<br/>speedMultiplier = 1.0
    
    CV-->>-User: UI Updates<br/>(Text changes, shader slows)

    loop Animation Loop<br/>(Released)
	    rect rgb(200, 15, 255, 0.1)
		    TLV->>CV: Tick<br/>(normal speed)
		    CV->>SS: elapsedTime += updateInterval × speedMultiplier
		    CV->>Shader: Invoke .colorEffect<br/>(Pass updated parameters)
		    Shader->>CV: Return computed pixel color
		    CV->>User: Render updated frame
	    end
    end
    
```


### Explanation

- **Press Down:** The user’s touch begins the gesture. The state changes cause amplitude and speed to increase.
- **Animation Loop (While Pressed):** Time is updated faster, and parameters (such as mix coefficient) are set so that the shader produces an “active” state.
- **Release:** On touch end, the state reverts to the resting values.
- **Continuous Updates:** The shader is invoked repeatedly via the `TimelineView` ticks with updated parameters.

---

## 6. SwiftUI View Hierarchy and Data Flow

Two additional Mermaid diagrams illustrate how the view is structured and how state parameters are passed from SwiftUI to the shader.

### 6.1. SwiftUI View Hierarchy

```mermaid
---
title: "SwiftUI View Hierarchy"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: dagre
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
      'primaryColor': '#22BB',
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
%% SwiftUI View Hierarchy
flowchart TD
    Root["ContentView"] --> TLV["TimelineView"]
    TLV --> ZS["ZStack"]

    subgraph ZStack_Layers["ZStack Layers"]
        ZS --> BG["Background Layer:<br/>Color.clear"]
        BG -- "modifier" --> BGMod1[".ignoresSafeArea()"]
        BGMod1 -- "modifier" --> BGMod2[".background { Rectangle() ... }"]
        BGMod2 -- "modifier" --> BGMod3[".colorEffect(...)"]
        BGMod3 -- "modifier" --> BGMod4[".gesture(DragGesture(...))"]
        BGMod4 -- "modifier" --> BGMod5[".onChange(of: context.date)"]
        BGMod5 -- "modifier" --> BGMod6[".sensoryFeedback(...)"]

        ZS --> FG["Foreground Layer:<br/>VStack"]
        FG -- "contains" --> SP["Spacer"]
        FG -- "contains" --> TXT["Text"]
        FG -- "contains" --> IMG["Image"]
        FG -- "modifier" --> FGPadding[".padding()"]
        FGPadding -- "modifier" --> FGHitTest[".allowsHitTesting(false)"]
    end

    style Root fill:#dff,stroke:#0050b3
    style ZStack_Layers fill:#22BB,stroke:#69c0ff
    style BG fill:#a2e6,stroke:#4682b4
    style FG fill:#a16,stroke:#4682b4
    
```

### 6.2. Data Flow: State to Shader Parameters

```mermaid
---
title: "Data Flow: State to Shader Parameters"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: dagre
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
      'primaryColor': '#22BB',
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
%% Data Flow: SwiftUI State to Shader Parameters
flowchart LR
    subgraph SwiftUI_State["SwiftUI State"]
        S1["elapsedTime: Double"]
        S2["amplitude: Float"]
        S3["isInteracting: Bool"]
        S4["speedMultiplier: Double"] --> S1
    end

    subgraph Constants_View_Data["Constants / View Data"]
        C1["wavesCount = 6.0 : Float"]
        C2["bounds: float4"]
    end

    subgraph Shader_Parameters["Shader Parameters"]
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

    style SwiftUI_State fill:#e6f7ff,stroke:#0050b3
    style Constants_View_Data fill:#fafafa,stroke:#8c8c8c
    style Shader_Parameters fill:#fffbe6,stroke:#d4b106
```

### Explanation

- **SwiftUI State Variables:**  
  - `elapsedTime`, `amplitude`, and `isInteracting` drive the shader parameters.
  - The boolean `isInteracting` converts to a float value (mix coefficient) for interpolation.

- **Constants:**  
  - Fixed values like the number of waves (`wavesCount`) and geometry bounds are also passed.

- **Shader Parameters:**  
  - These values are mapped directly and passed to the `harmonicColorEffect` call by SwiftUI.

---

## 7. Concluding Remarks

This document has presented:

• A **visual hierarchy** of the SwiftUI and Metal layers using Mermaid diagrams.  
• Detailed **flowcharts** that illustrate the shader function call sequence and logic flow.  
• **LaTeX-rendered equations** explaining the mathematical foundations:
  - The **harmonicSDF** equation,
  - The **glow** intensity calculation, and
  - Linear interpolation via the **mix** function.

All together, these diagrams and equations convey the concepts and internal complexities of the dynamic harmonic visual effect implemented through SwiftUI and Metal.

---


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
>**Licenses:**
>
>- **MIT License:**  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) - Full text in [LICENSE](LICENSE) file.
>- **Creative Commons Attribution 4.0 International:** [![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY) - Legal details in [LICENSE-CC-BY](LICENSE-CC-BY) and at [Creative Commons official site](http://creativecommons.org/licenses/by/4.0/).

---