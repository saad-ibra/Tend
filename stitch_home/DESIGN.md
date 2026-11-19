---
name: Mindful Ground
colors:
  surface: '#fbf9f6'
  surface-dim: '#dbdad7'
  surface-bright: '#fbf9f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f0'
  surface-container: '#efeeeb'
  surface-container-high: '#eae8e5'
  surface-container-highest: '#e4e2df'
  on-surface: '#1b1c1a'
  on-surface-variant: '#554339'
  inverse-surface: '#30312f'
  inverse-on-surface: '#f2f0ed'
  outline: '#887368'
  outline-variant: '#dbc1b5'
  surface-tint: '#99460a'
  primary: '#964407'
  on-primary: '#ffffff'
  primary-container: '#b65c21'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb68e'
  secondary: '#526354'
  on-secondary: '#ffffff'
  secondary-container: '#d2e5d2'
  on-secondary-container: '#566758'
  tertiary: '#785600'
  on-tertiary: '#ffffff'
  tertiary-container: '#946e1d'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbca'
  primary-fixed-dim: '#ffb68e'
  on-primary-fixed: '#331200'
  on-primary-fixed-variant: '#773300'
  secondary-fixed: '#d5e7d5'
  secondary-fixed-dim: '#b9cbb9'
  on-secondary-fixed: '#101f13'
  on-secondary-fixed-variant: '#3a4b3d'
  tertiary-fixed: '#ffdea4'
  tertiary-fixed-dim: '#eec067'
  on-tertiary-fixed: '#261900'
  on-tertiary-fixed-variant: '#5d4200'
  background: '#fbf9f6'
  on-background: '#1b1c1a'
  surface-variant: '#e4e2df'
typography:
  headline-xl:
    fontFamily: Newsreader
    fontSize: 40px
    fontWeight: '400'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Newsreader
    fontSize: 30px
    fontWeight: '400'
    lineHeight: 36px
    letterSpacing: -0.015em
  headline-lg:
    fontFamily: Newsreader
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Newsreader
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Newsreader
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Manrope
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Newsreader
    fontSize: 19px
    fontWeight: '400'
    lineHeight: 30px
  body-md:
    fontFamily: Manrope
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Manrope
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-md: 1.5rem
  gutter-lg: 2rem
  margin: 1rem
  margin-md: 2rem
  margin-lg: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system draws inspiration from Japanese wabi-sabi principles and Scandinavian functionalism, filtered through high-precision modern productivity interfaces. The product centers around *tending*—the daily, quiet act of caring for one's focus, routines, and thoughts rather than aggressive tracking or metric exploitation. 

The aesthetic is disciplined, content-first, and serene:
- **Tone:** Grounded, literate, steady, unhurried, tactile.
- **Visual Stance:** Restrained editorial minimalism. We treat white space as breathing room and borders as subtle joinery rather than heavy barriers.
- **Anti-Patterns:** No saturated primary gamification colors, no loud celebratory modal takeovers, no decorative skeuomorphic flourishes, and zero synthetic glossy gradients. Every element exists to clarify intent and preserve cognitive calm.

## Colors

The color architecture is built upon natural, organic dyes and pressed paper stocks rather than synthetic digital hex values:

- **Surface Base (`#FAF8F5`):** Linen paper tint that reduces optical strain compared to pure white. Secondary nested containers utilize `#F4F1EC` to create natural low-contrast separation.
- **Primary Ink Accent (`#C2652A`):** Sunbaked terracotta used for active states, intentional markers, primary call-to-actions, and completed streak nodes. It signals energy without urgency.
- **Secondary Tone (`#5A6B5C`):** Muted dry moss/sage used for calm metadata, botanical indicators, reflective tags, and secondary positive feedback.
- **Tertiary Accent (`#C49A45`):** Warm ochre for subtle warnings, contextual bookmarks, and focus highlights.
- **Ink System:**
  - High-emphasis text: Deep sumi charcoal (`#1A1918`).
  - Mid-emphasis body & icons: Soft charcoal (`#403E3B`).
  - Low-emphasis metadata & disabled states: Warm stone gray (`#736F6A`).
  - Hairline dividers & borders: Muted flaxen (`#E8E4DE`).

## Typography

The typographic hierarchy pairs the literary authority of **Newsreader** for reflective titles and long-form journal entries with the geometric clarity of **Manrope** for functional dashboards, metadata, and task execution:

