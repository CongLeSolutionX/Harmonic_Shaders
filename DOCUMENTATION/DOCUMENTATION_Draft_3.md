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


# Visual and Mathematical Explanation of the Harmonic Shader Architecture and Implementation

This document provides a detailed understanding of a dynamic harmonic wave effect implemented using Metal shaders integrated into SwiftUI. Below are the explanations through Mermaid diagrams and LaTeX-rendered math expressions highlighting the mechanism, data flow, and mathematical formulations involved.

---

## 1. High-Level Architecture: SwiftUI & Metal Integration

```mermaid
---
title: "System Integration Overview"
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
      'primaryColor': '#F5E3',
      'primaryTextColor': '#145A32',
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
    subgraph SwiftUI_Layer["SwiftUI Application"]
    direction LR
        CV("ContentView") --> TV("TimelineView")
        TV --> CV
        CV --> ZS("ZStack")
        ZS --> BG("Background: Color.clear + Shader Layer")
        ZS --> FG("Foreground: UI Content (Text, Image)")
        BG --> RECT("Rectangle Geometry")
        RECT --> CE("colorEffect Modifier")
        CE --> SL("ShaderLibrary.default.harmonicColorEffect")
    end

    subgraph Metal_Layer["Metal Shader (GPU)"]
    direction LR
        SL --> HS("harmonicColorEffect Shader Function")
        HS --> HF("Helper Functions (harmonicSDF, glow, getColor)")
        HS --> PixelColor("Final Pixel Color Computation")
    end

    CV --> SL
    CE --> HS
    PixelColor --> CE
    CE --> BG

    style SwiftUI_Layer fill:#e6f7ff,stroke:#0050b3,stroke-width:2px
    style Metal_Layer fill:#fffbe6,stroke:#d4b106,stroke-width:2px
```

**Explanation:**

* The **SwiftUI Layer** handles the UI, interaction, and animation timing.
* `TimelineView` provides time ticks, enabling continuous animation.
* A `ZStack` arranges layers: a transparent background hosting the shader and a foreground UI.
* `colorEffect` modifier bridges SwiftUI and the Metal shader function `harmonicColorEffect`.
* The **Metal Layer** executes on GPU, computing pixel colors using harmonic wave functions and glow effects.

---

## 2. Shader Function Call Hierarchy & Logic Flow

### 2.1. Function Call Hierarchy

```mermaid
---
title: "System Integration Overview"
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
flowchart TD
    HCE["harmonicColorEffect"] --> NORM["Normalize Coordinates (uv)"]
    HCE --> MOD["Calculate Modulated Parameters (a, offset)"]
    HCE --> INTERP["Interpolate visual params (frequency, glowWidth, glowIntensity)"]
    INTERP --> MIXF["mix() function for interpolation"]
    HCE --> LOOP["Loop through wave layers (i = 0 to wavesCount)"]
    LOOP --> PHASE["Calculate phase = time + i * π / wavesCount"]
    LOOP --> CALL_SDF["harmonicSDF(uv, a, offset, frequency, phase)"]
    CALL_SDF --> COS["cos()"]
    LOOP --> CALL_GLOW["glow(sdfDist, glowWidth, glowIntensity)"]
    CALL_GLOW --> POW["pow()"]
    CALL_GLOW --> ABS["abs()"]
    LOOP --> CALL_COLOR["Determine waveColor via getColor(i) and mix()"]
    CALL_COLOR --> ROUND["round()"]
    CALL_COLOR --> INT["int()"]
    LOOP --> ACCUM["Accumulate finalColor += waveColor * glowDist"]
    HCE --> FINAL["Clamp and return finalColor"]
    FINAL --> CLAMP["clamp()"]
```

### 2.2. Core Logic Flowchart of `harmonicColorEffect`

