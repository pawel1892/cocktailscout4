---
name: ds
description: CocktailScout design system rules for UI work. Use when the user types /ds, asks for CocktailScout design-system guidance, or edits/views/reviews any CocktailScout Rails view, partial, component, Tailwind class, UI styling, or frontend layout. Enforces Tailwind-first implementation, cs-* color tokens only, DRY component reuse, and design-system page consistency.
---

# CocktailScout Design System

Activate this context before working on any view, partial, component, Tailwind classes, UI styling, or frontend layout in the CocktailScout project.

## Core Rules

1. Use only `cs-*` color tokens. Do not use Tailwind built-in colors such as `gray-500`, `blue-600`, or `red-700`, and do not hardcode hex values. Exceptions: rank badge colors (`.rank-N-color/bg`) and one-off special effects such as multi-stop gradients that cannot be expressed with tokens.
2. Prefer Tailwind utilities. Add custom CSS only for rare effects such as complex shadows, gradients, or transforms. If the rare effect appears more than once, extract it to a component class.
3. Extract repeating visual patterns. If a visual pattern repeats across two or more places, put it in `app/frontend/stylesheets/design_system.css` for design-system-only chrome or `app/frontend/entrypoints/application.css` for project-wide components.
4. Keep `app/views/design_system/index.html.erb` bare. It should show components in stock form, with no extra one-off styling layered on top.
5. Use existing components on every page. Bespoke markup is acceptable only when an existing component genuinely does not fit.

## Color Tokens

Tokens are defined in the `@theme` block in `app/frontend/entrypoints/application.css`.

| Scale | Purpose | Steps |
|---|---|---|
| `cs-red` | Oxblood primary brand | 50 100 200 300 400 500 600 700 800 900 950 |
| `cs-gold` | Brass accent and premium | 50 100 200 300 400 500 600 700 800 900 950 |
| `cs-ink` | Warm neutral text, borders, surfaces | 50 100 200 300 400 500 600 700 800 900 950 |
| `cs-blue` | Links and info | 50 100 200 300 400 500 600 700 800 900 950 |
| `cs-success` | Green feedback | 50 100 400 500 700 900 |
| `cs-warning` | Amber feedback | 50 100 400 500 700 900 |
| `cs-error` | Red feedback | 50 100 400 500 700 900 |

Common roles:

- Page background: `bg-cs-ink-50`
- Body text: `text-cs-ink-800`
- Muted or label text: `text-cs-ink-500` or `text-cs-ink-400`
- Borders: `border-cs-ink-200` for subtle, `border-cs-ink-300` for stronger
- Brand heading: `text-cs-red-900`
- Accent/highlight: `text-cs-gold-400` or `text-cs-gold-600`
- Links: `text-cs-blue-600`

## Typography

| Role | Classes | Font |
|---|---|---|
| Display heading | `font-display font-semibold text-[54px] leading-none tracking-tight text-cs-red-900` | Cormorant Garamond |
| H1 / Hero | `font-display font-semibold text-[38px] leading-tight tracking-tight text-cs-red-900` | Cormorant Garamond |
| H2 | `font-display font-semibold text-[28px] leading-tight text-cs-red-900` | Cormorant Garamond |
| H3 / Card title | `font-sans font-bold text-[18px] text-cs-ink-900` | Inter |
| Body | `font-sans font-normal text-[15px] leading-relaxed text-cs-ink-800` | Inter |
| Small / meta | `font-sans text-[13px] text-cs-ink-600` | Inter |
| Mono / stat | `font-mono font-medium text-[13px] text-cs-ink-700` | JetBrains Mono |
| Eyebrow label | `font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-500` | Inter |

Use `.hero-h1` for fluid hero headings.

## Components

### Buttons

Always combine `.btn` with a variant.

