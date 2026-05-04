---
name: excalidraw-diagram
description: "Generate structured, argumentative Excalidraw diagrams from natural language descriptions. Use when creating architecture diagrams, system visualizations, data flow diagrams, pipeline visualizations, workflow charts, or any technical illustration that outputs .excalidraw JSON files. DO NOT USE FOR: Mermaid or markdown diagrams, text-based documentation (use brainstorming or architect), code generation, or non-visual output."
argument-hint: "[diagram topic or system to visualize]"
license: MIT
compatibility: "VS Code"
metadata:
  version: "8.0"
  updated: "2026-05-03"
  dependencies: []
---

# Excalidraw Diagram Creator

> Version: 8.0 | Updated: 2026-05-03 | Architect: Karim Bhalwani | Deps: none

## Overview

Generate `.excalidraw` JSON files that **argue visually**, not just display information. Every diagram produced by this skill uses shape, layout, and color to mirror the concept it represents - not just label it.

Output files are saved to an `excalidraw/` directory (created automatically if it does not exist). Users open `.excalidraw` files in the VS Code Excalidraw extension, at excalidraw.com, or in Obsidian.

## Core Philosophy

**Diagrams should ARGUE, not DISPLAY.**

A diagram is not formatted text. It is a visual argument that shows relationships, causality, and flow that words alone cannot express. The shape should BE the meaning.

- **The Isomorphism Test**: If you removed all text, would the structure alone communicate the concept? If not, redesign.
- **The Education Test**: Could someone learn something concrete from this diagram, or does it just label boxes? A good diagram teaches.

## When to Use

- Visualizing system architectures alongside `SPEC.md`
- Illustrating data pipelines (ETL, Medallion, Data Vault)
- Documenting RAG pipelines, agent workflows, or prompt flows
- Creating component interaction diagrams or state machines
- Mapping workflows and process flows for planning
- Producing before/after comparisons for refactoring proposals
- Any request for a diagram, visualization, flowchart, or architecture picture

## Workflow

### Step 0: Assess Depth Required

Before designing, determine what level of detail this diagram needs:

- **Simple/Conceptual**: Abstract shapes, labels, relationships. Use for mental models, philosophies, quick overviews.
- **Comprehensive/Technical**: Concrete examples, real data formats, actual event names. Use for systems, architectures, tutorials.

For technical diagrams, research actual specifications before drawing. Look up real event names, API endpoints, data formats - never use generic placeholders.

### Step 1: Understand Deeply

Read the content. For each concept, ask:

- What does this concept **DO**? (not what IS it)
- What relationships exist between concepts?
- What is the core transformation or flow?
- What would someone need to **SEE** to understand this?

### Step 2: Map Concepts to Visual Patterns

For each concept, find the visual pattern that mirrors its behavior. Consult `references/visual-patterns.md` for the full pattern library.

| If the concept...               | Use this pattern                             |
| ------------------------------- | -------------------------------------------- |
| Spawns multiple outputs         | **Fan-out** (radial arrows from center)      |
| Combines inputs into one        | **Convergence** (funnel, arrows merging)     |
| Has hierarchy or nesting        | **Tree** (lines + free-floating text)        |
| Is a sequence of steps          | **Timeline** (line + dots + labels)          |
| Loops or improves continuously  | **Spiral/Cycle** (arrow returning to start)  |
| Is an abstract state or context | **Cloud** (overlapping ellipses)             |
| Transforms input to output      | **Assembly line** (before → process → after) |
| Compares two things             | **Side-by-side** (parallel with contrast)    |
| Separates into phases           | **Gap/Break** (visual separation)            |

### Step 3: Ensure Variety

For multi-concept diagrams: **each major concept must use a different visual pattern**. No uniform card grids. No equal boxes. Visual variety mirrors conceptual variety.

### Step 4: Sketch the Flow

Before writing JSON, mentally trace how the eye moves through the diagram. There should be a clear visual story - typically left→right or top→bottom.

### Step 5: Generate JSON

Create the `.excalidraw` file. For the JSON structure, element templates, and color palette, consult:

- `references/color-palette.md` - All color choices
- `references/element-templates.md` - Copy-paste JSON for each element type
- `references/json-schema.md` - Excalidraw JSON format

**Output directory**: Save all `.excalidraw` files to the `excalidraw/` directory at the workspace root. Create the directory if it does not exist.

**File naming**: Use kebab-case descriptive names: `auth-architecture.excalidraw`, `etl-pipeline-flow.excalidraw`, `rag-pipeline.excalidraw`.

### Step 6: Verify Structure

After generating JSON, review the file against the Definition of Done checklist below. Verify element bindings, spacing, and that every relationship has an arrow or line.

