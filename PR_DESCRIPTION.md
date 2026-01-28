# Integrate aria-gltf and Enhance Interactivity Domain

## Overview

This PR integrates the `aria-gltf` library into `aria-planner` to enable proper glTF Interactivity Extension support, adds feature flags for gradual rollout, reorganizes tests for better maintainability, and adds database schemas for persistence.

## Key Changes

### 🎯 glTF Integration

**New Modules:**
- `GltfLoader` - Loads glTF files (.gltf/.glb) and extracts behavior graphs from KHR_interactivity extension
- `PointerResolver` - Implements JSON Pointer template parsing and resolution per RFC 6901
- `GltfAsset` predicate - Stores glTF assets in planner state
- `Types` - glTF type system with type mapping and default values

**Updated Commands:**
- `pointer/get` - Now resolves JSON pointers against glTF assets with template parameter support
- `pointer/set` - Sets properties in glTF assets via JSON pointers
- `pointer/interpolate` - Interpolates values and writes to glTF asset properties
- `activate_graph` - Optionally accepts and stores glTF assets

**Specification Compliance:**
- Full JSON Pointer template parsing (RFC 6901)
- Template parameter extraction and resolution
- Type validation and default value handling
- `isValid` output sockets per glTF Interactivity Extension spec
- Negative index validation

### 🚩 Feature Flags

**New Module:** `FeatureFlags`
- `:gltf_asset_support` - Gates glTF asset storage/retrieval
- `:pointer_template_support` - Gates JSON pointer template parsing
- `:gltf_loader_support` - Gates glTF file loading

All flags are **disabled by default** for backward compatibility. When disabled, features fall back to existing `VariableValue` behavior.

**Documentation:** `FEATURE_FLAGS.md` - Complete guide to feature flags, usage, and migration path

### 🧪 Test Reorganization

**Split large test file:**
- Deleted: `commands_test.exs` (1,298 lines)
- Created: 13 focused test files organized by functional category:
  - `arithmetic_operations_test.exs`
  - `binary_math_operations_test.exs`
  - `bitwise_boolean_operations_test.exs`
  - `comparison_operations_test.exs`
  - `matrix_operations_test.exs`
  - `quaternion_operations_test.exs`
  - `transform_operations_test.exs`
  - `type_conversion_test.exs`
  - `type_variants_test.exs`
  - `unary_math_operations_test.exs`
  - `vector_operations_test.exs`
  - `variable_flow_control_test.exs`
  - `math_helpers_test.exs`

**New Test Files:**
- `gltf_loader_test.exs` - Tests for glTF loading functionality
- `pointer_resolver_test.exs` - Tests for JSON pointer resolution
- `pointer_operations_test.exs` - Integration tests for pointer operations with real glTF assets

**Test Helper:**
- `test_helper.ex` - Shared test helper with common setup and aliases

### 📊 Database Schemas

**New Schema Modules:**
- `event_triggered_schema.ex`
- `graph_active_schema.ex`
- `node_executed_schema.ex`
- `socket_connected_schema.ex`
- `socket_value_schema.ex`
- `variable_value_schema.ex`

**New Migrations:**
- `20260128093328_create_interactivity_event_triggered.exs`
- `20260128093329_create_interactivity_graph_active.exs`
- `20260128093330_create_interactivity_node_executed.exs`
- `20260128093331_create_interactivity_socket_connected.exs`
- `20260128093332_create_interactivity_socket_value.exs`
- `20260128093333_create_interactivity_variable_value.exs`

### 📚 Documentation

- `EDGE_CASES.md` - Comprehensive documentation of edge cases and special behaviors
- `FEATURE_FLAGS.md` - Feature flag usage guide
- `thirdparty/rfc6901.txt` - RFC 6901 (JSON Pointer) specification

### 🔧 Command Improvements

**Enhanced Math Operations:**
- Improved error handling and edge case coverage
- Better NaN/Infinity handling
- Enhanced type validation

**Flow Control:**
- Improved documentation
- Better error messages

## Dependencies

- **Added:** `aria_gltf` (git dependency from https://github.com/V-Sekai-fire/aria-gltf.git, branch: `fix/unreachable-clause-warnings`)
  - Uses fix branch to resolve compiler warnings until upstream PR is merged
  - Related PR: https://github.com/V-Sekai-fire/aria-gltf/pull/6
- **Updated:** FunWithFlags configuration for feature flag persistence

## Backward Compatibility

✅ **Fully backward compatible** - All new features are gated behind feature flags (disabled by default)
✅ Existing code continues to work unchanged
✅ Pointer operations fall back to `VariableValue` when flags are disabled
✅ No breaking changes to existing APIs

## Migration Guide

### Enabling glTF Features

To enable glTF integration features:

```elixir
# Enable globally
FunWithFlags.enable(:gltf_asset_support)
FunWithFlags.enable(:pointer_template_support)
FunWithFlags.enable(:gltf_loader_support)

# Or enable for specific actors
FunWithFlags.enable(:gltf_asset_support, for_actor: actor_id)
```

### Using glTF Assets

```elixir
# Load glTF file
{:ok, {asset, behavior_graph}} = GltfLoader.load_from_file("path/to/file.gltf")

# Activate graph with glTF asset
{:ok, state} = ActivateGraph.c_activate_graph(state, "graph_id", gltf_asset: asset)

# Use pointer operations
{:ok, state} = PointerGet.c_pointer_get(state, "node_id", "pointer", "value", 
  pointer: "/nodes/{nodeId}/scale",
  type: 4
)
```

## Testing

All new features include comprehensive tests:
- Unit tests for individual modules
- Integration tests for pointer operations
- Edge case coverage
- Backward compatibility tests

Run tests with feature flags enabled:
```elixir
# In test setup
FunWithFlags.enable(:gltf_asset_support)
FunWithFlags.enable(:pointer_template_support)
FunWithFlags.enable(:gltf_loader_support)
```

## Files Changed

- **136 files** changed
- **7,756 lines** added/modified
- **New files:** 30+
- **Modified files:** 100+

## Breaking Changes

None - all changes are backward compatible.

## Related Issues/PRs

- Integrates aria-gltf library
- Implements glTF Interactivity Extension pointer operations
- Adds feature flag infrastructure for gradual rollout
- Uses aria-gltf fix branch: https://github.com/V-Sekai-fire/aria-gltf/pull/6

## Checklist

- [x] Code follows project style guidelines
- [x] Tests added/updated
- [x] Documentation updated
- [x] Backward compatibility maintained
- [x] Feature flags implemented
- [x] Database migrations added
- [x] Edge cases documented
- [x] Dependencies updated to use fix branch
