# Feature Flags for Interactivity Domain

This document describes the feature flags used to gate new and untested features in the interactivity domain.

## Overview

New features are gated behind feature flags to allow:
- Gradual rollout
- Easy rollback if issues are discovered
- A/B testing
- Safe deployment of experimental features

## Feature Flags

### `:gltf_asset_support`

**Status**: New feature (disabled by default)

**Description**: Enables glTF asset storage and retrieval functionality. When enabled, pointer operations can access glTF assets stored in state. When disabled, pointer operations fall back to VariableValue.

**Affected Modules**:
- `AriaPlanner.Domains.Interactivity.Predicates.GltfAsset`
- `AriaPlanner.Domains.Interactivity.Commands.PointerGet`
- `AriaPlanner.Domains.Interactivity.Commands.PointerSet`
- `AriaPlanner.Domains.Interactivity.Commands.PointerInterpolate`
- `AriaPlanner.Domains.Interactivity.Commands.ActivateGraph`

**Usage**:
```elixir
if FeatureFlags.gltf_asset_enabled?() do
  # Use glTF asset functionality
else
  # Fall back to VariableValue
end
```

### `:pointer_template_support`

**Status**: New feature (disabled by default)

**Description**: Enables JSON pointer template parsing with parameter substitution. When enabled, pointer operations support templates like `/nodes/{nodeId}/scale` where `{nodeId}` is replaced at runtime. When disabled, pointers are treated as simple paths without template parsing.

**Affected Modules**:
- `AriaPlanner.Domains.Interactivity.PointerResolver`
- `AriaPlanner.Domains.Interactivity.Commands.PointerGet`
- `AriaPlanner.Domains.Interactivity.Commands.PointerSet`
- `AriaPlanner.Domains.Interactivity.Commands.PointerInterpolate`

**Usage**:
```elixir
if FeatureFlags.pointer_template_enabled?() do
  # Parse and resolve templates
else
  # Treat as simple pointer path
end
```

### `:gltf_loader_support`

**Status**: New feature (disabled by default)

**Description**: Enables glTF file loading and behavior graph extraction functionality. When enabled, glTF files can be loaded and behavior graphs extracted from the KHR_interactivity extension. When disabled, loader functions return errors.

**Affected Modules**:
- `AriaPlanner.Domains.Interactivity.GltfLoader`

**Usage**:
```elixir
if FeatureFlags.gltf_loader_enabled?() do
  GltfLoader.load_from_file("path/to/file.gltf")
else
  {:error, "glTF loader support is disabled"}
end
```

## Enabling Feature Flags

Feature flags are managed using FunWithFlags. To enable a flag:

### Via Database

```elixir
# Enable globally
FunWithFlags.enable(:gltf_asset_support)

# Enable for specific actors (future use)
FunWithFlags.enable(:gltf_asset_support, for_actor: actor_id)

# Disable
FunWithFlags.disable(:gltf_asset_support)
```

### Via Configuration (for testing)

```elixir
# In config/test.exs or config/dev.exs
config :fun_with_flags, :test_mode, true

# Then in tests
FunWithFlags.enable(:gltf_asset_support)
```

## Default Behavior

By default, all new feature flags are **disabled**. This ensures:
- Existing functionality continues to work unchanged
- New features are opt-in
- Gradual rollout is possible

When a feature flag is disabled:
- Pointer operations fall back to VariableValue (backward compatible)
- Template parsing is skipped (pointers treated as simple paths)
- glTF loader returns errors

## Migration Path

1. **Phase 1**: Deploy with flags disabled (current state)
2. **Phase 2**: Enable flags in test/staging environments
3. **Phase 3**: Enable flags for a subset of users/operations
4. **Phase 4**: Enable flags globally after validation
5. **Phase 5**: Remove feature flags once stable (optional)

## Testing

Feature flags should be explicitly enabled in tests that exercise new functionality:

```elixir
defmodule MyTest do
  use ExUnit.Case

  setup do
    # Enable feature flags for this test
    FunWithFlags.enable(:gltf_asset_support)
    FunWithFlags.enable(:pointer_template_support)
    FunWithFlags.enable(:gltf_loader_support)

    on_exit(fn ->
      # Clean up
      FunWithFlags.disable(:gltf_asset_support)
      FunWithFlags.disable(:pointer_template_support)
      FunWithFlags.disable(:gltf_loader_support)
    end)

    :ok
  end

  test "new feature works when enabled" do
    # Test new functionality
  end
end
```

## Related Documentation

- [FunWithFlags Documentation](https://hexdocs.pm/fun_with_flags/)
- [glTF Interactivity Extension Specification](../thirdparty/specification/)
- [RFC 6901: JSON Pointer](../thirdparty/rfc6901.txt)
