### The 3 Essential Character Domains: Structural Decay

This unified system replaces traditional physics with **Structural Decay**, treating the character (Sleeve) as a failing manifold mesh managed by three distinct solvers.

---

- **1. Spatial:** Fits **Tapered Capsules** around bones and items from the **Existing Assets list**. If the fit is illegal or overlapping, the **Manifold Processing Agent** fails to "stitch" the geometry, resulting in **Surface Tearing**—visible mesh holes and manifold gaps.
- **2. Topological:** Maps the skeletal bone-path from Spine to Augment. If the hierarchy is too deep or disconnected, **Limb De-rezzing** occurs; the high-fidelity VRM limb disappears, replaced by its raw **Tapered Capsule** primitive.
- **3. Resource:** Constrains triangle and bone counts within the engine buffer. Overloading triggers **Vocal Static**; the **VoIP** stream degrades into bit-crushed white noise as bandwidth is diverted to maintain the physical rig.

This unified system replaces traditional physics with **Structural Decay**, treating the character (Sleeve) as a failing manifold mesh managed by three distinct solvers. The MiniZinc thirdparty folder already contains useful models we can reuse—mapped below to each domain.

---

- **1. Spatial (fitting / collision):** The `carpet-cutting` model (`carpet-cutting/cc_base.mzn`) provides a 2D `diffn` packing baseline, but your assets require 3D packing. Upgrade the formulation by either:
  - converting tapered capsules into conservative axis-aligned 3D bounding boxes and implementing a 3D non-overlap (`diffn`-style) constraint over (x,y,z,width,depth,height), or
  - approximating capsules as a stack of 2D slices and using layered/zoned `diffn` (from `yumi-dynamic`) with clearance, or
  - using an oriented-box (OBB) packing variant with added clearance checks for capsule geometry.
Map asset geometry to the chosen 3D packing variables; if the solver cannot find a legal placement, trigger the engine's **Surface Tearing** fallback.
- **2. Topological (rigging path):** Use `yumi-dynamic/yumi-dynamic.mzn`. This model includes `circuit` constraints and path-like formulations suitable for verifying a single, connected rigging path from spine to augment hardpoints. If the circuit check fails, trigger **Limb De-rezzing** and fall back to capsule primitives.
- **3. Resource (bandwidth / triangle budget):** Use the `ihtc-2024-marte/model.mzn` (it includes `bin_packing_load.mzn`) as the `gbac`-equivalent: it contains `bin_packing_load` constraints that map naturally onto per-frame triangle/bone budgets vs. asset "weights." If the packing/load constraints are unsatisfiable, trigger **Vocal Static** (VoIP degradation).

Recommendations for a Minimal, High-Impact Implementation

- Focus first on the **Resource** and **Topological** solvers for fastest payoff:
  - The `ihtc-2024-marte` model already contains `bin_packing_load` logic—use it to implement a simple load check: sum(asset_weights) <= bandwidth_limit.
  - Use `yumi-dynamic` to validate rigging connectivity. Its `circuit` usage fits the "single path" requirement and is easier to adapt than a full spatial packing approach.
- Use `carpet-cutting` only if you want automated placement/fitting of items on the mesh. Manual hardpoint selection plus `yumi-dynamic` rig checks is an acceptable shortcut.

Quick mapping (files present in this repo):

- Spatial: [thirdparty/minizinc/carpet-cutting/cc_base.mzn](thirdparty/minizinc/carpet-cutting/cc_base.mzn)
- Topological: [thirdparty/minizinc/yumi-dynamic/yumi-dynamic.mzn](thirdparty/minizinc/yumi-dynamic/yumi-dynamic.mzn)
- Resource: [thirdparty/minizinc/ihtc-2024-marte/model.mzn](thirdparty/minizinc/ihtc-2024-marte/model.mzn)

Next steps

- Create branch `minizinc-solver-mapping` and adapt the `ihtc-2024-marte` model into a lightweight checker that accepts an `assets` list plus `bandwidth_limit` and returns SAT/UNSAT.
- Add a small wrapper script (or Mix task) that converts your engine asset list into MiniZinc `.dzn` input and invokes the appropriate model.

If you want, I can now:

- produce a minimal MiniZinc snippet (based on the `bin_packing_load` usage in `ihtc-2024-marte`) to validate asset weights vs. bandwidth, and
- open a branch and commit the `proposal.md` change.
