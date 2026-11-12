---
name: Luminous Sanctuary
colors:
  surface: '#121317'
  surface-dim: '#121317'
  surface-bright: '#38393e'
  surface-container-lowest: '#0d0e12'
  surface-container-low: '#1a1b20'
  surface-container: '#1e1f24'
  surface-container-high: '#292a2e'
  surface-container-highest: '#343439'
  on-surface: '#e3e2e8'
  on-surface-variant: '#c9c4d1'
  inverse-surface: '#e3e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#938f9b'
  outline-variant: '#484550'
  surface-tint: '#c9bfff'
  primary: '#ded7ff'
  on-primary: '#302764'
  primary-container: '#c2b7ff'
  on-primary-container: '#4f4584'
  inverse-primary: '#5f5696'
  secondary: '#ddbecd'
  on-secondary: '#3f2a36'
  secondary-container: '#57404c'
  on-secondary-container: '#cbadbc'
  tertiary: '#d8dbed'
  on-tertiary: '#2c303e'
  tertiary-container: '#bcbfd1'
  on-tertiary-container: '#4a4e5c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e5deff'
  primary-fixed-dim: '#c9bfff'
  on-primary-fixed: '#1b0f4f'
  on-primary-fixed-variant: '#473e7c'
  secondary-fixed: '#fadae9'
  secondary-fixed-dim: '#ddbecd'
  on-secondary-fixed: '#281621'
  on-secondary-fixed-variant: '#57404c'
  tertiary-fixed: '#dfe2f4'
  tertiary-fixed-dim: '#c3c6d8'
  on-tertiary-fixed: '#171b28'
  on-tertiary-fixed-variant: '#424655'
  background: '#121317'
  on-background: '#e3e2e8'
  surface-variant: '#343439'
typography:
  display-hero:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '600'
    lineHeight: 44px
  display-hero-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 1.75rem
---

## Brand & Style

This design system establishes an intimate, quiet, and hyper-refined sanctuary for human-AI companionship. Designed specifically for modern mobile experiences, it blends contemporary minimalism with ethereal iOS "Liquid Glass" physics. The visual language conveys emotional safety, psychological grounding, and unhurried conversation. 

The aesthetic is dark, warm, and atmospheric: deep nocturnal ink tones recede softly into the distance, allowing the AI presence and dialogue to emerge with clarity and gentle presence. Surfaces do not feel like heavy, vintage leaded crystal or loud skeumorphic acrylics; instead, they evoke weightless, ultra-thin suspended lenses—crisp frosted diaphragms that filter light with razor-sharp refractive rims and soft inner luminescence.

## Colors

The palette balances profound spatial depth with tender, low-saturation emotional highlights:

- **Canvas & Spatial Foundation**:
  - `canvas-root`: `#08090D` (Infinite deep midnight ink; absolute background baseline).
  - `surface-base`: `#121319` (Receded structural plane).
  - `surface-elevated`: `#17191F` (Resting opaque card foundation).
  - `surface-card-subtle`: `#1E2028` (Secondary structural container).

- **Liquid Glass Materials (Opacity & Refraction Tiers)**:
  - `glass-ultra-thin`: `rgba(255, 255, 255, 0.04)` with `backdrop-filter: blur(16px)` (ambient atmospheric panels, unselected states).
  - `glass-standard`: `rgba(255, 255, 255, 0.07)` with `backdrop-filter: blur(24px)` (interactive sheets, input dock, dynamic island modules).
  - `glass-prominent`: `rgba(255, 255, 255, 0.11)` with `backdrop-filter: blur(32px)` (active floating bottom bar, modal overlays).
  - `glass-border-subtle`: `rgba(255, 255, 255, 0.08)` (resting boundary).
  - `glass-border-edge`: `rgba(255, 255, 255, 0.14)` (top highlight gradient simulating light hitting bevelled edges).

- **Typographic & Icon Hierarchies**:
  - `text-primary`: `#F5F5F7` (Pure off-white, high-legibility dialogue and key statements).
  - `text-secondary`: `#A2A5AF` (Balanced slate mist for metadata, contextual labels, timestamps).
  - `text-tertiary`: `#646772` (Placeholder text, subtle dividers, de-emphasized badges).

- **Emotional Accents**:
  - `accent-lavender`: `#C2B7FF` (Primary interactive focal points, active voice waveform glows, self identity).
  - `accent-blush`: `#E4C5D4` (Warm secondary presence, AI companion response indicator, emotional resonance cues).
  - `accent-aurora-gradient`: Linear diagonal ramp from `#C2B7FF` through `#D3BEEA` to `#E4C5D4` for moments of deep connection.

## Typography

Typography prioritizes quiet, sustained reading and conversational comfort. On native Apple environments, tokens fall back natively to `SF Pro Text`, `SF Pro Display`, and `PingFang SC` to preserve native iOS rendering characteristics.

