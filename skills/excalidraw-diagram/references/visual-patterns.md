# Visual Pattern Library

Nine reusable visual patterns for mapping concepts to diagram structures. Each pattern mirrors a specific behavioral concept - choose the pattern that matches what the concept **does**, not just what it **is**.

---

## Pattern Selection Guide

| If the concept...              | Use this pattern      |
| ------------------------------ | --------------------- |
| Spawns multiple outputs        | Fan-Out               |
| Combines inputs into one       | Convergence           |
| Has hierarchy or nesting       | Tree                  |
| Is a sequence of steps         | Timeline              |
| Loops or improves continuously | Spiral/Cycle          |
| Is an abstract state/context   | Cloud                 |
| Transforms input to output     | Assembly Line         |
| Compares two things            | Side-by-Side          |
| Separates into phases          | Gap/Break             |

---

## 1. Fan-Out (One-to-Many)

Central element with arrows radiating to multiple targets.

**Use for**: Sources, PRDs, root causes, central hubs, broadcast events.

```text
        ○
       ↗
  □ → ○
       ↘
        ○
```

**Implementation**: One rectangle or ellipse at center. Multiple arrows with different `endBinding` targets radiating outward. Distribute targets at even angular intervals.

---

## 2. Convergence (Many-to-One)

Multiple inputs merging through arrows to single output.

**Use for**: Aggregation, funnels, synthesis, data merging, consensus.

```text
  ○ ↘
  ○ → □
  ○ ↗
```

**Implementation**: Multiple source elements with arrows converging to a single target. The target element should be visually larger (hero scale) to show it is the result.

---

## 3. Tree (Hierarchy)

Parent-child branching with connecting lines and free-floating text.

**Use for**: File systems, org charts, taxonomies, module hierarchies, decision trees.

```text
  label
  ├── label
  │   ├── label
  │   └── label
  └── label
```

**Implementation**: Use `line` elements for the trunk and branches. Use free-floating text for labels - no boxes needed. This creates a cleaner result than rectangles with contained text.

---

## 4. Timeline (Sequence)

Horizontal or vertical line with small dots at intervals and free-floating labels beside each dot.

**Use for**: Sequences, lifecycles, state transitions, protocol events, deployment stages.

```text
  ●─── Label 1
  │
  ●─── Label 2
  │
  ●─── Label 3
```

**Implementation**: One `line` element as the spine. Small `ellipse` elements (10-20px) as dots at regular intervals along the line. Free-floating text labels positioned to the right (horizontal) or below (vertical) each dot.

---

## 5. Spiral/Cycle (Continuous Loop)

Elements in sequence with arrow returning to start.

**Use for**: Feedback loops, iterative processes, CI/CD, evolution, continuous improvement.

```text
  □ → □
  ↑     ↓
  □ ← □
```

**Implementation**: Four or more elements arranged in a square or circular layout. Arrows connect each to the next, with the last arrow connecting back to the first. Use curved arrow points for visual appeal.

---

## 6. Cloud (Abstract State)

Overlapping ellipses with varied sizes.

**Use for**: Context, memory, conversations, mental states, knowledge bases, abstract concepts.

**Implementation**: Three to five overlapping `ellipse` elements with varying sizes and slightly different positions. Use a single semantic color from the palette. Add free-floating text labels inside or near the cluster.

---

## 7. Assembly Line (Transformation)

Input → Process Box → Output with clear before/after contrast.

**Use for**: Transformations, ETL pipelines, data processing, conversion, formatting.

```text
  ○○○ → [PROCESS] → □□□
  chaos              order
```

**Implementation**: Input elements on the left (can be informal/varied shapes), a central process rectangle (hero scale), and output elements on the right (can be uniform/ordered). The visual contrast between input and output shapes should mirror the transformation.

---

## 8. Side-by-Side (Comparison)

Two parallel structures with visual contrast.

**Use for**: Before/after, options, trade-offs, old vs. new, competing approaches.

**Implementation**: Two vertical columns with matching structure but different colors or shapes. A dashed `line` element between them serves as a divider. Free-floating text labels at the top of each column identify what is being compared.

---

## 9. Gap/Break (Separation)

Visual whitespace or barrier between sections.

**Use for**: Phase changes, context resets, boundaries, deployment stages, environment separation.

**Implementation**: Use a dashed `line` element as a section divider. Leave 100-200px of whitespace between sections. Free-floating text labels above or beside the divider identify each phase.

---

## Lines as Structure

Use lines (`type: "line"`, not arrows) as primary structural elements instead of boxes:

- **Timelines**: Line + small dots + free-floating labels
- **Tree structures**: Vertical trunk + horizontal branches + free-floating text
- **Dividers**: Thin dashed lines to separate sections
- **Flow spines**: A central line that elements relate to

Lines + free-floating text often creates a cleaner, more professional result than boxes + contained text.

---

## Combining Patterns

Complex diagrams combine multiple patterns. Rules:

1. **Each major concept gets a different pattern.** No uniform grids.
2. **Patterns connect via arrows.** The output of one pattern feeds into the input of the next.
3. **Scale distinguishes importance.** The primary pattern is largest; supporting patterns are smaller.
4. **Whitespace separates patterns.** Use 150-200px gaps between distinct pattern groups.
5. **Flow direction is consistent.** If the diagram flows left→right, all patterns follow that direction.


