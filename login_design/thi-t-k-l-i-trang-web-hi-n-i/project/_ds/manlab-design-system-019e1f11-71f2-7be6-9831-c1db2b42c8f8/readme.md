# ManLab Design System

A design system for **ManLab** — a laboratory & metrology management ERP for a Vietnamese testing/measurement institute (Viện Đo lường & Thử nghiệm). This system was authored to support the **P21 “Kiểm soát sự phù hợp”** (Conformity Control) module, whose job is to declare, evaluate, internally approve, and publicly publish the institute's measurement/testing capabilities, with a rigorous three-layer status model and ISO 17025-style evidence checklists.

> **Sources.** No codebase, Figma, logo, or brand assets were provided — only a detailed software-requirements spec (Thủ tục ETV.MP 21, Lần ban hành 02 / Bản 2026) for the P21 module. The visual direction here (institutional blue, slate neutrals, the status palette, the precision-gauge mark, Be Vietnam Pro + JetBrains Mono) was designed from scratch to fit an enterprise lab ERP and is open to revision once real brand assets exist. UI language is **Vietnamese**.

---

## Product context

ManLab is internal ERP software. The P21 module is used by four roles (RBAC): **Super Admin** (system config only — barred from professional data), **Lãnh đạo Viện** (institute leadership — final approval + digital signature), **Lãnh đạo phòng** (department head — review), and **Người thực hiện** (operator — creates records, maps devices, uploads evidence).

The defining concept is the **three independent-but-linked status layers**, every workflow screen surfaces them:
1. **Lớp 1 — Hồ sơ P21** (administrative record lifecycle): Nháp → Chờ soát xét → Đang đánh giá → Chờ phê duyệt → Đã phê duyệt nội bộ → Kết thúc.
2. **Lớp 2 — Đối tượng năng lực / PTĐ** (technical capability): Mới tạo → Đang đánh giá → Chưa đủ điều kiện / Đủ điều kiện nội bộ → Được công khai/Còn hiệu lực → Tạm dừng.
3. **Lớp 3 — Công bố / Thông báo** (external legal validity): Đang lập → Đã gửi → Đã công khai → Đang điều chỉnh → Hủy bỏ/Hết hiệu lực.

Data is **inherited (snapshot)** from the master menu “Danh mục phương tiện đo” — operators map devices/parameters rather than re-typing; on approval the technical fields are frozen. KPI gating is quantitative: data completeness ≥ 80% to submit, checklist score ≥ 85/100 **and** 100% of critical criteria “Đạt” to escalate for approval. Public capabilities expose a **QR lookup**.

---

## CONTENT FUNDAMENTALS — how ManLab writes

- **Language:** Vietnamese, with English names shown alongside technical objects (bilingual: *Tên tiếng Việt / English Name*), because accreditation scopes are bilingual.
- **Register:** formal, institutional, precise. This is regulated metrology — copy reads like procedure, not marketing. No exclamation marks, no hype.
- **Person:** impersonal/system voice. The software is the actor: “Hệ thống tự động chuyển trạng thái…”, “Hệ thống tự động khóa…”. Addressing the user is rare and neutral. Avoid “bạn”.
- **Domain vocabulary is fixed** — use the spec's exact terms, they are legal/technical: *phương tiện đo, độ không đảm bảo đo (U), sai số cho phép lớn nhất (MPE), giới hạn phát hiện/định lượng (LOD/LOQ), cấp chính xác, soát xét, phê duyệt nội bộ, công bố, thông báo, hậu kiểm, trọng yếu (Critical), tạm dừng*.
- **Status labels are nouns/short phrases**, sentence case in Vietnamese: “Đủ điều kiện nội bộ”, “Còn hiệu lực”, “Tạm dừng”. Never invent new status wording — it maps 1:1 to the state machine.
- **Numbers & codes are exact and monospaced:** record IDs `P21-2026-001`, object codes `P21.MT.042`, values `U = 8.5% (k=2)`, `MPE ±0.02%`, `LOD 2 mg/L`. Keep units attached.
- **Casing:** UI labels in sentence case; tiny eyebrow/column headers in UPPERCASE with wide tracking. Buttons are imperative verb phrases: “Trình soát xét”, “Ký số”, “Thêm đối tượng từ Danh mục PTĐ”.
- **No emoji** anywhere in product UI. Tone is trustworthy, calm, audit-ready.

---

## VISUAL FOUNDATIONS

**Overall vibe:** a modern technical SaaS with institutional trust — crisp, data-dense, calm. Hairline borders and soft cool-tinted shadows do the structural work; color is reserved almost entirely for **status meaning**.

