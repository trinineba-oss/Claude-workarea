# Architecture & Technical Design Specification: 2D Emergent Physics & Chemistry Engine (Android Target)

## 1. System Architecture Overview

To achieve the emergent gameplay of *The Legend of Zelda: Breath of the Wild* (BotW) within a 2D environment optimized for mobile devices, the engine architecture relies on a decoupled, data-oriented design. The core objective is allowing system rules (physics, elemental reactions, thermal dynamics) to interact automatically without hardcoding specific item-to-item behavior.

```
+-------------------------------------------------------------------+
|                        Game Loop / Core                           |
+-------------------------------------------------------------------+
       |                            |                           |
       v                            v                           v
+--------------+           +------------------+        +-----------------+
| World Manager|           | Engine Core      |        | State Manager   |
| (Chunks/Save)|           | Systems          |        | (Save/Load/Sync)|
+--------------+           +------------------+        +-----------------+
       |                            |                           |
       |                   +--------+--------+                  |
       v                   v                 v                  v
+--------------+    +--------------+  +---------------+  +---------------+
| Tilemap Layer|    | Physics &    |  | Elemental     |  | Entity        |
| (Spatial Grid|    | Kinematics   |  | Chemistry     |  | Component System|
|  & Z-Height) |    | Engine       |  | Matrix System |  | (ECS)         |
+--------------+    +--------------+  +---------------+  +---------------+
```

### 1.1 Core Engine Selection (Godot vs. Unity for Android)

