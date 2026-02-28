# Interactivity domain command catalog

Catalog of Elixir command modules under `lib/domains/interactivity/commands/` for Phase 2 parity. Spec operation ID format: `domain/op` (e.g. `math/add`). Internal name: `c_domain_op` (e.g. `c_math_add`).

## Math (math/*)

| Spec operation | Elixir module | Janet status |
|----------------|---------------|--------------|
| math/add | MathAdd | done (Phase 1) |
| math/sub | MathSub | done (Phase 2) |
| math/mul | MathMul | done (Phase 2) |
| math/div | MathDiv | done (Phase 2) |
| math/abs | MathAbs | pending |
| math/e | MathE | pending |
| math/pi | MathPi | pending |
| math/inf | MathInf | pending |
| math/nan | MathNaN | pending |
| math/neg | MathNeg | pending |
| math/sqrt | MathSqrt | pending |
| math/cbrt | MathCbrt | pending |
| math/sin, cos, tan | MathSin, MathCos, MathTan | pending |
| math/asin, acos, atan, atan2 | MathAsin, MathAcos, MathAtan, MathAtan2 | pending |
| math/sinh, cosh, tanh | MathSinh, MathCosh, MathTanh | pending |
| math/asinh, acosh, atanh | MathAsinh, MathAcosh, MathAtanh | pending |
| math/exp, log, log2, log10 | MathExp, MathLog, MathLog2, MathLog10 | pending |
| math/pow | MathPow | pending |
| math/floor, ceil, round, trunc | MathFloor, MathCeil, MathRound, MathTrunc | pending |
| math/sign | MathSign | pending |
| math/min, max, clamp | MathMin, MathMax, MathClamp | pending |
| math/mix, saturate, fract | MathMix, MathSaturate, MathFract | pending |
| math/deg, rad | MathDeg, MathRad | pending |
| math/length, normalize, dot, cross | MathLength, MathNormalize, MathDot, MathCross | pending |
| math/eq, lt, le, gt, ge | MathEq, MathLt, MathLe, MathGt, MathGe | pending |
| math/and, or, not, xor | MathAnd, MathOr, MathNot, MathXor | pending |
| math/select, switch | MathSelect, MathSwitch | pending |
| math/combine2–4, extract2–4 | MathCombine*, MathExtract* | pending |
| math/combine2x2–4x4, extract2x2–4x4 | MathCombine*x*, MathExtract*x* | pending |
| math/transpose, inverse, determinant | MathTranspose, MathInverse, MathDeterminant | pending |
| math/mat_compose, mat_decompose, mat_mul | MathMatCompose, MathMatDecompose, MathMatMul | pending |
| math/transform, rotate_2d, rotate_3d | MathTransform, MathRotate2D, MathRotate3D | pending |
| math/quat_* | MathQuatFromAxisAngle, MathQuatMul, etc. | pending |
| math/rem, lsl, asr, clz, ctz, popcnt | MathRem, MathLsl, MathAsr, MathClz, MathCtz, MathPopcnt | pending |
| math/is_nan, is_inf | MathIsNaN, MathIsInf | pending |
| math/random | MathRandom | pending |

## Flow (flow/*)

| Spec operation | Elixir module | Janet status |
|----------------|---------------|--------------|
| flow/sequence | FlowSequence | done (Phase 1) |
| flow/branch | FlowBranch | pending |
| flow/switch | FlowSwitch | pending |
| flow/while | FlowWhile | pending |
| flow/for | FlowFor | pending |
| flow/do_n | FlowDoN | pending |
| flow/multi_gate | FlowMultiGate | pending |
| flow/wait_all | FlowWaitAll | pending |
| flow/set_delay | FlowSetDelay | pending |
| flow/cancel_delay | FlowCancelDelay | pending |
| flow/throttle | FlowThrottle | pending |

## Variable (variable/*)

| Spec operation | Elixir module | Janet status |
|----------------|---------------|--------------|
| variable/get | VariableGet | pending |
| variable/set | VariableSet | pending |
| variable/interpolate | VariableInterpolate | pending |
| set_variable | SetVariable | pending |

## Pointer (pointer/*)

| Spec operation | Elixir module | Janet status |
|----------------|---------------|--------------|
| pointer/get | PointerGet | pending |
| pointer/set | PointerSet | pending |
| pointer/interpolate | PointerInterpolate | pending |

## Animation (animation/*)

| Spec operation | Elixir module | Janet status |
|----------------|---------------|--------------|
| animation/start | AnimationStart | pending |
| animation/stop | AnimationStop | pending |
| animation/stop_at | AnimationStopAt | pending |

## Event (event/*)

| Spec operation | Elixir module | Janet status |
|----------------|---------------|--------------|
| event/send | EventSend | pending |
| event/receive | EventReceive | pending |
| event/on_start | EventOnStart | pending |
| event/on_tick | EventOnTick | pending |

## Type (type/*)

| Spec operation | Elixir module | Janet status |
|----------------|---------------|--------------|
| type/float_to_int | TypeFloatToInt | pending |
| type/float_to_bool | TypeFloatToBool | pending |
| type/int_to_float | TypeIntToFloat | pending |
| type/int_to_bool | TypeIntToBool | pending |
| type/bool_to_float | TypeBoolToFloat | pending |
| type/bool_to_int | TypeBoolToInt | pending |

## Graph / execution

| Command | Elixir module | Janet status |
|---------|---------------|--------------|
| activate_graph | ActivateGraph | done (Phase 1) |
| connect_socket | ConnectSocket | pending |
| execute_node | ExecuteNode | pending |
| debug_log | DebugLog | pending |

## Predicates (Elixir)

- GraphActive, SocketValue, NodeExecuted (ported in Phase 1)
- GltfAsset, NodeExecutedSchema, VariableValueSchema, EventTriggeredSchema (pending)

## References

- Elixir source: `lib/domains/interactivity/`
- Operation mapping: `operation_mapping.ex` (spec_to_command / command_to_spec)
- Phase 2 proposal: [phase2-interactivity-parity.md](phase2-interactivity-parity.md)