```mermaid
---
title: "Core Logic Flowchart of `harmonicColorEffect`"
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
      'primaryColor': '#22BB',
      'primaryTextColor': '#F8B229',
      'lineColor': '#F8B229',
      'primaryBorderColor': '#27AE60',
      'secondaryColor': '#EBDEF0',
      'secondaryTextColor': '#6C3483',
      'secondaryBorderColor': '#A569BD'
    }
  }
}%%
flowchart TD
    Start["Start harmonicColorEffect"] --> GetInputs["Receive inputs:<br/> pos, color, bounds, wavesCount, time, amplitude, mixCoeff"]
    GetInputs --> NormalizeCoords["Normalize coordinates:<br/>$$uv = \\frac{pos}{(width, height)} - (0.5, 0.5)$$"]
    NormalizeCoords --> ComputeParams["Compute:<br/>$$a = \\cos(3\\cdot uv_x) \\times amplitude \\times 0.2$$<br/>$$offset = \\sin(12\\cdot uv_x + time) \\times a \\times 0.1$$"]
    ComputeParams --> InterpolateParams["Interpolate via mixCoeff:<br/>$$frequency = mix(3,12,mixCoeff)$$<br/>$$glowWidth = mix(0.6,0.9,mixCoeff)$$<br/>$$ glowIntensity = mix(0.02,0.01,mixCoeff)$$"]
    InterpolateParams --> InitColor["Initialize finalColor = float3(0.0)"]
    InitColor --> LoopStart["For i in [0, wavesCount):"]
    LoopStart --> PhaseCalc["Calculate phase:<br/>$$phase = time + i \\times \\frac{\\pi}{wavesCount}$$"]
    PhaseCalc --> CalcSDF["Calculate sdfDist via harmonicSDF(uv, a, offset, frequency, phase)"]
    CalcSDF --> CalcGlow["Calculate glowDist = glow(sdfDist, glowWidth, glowIntensity)"]
    CalcGlow --> WaveColor["Determine waveColor:<br/>$$waveColor = mix(\\mathbf{1}, getColor(i), mixCoeff)$$"]
    WaveColor --> Accumulate["Accumulate:<br/>$$finalColor += waveColor \\times glowDist$$"]
    Accumulate --> LoopEnd["End loop when i == wavesCount"]
    LoopEnd --> ClampFinal["Clamp finalColor:<br/>$$finalColor = clamp(finalColor, 0, 1)$$"]
    ClampFinal --> ReturnColor["Return color:<br/>$$\\text{half4}(finalColor, 1.0)$$"]
    ReturnColor --> End["End"]

```

---

## 3. Mathematical Descriptions of Core Shading Functions

### 3.1 Harmonic Signed Distance Function (`harmonicSDF`)

Calculates the unsigned distance from a pixel coordinate to the position on the harmonic wave.

$$
\begin{aligned}
\text{harmonicSDF}(\mathbf{uv}, a, \text{offset}, f, \phi) &= \left| y - \text{offset} + a \cos(f x + \phi) \right| \\
&= \left| (uv_y - \text{offset}) + a \cos(f \, uv_x + \phi) \right|
\end{aligned}
$$

where
- $\mathbf{uv} = (uv_x, uv_y)$ are normalized coordinates centered at (0,0),
- $a$ is modulated amplitude,
- $\text{offset}$ is vertical offset,
- $f$ is spatial frequency,
- $\phi$ is phase shift.

### 3.2 Glow Intensity Function (`glow`)

Computes glowing intensity inversely proportional to distance raised to a strength exponent.

$$
\text{glow}(x, str, dist) = \frac{dist}{|x|^{str}}
$$

where
- $x$ is distance (from `harmonicSDF`),
- $str$ controls falloff steepness,
- $dist$ is base intensity scaling.

### 3.3 Color Lookup Function (`getColor`)

Maps an integer index $t$ to a fixed RGB color vector $\mathbf{c}\in\mathbb{R}^3$, i.e.,

