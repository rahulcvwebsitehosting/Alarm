# Alarm Vibrant Dark Design System

This document is the visual source of truth for the Flutter application.

## Personality

Vibrant dark minimalism: energetic but calm, content-first, stable, and
high-contrast. Color highlights primary actions and state without competing
with alarm readability.

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

- Rotate accents across repeated cards only as restrained state cues.
- Use one subtle elevation shadow and a one-pixel tonal border.
- Layer sparse dots and low-opacity radial glows over the cosmic background.
- Keep surfaces unrotated and free of oversized decorative typography.
- Keep body copy white or near-white; accents are for actions and status.
- Use Rubik Bold for display hierarchy and Rubik Regular for body text.

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