- Set conversational text (`body-lg`) with open line-height (`1.55` to `1.6`) to prevent cognitive exhaustion during long, introspective chat sessions.
- Chinese glyphs inherit standard system metrics; ensure punctuation does not stick to edges by enforcing soft dynamic wrap boundaries.
- Numeric characters and time displays in chat threads should render with tabular figures (`font-variant-numeric: tabular-nums`) to maintain visual alignment during live speech generation.

## Layout & Spacing

The layout is constructed around two distinct conceptual planes: the **Content Stage** and the **Floating Glass Console**:

- **Content Stage**: Uses a fluid single-column mobile-first flow constrained within a maximum width of 480px on larger form factors, maintaining a 20px (`1.25rem`) viewport boundary.
- **Vertical Hierarchy & Safe Areas**:
  - Top safe margins expand dynamically behind translucent status bar glass (`pt-[env(safe-area-inset-top) + 8px]`).
  - Bottom controls float detached above the home indicator, reserving a consistent 72px–88px clearance to allow conversational cards to glide smoothly underneath.
- **Micro-Gaps**: Chat bubbles, metadata badges, and sensory reactions use an 8px base rhythm (`space-sm`) to keep content tight and coherent, while card sections use 20px–28px distances to preserve serenity and breathing room.

## Elevation & Depth

Visual depth is produced by refractive transparency, light rim highlights, and ambient dark diffusion rather than heavy black drop shadows:

- **Level 0 (Background Canvas)**: Pure matte `#08090D`, zero reflection.
- **Level 1 (Structural Inset)**: `#17191F` with a soft inward contour or 1px border `rgba(255, 255, 255, 0.05)`.
- **Level 2 (Liquid Glass Floating Elements)**: 
  - Background: `rgba(255, 255, 255, 0.06)` to `rgba(255, 255, 255, 0.09)`.
  - Backdrop Blur: `backdrop-filter: blur(20px) saturate(180%)`.
  - Rim Highlight: A top-to-bottom linear border gradient (`border-color: linear-gradient(180deg, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0.04) 100%)`).
  - Ambient Glow: `0 12px 32px -8px rgba(0, 0, 0, 0.5), 0 0 1px 1px rgba(255, 255, 255, 0.06) inset`.
- **Level 3 (Modal Sheets & Interactive HUD)**:
  - Background: `rgba(28, 30, 38, 0.72)`.
  - Backdrop Blur: `backdrop-filter: blur(36px) saturate(190%)`.
  - Shadow: `0 24px 48px -12px rgba(0, 0, 0, 0.7)`.

## Shapes

The design system enforces a pill-and-squircle geometric rhythm:

- **Cards & Modal Sheets**: Radii are set to `24px`–`28px` using continuous iOS-style super-ellipses (smooth squircle clipping) to eliminate visual tension in corners.
- **Interactive Controls & System Pills**: Action buttons, voice bars, tag chips, floating tab navigation bars, and input trays adhere strictly to full capsule geometry (`border-radius: 9999px`).
- **Inner Nested Shapes**: Child elements within 24px cards adopt concentric 14px–16px radii to preserve harmonious organic spacing.

## Components

### 1. Liquid Glass Action Bar & Dock
- **Geometry**: Height strictly 48px–52px; continuous pill silhouette (`rounded-full`).
- **Surface**: `bg-white/8 backdrop-blur-xl border border-white/12`.
- **Interaction**: Inner shadow gradient illuminates faintly upon touch; press scale shifts smoothly to `0.97`.

### 2. Conversational Bubbles
- **AI Companion Bubble**:
  - Surface: Opaque-matte base `#17191F` accented with an ultra-delicate top border `rgba(228, 197, 212, 0.2)` and a soft lavender ambient trace.
  - Border Radius: `24px 24px 24px 6px`.
  - Text: `#F5F5F7`.
- **User Bubble**:
  - Surface: Glass substrate `rgba(194, 183, 255, 0.12)` enclosed by `border border-white/15`.
  - Border Radius: `24px 24px 6px 24px`.
  - Text: `#F5F5F7`.

### 3. Voice Input & Dynamic Presence Bar
- **Geometry**: Height 50px, full capsule, floating 16px above the home bar.
- **Sensory Indicator**: Dynamic audio waveform rendered in glowing `#C2B7FF` with a subtle pulsing halo (`box-shadow: 0 0 16px rgba(194, 183, 255, 0.2)`).
- **Secondary Actions**: Round 40px glass disc buttons for quick emotional reactions and camera inputs.

### 4. Interactive Chips & Mood Selector
- **Unselected**: Height 36px, `bg-white/5 border border-white/8 text-[#A2A5AF] rounded-full`.
- **Active / Selected**: Height 36px, `bg-gradient-to-r from-[#C2B7FF]/20 to-[#E4C5D4]/20 border border-[#C2B7FF]/40 text-[#F5F5F7] rounded-full`.

### 5. Floating Navigation Glass Bar
- **Structure**: Suspended detached dock (`mx-5 mb-4`), height 60px.
- **Glass Spec**: `backdrop-blur-2xl bg-[#121319]/60 border border-white/10 shadow-2xl rounded-full`.
- **Active Tab**: Capsule indicator gliding along the track using liquid spring physics, glowing with low-opacity lavender.