| Class | Use |
|---|---|
| `.btn.btn-primary` | Primary CTA, oxblood |
| `.btn.btn-gold` | Accent CTA, brass, for dark surfaces |
| `.btn.btn-outline` | Secondary, transparent with oxblood border |
| `.btn.btn-outline-gold` | Secondary on dark, transparent with gold border |
| `.btn.btn-soft` | Soft red tertiary on light |
| `.btn.btn-ghost` | Ghost for light surfaces |
| `.btn.btn-ghost-dark` | Ghost for dark or oxblood surfaces |
| `.btn.btn-danger` | Destructive action |
| `.btn.btn-link` | Text-style blue button |
| `.btn.btn-sm` | Small size modifier |
| `.btn.btn-lg` | Large size modifier |
| `.btn-group` | Segmented control wrapper; `button[aria-pressed="true"]` is active |

For loading state, add `.btn-loading`, `disabled`, and `aria-busy="true"`. The spinner appears through `::before`; update the label to the in-progress action.

```html
<button class="btn btn-primary btn-loading" disabled aria-busy="true">Speichert...</button>
```

### Cards

| Class | Use |
|---|---|
| `.card` | Base white container with border, shadow, and flex column |
| `.card-header` | Top section with title and optional action |
| `.card-body` | Main content area |
| `.card-footer` | Bottom metadata row |
| `.card-label` | Mono label inside header |
| `.card-elevated` | Borderless clickable tile with hover lift |
| `.card-ghost` | Dashed empty-state card |
| `.card-gold` | Warm brass gradient for editorial or premium content |
| `.card-dark` | Inverted oxblood stat tile or promo |

Specific card classes:

- `.cocktail-card` for recipe list rows with 108px thumbnail grid
- `.card-b` for homepage recipe cards with 140px thumbnail grid and hover lift
- `.news-card` for article cards with date line
- `.about-side` for sidebar info blocks

### Tags And Labels

Variant classes include the `.tag` base styles; do not add `.tag` explicitly.

| Class | Use |
|---|---|
| `.tag-primary` | Dark oxblood brand with gold text |
| `.tag-gold` | Dark brass accent |
| `.tag-primary-soft` | Soft red |
| `.tag-gold-soft` | Soft brass |
| `.tag-neutral` | Gray-neutral status |
| `.tag-info` | Blue information |
| `.tag-success` | Green status |
| `.tag-warning` | Amber status |
| `.tag-error` | Red status |
| `.tag-light-blue` | Light blue category |
| `.tag-mini` | Compact uppercase mono label |

Choose tag colors semantically:

- `tag-neutral`: smoke, peat, savory, neutral, gray, earthy
- `tag-light-blue`: citrus, cucumber, salty, maritime, floral-blue
- `tag-gold-soft`: caramel, vanilla, honey, spice, warm, sweet
- `tag-info`: informational blue, light botanical, herbal-blue
- `tag-primary-soft`: very light red; avoid in dense tables unless intentional
- `tag-success`, `tag-warning`, `tag-error`: status only, not flavor

### Links

| Class | Use |
|---|---|
| `.link` | Default inline link, blue, border-bottom on hover |
| `.link.link-underline` | Persistent underline |
| `.link.link-muted` | Breadcrumbs or footer |
| `.link-arrow` | Standalone "see all" link |
| `.link.link-danger` | Destructive inline link |
| `.link.link-on-dark` | Gold link on oxblood surface |

### Callouts

Use `<div class="callout[-variant]"><i class="fa-..."></i><div>content</div></div>`.

| Class | Use |
|---|---|
| `.callout` | Neutral info |
| `.callout-gold` | Pro tip or premium advice |
| `.callout-red` | Important warning |
| `.callout-info` | Community note |
| `.callout-success` | Confirmation |
| `.callout-warning` | Caution |

### Forms

| Class | Use |
|---|---|
| `.input-field` | Text input, select, or textarea |
| `.label-field` | Label above input |
| `.form-group` | Label, input, and hint wrapper |
| `.input-error` | Error state on `.input-field` |
| `.label-error` | Error state on `.label-field` |
| `.form-error-message` | Error text below input or choice group |
| `.form-hint` | Hint text below input |
| `.check-field` | Checkbox input |
| `.radio-field` | Radio input |
| `.check-label` | Label wrapper for check/radio |
| `.check-field-error` | Error modifier for checkbox or radio |