$$
\text{getColor}(t) = \mathbf{c}_t = 
\begin{cases}
(0.482, 0.831, 0.855), & t = 0 \quad (\text{Teal-ish}) \\
(0.412, 0.412, 0.847), & t = 1 \quad (\text{Purple-ish}) \\
(0.941, 0.314, 0.412), & t = 2 \quad (\text{Red-pink}) \\
(0.275, 0.490, 0.941), & t = 3 \quad (\text{Blue}) \\
(0.078, 0.863, 0.863), & t = 4 \quad (\text{Cyan}) \\
(0.784, 0.627, 0.549), & t = 5 \quad (\text{Brown-ish}) \\
(1.0, 1.0, 1.0), & \text{otherwise (default white)}
\end{cases}
$$

---

## 4. SwiftUI View Layer Hierarchy

```mermaid
---
title: "System Integration Overview"
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
flowchart TD
    CV["ContentView"]
    TLV["TimelineView"]
    ZS["ZStack"]

    CV --> TLV
    TLV --> ZS

    subgraph ZStack_Layers["ZStack Layers"]
        ZS --> BG["Background Layer:<br/>Color.clear"]
        BG --> BG_mod1[".ignoresSafeArea()"]
        BG_mod1 --> BG_mod2[".background(Rectangle + colorEffect(shader))"]
        BG_mod2 --> BG_mod3[".gesture(DragGesture)"]
        BG_mod3 --> BG_mod4[".onChange(of: context.date)"]
        BG_mod4 --> BG_mod5[".sensoryFeedback()"]

        ZS --> FG["Foreground Layer:<br/>VStack -> Text + Image"]
        FG --> Spacer
        FG --> Text_El["Text:<br/> 'Hold Anywhere!' / 'Holding...'"]
        FG --> Image_El["Image ('My-meme-orange-microphone')"]
        FG --> FG_mod[".padding()"]
        FG_mod --> FG_hitTest[".allowsHitTesting(false)"]
    end
    
```

**Explanation:**

* Background hosts the shader and gesture handlers.
* Foreground displays UI text and image with hit testing disabled to pass touches through to background.

---

## 5. State Management and Interaction Sequence

```mermaid
---
title: "State Management and Interaction Sequence"
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
    
    participant CV as ContentView
    participant GS as Gesture State
    participant SS as Shader State
    participant TLV as TimelineView
    participant Shader as harmonicColorEffect

    User->>+CV: Touch Down
    CV->>GS: DragGesture.onChanged<br/>(start)
    GS->>SS: isInteracting = true
    SS->>CV: Animate amplitude=2.0, speedMultiplier=2.0
    CV->>User: Haptic Feedback

    loop Animation Loop<br/>(Pressed)
	    rect rgb(200, 15, 255, 0.1)
	        TLV->>CV: context.date tick<br/>(fast)
	        CV->>SS: elapsedTime += updateInterval * speedMultiplier
	        CV->>Shader: Draw frame with new params
	        Shader->>CV: Return pixel colors
	        CV->>User: Render frame
	    end
    end

    User->>+CV: Touch Up
    CV->>GS: DragGesture.onEnded
    GS->>SS: isInteracting = false
    SS->>CV: Animate amplitude=0.5, speedMultiplier=1.0

    loop Animation Loop<br/>(Released)
	    rect rgb(200, 15, 255, 0.1)
	        TLV->>CV: context.date tick<br/>(normal)
	        CV->>SS: elapsedTime += updateInterval * speedMultiplier
	        CV->>Shader: Draw frame with new params
	        Shader->>CV: Return pixel colors
	        CV->>User: Render frame
	    end
    end
```

---

## 6. Data Flow: From SwiftUI State to Shader Parameters