## Depth Levels

### Simple / Conceptual Diagrams

Use abstract shapes when:

- Explaining a mental model or philosophy
- The audience does not need technical specifics
- The concept IS the abstraction (e.g., "separation of concerns")

### Comprehensive / Technical Diagrams

Use concrete examples when:

- Diagramming a real system, protocol, or architecture
- The audience needs to understand what things actually look like
- You are showing how multiple technologies integrate

**For technical diagrams, include evidence artifacts** - code snippets, JSON payloads, real event names embedded directly in the diagram using dark-background rectangles with colored text. See `references/color-palette.md` for evidence artifact colors.

## Multi-Zoom Architecture

Comprehensive diagrams operate at multiple zoom levels simultaneously:

| Level                               | What It Shows                                        | Example                                               |
| ----------------------------------- | ---------------------------------------------------- | ----------------------------------------------------- |
| **Level 1: Summary Flow**           | Full pipeline at a glance                            | `Input → Processing → Output`                         |
| **Level 2: Section Boundaries**     | Labeled regions grouping related components          | Backend / Frontend, Setup / Execution / Cleanup       |
| **Level 3: Detail Inside Sections** | Evidence artifacts, code snippets, concrete examples | Actual API response format inside a "Backend" section |

For comprehensive diagrams, aim to include all three levels.

## Container vs. Free-Floating Text

**Not every piece of text needs a shape around it.** Default to free-floating text. Add containers only when they serve a purpose.

| Use a Container When...                               | Use Free-Floating Text When...                |
| ----------------------------------------------------- | --------------------------------------------- |
| It is the focal point of a section                    | It is a label or description                  |
| It needs visual grouping with other elements          | It is supporting detail or metadata           |
| Arrows need to connect to it                          | It describes something nearby                 |
| The shape itself carries meaning (diamond = decision) | Typography alone creates sufficient hierarchy |
| It represents a distinct "thing" in the system        | It is a section title or annotation           |

**Rule**: Aim for <30% of text elements inside containers. Use font size and color for hierarchy instead of boxes.

## Shape Meaning

Choose shape based on what it represents - or use no shape at all:

| Concept Type            | Shape                         | Why                          |
| ----------------------- | ----------------------------- | ---------------------------- |
| Labels, descriptions    | **none** (free-floating text) | Typography creates hierarchy |
| Section titles          | **none** (free-floating text) | Font size/weight is enough   |
| Timeline markers        | small `ellipse` (10-20px)     | Visual anchor, not container |
| Start, trigger, input   | `ellipse`                     | Soft, origin-like            |
| End, output, result     | `ellipse`                     | Completion, destination      |
| Decision, condition     | `diamond`                     | Classic decision symbol      |
| Process, action, step   | `rectangle`                   | Contained action             |
| Abstract state, context | overlapping `ellipse`         | Fuzzy, cloud-like            |
| Hierarchy node          | lines + text (no boxes)       | Structure through lines      |

## Layout Principles

- **Hierarchy Through Scale**: Hero elements 300×150, primary 180×90, secondary 120×60, small 60×40
- **Whitespace = Importance**: The most important element has 200px+ of empty space around it
- **Flow Direction**: Guide the eye left→right or top→bottom for sequences, radial for hub-and-spoke
- **Connections Required**: If A relates to B, there must be an arrow. Position alone does not show relationships.

## Modern Aesthetics

- **Roughness**: `roughness: 0` for clean modern diagrams (default). Use `roughness: 1` only for hand-drawn/informal.
- **Stroke Width**: `1` = thin/elegant, `2` = standard shapes/arrows, `3` = bold emphasis (use sparingly)
- **Opacity**: Always `opacity: 100`. Use color, size, and stroke width for hierarchy instead of transparency.
- **Small Markers**: Use 10-20px ellipses as timeline markers, bullet points, and visual anchors instead of full shapes.

## Large Diagram Strategy

For comprehensive or technical diagrams, **build the JSON one section at a time**. Do NOT generate the entire file in a single pass.

1. **Create the base file** with the JSON wrapper and first section of elements.
2. **Add one section per edit.** Each section gets its own dedicated pass.
3. **Use descriptive string IDs** (e.g., `"trigger_rect"`, `"arrow_fan_left"`) for readability.
4. **Namespace seeds by section** (section 1 uses 100xxx, section 2 uses 200xxx) to avoid collisions.
5. **Update cross-section bindings** as you go - edit earlier elements' `boundElements` when adding connecting arrows.

After all sections are in place, review the complete JSON for binding correctness and spacing balance.

## Outputs & Deliverables

