# UI COMPONENTS

## OVERVIEW
Reusable UI primitives and base elements used to construct the shell's interface. These components are designed to be generic, themeable, and performant.

## STRUCTURE
| Directory | Purpose |
|-----------|---------|
| `button/` | Interactive elements (BaseButton, QuickButton, StatusButton) |
| `carousel/` | Scrollable selection views and horizontal lists |
| `indicators/` | Visual status representations (Progress, Usage, Activity) |
| `layout/` | Structural containers (DetailRow, SectionSeparator) |
| `panel/` | Core surface elements (Panel, InvertedCorner, ScreenBorder) |

## KEY CONVENTIONS
- **Root ID**: Every component must use `id: root` for its top-level element.
- **Styling**: All colors, radii, spacing, and durations must be sourced from `Config.qml`.
- **List Optimization**: Avoid using transparency (alpha) in `ListView` or `PathView` delegates to ensure smooth scrolling.
- **Imports**: Use relative imports for sibling UI components (e.g., `import "../layout"`).

## ANTI-PATTERNS
- **Hardcoding**: Never use hex codes, RGB values, or fixed pixel sizes directly in components.
- **Ad-hoc Transitions**: Do not define custom durations; use `Config.animations.fast` or `Config.animations.normal`.
- **State Leakage**: Components should be stateless where possible, relying on properties for configuration.