```mermaid
---
title: "System Integration Overview"
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
flowchart TD
    subgraph SwiftUI_State["SwiftUI State"]
        ET["elapsedTime: Double"]
        AMP["amplitude: Float"]
        INT["isInteracting: Bool"]
        SM["speedMultiplier: Double"]
    end

    subgraph Constants["Constants"]
        WC["wavesCount: Float (6.0)"]
        BND["bounds: float4"]
    end

    subgraph Shader_Params["Parameters to harmonicColorEffect"]
        TIME["time: float"]
        AMPL["amplitude: float"]
        MIXC["mixCoeff: float (0.0 or 1.0)"]
        WAVES["wavesCount: float"]
        BOUNDS["bounds: float4"]
    end

    ET --> TIME
    AMP --> AMPL
    INT -->|?1.0 : 0.0| MIXC
    WC --> WAVES
    BND --> BOUNDS

    SM --> ET
```

**Explanation:**

* SwiftUI state variables control the animation timing and effect strength.
* `isInteracting` boolean converts to a float coefficient driving interpolation in the shader.

---

# Summary of Key Mathematical Equations

| Concept                   | Equation                                                                                                       | Explanation                                 |     |     |
| ------------------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | --- | --- |
| Coordinate Normalization  | $\displaystyle uv = \frac{pos}{(W, H)} - (0.5, 0.5)$                                                           | Transforms pixel pos to [-0.5, 0.5] range   |     |     |
| Harmonic SDF              | \displaystyle d = \left(uv_y - offset) + a \cos(f uv_x + \phi) \right\)                                        | Distance to harmonic wave curve             |     |     |
| Glow Intensity            | $\displaystyle I = \frac{dist}{x^{str}}$                                                                       | Intensity falls with powered distance       |     |     |
| Color Interpolation (mix) | $\displaystyle C_{wave} = (1 - mixCoeff) \times \mathbf{1} + mixCoeff \times getColor(i)$                      | Interpolates from white to palette color    |     |     |
| Phase for Wave $i$        | $\displaystyle \phi_i = time + i \times \frac{\pi}{wavesCount}$                                                | Phase shift for animation per wave          |     |     |
| Final Color Accumulation  | $\displaystyle C_{final} = \mathrm{clamp}\left(\sum_{i=0}^{wavesCount - 1} C_{wave_i} \times I_i, 0, 1\right)$ | Sum color contributions with glow and clamp |     |     |

---

# Visual Summary

```mermaid
---
title: "System Integration Overview"
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
flowchart TD
    UV["Normalized UV coords:<br/> \(uv = \frac{pos}{bounds} - 0.5\)"] --> AmpCalc["Amplitude:<br/> \(a = \cos(3 uv_x) \times amplitude \times 0.2\)"]
    UV --> OffsetCalc["Offset:<br/> \(offset = \sin(12 uv_x + time) \times a \times 0.1\)"]
    AmpCalc --> WaveCalc["For each wave i:"]
    OffsetCalc --> WaveCalc
    WaveCalc --> PhaseCalc["Phase:<br/>\(\phi_i = time + i \frac{\pi}{wavesCount}\)"]
    PhaseCalc --> SDCalc["SDF Distance:<br/>\(d = |uv_y - offset + a \cos(f uv_x + \phi_i)| \)"]
    SDCalc --> GlowCalc["Glow Intensity:<br/>\(I = \frac{dist}{|d|^{str}}\)"]
    GlowCalc --> ColCalc["Color:<br/>\(C_{wave} = mix(\mathbf{1}, getColor(i), mixCoeff)\)"]
    ColCalc --> AccumColor["Accumulate \(C_{final} += C_{wave} \times I\)"]
    AccumColor --> ClampCol["Clamp \(C_{final} \in [0,1]\)"]
    
```


---

# Conclusion

This visual and mathematical overview reveals how:

- SwiftUI coordinates UI and input states with GPU-accelerated Metal shaders.
- The shader implements a layered harmonic wave effect based on sine and cosine functions with dynamic amplitude, phase, offset and glow effects.
- Interaction modulates wave parameters smoothly impacting frequency, glow sharpness, amplitude, and colors.
- Efficient GPU computation enables real-time visual responsiveness to touch input.


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