```html
<label class="check-label">
  <input type="checkbox" class="check-field">
  Label text
</label>

<label class="check-label text-cs-error-700">
  <input type="checkbox" class="check-field check-field-error">
  Label text
</label>
```

Use native `disabled`; all form elements are styled automatically.

### Tables

| Class | Use |
|---|---|
| `.table-container` | Scrollable wrapper with border and shadow |
| `.table-standard` | Table base |
| `.table-body` | `tbody` with row dividers |
| `.table-th` | Header cell; add `text-right` for numeric columns |
| `.table-td` | Body cell; add `text-right font-mono` for numbers |
| `.table-tr-hover` | Hover highlight on row |

## Spacing And Layout

Base unit is 4px. Use standard Tailwind spacing tokens.

Component spacing is already baked in; do not override it:

| Component | Baked-in spacing |
|---|---|
| `.btn` | `py-[10px] px-[18px]` |
| `.btn-sm` | `py-1.5 px-3` |
| `.btn-lg` | `py-[13px] px-[22px]` |
| `.input-field` | `px-3 py-2` |
| `.label-field` | `mb-1.5` |
| `.card-header` | `px-[18px] py-[14px]` |
| `.card-body` | `p-[18px]` |
| `.card-footer` | `px-[18px] py-[10px]` |

Manual spacing is for page layout only:

| Pattern | Token |
|---|---|
| Tags inline | `gap-1` |
| Button groups and form rows | `gap-2` |
| Stacked form fields | `gap-4` |
| Card grids | `gap-6` |
| Section margin | `mb-12` or `mb-20` |

Standard grid layouts:

- `grid grid-cols-1` for detail pages, articles, forms
- `grid grid-cols-2` for split panels, settings, ingredient tables
- `grid grid-cols-3` for recipe card grids, feature rows
- `grid grid-cols-4` for dense thumbnail grids

Standard container widths:

- `max-w-sm` 384px: modals, narrow forms
- `max-w-md` 448px: auth pages
- `max-w-xl` 576px: article body text
- `max-w-2xl` 672px: cards, form content
- `max-w-4xl` 896px: content plus sidebar
- `max-w-7xl` 1280px: full page wrapper

## Misc Utilities

| Class | Use |
|---|---|
| `.rating-chip` | Score badge base |
| `.rating-chip-high` | Green, 7 or higher |
| `.rating-chip-mid` | Gold, 4 to 7 |
| `.rating-chip-low` | Red, below 4 |
| `.meta-chip` | Inline mono metadata pill |
| `.prose-cs` | Markdown prose container |
| `.md-quote` | Markdown blockquote with gold left border |

## CSS Custom Properties

Available everywhere:

```css
--cs-radius-sm: 4px;
--cs-radius: 6px;
--cs-radius-lg: 10px;
--cs-radius-xl: 16px;
--cs-shadow-xs;
--cs-shadow-sm;
--cs-shadow-md;
--cs-shadow-lg;
```

Use with arbitrary values such as `shadow-[var(--cs-shadow-md)]`, or reference in custom CSS only when custom CSS is justified.

## Exceptions

| Exception | Condition |
|---|---|
| Hardcoded hex color | Only rank badge colors (`.rank-N-color/bg`) |
| Arbitrary Tailwind value | Pixel-precise sizes such as `text-[13px]` or `px-[18px]` when no token fits |
| Custom CSS class | Rare complex effect; if it repeats at least twice, extract it |
| Tailwind built-in color | Never; map to the nearest `cs-*` token |

## Key Files

| File | Purpose |
|---|---|
| `app/frontend/entrypoints/application.css` | `@theme` tokens and `@utility` component classes |
| `app/frontend/stylesheets/design_system.css` | Design-system page chrome only |
| `app/views/design_system/index.html.erb` | Living reference with stock component examples |
