brew # glTF 2.0 Interactivity Extension Specification

This directory contains the split specification document for the glTF 2.0 Interactivity Extension in Markdown format.

## File Structure

The specification has been split into logical sections:

- **00_header_and_introduction.md** (267 lines)

  - Document header, metadata, and attributes
  - Foreword and copyright information
  - Introduction: General, Document Conventions, Motivation and Design Goals

- **01_core_concepts.md** (420 lines)

  - Graphs
  - Nodes (general concepts: Operation, Sockets, Configuration)
  - Custom Events
  - Custom Variables
  - Implementation-Specific Limits

- **02_node_types.md** (3997 lines)

  - Detailed specifications for all node types
  - Math Nodes (Constants, Arithmetic, Comparison, Special, Angle/Trig, Hyperbolic, Exponential, Vector, Matrix, Quaternion, Swizzle, Integer Arithmetic, Integer Comparison, Integer Bitwise, Boolean Arithmetic)
  - Type Conversion Nodes
  - Control Flow Nodes
  - State Manipulation Nodes
  - Event Nodes

- **03_extending_gltf.md** (1066 lines)

  - Extending glTF Object Model
  - Implementation-Specific Runtime Limits
  - Active Camera State
  - Animation State
  - JSON Syntax (General, Types, Variables, Events, Declarations, Nodes)

- **04_validation.md** (377 lines)
  - Validation Glossary
  - Extension Object Validation
  - Graph Object Validation
  - Variable Object Validation
  - Event Object Validation
  - Declaration Object Validation
  - Node Object Validation
  - Inline Value Object Validation

## Original File

The original complete specification is available at `../Specification.adoc` (5222 lines total).

## Conversion

The Markdown files were generated from the original AsciiDoc specification using:
1. `asciidoctor` to convert AsciiDoc to HTML
2. `pandoc` to convert HTML to Markdown

## Usage

To reconstruct the full specification in Markdown:

```bash
cat 00_header_and_introduction.md \
    01_core_concepts.md \
    02_node_types.md \
    03_extending_gltf.md \
    04_validation.md > ../Specification.md
```
