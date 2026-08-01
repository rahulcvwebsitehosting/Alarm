# Alarm Dopamine Design System

This document is the visual source of truth for the Flutter application.

## Personality

Dark dopamine maximalism: energetic, joyful, deliberately asymmetric, and
high-contrast. Decoration must never reduce alarm readability or obscure a
primary action.

## Tokens

- Background: `#0D0D1A`
- Surface: `#21143B`
- Strong surface: `#2D1B4E`
- Foreground: `#FFFFFF`
- Magenta: `#FF3AF2`
- Cyan: `#00F5D4`
- Yellow: `#FFE600`
- Orange: `#FF6B35`
- Purple: `#7B2FFF`
- Danger: `#FF5263`
- Spacing: 4, 8, 16, 24, 32
- Radius: 14, 20, 28, pill
- Motion: 180 ms fast, 280 ms standard

The runtime definitions live in
`lib/theme/dopamine/dopamine_tokens.dart`. Do not duplicate raw colors in
feature widgets.

## Composition

- Rotate the five accents across repeated cards and navigation destinations.
- Pair accent backgrounds with a clashing border color.
- Use a maximum of three shadow layers: one glow and two hard offsets.
- Layer subtle dots, diagonal stripes, radial glows, and a few vector
  sparkles over the cosmic background.
- Use oversized translucent words only as excluded-semantics decoration.
- Keep body copy white or near-white; accents are for labels and decoration.
- Use Rubik ExtraBold for display hierarchy and Rubik Regular for body text.

## Native UX Guardrails

- Every touch target is at least 48 dp with visible pressed feedback.
- The bottom navigation contains four labeled top-level destinations and must
  remain compact on a 360 dp phone.
- Respect top/bottom safe areas and reserve list padding above floating actions.
- Continuous decorative motion stops when `disableAnimations` is enabled.
- Layouts must remain operable at 375 dp portrait, phone landscape, and tablet.
- Prefer wrapping to truncation; test large system text before release.
- Use Flutter vector icons, never emoji or raster icons for controls.
- Critical meaning must not rely on color alone.