- **Headlines (Newsreader):** Brings warmth and an unhurried, bookish cadence to milestone markers, page headers, and reflection prompts. Uses moderate proportional negative tracking.
- **Body & Functional Labels (Manrope):** Renders crisp, compact UI text, daily habit rows, and timestamps. Generous x-height ensures immediate readability on mobile screens at glanceable intervals.
- **Numerical Data:** Tabular numerals enabled by default across all progress rings, counts, and timers to avoid visual jitter during real-time updates.

## Layout & Spacing

The layout model is governed by an 8-point base grid system combined with an editorial column rule:

- **Mobile (< 768px):** 4-column fluid layout, `margin: 1rem` (16px), and `gutter: 1rem` (16px). Single-column stack prioritized for undisturbed linear focus.
- **Tablet (768px – 1023px):** 8-column fluid layout with dynamic sidebar collapse. Margins expand to 32px.
- **Desktop (≥ 1024px):** Fixed-reading canvas centered with a maximum text line length of 680px for long-form reflections, flanked by structured utility columns (habit tracks, progress rail). Total content width capped at 1120px to prevent panoramic scanning.
- **Vertical Rhythm:** Paragraphs and discrete entry blocks utilize `space-lg` (24px) gaps to induce visual stillness. Micro-elements within an interactive unit use `space-sm` (8px).

## Elevation & Depth

Spatial layering relies on physical sheet metaphors rather than atmospheric shadows:

- **Tonal Stepping:** Surfaces layer from `#FAF8F5` (Canvas Background) to `#FFFFFF` (Elevated Resting Cards) to `#F4F1EC` (Recessed Areas, such as input fields and well containers).
- **Hairline Joinery:** Depth boundaries are defined primarily by subtle 1px strokes (`#E8E4DE`). No bold outlines or harsh demarcations.
- **Shadow Philosophy:** Minimal and diffused. For interactive floating drawers or contextual menus, use an ambient, tinted shadow: `0px 4px 20px -2px rgba(26, 25, 24, 0.04), 0px 1px 4px 0px rgba(26, 25, 24, 0.02)`. No high-contrast drop shadows.

## Shapes

Corner radii balance organic softness with structural architectural order:

- **Base Components (Inputs, Buttons, Cards):** Standardized with `rounded-lg` (16px / 1rem) to produce a calm, approachable silhouette that avoids juvenile bubbliness.
- **Micro UI (Badges, Chips, Habit Dots):** Use `rounded-full` (pill shape) for complete circular or capsule encapsulation.
- **Canvas Containers & Dialogs:** Softened up to `rounded-xl` (24px / 1.5rem) to evoke thick-cornered notebooks and archival cards.

## Components

### Buttons
- **Primary:** Filled terracotta (`#C2652A`) with sumi-tinted white text (`#FAF8F5`). 44px minimum touch target height. Subtle hover state transitions to `#B05822` without transform scale.
- **Secondary / Ghost:** Clear background, `#E8E4DE` 1px border, `#403E3B` text. On hover, background shifts quietly to `#F4F1EC`.
- **Tertiary:** Borderless, warm charcoal text with inline underline appearing only on active hover.

### Habit Trackers & Checkboxes
- **Custom Checkpoints:** Rather than generic checkboxes, habits employ custom 20px organic pill or circular rings.
- **Unchecked:** 1.5px border of `#E8E4DE` on `#FFFFFF` base.
- **Checked (Tended):** Filled with `#5A6B5C` (Sage) or `#C2652A` (Terracotta) featuring an organic check glyph rendered in `#FAF8F5`. Transition is smooth (150ms ease-out) without bouncy particle explosions.

### Input Fields & Editor Blocks
- **Inputs:** Low-contrast background `#F4F1EC`, borderless at rest, padding 12px 16px. On focus, transitions to `#FFFFFF` with a 1px border in `#C2652A` and zero outer focus ring bloom.
- **Long-Form Writing Blocks:** Typographic, borderless canvas. In-place editable content blocks that resemble clean, unadorned stationery.

### Chips & Filters
- Compact 28px height with pill radius. 
- Inactive state: `#F4F1EC` surface, `#736F6A` text.
- Active state: `#1A1918` background with `#FAF8F5` text, providing grounding without jarring chromatic accents.

### Cards & Content Modules
- `#FFFFFF` surface resting on `#FAF8F5` base, wrapped in a 1px `#E8E4DE` border. 
- Generous internal padding (20px mobile, 24px desktop).
- No aggressive hover lifts; transitions limited to hairline border shift to `#D9D4CC`.