*   **Recommended Engine: Godot 4.x (C# or C++)**
    *   *Rationale:* Godot’s lightweight runtime footprint ($\sim 30\text{ MB}$ base apk size) yields superior performance on low-to-mid tier Android devices. Its native 2D engine does not rely on flattened 3D primitives like Unity, resulting in lower draw calls and sub-millisecond frame updates for dynamic 2D lighting and tilemaps.
*   **Alternative: Unity (C#)**
    *   *Rationale:* Better asset store ecosystem and mature multi-threading job system (`C# Job System` + `Burst Compiler`) if heavy CPU parallelism is needed for thousands of simultaneous particle chemistry reactions.

---

## 2. The Chemistry Engine Matrix

The Chemistry Engine handles non-physics interactions between materials and elements. Rather than hardcoding interactions (e.g., `if (arrow == fire && target == grass)`), objects possess **Element State Flags** and **Material Properties**.

### 2.1 Primary Elements & Materials

| Element/Material | Conductive | Flammable | Freeze-able | Density ($\mathrm{kg/m^3}$) | Thermal Capacity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Wood** | False | True | False | 600 | Low |
| **Metal** | True | False | False | 7800 | High |
| **Water** | True (if wet) | False | True | 1000 | Very High |
| **Ice** | False | False | True (Melts) | 917 | Moderate |
| **Grass/Foliage**| False | True (Fast) | False | 300 | Very Low |
| **Stone/Earth** | False | False | False | 2400 | High |

### 2.2 Elemental Reaction Matrix Logic

Every interactive entity and tile cell maintains an `ElementalStateVector`:

$$\vec{E} = \begin{bmatrix} T \\ H \\ C \\ L \end{bmatrix} = \begin{bmatrix} \text{Temperature (Kelvin)} \\ \text{Humidity/Wetness } [0, 1] \\ \text{Charge (Volts)} \\ \text{Lift/Updraft Force} \end{bmatrix}$$

```csharp
public struct ChemistryProperties {
    public float temperature; // Base room temp = 293.15K (20C)
    public float wetness;     // 0.0f to 1.0f
    public float charge;      // Voltage accumulated
    public MaterialType material;
}

public static class ChemistryMatrix {
    public static void EvaluateCellInteraction(ref ChemistryProperties source, ref ChemistryProperties target, float deltaTime) {
        // Thermal Transfer: Q = k * (T2 - T1)
        float tempDelta = (source.temperature - target.temperature) * deltaTime;
        target.temperature += tempDelta * 0.1f;

        // Combustion Check
        if (target.material.isFlammable && target.temperature > target.material.ignitionPoint) {
            TriggerCombustion(target);
        }

        // Conductive Electrical Spread
        if (source.charge > 10.0f && target.material.isConductive) {
            target.charge = source.charge * 0.85f; // Dissipate across nodes
            ApplyElectricShockDamage(target);
        }

        // Phase Transition: Ice to Water
        if (target.material == MaterialType.Ice && target.temperature > 273.15f) {
            MeltToWaterTile(target);
        }
        
        // Updraft Generation: Intense Heat + Air
        if (source.temperature > 373.15f) {
            GenerateUpdraftVector(source.position, source.temperature);
        }
    }
}
```

---

## 3. 2D Physics & Ability Mechanics

### 3.1 Pseudo-Z Height Elevation System

In a 2D top-down game, height must be simulated to allow climbing, falling, jumping, and paragliding.

*   **Coordinate Space:** Position is tracked as $(X, Y, Z)$ where $X$ and $Y$ are world-plane coordinates and $Z$ represents elevation layer ($Z \in [0, 255]$).
*   **Collision Layer Masking:** Entities only collide with objects matching their current $Z$-index range.

```csharp
public class ZElevationHandler : MonoBehaviour {
    public int currentZLayer = 1;
    public float zSubHeight = 0.0f; // Fine elevation within layer
    public float verticalVelocity = 0.0f;
    public bool isGliding = false;

    public void UpdateElevation(float deltaTime) {
        if (verticalVelocity != 0 || isGliding) {
            float gravity = isGliding ? -1.5f : -9.81f; // Terminal velocity reduction on glide
            verticalVelocity += gravity * deltaTime;
            zSubHeight += verticalVelocity * deltaTime;

            if (zSubHeight <= 0.0f) {
                if (CanLandOnTile(currentZLayer - 1)) {
                    currentZLayer--;
                    zSubHeight = 1.0f;
                    verticalVelocity = 0.0f;
                } else if (currentZLayer == 0) {
                    // Impact Ground / Fall Damage
                    ResolveGroundImpact(verticalVelocity);
                    verticalVelocity = 0.0f;
                }
            }
        }
    }
}
```

### 3.2 Ability Mechanics Architecture

#### A. Magnesis (Magnetic Kinematic Vector Tether)
*   **Targeting Filter:** Query physics engine for overlapping colliders with `Material == Metal`.
*   **Control Implementation:** A spring-damper kinematic force is applied between player cursor position $\vec{P}_{\text{cursor}}$ and object center $\vec{P}_{\text{obj}}$.

$$\vec{F}_{\text{magnesis}} = -k_{p} (\vec{P}_{\text{obj}} - \vec{P}_{\text{cursor}}) - k_{d} \vec{V}_{\text{obj}}$$

#### B. Stasis (Kinetic Vector Accumulator)
*   **Execution:**
    1. Freeze object's dynamic body position & rotation updates.
    2. Intercept incoming collision impulses $\vec{J}_i$ and store in an array `List<Vector2> storedImpulses`.
    3. Draw visual vector arrows scaled by $\sum |\vec{J}_i|$.
    4. Upon timer expiry, unfreeze body and apply total resultant impulse instantaneously:

$$\vec{J}_{\text{total}} = \sum_{i=1}^{n} \vec{J}_i$$

```csharp
public class StasisTarget : MonoBehaviour {
    private bool isFrozen = false;
    private Vector2 accumulatedImpulse = Vector2.zero;
    private Rigidbody2D rb;

    public void ApplyStasisHit(Vector2 force, Vector2 hitPoint) {
        if (!isFrozen) return;
        accumulatedImpulse += force;
        Visualizer2D.DrawDirectionalArrow(hitPoint, accumulatedImpulse);
    }

    public IEnumerator ReleaseStasis(float duration) {
        yield return new WaitForSeconds(duration);
        isFrozen = false;
        rb.bodyType = RigidbodyType2D.Dynamic;
        rb.AddForce(accumulatedImpulse, ForceMode2D.Impulse);
        accumulatedImpulse = Vector2.zero;
    }
}
```

#### C. Cryonis (Water Surface Instantiation)
*   Raycast or tap-select a tile marked `Material == Water`.
*   Replace standard water tile with a rigid `IcePillar` entity on layer $Z + 1$.
*   If an entity is situated over the targeted water cell during instantiation, raise its $Z$-elevation parameter instantly.

---

## 4. World Streaming & Optimization for Android

To maintain $60\text{ FPS}$ on ARM mobile chips (e.g., Snapdragon 600/700 series), memory allocations must be strictly controlled to prevent Garbage Collection (GC) spikes.

### 4.1 Spatial Chunking & Dynamic Loading

*   World is divided into chunks of $32 \times 32$ tiles.
*   Only a $3 \times 3$ grid of chunks surrounding the player is held active in memory.
*   **Chunk Lifecycle:**
    1. `Far (Dormant)`: Serialized to disk/cache as binary byte streams (`.dat`).
    2. `Medium (Preload)`: Asset textures loaded into GPU memory, physics disabled.
    3. `Active (Simulated)`: Physics body active, AI behavior trees executing, chemistry matrix updates running.

```
+---------------+---------------+---------------+
|  Chunk (0,2)  |  Chunk (1,2)  |  Chunk (2,2)  |
|   (Preload)   |   (Preload)   |   (Preload)   |
+---------------+---------------+---------------+
|  Chunk (0,1)  |  PLAYER HERE  |  Chunk (2,1)  |
|   (Preload)   | (Active 3x3)  |   (Preload)   |
+---------------+---------------+---------------+
|  Chunk (0,0)  |  Chunk (1,0)  |  Chunk (2,0)  |
|   (Preload)   |   (Preload)   |   (Preload)   |
+---------------+---------------+---------------+
```

### 4.2 State Serialization Protocol (Delta Encoding)

Instead of saving the entire world tilemap state, store only **modified entity deltas**:

```csharp
[System.Serializable]
public struct DynamicObjectState {
    public int entityID;
    public Vector3Position position; // (x, y, z)
    public ushort health;
    public byte materialFlags; // Flammable, Wet, Destroyed
}

[System.Serializable]
public class ChunkDeltaData {
    public int chunkX;
    public int chunkY;
    public List<DynamicObjectState> modifiedEntities;
    public List<int> destroyedTileIndices; 
}
```

---

## 5. Mobile Control Scheme & User Interface

### 5.1 Touch Controls & Haptics Layout

*   **Left Hand Zone:** Floating Virtual Analog Stick (Movement and Directional Aiming).
*   **Right Hand Zone:** Context-Sensitive Action Buttons (Attack/Interact, Jump/Glide, Rune Ability Trigger, Aim Bow).
*   **Center/Top Zone:** Quick-swap wheel overlay for Runes (Magnesis, Stasis, Cryonis, Bombs) and Weapons.

```
+-------------------------------------------------------------------+
| [HP: |||||||| ]  [Stamina: (O)]                [Rune: Magnesis]   |
|                                                                   |
|                                                                   |
|       (STICK)                                    (RUNE)  (BOW)    |
|       /     \                                                     |
|      |  +  |                                   (JUMP)  (ATTACK)  |
|       \     /                                                     |
+-------------------------------------------------------------------+
```

### 5.2 Dynamic Input Abstraction

To ensure compatibility with Android controllers (e.g., Razer Kishi, Xbox Wireless Controller), pipe all input through a unified input mapping interface:

```csharp
public interface IInputProvider {
    Vector2 GetMovementVector();
    Vector2 GetAimingVector();
    bool IsActionPressed(InputAction action);
}

public class TouchInputProvider : IInputProvider { /* Canvas Touch Handlers */ }
public class GamepadInputProvider : IInputProvider { /* Android KeyCode Handlers */ }
```

---

## 6. Implementation Roadmap for Development

1.  **Phase 1: Core Physics & Chemistry Engine (Weeks 1–4)**
    *   Build 2D grid/cell environment.
    *   Implement basic chemistry matrix (Fire spreading across flammable tiles, water extinguishing fire, conductivity).
2.  **Phase 2: Player Controller & Elevation System (Weeks 5–8)**
    *   Implement top-down movement combined with $Z$-height layer simulation.
    *   Build stamina management, climbing surface logic, and gliding mechanics.
3.  **Phase 3: Rune Ability Suite (Weeks 9–12)**
    *   Implement Magnesis (physics drag tethers).
    *   Implement Stasis (time freezing + impulse accumulation).
    *   Implement Cryonis (water height-block spawning).
    *   Implement Remote Bombs (explosive kinetic impulse + combustion trigger).
4.  **Phase 4: World Streaming & AI Systems (Weeks 13–16)**
    *   Build chunk loading/unloading algorithm with Delta Serialization for save files.
    *   Implement Finite State Machine AI for enemy behavior (Patrol, Alert, Search Weapon, Flee from Fire).
5.  **Phase 5: Optimization & Mobile UI (Weeks 17–20)**
    *   Integrate virtual touch controls, haptic feedback hooks, and gamepad abstraction layers.
    *   Optimize draw calls (sprite batching, tilemap pooling) to maintain continuous 60 FPS on target Android hardware.