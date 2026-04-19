```markdown
# Design System: The Obsidian Veil

## 1. Overview & Creative North Star
### Creative North Star: "The Digital Vault"
In the enterprise security space, "trust" is often misidentified as "stiffness." This design system rejects the clinical, boxy nature of traditional password managers in favor of **The Digital Vault**—an experience that feels like a high-end physical safe illuminated by low-light instrumentation. 

We break the "template" look by leaning into **Tonal Depth** and **Glassmorphism**. Instead of a grid of borders, the UI is treated as a single fluid environment where information floats in a 3D space. Asymmetry is used intentionally: large, bold titles are offset against compact, high-density data lists to create an editorial rhythm that feels premium and custom-built for a 400x600px viewport.

---

## 2. Colors & Surface Hierarchy
This palette transitions from deep, oceanic slates to vibrant neon cyans, creating a high-contrast environment that demands focus on security actions.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined through background color shifts or tonal transitions. To separate a header from a list, transition from `surface` to `surface-container-low`.

### Surface Hierarchy & Nesting
Depth is achieved through the physical stacking of layers. 
- **Base Layer:** `surface` (#0c1324)
- **Primary Containers:** `surface-container-low` (#151b2d) for secondary grouping.
- **Interactive Elements:** `surface-container-high` (#23293c) for cards that require a "lift."
- **Nesting Logic:** Place a `surface-container-lowest` (#070d1f) input field inside a `surface-container-high` card to create an "etched-in" look without a single stroke.

### The "Glass & Gradient" Rule
Floating elements (Modals, Tooltips, Active Overlays) must use Glassmorphism:
- **Background:** `surface_variant` at 60% opacity.
- **Backdrop Blur:** 12px to 20px.
- **Signature Gradient:** Use a linear gradient from `primary` (#00daf3) to `on_primary_container` (#008e9f) for main CTAs to give them a "glowing" phosphor quality.

---

## 3. Typography
We use **Inter** to maintain a professional, Swiss-style clarity, but we apply it with editorial weight.

- **The Power of Scale:** Use `display-sm` for vault health scores or master status, contrasted immediately with `label-sm` for technical metadata. This massive delta in size creates a "Premium Dashboard" feel.
- **Functional Hierarchy:**
    - **Headlines:** `headline-sm` in `on_surface` for major navigation points.
    - **Body:** `body-md` in `on_surface_variant` for general data to reduce visual noise.
    - **Labels:** `label-md` in `primary` (all caps, 0.05em tracking) for category tags like "WORK" or "PERSONAL".

---

## 4. Elevation & Depth
### The Layering Principle
Do not use shadows to define structure; use them only to define **state**. A static card should have no shadow. A card being hovered or dragged should transition its background to `surface-container-highest` and gain an **Ambient Shadow**.

- **Ambient Shadows:** Extra-diffused. `x:0, y:8, blur:24, color: rgba(0, 218, 243, 0.08)`. This uses a tint of the `primary` color to simulate light refracting through glass.
- **The "Ghost Border" Fallback:** If accessibility requires a stroke, use `outline-variant` at 15% opacity. It should be felt, not seen.

---

## 5. Components

### Primary "Glow" Button
- **Base:** Gradient of `primary` to `on_primary_container`.
- **Corner Radius:** `md` (0.75rem).
- **State:** On hover, apply a `primary_fixed` outer glow (4px blur).
- **Typography:** `label-md` Bold, `on_primary` color.

### Password Cards (List Items)
- **Constraint:** Forbid divider lines.
- **Style:** Use `surface-container-low` background. On hover, shift to `surface-container-high`.
- **Padding:** 1rem (16px) vertical, 1.25rem (20px) horizontal.
- **Left Element:** A 40x40px rounded-md square using `secondary_container` with a `secondary` icon.

### Glass Input Fields
- **Base:** `surface-container-lowest`.
- **Interaction:** On focus, the "Ghost Border" (outline-variant) increases to 40% opacity, and a subtle `primary` inner glow appears.
- **Labels:** Floating `label-sm` in `on_surface_variant`.

### Vault "Health" Chip
- **Visuals:** `tertiary_container` background with `tertiary` text.
- **Radius:** `full`.
- **Usage:** Indicates security strength (e.g., "Leaked," "Weak," "Safe").

---

## 6. Do's and Don'ts

### Do
- **Do** use high-contrast typography sizes to create a sense of importance.
- **Do** allow the background color to bleed through via backdrop-blur on all overlays.
- **Do** use `primary` (neon cyan) sparingly as a surgical tool for the eye.
- **Do** leverage "Negative Space" as a divider. Let the eye rest between items.

### Don't
- **Don't** use pure black or pure white. Use the `surface` and `on_surface` tokens to maintain the "Deep Sea" atmosphere.
- **Don't** use 100% opaque borders. It breaks the illusion of glass.
- **Don't** use standard "drop shadows" (black with high opacity). They look "dirty" on deep blue backgrounds.
- **Don't** cram the 400x600px space. If the list is long, use a graceful fade-to-transparent at the bottom of the viewport using a `surface` gradient mask.

---

## 7. Signature Interaction: The "Haptic" Hover
When a user hovers over a vault item, the background shouldn't just change color; it should feel like it's lighting up from within. Use a subtle radial gradient `circle at mouse_position` that uses `primary` at 5% opacity to follow the cursor within the card. This "flashlight" effect reinforces the "Digital Vault" theme.```