- **Primary Output**: `.excalidraw` JSON file saved to `excalidraw/` directory
- **Secondary Output**: Brief description of the diagram's structure and how to open it
- **Success Criteria**: Diagram passes the Isomorphism Test and Education Test
- **Quality Gate**: All elements properly bound, no orphaned arrows, visual variety present

## Definition of Done

### Conceptual Checks

- [ ] Isomorphism: Each visual structure mirrors its concept's behavior
- [ ] Argument: The diagram shows something text alone could not
- [ ] Variety: Each major concept uses a different visual pattern
- [ ] No uniform containers: Avoided card grids and equal boxes

### Container Discipline

- [ ] Minimal containers: Most text is free-floating, <30% inside shapes
- [ ] Lines as structure: Tree/timeline patterns use lines + text, not boxes
- [ ] Typography hierarchy: Font size and color create visual hierarchy

### Structural Checks

- [ ] Connections: Every relationship has an arrow or line
- [ ] Flow: Clear visual path for the eye to follow
- [ ] Hierarchy: Important elements are larger and more isolated

### Technical Checks

- [ ] Text clean: `text` and `originalText` contain only readable words
- [ ] Font: `fontFamily: 3` on all text elements
- [ ] Roughness: `roughness: 0` unless hand-drawn style explicitly requested
- [ ] Opacity: `opacity: 100` on all elements
- [ ] Output location: File saved to `excalidraw/` directory
- [ ] Valid JSON: File is valid Excalidraw JSON with `type: "excalidraw"`, `version: 2`

### Evidence Checks (Technical Diagrams Only)

- [ ] Research done: Actual specs, formats, event names looked up
- [ ] Evidence artifacts: Code snippets, JSON examples, or real data included
- [ ] Multi-zoom: Summary flow + section boundaries + detail present
- [ ] Concrete over abstract: Real content shown, not just labeled boxes

## Constraints

- **NO render pipeline.** This skill generates `.excalidraw` JSON only. Users view diagrams in VS Code Excalidraw extension, excalidraw.com, or Obsidian.
- **NO image generation.** Output is structured JSON, not PNG/SVG.
- **NO implementation code.** Diagrams only - do not implement systems shown in diagrams.
- **NO inventing colors.** All colors must come from `references/color-palette.md`.

## Common Pitfalls

- **Uniform Card Grids**: Making every concept the same rectangle in a grid. Each concept should use a visual pattern that mirrors its behavior.
- **Everything in Boxes**: Putting every label in a rectangle. Default to free-floating text; add containers only when they carry meaning.
- **Generic Placeholders**: Using "Event 1", "Step A", "Input" instead of real terminology. Research actual names, formats, and data.
- **Missing Connections**: Placing elements near each other without arrows. Proximity does not show relationships - arrows do.
- **Ignoring Scale Hierarchy**: Making all elements the same size. Important elements should be visually dominant (larger, more whitespace).
- **Broken Bindings**: Arrow `startBinding`/`endBinding` referencing element IDs that do not exist, or missing `boundElements` on the target shape.
- **Token Overflow on Large Diagrams**: Generating entire comprehensive diagrams in one pass. Build section-by-section to stay within output limits.

## Integration Points

| Phase        | Input From         | Output To              | Context                                      |
| ------------ | ------------------ | ---------------------- | -------------------------------------------- |
| Architecture | `architect`        | `SPEC.md` companion    | Visual architecture alongside specification  |
| Data Design  | `data-engineering` | Pipeline documentation | ETL/Medallion/Data Vault visualizations      |
| AI Systems   | `llm-app-patterns` | Pattern documentation  | RAG pipeline and agent architecture diagrams |
| Planning     | `concise-planning` | Workflow visualization | Process flow diagrams for implementation     |
| Discovery    | `brainstorming`    | Idea visualization     | Visual exploration of design options         |
| Review       | `guardian`         | Review documentation   | Architecture review visual aids              |

## References

Load these before generating any diagram:

### Reference Documents

- [color-palette.md](./references/color-palette.md) - Single source of truth for all color choices. Load before generating any diagram. Contains semantic shape colors, text hierarchy colors, and evidence artifact colors.
- [element-templates.md](./references/element-templates.md) - Copy-paste JSON templates for each Excalidraw element type (text, rectangle, arrow, line, ellipse, diamond). Pull colors from color-palette.md based on each element's semantic purpose.
- [json-schema.md](./references/json-schema.md) - Excalidraw JSON format reference. Element types, common properties, text-specific properties, arrow bindings, and the top-level file structure.
- [visual-patterns.md](./references/visual-patterns.md) - Visual pattern library with ASCII examples. Nine reusable patterns (fan-out, convergence, tree, timeline, cycle, cloud, assembly line, side-by-side, gap/break) with when-to-use guidance and implementation notes.