- **Color.** Institutional **blue** (`--brand` = blue-600 `#1C50C9`) is the single action/brand color. Neutrals are a faintly-blue **slate** ramp (lab-grade, never warm gray). A **teal** accent (`--accent` = teal-600) is reserved for “verified / public / live” (the QR portal, Còn hiệu lực). The **status palette is the heart of the system** and is locked: gray=draft, amber=pending, blue=in-progress, violet=review, green=approved, teal=public/live, orange=suspended (recoverable), red=rejected/terminal. One color = one meaning across all three status layers. See `tokens/colors.css`.
- **Type.** **Be Vietnam Pro** (full Vietnamese diacritic coverage) for everything UI + display; **JetBrains Mono** for codes, IDs, and measured values. Base size 14px (ERP density). Display is extrabold with tight tracking; body is regular; eyebrows are 11px uppercase, 0.06em tracking. See `tokens/typography.css`.
- **Spacing.** 4px base grid. Comfortable-but-dense: control heights 28/34/42px, page gutter 32px. See `tokens/spacing.css`.
- **Radii.** Small and technical: controls 7px, cards 10px, panels 14px, pills 999px. Nothing is heavily rounded.
- **Borders.** 1px hairlines (`--border-subtle/-default`) are the primary separators — tables, cards, and panels lean on borders far more than shadow.
- **Shadows / elevation.** Soft, low, cool-tinted (rgba of slate-950). `--shadow-sm` for resting cards, `--shadow-md` on hover, `--shadow-xl` for modals. No heavy or colored drop shadows. No glow.
- **Backgrounds.** Flat. Page = slate-50, surfaces = white, sunken/inset = slate-100/25. **No gradients**, no textures, no decorative imagery. The dark sidebar (slate-900) is the one strong field.
- **Cards.** White, 1px subtle border, 10px radius, `--shadow-sm`. Optional 3px left **accent bar** colored by a status `-solid` token. Optional header with eyebrow/title/subtitle + right-aligned actions.
- **Animation.** Quick and precise — 120–180ms, standard/`ease-out` curves, **no bounce**. Status dots may `pulse` (a subtle ping) only for live/active states (Đang đánh giá, Còn hiệu lực). Respect reduced-motion.
- **Hover/press.** Hover = a step-darker fill (primary) or slate-100 wash (secondary/ghost); cards lift 1px + `shadow-md`. Press = the next-darker token. Focus = 3px soft-blue ring (`--ring`). No scale-shrink.
- **Transparency/blur.** Used sparingly — only the modal scrim (`rgba(12,17,27,.5)` + 2px blur).
- **Imagery.** None by default; this is a records system. Where a person is needed, use the initials `Avatar` (deterministic hue), not photos.

---

## ICONOGRAPHY

- **Set:** [**Lucide**](https://lucide.dev) — linked from CDN in specimen cards (`lucide@0.456.0`) and inlined as path data in the UI kit (`ui_kits/manlab-p21/icons.jsx` → `window.MLIcon`). Lucide's outline style (1.75px stroke, rounded caps, `currentColor`) matches the precise/technical aesthetic.
- **Stroke weight 1.75**, size 18px default (16px inside buttons, 20–24px for feature glyphs). Icons inherit text color via `currentColor`.
- **Domain mapping** (see the Iconography card): `gauge` = phương tiện đo, `beaker`/`flask-conical` = thử nghiệm, `microscope` = quan trắc, `clipboard-check` = hồ sơ, `shield-check` = đủ điều kiện, `file-signature` = ký số, `qr-code` = công khai, `lock` = tạm dừng, `circle-check`/`circle-x` = đạt/không đạt, `triangle-alert` = cảnh báo, `history` = nhật ký.
- **No emoji** and **no Unicode-glyph icons** in product UI. The only “drawn” marks are the logo (`assets/logo-mark.svg`, a precision-gauge monogram) and the decorative faux-QR matrix in the public lookup mock.
- If you need icons beyond the inlined set, pull them from Lucide (same stroke/style) — do not mix icon families.

> **Substitution flag:** the icon set (Lucide) and both fonts (Be Vietnam Pro, JetBrains Mono) are stand-ins chosen to fit the brief, loaded from CDN. Swap them if the institute has mandated typefaces/marks.

---

## Index / manifest

**Root**
- `styles.css` — global entry point (import this). `@import`s the token + base files below.
- `readme.md` — this guide.
- `SKILL.md` — Agent-Skill front-matter for use in Claude Code.

**`tokens/`** — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `elevation.css`, `base.css`.

**`components/`** — React primitives (each: `.jsx` + `.d.ts` + `.prompt.md` + a directory `@dsCard` HTML). Exposed on `window.ManLabDesignSystem_019e1f`.
- `forms/` — **Button**, **IconButton**, **Input**, **Select**, **Checkbox**, **SegmentedControl**
- `feedback/` — **StatusBadge** (the three-layer chip), **ProgressMeter** (KPI gauge)
- `data-display/` — **Card**, **Tag**, **Avatar**
- `navigation/` — **Tabs**

**`guidelines/`** — foundation specimen cards: type scale, font families, brand/slate/status/semantic colors, spacing scale, radius & elevation, logo lockup, iconography.

**`assets/`** — `logo-mark.svg` (precision-gauge monogram).

**`ui_kits/manlab-p21/`** — high-fidelity click-through of the P21 module: dashboard/record list, object declaration (+ mapping modal), evaluation checklist (live KPI gating), public QR lookup. See its own `README.md`.
