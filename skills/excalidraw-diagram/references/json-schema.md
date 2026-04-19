# Excalidraw JSON Schema

## Top-Level File Structure

Every `.excalidraw` file must follow this structure:

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [...],
  "appState": {
    "viewBackgroundColor": "#ffffff",
    "gridSize": 20
  },
  "files": {}
}
```

---

## Element Types

| Type        | Use For                             |
| ----------- | ----------------------------------- |
| `rectangle` | Processes, actions, components      |
| `ellipse`   | Entry/exit points, external systems |
| `diamond`   | Decisions, conditionals             |
| `arrow`     | Connections between shapes          |
| `text`      | Labels inside or outside shapes     |
| `line`      | Non-arrow connections, structure    |
| `frame`     | Grouping containers                 |

---

## Common Properties

All elements share these:

| Property          | Type   | Description                                |
| ----------------- | ------ | ------------------------------------------ |
| `id`              | string | Unique identifier (use descriptive names)  |
| `type`            | string | Element type                               |
| `x`, `y`          | number | Position in pixels                         |
| `width`, `height` | number | Size in pixels                             |
| `strokeColor`     | string | Border color (hex)                         |
| `backgroundColor` | string | Fill color (hex or `"transparent"`)        |
| `fillStyle`       | string | `"solid"`, `"hachure"`, `"cross-hatch"`    |
| `strokeWidth`     | number | `1`, `2`, or `4`                           |
| `strokeStyle`     | string | `"solid"`, `"dashed"`, `"dotted"`          |
| `roughness`       | number | `0` (smooth), `1` (default), `2` (rough)  |
| `opacity`         | number | `0`–`100` (always use `100`)               |
| `seed`            | number | Random seed for roughness                  |
| `angle`           | number | Rotation in radians (usually `0`)          |
| `isDeleted`       | bool   | Set to `false`                             |
| `groupIds`        | array  | Group membership (usually `[]`)            |
| `boundElements`   | array  | Elements bound to this one (arrows, text)  |
| `locked`          | bool   | Lock element from editing (usually `false`)|

---

## Text-Specific Properties

| Property        | Description                           |
| --------------- | ------------------------------------- |
| `text`          | The display text (readable words only)|
| `originalText`  | Same as `text`                        |
| `fontSize`      | Size in pixels (16-20 recommended)    |
| `fontFamily`    | `3` for monospace (always use this)   |
| `textAlign`     | `"left"`, `"center"`, `"right"`       |
| `verticalAlign` | `"top"`, `"middle"`, `"bottom"`       |
| `containerId`   | ID of parent shape (null if free-floating) |
| `lineHeight`    | Line spacing multiplier (use `1.25`)  |

---

## Arrow-Specific Properties

| Property         | Description                                        |
| ---------------- | -------------------------------------------------- |
| `points`         | Array of `[x, y]` coordinates relative to element origin |
| `startBinding`   | Connection to start shape                          |
| `endBinding`     | Connection to end shape                            |
| `startArrowhead` | `null`, `"arrow"`, `"bar"`, `"dot"`, `"triangle"`  |
| `endArrowhead`   | `null`, `"arrow"`, `"bar"`, `"dot"`, `"triangle"`  |

---

## Binding Format

```json
{
  "elementId": "shapeId",
  "focus": 0,
  "gap": 2
}
```

- `elementId`: ID of the shape this arrow connects to
- `focus`: Position along the shape edge (`0` = center, `-1` to `1` range)
- `gap`: Pixel gap between arrow tip and shape edge

---

## Rectangle Roundness

Add for rounded corners:

```json
"roundness": { "type": 3 }
```

---

## ID Naming Convention

Use descriptive string IDs for readability:

| Pattern                  | Example                    |
| ------------------------ | -------------------------- |
| `<section>_<type>`       | `trigger_rect`, `end_ellipse` |
| `<section>_<type>_text`  | `trigger_rect_text`        |
| `arrow_<from>_<to>`      | `arrow_trigger_process`    |
| `label_<section>_<name>` | `label_header_title`       |

---

## Seed Namespacing

To avoid seed collisions in multi-section diagrams:

| Section   | Seed Range     |
| --------- | -------------- |
| Section 1 | `100000`–`199999` |
| Section 2 | `200000`–`299999` |
| Section 3 | `300000`–`399999` |
| Section N | `N×100000`     |


