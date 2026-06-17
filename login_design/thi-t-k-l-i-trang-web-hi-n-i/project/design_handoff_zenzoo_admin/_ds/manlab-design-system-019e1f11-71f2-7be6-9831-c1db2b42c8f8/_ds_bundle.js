/* @ds-bundle: {"format":3,"namespace":"ManLabDesignSystem_019e1f","components":[{"name":"Avatar","sourcePath":"components/data-display/Avatar.jsx"},{"name":"Card","sourcePath":"components/data-display/Card.jsx"},{"name":"Tag","sourcePath":"components/data-display/Tag.jsx"},{"name":"ProgressMeter","sourcePath":"components/feedback/ProgressMeter.jsx"},{"name":"StatusBadge","sourcePath":"components/feedback/StatusBadge.jsx"},{"name":"Button","sourcePath":"components/forms/Button.jsx"},{"name":"Checkbox","sourcePath":"components/forms/Checkbox.jsx"},{"name":"IconButton","sourcePath":"components/forms/IconButton.jsx"},{"name":"Input","sourcePath":"components/forms/Input.jsx"},{"name":"SegmentedControl","sourcePath":"components/forms/SegmentedControl.jsx"},{"name":"Select","sourcePath":"components/forms/Select.jsx"},{"name":"Tabs","sourcePath":"components/navigation/Tabs.jsx"}],"sourceHashes":{"components/data-display/Avatar.jsx":"2b60423d39c2","components/data-display/Card.jsx":"b8e3f233eecf","components/data-display/Tag.jsx":"cd38eeb4d915","components/feedback/ProgressMeter.jsx":"3d62e5a2014d","components/feedback/StatusBadge.jsx":"560bf9005ae8","components/forms/Button.jsx":"a7b29cf31378","components/forms/Checkbox.jsx":"d72498ad030c","components/forms/IconButton.jsx":"ac0a597a1305","components/forms/Input.jsx":"53c59fd728d7","components/forms/SegmentedControl.jsx":"c1279fa78136","components/forms/Select.jsx":"573c816b498d","components/navigation/Tabs.jsx":"a97c11734338","ui_kits/manlab-p21/ChecklistScreen.jsx":"506951ff3a55","ui_kits/manlab-p21/DashboardScreen.jsx":"e7def6e6efa7","ui_kits/manlab-p21/DeclarationScreen.jsx":"73ceff2fcc0e","ui_kits/manlab-p21/PublicLookupScreen.jsx":"5604fc1887fd","ui_kits/manlab-p21/Shell.jsx":"f4dfb0ce66a0","ui_kits/manlab-p21/app.jsx":"2a7870e3983f","ui_kits/manlab-p21/data.jsx":"e9f774061524","ui_kits/manlab-p21/icons.jsx":"e071c9f0b185"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.ManLabDesignSystem_019e1f = window.ManLabDesignSystem_019e1f || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/data-display/Avatar.jsx
try { (() => {
/** ManLab Avatar — initials chip for people (Lãnh đạo Viện, Người thực hiện…). */
function Avatar({
  name = '',
  size = 'md',
  src = null,
  role = null
}) {
  const dims = {
    xs: 22,
    sm: 28,
    md: 36,
    lg: 44
  };
  const fonts = {
    xs: 'var(--text-2xs)',
    sm: 'var(--text-xs)',
    md: 'var(--text-sm)',
    lg: 'var(--text-md)'
  };
  const d = dims[size] || 36;
  const initials = name.trim().split(/\s+/).slice(-2).map(w => w[0]).join('').toUpperCase().slice(0, 2);
  // Deterministic hue from name
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  const palettes = [['var(--blue-100)', 'var(--blue-700)'], ['var(--teal-100)', 'var(--teal-700)'], ['var(--violet-100)', 'var(--violet-700)'], ['var(--amber-100)', 'var(--amber-700)'], ['var(--green-100)', 'var(--green-700)']];
  const [bg, fg] = palettes[Math.abs(hash) % palettes.length];
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: role ? 9 : 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: d,
      height: d,
      flexShrink: 0,
      borderRadius: '50%',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      font: `var(--fw-semibold) ${fonts[size]}/1 var(--font-sans)`,
      color: src ? 'transparent' : fg,
      background: bg,
      backgroundImage: src ? `url(${src})` : 'none',
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      border: 'var(--bw-hair) solid color-mix(in srgb, currentColor 12%, transparent)'
    }
  }, !src && (initials || '?')), role && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-label)',
      color: 'var(--text-strong)',
      whiteSpace: 'nowrap'
    }
  }, name), /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-caption)',
      color: 'var(--text-muted)',
      whiteSpace: 'nowrap'
    }
  }, role)));
}
Object.assign(__ds_scope, { Avatar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/Avatar.jsx", error: String((e && e.message) || e) }); }

// components/data-display/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** ManLab Card — surface container with optional header, accent, and padding control. */
function Card({
  children,
  title,
  subtitle,
  eyebrow,
  actions,
  accent = null,
  padding = 'md',
  hover = false,
  style = {},
  ...rest
}) {
  const pads = {
    none: 0,
    sm: 'var(--space-6)',
    md: 'var(--space-8)',
    lg: 'var(--space-9)'
  };
  const [hovered, setHovered] = React.useState(false);
  const hasHeader = title || subtitle || eyebrow || actions;
  return /*#__PURE__*/React.createElement("div", _extends({
    onMouseEnter: () => hover && setHovered(true),
    onMouseLeave: () => hover && setHovered(false),
    style: {
      position: 'relative',
      background: 'var(--surface-card)',
      border: 'var(--bw-hair) solid var(--border-subtle)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: hovered ? 'var(--shadow-md)' : 'var(--shadow-sm)',
      overflow: 'hidden',
      transition: 'box-shadow var(--dur-base) var(--ease-standard), transform var(--dur-base) var(--ease-standard)',
      transform: hovered ? 'translateY(-1px)' : 'none',
      ...style
    }
  }, rest), accent && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      insetInlineStart: 0,
      top: 0,
      bottom: 0,
      width: 3,
      background: accent
    }
  }), hasHeader && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      gap: 'var(--space-6)',
      padding: `var(--space-6) ${typeof pads[padding] === 'string' ? pads[padding] : '16px'}`,
      paddingBottom: 'var(--space-5)',
      borderBottom: 'var(--bw-hair) solid var(--border-subtle)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: '3px',
      minWidth: 0
    }
  }, eyebrow && /*#__PURE__*/React.createElement("span", {
    className: "eyebrow"
  }, eyebrow), title && /*#__PURE__*/React.createElement("h3", {
    style: {
      font: 'var(--type-h3)',
      color: 'var(--text-strong)'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-caption)',
      color: 'var(--text-muted)'
    }
  }, subtitle)), actions && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 'var(--space-4)',
      flexShrink: 0
    }
  }, actions)), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: pads[padding]
    }
  }, children));
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/Card.jsx", error: String((e && e.message) || e) }); }

// components/data-display/Tag.jsx
try { (() => {
/** ManLab Tag — neutral metadata label (categories, units, codes). For status use StatusBadge. */
function Tag({
  children,
  tone = 'neutral',
  icon = null,
  mono = false,
  size = 'md',
  onRemove = null
}) {
  const tones = {
    neutral: {
      fg: 'var(--slate-600)',
      bg: 'var(--slate-100)',
      bd: 'var(--slate-200)'
    },
    brand: {
      fg: 'var(--blue-700)',
      bg: 'var(--blue-50)',
      bd: 'var(--blue-100)'
    },
    accent: {
      fg: 'var(--teal-700)',
      bg: 'var(--teal-50)',
      bd: 'var(--teal-100)'
    },
    outline: {
      fg: 'var(--text-body)',
      bg: 'transparent',
      bd: 'var(--border-default)'
    }
  };
  const t = tones[tone] || tones.neutral;
  const z = size === 'sm' ? {
    pad: '1px 7px',
    font: 'var(--text-2xs)'
  } : {
    pad: '3px 9px',
    font: 'var(--text-xs)'
  };
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 5,
      padding: z.pad,
      font: `${mono ? `var(--fw-medium) ${z.font}/1 var(--font-mono)` : `var(--fw-medium) ${z.font}/1 var(--font-sans)`}`,
      color: t.fg,
      background: t.bg,
      border: `var(--bw-hair) solid ${t.bd}`,
      borderRadius: 'var(--radius-sm)',
      whiteSpace: 'nowrap'
    }
  }, icon && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      flexShrink: 0
    }
  }, icon), children, onRemove && /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onRemove,
    "aria-label": "X\xF3a",
    style: {
      display: 'inline-flex',
      border: 'none',
      background: 'none',
      padding: 0,
      marginInlineStart: 1,
      cursor: 'pointer',
      color: 'currentColor',
      opacity: 0.6
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "12",
    viewBox: "0 0 24 24",
    stroke: "currentColor",
    strokeWidth: "2.4",
    strokeLinecap: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M18 6 6 18M6 6l12 12"
  }))));
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/Tag.jsx", error: String((e && e.message) || e) }); }

// components/feedback/ProgressMeter.jsx
try { (() => {
/**
 * ManLab ProgressMeter — KPI / completion gauge used across P21
 * (data completeness ≥80%, checklist score ≥85/100). Color reflects
 * pass/warn/fail against an optional threshold.
 */
function ProgressMeter({
  value = 0,
  max = 100,
  threshold = null,
  label,
  showValue = true,
  unit = '',
  size = 'md'
}) {
  const pct = Math.max(0, Math.min(100, value / max * 100));
  const passes = threshold == null ? null : value >= threshold;
  const color = passes == null ? 'var(--brand)' : passes ? 'var(--green-500)' : pct >= 60 ? 'var(--amber-500)' : 'var(--red-500)';
  const heights = {
    sm: 5,
    md: 8,
    lg: 12
  };
  const h = heights[size] || 8;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: '6px',
      width: '100%'
    }
  }, (label || showValue) && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'baseline',
      gap: 12
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-label)',
      color: 'var(--text-body)'
    }
  }, label), showValue && /*#__PURE__*/React.createElement("span", {
    style: {
      font: `var(--fw-semibold) var(--text-sm)/1 var(--font-mono)`,
      color
    }
  }, value, unit, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-faint)',
      fontWeight: 400
    }
  }, ` / ${max}${unit}`))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      width: '100%',
      height: h,
      background: 'var(--surface-sunken)',
      borderRadius: 'var(--radius-pill)',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: `${pct}%`,
      height: '100%',
      background: color,
      borderRadius: 'var(--radius-pill)',
      transition: 'width var(--dur-slow) var(--ease-out)'
    }
  }), threshold != null && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: -2,
      bottom: -2,
      left: `${threshold / max * 100}%`,
      width: 2,
      background: 'var(--slate-500)',
      opacity: 0.55
    },
    title: `Ngưỡng ${threshold}${unit}`
  })));
}
Object.assign(__ds_scope, { ProgressMeter });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/ProgressMeter.jsx", error: String((e && e.message) || e) }); }

// components/feedback/StatusBadge.jsx
try { (() => {
/**
 * ManLab StatusBadge — the canonical chip for P21's three-layer status model.
 * `status` maps to a semantic token group; default Vietnamese labels are built in
 * but can be overridden with `children`.
 */
const STATUS = {
  draft: {
    fg: 'var(--status-draft-fg)',
    bg: 'var(--status-draft-bg)',
    bd: 'var(--status-draft-border)',
    dot: 'var(--status-draft-solid)',
    label: 'Nháp'
  },
  pending: {
    fg: 'var(--status-pending-fg)',
    bg: 'var(--status-pending-bg)',
    bd: 'var(--status-pending-border)',
    dot: 'var(--status-pending-solid)',
    label: 'Chờ soát xét'
  },
  progress: {
    fg: 'var(--status-progress-fg)',
    bg: 'var(--status-progress-bg)',
    bd: 'var(--status-progress-border)',
    dot: 'var(--status-progress-solid)',
    label: 'Đang đánh giá'
  },
  review: {
    fg: 'var(--status-review-fg)',
    bg: 'var(--status-review-bg)',
    bd: 'var(--status-review-border)',
    dot: 'var(--status-review-solid)',
    label: 'Chờ phê duyệt'
  },
  approved: {
    fg: 'var(--status-approved-fg)',
    bg: 'var(--status-approved-bg)',
    bd: 'var(--status-approved-border)',
    dot: 'var(--status-approved-solid)',
    label: 'Đủ điều kiện nội bộ'
  },
  public: {
    fg: 'var(--status-public-fg)',
    bg: 'var(--status-public-bg)',
    bd: 'var(--status-public-border)',
    dot: 'var(--status-public-solid)',
    label: 'Còn hiệu lực'
  },
  suspended: {
    fg: 'var(--status-suspended-fg)',
    bg: 'var(--status-suspended-bg)',
    bd: 'var(--status-suspended-border)',
    dot: 'var(--status-suspended-solid)',
    label: 'Tạm dừng'
  },
  rejected: {
    fg: 'var(--status-rejected-fg)',
    bg: 'var(--status-rejected-bg)',
    bd: 'var(--status-rejected-border)',
    dot: 'var(--status-rejected-solid)',
    label: 'Hủy bỏ'
  }
};
function StatusBadge({
  status = 'draft',
  children,
  size = 'md',
  dot = true,
  pulse = false
}) {
  const s = STATUS[status] || STATUS.draft;
  const sizes = {
    sm: {
      pad: '2px 7px 2px 6px',
      font: 'var(--text-2xs)',
      dotSize: 5,
      gap: 5
    },
    md: {
      pad: '3px 9px 3px 8px',
      font: 'var(--text-xs)',
      dotSize: 6,
      gap: 6
    }
  };
  const z = sizes[size] || sizes.md;
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: z.gap,
      padding: z.pad,
      borderRadius: 'var(--radius-pill)',
      font: `var(--fw-semibold) ${z.font}/1 var(--font-sans)`,
      letterSpacing: 'var(--ls-snug)',
      whiteSpace: 'nowrap',
      color: s.fg,
      background: s.bg,
      border: `var(--bw-hair) solid ${s.bd}`
    }
  }, dot && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'relative',
      display: 'inline-flex',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: z.dotSize,
      height: z.dotSize,
      borderRadius: '50%',
      background: s.dot,
      display: 'block'
    }
  }), pulse && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: '50%',
      background: s.dot,
      animation: 'manlab-ping 1.6s var(--ease-out) infinite'
    }
  })), children || s.label, pulse && /*#__PURE__*/React.createElement("style", null, '@keyframes manlab-ping{0%{transform:scale(1);opacity:.6}70%,100%{transform:scale(2.4);opacity:0}}'));
}
Object.assign(__ds_scope, { StatusBadge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/StatusBadge.jsx", error: String((e && e.message) || e) }); }

// components/forms/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ManLab Button — primary action control.
 * Variants: primary | secondary | ghost | danger | success
 * Sizes: sm | md | lg
 */
function Button({
  children,
  variant = 'primary',
  size = 'md',
  iconLeft = null,
  iconRight = null,
  block = false,
  disabled = false,
  type = 'button',
  ...rest
}) {
  const heights = {
    sm: 'var(--control-sm)',
    md: 'var(--control-md)',
    lg: 'var(--control-lg)'
  };
  const pads = {
    sm: '0 10px',
    md: '0 14px',
    lg: '0 20px'
  };
  const fonts = {
    sm: 'var(--text-sm)',
    md: 'var(--text-base)',
    lg: 'var(--text-md)'
  };
  const palettes = {
    primary: {
      bg: 'var(--brand)',
      bgHover: 'var(--brand-hover)',
      bgActive: 'var(--brand-active)',
      fg: 'var(--text-on-brand)',
      bd: 'transparent'
    },
    success: {
      bg: 'var(--green-600)',
      bgHover: 'var(--green-700)',
      bgActive: 'var(--green-700)',
      fg: '#fff',
      bd: 'transparent'
    },
    danger: {
      bg: 'var(--red-600)',
      bgHover: 'var(--red-700)',
      bgActive: 'var(--red-700)',
      fg: '#fff',
      bd: 'transparent'
    },
    secondary: {
      bg: 'var(--surface-card)',
      bgHover: 'var(--surface-hover)',
      bgActive: 'var(--surface-active)',
      fg: 'var(--text-strong)',
      bd: 'var(--border-default)'
    },
    ghost: {
      bg: 'transparent',
      bgHover: 'var(--surface-hover)',
      bgActive: 'var(--surface-active)',
      fg: 'var(--text-body)',
      bd: 'transparent'
    }
  };
  const p = palettes[variant] || palettes.primary;
  const [state, setState] = React.useState('rest');
  const bg = disabled ? undefined : state === 'active' ? p.bgActive : state === 'hover' ? p.bgHover : p.bg;
  const style = {
    display: block ? 'flex' : 'inline-flex',
    width: block ? '100%' : undefined,
    alignItems: 'center',
    justifyContent: 'center',
    gap: '7px',
    height: heights[size],
    padding: pads[size],
    font: `var(--fw-semibold) ${fonts[size]}/1 var(--font-sans)`,
    letterSpacing: 'var(--ls-snug)',
    color: disabled ? 'var(--text-faint)' : p.fg,
    background: disabled ? 'var(--surface-sunken)' : bg,
    border: `var(--bw-hair) solid ${disabled ? 'var(--border-subtle)' : p.bd}`,
    borderRadius: 'var(--radius-md)',
    cursor: disabled ? 'not-allowed' : 'pointer',
    whiteSpace: 'nowrap',
    transition: 'var(--transition-control)',
    boxShadow: variant === 'secondary' && !disabled ? 'var(--shadow-xs)' : 'none'
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: type,
    disabled: disabled,
    style: style,
    onMouseEnter: () => setState('hover'),
    onMouseLeave: () => setState('rest'),
    onMouseDown: () => setState('active'),
    onMouseUp: () => setState('hover')
  }, rest), iconLeft && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      flexShrink: 0
    }
  }, iconLeft), children, iconRight && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      flexShrink: 0
    }
  }, iconRight));
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Button.jsx", error: String((e && e.message) || e) }); }

// components/forms/Checkbox.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** ManLab Checkbox — square check with label, supports indeterminate. */
function Checkbox({
  checked = false,
  indeterminate = false,
  onChange,
  label,
  description,
  disabled = false,
  id,
  ...rest
}) {
  const fieldId = id || (label ? `cb-${String(label).replace(/\s+/g, '-').toLowerCase()}` : undefined);
  const on = checked || indeterminate;
  return /*#__PURE__*/React.createElement("label", {
    htmlFor: fieldId,
    style: {
      display: 'flex',
      alignItems: description ? 'flex-start' : 'center',
      gap: '9px',
      cursor: disabled ? 'not-allowed' : 'pointer',
      opacity: disabled ? 0.5 : 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'relative',
      flexShrink: 0,
      width: 18,
      height: 18,
      marginTop: description ? 1 : 0,
      borderRadius: 'var(--radius-xs)',
      background: on ? 'var(--brand)' : 'var(--surface-card)',
      border: `var(--bw-thin) solid ${on ? 'var(--brand)' : 'var(--border-strong)'}`,
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      transition: 'var(--transition-control)'
    }
  }, /*#__PURE__*/React.createElement("input", _extends({
    type: "checkbox",
    id: fieldId,
    checked: checked,
    disabled: disabled,
    onChange: onChange,
    style: {
      position: 'absolute',
      opacity: 0,
      width: '100%',
      height: '100%',
      margin: 0,
      cursor: 'inherit'
    }
  }, rest)), indeterminate ? /*#__PURE__*/React.createElement("svg", {
    width: "11",
    height: "11",
    viewBox: "0 0 24 24",
    stroke: "#fff",
    strokeWidth: "4",
    strokeLinecap: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M5 12h14"
  })) : checked ? /*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "12",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "#fff",
    strokeWidth: "3.4",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M20 6 9 17l-5-5"
  })) : null), (label || description) && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: '2px'
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-body)',
      color: 'var(--text-strong)'
    }
  }, label), description && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-caption)',
      color: 'var(--text-muted)'
    }
  }, description)));
}
Object.assign(__ds_scope, { Checkbox });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Checkbox.jsx", error: String((e && e.message) || e) }); }

// components/forms/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ManLab IconButton — square button holding a single icon.
 * Variants: ghost (default) | secondary | brand
 */
function IconButton({
  children,
  label,
  variant = 'ghost',
  size = 'md',
  active = false,
  disabled = false,
  ...rest
}) {
  const dims = {
    sm: 28,
    md: 34,
    lg: 42
  };
  const d = dims[size];
  const palettes = {
    ghost: {
      bg: 'transparent',
      fg: 'var(--text-muted)',
      bd: 'transparent'
    },
    secondary: {
      bg: 'var(--surface-card)',
      fg: 'var(--text-body)',
      bd: 'var(--border-default)'
    },
    brand: {
      bg: 'var(--brand)',
      fg: 'var(--text-on-brand)',
      bd: 'transparent'
    }
  };
  const p = palettes[variant] || palettes.ghost;
  const [hover, setHover] = React.useState(false);
  const style = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: d,
    height: d,
    color: active ? 'var(--brand)' : p.fg,
    background: disabled ? 'transparent' : active ? 'var(--surface-brand-soft)' : hover && variant !== 'brand' ? 'var(--surface-hover)' : hover && variant === 'brand' ? 'var(--brand-hover)' : p.bg,
    border: `var(--bw-hair) solid ${p.bd}`,
    borderRadius: 'var(--radius-md)',
    cursor: disabled ? 'not-allowed' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    transition: 'var(--transition-control)'
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-label": label,
    title: label,
    disabled: disabled,
    style: style,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false)
  }, rest), children);
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/forms/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * ManLab Input — labelled text field with optional helper/error,
 * prefix/suffix adornments, and a locked (kế thừa) read-only style.
 */
function Input({
  label,
  value,
  placeholder,
  helper,
  error,
  required = false,
  disabled = false,
  locked = false,
  prefix = null,
  suffix = null,
  mono = false,
  id,
  ...rest
}) {
  const [focus, setFocus] = React.useState(false);
  const fieldId = id || (label ? `in-${label.replace(/\s+/g, '-').toLowerCase()}` : undefined);
  const borderColor = error ? 'var(--red-500)' : focus ? 'var(--border-focus)' : 'var(--border-default)';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: '6px',
      width: '100%'
    }
  }, label && /*#__PURE__*/React.createElement("label", {
    htmlFor: fieldId,
    style: {
      font: 'var(--type-label)',
      color: 'var(--text-strong)',
      display: 'flex',
      alignItems: 'center',
      gap: '4px'
    }
  }, label, required && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--red-500)'
    }
  }, "*"), locked && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-caption)',
      color: 'var(--text-faint)',
      fontWeight: 400
    }
  }, "\xB7 k\u1EBF th\u1EEBa")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      height: 'var(--control-md)',
      padding: '0 12px',
      background: disabled || locked ? 'var(--surface-sunken)' : 'var(--surface-card)',
      border: `var(--bw-hair) solid ${borderColor}`,
      borderRadius: 'var(--radius-md)',
      boxShadow: focus && !error ? 'var(--ring)' : error && focus ? '0 0 0 3px color-mix(in srgb, var(--red-500) 30%, transparent)' : 'none',
      transition: 'var(--transition-control)'
    }
  }, prefix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-faint)',
      display: 'inline-flex',
      flexShrink: 0
    }
  }, prefix), /*#__PURE__*/React.createElement("input", _extends({
    id: fieldId,
    value: value,
    placeholder: placeholder,
    disabled: disabled || locked,
    readOnly: locked,
    onFocus: () => setFocus(true),
    onBlur: () => setFocus(false),
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      outline: 'none',
      background: 'transparent',
      font: mono ? 'var(--type-mono)' : `var(--fw-regular) var(--text-base)/1.4 var(--font-sans)`,
      color: 'var(--text-strong)'
    }
  }, rest)), suffix && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-muted)',
      font: 'var(--type-caption)',
      flexShrink: 0
    }
  }, suffix)), (helper || error) && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-caption)',
      color: error ? 'var(--danger-fg)' : 'var(--text-muted)'
    }
  }, error || helper));
}
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Input.jsx", error: String((e && e.message) || e) }); }

// components/forms/SegmentedControl.jsx
try { (() => {
/**
 * ManLab SegmentedControl — pill of mutually exclusive options.
 * Tailored for checklist results (Đạt / Không đạt / N/A) with tone-coded selection.
 */
function SegmentedControl({
  options = [],
  value,
  onChange,
  size = 'md',
  toneMap = null,
  block = false
}) {
  const z = size === 'sm' ? {
    h: 26,
    font: 'var(--text-xs)',
    pad: '0 10px'
  } : {
    h: 32,
    font: 'var(--text-sm)',
    pad: '0 14px'
  };
  const defaultTone = {
    fg: 'var(--text-on-brand)',
    bg: 'var(--brand)'
  };
  return /*#__PURE__*/React.createElement("div", {
    role: "group",
    style: {
      display: 'inline-flex',
      width: block ? '100%' : undefined,
      padding: 3,
      gap: 2,
      background: 'var(--surface-sunken)',
      border: 'var(--bw-hair) solid var(--border-subtle)',
      borderRadius: 'var(--radius-md)'
    }
  }, options.map(o => {
    const val = typeof o === 'string' ? o : o.value;
    const lab = typeof o === 'string' ? o : o.label;
    const on = val === value;
    const tone = toneMap && toneMap[val] || defaultTone;
    return /*#__PURE__*/React.createElement("button", {
      key: val,
      type: "button",
      onClick: () => onChange && onChange(val),
      style: {
        flex: block ? 1 : undefined,
        height: z.h,
        padding: z.pad,
        border: 'none',
        cursor: 'pointer',
        borderRadius: 'var(--radius-sm)',
        whiteSpace: 'nowrap',
        font: `${on ? 'var(--fw-semibold)' : 'var(--fw-medium)'} ${z.font}/1 var(--font-sans)`,
        color: on ? tone.fg : 'var(--text-muted)',
        background: on ? tone.bg : 'transparent',
        boxShadow: on ? 'var(--shadow-xs)' : 'none',
        transition: 'var(--transition-control)'
      }
    }, lab);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/forms/Select.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** ManLab Select — styled native dropdown with custom chevron. */
function Select({
  label,
  value,
  onChange,
  options = [],
  placeholder,
  helper,
  required = false,
  disabled = false,
  id,
  ...rest
}) {
  const [focus, setFocus] = React.useState(false);
  const fieldId = id || (label ? `sel-${label.replace(/\s+/g, '-').toLowerCase()}` : undefined);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: '6px',
      width: '100%'
    }
  }, label && /*#__PURE__*/React.createElement("label", {
    htmlFor: fieldId,
    style: {
      font: 'var(--type-label)',
      color: 'var(--text-strong)'
    }
  }, label, required && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--red-500)'
    }
  }, " *")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      display: 'flex',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("select", _extends({
    id: fieldId,
    value: value,
    onChange: onChange,
    disabled: disabled,
    onFocus: () => setFocus(true),
    onBlur: () => setFocus(false),
    style: {
      appearance: 'none',
      WebkitAppearance: 'none',
      width: '100%',
      height: 'var(--control-md)',
      padding: '0 34px 0 12px',
      font: `var(--fw-regular) var(--text-base)/1 var(--font-sans)`,
      color: value ? 'var(--text-strong)' : 'var(--text-faint)',
      background: disabled ? 'var(--surface-sunken)' : 'var(--surface-card)',
      border: `var(--bw-hair) solid ${focus ? 'var(--border-focus)' : 'var(--border-default)'}`,
      borderRadius: 'var(--radius-md)',
      boxShadow: focus ? 'var(--ring)' : 'none',
      cursor: disabled ? 'not-allowed' : 'pointer',
      transition: 'var(--transition-control)'
    }
  }, rest), placeholder && /*#__PURE__*/React.createElement("option", {
    value: "",
    disabled: true
  }, placeholder), options.map(o => {
    const val = typeof o === 'string' ? o : o.value;
    const lab = typeof o === 'string' ? o : o.label;
    return /*#__PURE__*/React.createElement("option", {
      key: val,
      value: val
    }, lab);
  })), /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2.2",
    strokeLinecap: "round",
    strokeLinejoin: "round",
    style: {
      position: 'absolute',
      right: '11px',
      color: 'var(--text-faint)',
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "m6 9 6 6 6-6"
  }))), helper && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-caption)',
      color: 'var(--text-muted)'
    }
  }, helper));
}
Object.assign(__ds_scope, { Select });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Select.jsx", error: String((e && e.message) || e) }); }

// components/navigation/Tabs.jsx
try { (() => {
/** ManLab Tabs — underline tab bar. Controlled or uncontrolled. */
function Tabs({
  tabs = [],
  value,
  defaultValue,
  onChange
}) {
  const [internal, setInternal] = React.useState(defaultValue ?? (tabs[0] && tabs[0].id));
  const active = value !== undefined ? value : internal;
  const select = id => {
    if (value === undefined) setInternal(id);
    onChange && onChange(id);
  };
  return /*#__PURE__*/React.createElement("div", {
    role: "tablist",
    style: {
      display: 'flex',
      gap: 'var(--space-7)',
      borderBottom: 'var(--bw-hair) solid var(--border-subtle)'
    }
  }, tabs.map(t => {
    const on = t.id === active;
    return /*#__PURE__*/React.createElement("button", {
      key: t.id,
      role: "tab",
      "aria-selected": on,
      onClick: () => select(t.id),
      style: {
        position: 'relative',
        display: 'inline-flex',
        alignItems: 'center',
        gap: 7,
        padding: '0 0 11px',
        border: 'none',
        background: 'none',
        cursor: 'pointer',
        font: `${on ? 'var(--fw-semibold)' : 'var(--fw-medium)'} var(--text-base)/1 var(--font-sans)`,
        color: on ? 'var(--text-strong)' : 'var(--text-muted)',
        transition: 'color var(--dur-fast) var(--ease-standard)'
      }
    }, t.icon && /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'inline-flex'
      }
    }, t.icon), t.label, t.count != null && /*#__PURE__*/React.createElement("span", {
      style: {
        font: `var(--fw-semibold) var(--text-2xs)/1 var(--font-mono)`,
        padding: '2px 6px',
        borderRadius: 'var(--radius-pill)',
        background: on ? 'var(--blue-50)' : 'var(--surface-sunken)',
        color: on ? 'var(--blue-700)' : 'var(--text-muted)'
      }
    }, t.count), /*#__PURE__*/React.createElement("span", {
      style: {
        position: 'absolute',
        left: 0,
        right: 0,
        bottom: -1,
        height: 2,
        background: on ? 'var(--brand)' : 'transparent',
        borderRadius: '2px 2px 0 0',
        transition: 'background var(--dur-fast) var(--ease-standard)'
      }
    }));
  }));
}
Object.assign(__ds_scope, { Tabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/Tabs.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/ChecklistScreen.jsx
try { (() => {
/* ManLab UI kit — electronic evaluation checklist (live KPI scoring + gating) */
(function () {
  const Icon = window.MLIcon;
  const DS = window.ManLabDesignSystem_019e1f;
  const {
    StatusBadge,
    ProgressMeter,
    Button,
    SegmentedControl,
    Tag
  } = DS;
  const {
    CHECKLIST
  } = window.MLData;
  const TONE = {
    'Đạt': {
      fg: '#fff',
      bg: 'var(--green-600)'
    },
    'Không đạt': {
      fg: '#fff',
      bg: 'var(--red-600)'
    },
    'N/A': {
      fg: 'var(--text-strong)',
      bg: 'var(--surface-card)'
    }
  };
  function Checklist({
    record,
    onBack
  }) {
    const [items, setItems] = React.useState(CHECKLIST);
    const setResult = (n, r) => setItems(items.map(it => it.n === n ? {
      ...it,
      result: r
    } : it));
    const score = items.reduce((acc, it) => it.result === 'Đạt' ? acc + it.weight : it.result === 'N/A' ? acc : acc, 0);
    const maxApplicable = items.reduce((acc, it) => it.result === 'N/A' ? acc : acc + it.weight, 0);
    const normScore = maxApplicable ? Math.round(score / maxApplicable * 100) : 0;
    const criticalFail = items.some(it => it.critical && it.result === 'Không đạt');
    const passes = normScore >= 85 && !criticalFail;
    return /*#__PURE__*/React.createElement("div", {
      style: {
        padding: '20px 28px',
        maxWidth: 1100,
        margin: '0 auto'
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: onBack,
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        border: 'none',
        background: 'none',
        cursor: 'pointer',
        font: 'var(--type-label)',
        color: 'var(--text-muted)',
        padding: 0,
        marginBottom: 14
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "arrow-left",
      size: 16
    }), "Quay l\u1EA1i h\u1ED3 s\u01A1 ", record.id), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'grid',
        gridTemplateColumns: '1fr 300px',
        gap: 22,
        alignItems: 'start'
      }
    }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h1", {
      style: {
        font: 'var(--type-h2)',
        marginBottom: 4
      }
    }, "Checklist \u0111\xE1nh gi\xE1 \u0111\u1ECBnh l\u01B0\u1EE3ng"), /*#__PURE__*/React.createElement("p", {
      style: {
        font: 'var(--type-body)',
        color: 'var(--text-muted)',
        marginBottom: 18
      }
    }, "T\xEDch ch\u1ECDn k\u1EBFt qu\u1EA3 t\u1EEBng ti\xEAu ch\xED \u2014 h\u1EC7 th\u1ED1ng t\u1EF1 \u0111\u1ED9ng c\u1ED9ng \u0111i\u1EC3m KPI."), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 10
      }
    }, items.map(it => /*#__PURE__*/React.createElement("div", {
      key: it.n,
      style: {
        display: 'flex',
        gap: 14,
        padding: '16px 18px',
        borderRadius: 'var(--radius-lg)',
        background: 'var(--surface-card)',
        border: `1px solid ${it.critical && it.result === 'Không đạt' ? 'var(--red-200, var(--red-100))' : 'var(--border-subtle)'}`,
        boxShadow: 'var(--shadow-sm)'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 26,
        height: 26,
        flexShrink: 0,
        borderRadius: 'var(--radius-sm)',
        background: 'var(--surface-sunken)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        font: 'var(--fw-semibold) var(--text-sm) var(--font-mono)',
        color: 'var(--text-muted)'
      }
    }, it.n), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'flex-start',
        gap: 8,
        marginBottom: 10
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        font: 'var(--fw-medium) var(--text-sm)/1.45 var(--font-sans)',
        color: 'var(--text-strong)'
      }
    }, it.text), it.critical ? /*#__PURE__*/React.createElement(Tag, {
      size: "sm",
      tone: "neutral",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "shield",
        size: 11
      })
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--critical-fg)'
      }
    }, "Tr\u1ECDng y\u1EBFu")) : /*#__PURE__*/React.createElement(Tag, {
      size: "sm",
      tone: "outline"
    }, "Th\u01B0\u1EDDng \xB7 ", it.weight, "\u0111")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: 12
      }
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      size: "sm",
      value: it.result,
      onChange: r => setResult(it.n, r),
      options: it.critical ? ['Đạt', 'Không đạt'] : ['Đạt', 'Không đạt', 'N/A'],
      toneMap: TONE
    }), it.file ? /*#__PURE__*/React.createElement("a", {
      href: "#",
      onClick: e => e.preventDefault(),
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        font: 'var(--text-xs)',
        color: 'var(--brand)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "paperclip",
      size: 13
    }), it.file) : /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        font: 'var(--text-xs)',
        color: 'var(--amber-600)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "triangle-alert",
      size: 13
    }), "C\u1EA7n \u0111\xEDnh k\xE8m b\u1EB1ng ch\u1EE9ng"))))))), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'sticky',
        top: 20,
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        padding: 20,
        boxShadow: 'var(--shadow-sm)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "eyebrow",
      style: {
        marginBottom: 14
      }
    }, "K\u1EBFt qu\u1EA3 KPI"), /*#__PURE__*/React.createElement("div", {
      style: {
        textAlign: 'center',
        marginBottom: 16
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--fw-extra) 52px/1 var(--font-mono)',
        color: passes ? 'var(--green-600)' : 'var(--red-600)',
        letterSpacing: '-0.03em'
      }
    }, normScore), /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--text-muted)',
        marginTop: 2
      }
    }, "/ 100 \u0111i\u1EC3m \xB7 ng\u01B0\u1EE1ng \u0111\u1EA1t 85")), /*#__PURE__*/React.createElement(ProgressMeter, {
      value: normScore,
      threshold: 85,
      showValue: false
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 18,
        display: 'flex',
        flexDirection: 'column',
        gap: 9
      }
    }, /*#__PURE__*/React.createElement(Gate, {
      ok: normScore >= 85,
      label: "T\u1ED5ng \u0111i\u1EC3m \u2265 85"
    }), /*#__PURE__*/React.createElement(Gate, {
      ok: !criticalFail,
      label: "100% ti\xEAu ch\xED tr\u1ECDng y\u1EBFu \u0111\u1EA1t"
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 18,
        paddingTop: 16,
        borderTop: '1px solid var(--border-subtle)'
      }
    }, passes ? /*#__PURE__*/React.createElement(Button, {
      variant: "success",
      block: true,
      iconLeft: /*#__PURE__*/React.createElement(Icon, {
        name: "file-signature",
        size: 16
      })
    }, "K\u1EBFt lu\u1EADn \u0111\u1EA1t & tr\xECnh duy\u1EC7t") : /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      block: true,
      disabled: true
    }, "Tr\xECnh ph\xEA duy\u1EC7t"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 7,
        marginTop: 10,
        padding: '9px 11px',
        background: 'var(--danger-bg)',
        borderRadius: 'var(--radius-md)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "lock",
      size: 15,
      style: {
        color: 'var(--danger-fg)',
        marginTop: 1
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--danger-fg)'
      }
    }, "Lu\u1ED3ng tr\xECnh duy\u1EC7t \u0111ang b\u1ECB kh\xF3a. C\u1EA7n kh\u1EAFc ph\u1EE5c & b\u1EA5m ", /*#__PURE__*/React.createElement("b", null, "Y\xEAu c\u1EA7u b\u1ED5 sung"), ".")))))));
  }
  function Gate({
    ok,
    label
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        font: 'var(--type-label)',
        color: ok ? 'var(--green-700)' : 'var(--text-muted)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: ok ? 'circle-check' : 'circle-x',
      size: 17,
      style: {
        color: ok ? 'var(--green-500)' : 'var(--red-500)'
      }
    }), label);
  }
  window.MLChecklist = Checklist;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/ChecklistScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/DashboardScreen.jsx
try { (() => {
/* ManLab UI kit — Dashboard + P21 record list */
(function () {
  const Icon = window.MLIcon;
  const DS = window.ManLabDesignSystem_019e1f;
  const {
    StatusBadge,
    ProgressMeter,
    Avatar,
    Button,
    IconButton,
    Tag
  } = DS;
  const {
    RECORDS
  } = window.MLData;
  const STAT = [{
    label: 'Hồ sơ đang xử lý',
    value: '7',
    icon: 'clipboard-check',
    tone: 'var(--blue-600)',
    bg: 'var(--blue-50)'
  }, {
    label: 'Năng lực còn hiệu lực',
    value: '142',
    icon: 'shield-check',
    tone: 'var(--teal-600)',
    bg: 'var(--teal-50)'
  }, {
    label: 'Chờ phê duyệt',
    value: '3',
    icon: 'file-signature',
    tone: 'var(--violet-600)',
    bg: 'var(--violet-50)'
  }, {
    label: 'Tạm dừng / cảnh báo',
    value: '2',
    icon: 'triangle-alert',
    tone: 'var(--orange-600)',
    bg: 'var(--orange-50)'
  }];
  const FILTERS = ['Tất cả', 'Nháp', 'Đang đánh giá', 'Chờ phê duyệt', 'Còn hiệu lực', 'Tạm dừng'];
  const FMAP = {
    'Nháp': 'draft',
    'Đang đánh giá': 'progress',
    'Chờ phê duyệt': 'review',
    'Còn hiệu lực': 'public',
    'Tạm dừng': 'suspended'
  };
  function StatCard({
    s
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        padding: '16px 18px',
        boxShadow: 'var(--shadow-sm)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 11
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 38,
        height: 38,
        borderRadius: 'var(--radius-md)',
        background: s.bg,
        color: s.tone,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: s.icon,
      size: 20
    })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--fw-bold) 26px/1 var(--font-sans)',
        color: 'var(--text-strong)',
        letterSpacing: '-0.02em'
      }
    }, s.value))), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 11,
        font: 'var(--type-caption)',
        color: 'var(--text-muted)'
      }
    }, s.label));
  }
  function Dashboard({
    onOpen
  }) {
    const [filter, setFilter] = React.useState('Tất cả');
    const rows = RECORDS.filter(r => filter === 'Tất cả' || r.status === FMAP[filter]);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        padding: '24px 28px',
        maxWidth: 1280,
        margin: '0 auto'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 14,
        marginBottom: 24
      }
    }, STAT.map(s => /*#__PURE__*/React.createElement(StatCard, {
      key: s.label,
      s: s
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 14
      }
    }, /*#__PURE__*/React.createElement("h2", {
      style: {
        font: 'var(--type-h2)'
      }
    }, "H\u1ED3 s\u01A1 P21"), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      iconLeft: /*#__PURE__*/React.createElement(Icon, {
        name: "plus",
        size: 16
      }),
      onClick: () => onOpen(RECORDS[4])
    }, "Kh\u1EDFi t\u1EA1o h\u1ED3 s\u01A1")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 6,
        marginBottom: 16,
        flexWrap: 'wrap'
      }
    }, FILTERS.map(f => {
      const on = f === filter;
      return /*#__PURE__*/React.createElement("button", {
        key: f,
        onClick: () => setFilter(f),
        style: {
          padding: '6px 13px',
          borderRadius: 'var(--radius-pill)',
          cursor: 'pointer',
          font: `${on ? 'var(--fw-semibold)' : 'var(--fw-medium)'} var(--text-sm)/1 var(--font-sans)`,
          background: on ? 'var(--slate-900)' : 'var(--surface-card)',
          color: on ? '#fff' : 'var(--text-body)',
          border: `1px solid ${on ? 'var(--slate-900)' : 'var(--border-default)'}`,
          transition: 'var(--transition-control)'
        }
      }, f);
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        overflow: 'hidden',
        boxShadow: 'var(--shadow-sm)'
      }
    }, /*#__PURE__*/React.createElement("table", {
      style: {
        width: '100%',
        borderCollapse: 'collapse'
      }
    }, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", {
      style: {
        background: 'var(--surface-sunken)'
      }
    }, ['Mã hồ sơ', 'Tên năng lực / Cơ quan', 'Đối tượng', 'Điểm KPI', 'Người thực hiện', 'Trạng thái', ''].map((h, i) => /*#__PURE__*/React.createElement("th", {
      key: i,
      style: {
        textAlign: i === 2 || i === 3 ? 'center' : 'left',
        padding: '11px 16px',
        font: 'var(--fw-semibold) var(--text-2xs)/1 var(--font-sans)',
        letterSpacing: 'var(--ls-caps)',
        textTransform: 'uppercase',
        color: 'var(--text-muted)',
        whiteSpace: 'nowrap'
      }
    }, h)))), /*#__PURE__*/React.createElement("tbody", null, rows.map(r => /*#__PURE__*/React.createElement("tr", {
      key: r.id,
      onClick: () => onOpen(r),
      style: {
        borderTop: '1px solid var(--border-subtle)',
        cursor: 'pointer',
        transition: 'background var(--dur-fast)'
      },
      onMouseEnter: e => e.currentTarget.style.background = 'var(--surface-hover)',
      onMouseLeave: e => e.currentTarget.style.background = 'transparent'
    }, /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '13px 16px',
        whiteSpace: 'nowrap'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--fw-semibold) var(--text-sm)/1 var(--font-mono)',
        color: 'var(--brand)'
      }
    }, r.id)), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '13px 16px',
        maxWidth: 360
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--fw-medium) var(--text-sm)/1.35 var(--font-sans)',
        color: 'var(--text-strong)'
      }
    }, r.name), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 6,
        marginTop: 5
      }
    }, /*#__PURE__*/React.createElement(Tag, {
      size: "sm",
      tone: "neutral"
    }, r.agency), /*#__PURE__*/React.createElement(Tag, {
      size: "sm",
      tone: "outline"
    }, r.action))), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '13px 16px',
        textAlign: 'center',
        font: 'var(--fw-semibold) var(--text-sm) var(--font-mono)',
        color: 'var(--text-body)'
      }
    }, r.objects), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '13px 16px',
        textAlign: 'center'
      }
    }, r.score != null ? /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--fw-bold) var(--text-sm) var(--font-mono)',
        color: r.score >= 85 ? 'var(--green-600)' : 'var(--amber-600)'
      }
    }, r.score, /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--text-faint)',
        fontWeight: 400
      }
    }, "/100")) : /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--text-faint)'
      }
    }, "\u2014")), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '13px 16px',
        whiteSpace: 'nowrap'
      }
    }, /*#__PURE__*/React.createElement(Avatar, {
      name: r.owner,
      size: "xs",
      role: r.updated
    })), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '13px 16px'
      }
    }, /*#__PURE__*/React.createElement(StatusBadge, {
      status: r.status,
      pulse: r.status === 'progress' || r.status === 'public'
    })), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '13px 16px',
        textAlign: 'right'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-right",
      size: 18,
      style: {
        color: 'var(--text-faint)'
      }
    }))))))));
  }
  window.MLDashboard = Dashboard;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/DashboardScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/DeclarationScreen.jsx
try { (() => {
/* ManLab UI kit — P21 object declaration screen (data grid + mapping modal) */
(function () {
  const Icon = window.MLIcon;
  const DS = window.ManLabDesignSystem_019e1f;
  const {
    StatusBadge,
    ProgressMeter,
    Button,
    IconButton,
    Tag,
    Tabs,
    Checkbox,
    Input,
    Select
  } = DS;
  const {
    OBJECTS
  } = window.MLData;
  const MASTER = [{
    code: 'MTD.0301',
    vi: 'pH trong nước',
    en: 'pH in water',
    group: 'QTMT',
    spec: 'TCVN 6492:2011',
    q1: 'LOD — · LOQ —',
    u: 'U = 0.1 (k=2)'
  }, {
    code: 'MTD.0312',
    vi: 'Độ dẫn điện (EC)',
    en: 'Electrical Conductivity',
    group: 'QTMT',
    spec: 'SMEWW 2510B',
    q1: 'LOD 2 µS/cm',
    u: 'U = 3.0% (k=2)'
  }, {
    code: 'MTD.0145',
    vi: 'Cân phân tích 4 số lẻ',
    en: 'Analytical Balance',
    group: 'Đo lường',
    spec: 'Dải (0–220) g · Cấp I',
    q1: 'MPE ±0.2 mg',
    u: 'U = 0.1 mg (k=2)'
  }, {
    code: 'MTD.0150',
    vi: 'Bình định mức 1000 mL',
    en: 'Volumetric Flask',
    group: 'Đo lường',
    spec: 'Dung tích 1000 mL · Cấp A',
    q1: 'MPE ±0.4 mL',
    u: 'U = 0.2 mL (k=2)'
  }, {
    code: 'MTD.0420',
    vi: 'Amoni (NH₄⁺) trong nước',
    en: 'Ammonium in water',
    group: 'QTMT',
    spec: 'TCVN 6179-1:1996',
    q1: 'LOD 0.02 mg/L',
    u: 'U = 7.4% (k=2)'
  }];
  function MappingModal({
    onClose,
    onAdd
  }) {
    const [sel, setSel] = React.useState({});
    const [q, setQ] = React.useState('');
    const count = Object.values(sel).filter(Boolean).length;
    const list = MASTER.filter(m => (m.vi + m.en + m.code).toLowerCase().includes(q.toLowerCase()));
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'fixed',
        inset: 0,
        zIndex: 900,
        background: 'rgba(12,17,27,0.5)',
        backdropFilter: 'blur(2px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24
      },
      onClick: onClose
    }, /*#__PURE__*/React.createElement("div", {
      onClick: e => e.stopPropagation(),
      style: {
        width: 720,
        maxHeight: '82vh',
        background: 'var(--surface-card)',
        borderRadius: 'var(--radius-xl)',
        boxShadow: 'var(--shadow-xl)',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '18px 22px',
        borderBottom: '1px solid var(--border-subtle)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 34,
        height: 34,
        borderRadius: 'var(--radius-md)',
        background: 'var(--blue-50)',
        color: 'var(--brand)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "gauge",
      size: 19
    })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--type-h3)'
      }
    }, "Th\xEAm \u0111\u1ED1i t\u01B0\u1EE3ng t\u1EEB Danh m\u1EE5c ph\u01B0\u01A1ng ti\u1EC7n \u0111o"), /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--text-muted)'
      }
    }, "D\u1EEF li\u1EC7u k\u1EF9 thu\u1EADt k\u1EBF th\u1EEBa t\u1EF1 \u0111\u1ED9ng \u2014 kh\xF4ng nh\u1EADp tay"))), /*#__PURE__*/React.createElement(IconButton, {
      label: "\u0110\xF3ng",
      onClick: onClose
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "x",
      size: 18
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: '14px 22px',
        borderBottom: '1px solid var(--border-subtle)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        height: 'var(--control-md)',
        padding: '0 12px',
        background: 'var(--surface-sunken)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-md)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "search",
      size: 16,
      style: {
        color: 'var(--text-faint)'
      }
    }), /*#__PURE__*/React.createElement("input", {
      value: q,
      onChange: e => setQ(e.target.value),
      placeholder: "T\xECm theo t\xEAn ho\u1EB7c m\xE3 thi\u1EBFt b\u1ECB\u2026",
      style: {
        flex: 1,
        border: 'none',
        outline: 'none',
        background: 'transparent',
        font: 'var(--type-body)',
        color: 'var(--text-strong)'
      }
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        overflowY: 'auto',
        flex: 1
      }
    }, list.map(m => {
      const on = !!sel[m.code];
      return /*#__PURE__*/React.createElement("label", {
        key: m.code,
        style: {
          display: 'flex',
          gap: 12,
          padding: '13px 22px',
          borderBottom: '1px solid var(--border-subtle)',
          cursor: 'pointer',
          background: on ? 'var(--blue-50)' : 'transparent'
        }
      }, /*#__PURE__*/React.createElement(Checkbox, {
        checked: on,
        onChange: () => setSel({
          ...sel,
          [m.code]: !on
        })
      }), /*#__PURE__*/React.createElement("div", {
        style: {
          flex: 1,
          minWidth: 0
        }
      }, /*#__PURE__*/React.createElement("div", {
        style: {
          display: 'flex',
          alignItems: 'center',
          gap: 8
        }
      }, /*#__PURE__*/React.createElement("span", {
        style: {
          font: 'var(--fw-semibold) var(--text-xs)/1 var(--font-mono)',
          color: 'var(--text-muted)'
        }
      }, m.code), /*#__PURE__*/React.createElement("span", {
        style: {
          font: 'var(--type-label)',
          color: 'var(--text-strong)'
        }
      }, m.vi), /*#__PURE__*/React.createElement(Tag, {
        size: "sm",
        tone: m.group === 'QTMT' ? 'accent' : 'brand'
      }, m.group)), /*#__PURE__*/React.createElement("div", {
        style: {
          display: 'flex',
          gap: 14,
          marginTop: 5,
          font: 'var(--type-caption)',
          color: 'var(--text-muted)'
        }
      }, /*#__PURE__*/React.createElement("span", {
        style: {
          fontStyle: 'italic'
        }
      }, m.en), /*#__PURE__*/React.createElement("span", null, "\xB7 ", m.spec), /*#__PURE__*/React.createElement("span", {
        className: "mono"
      }, "\xB7 ", m.u))));
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '14px 22px',
        borderTop: '1px solid var(--border-subtle)',
        background: 'var(--surface-inset)'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--text-muted)'
      }
    }, count > 0 ? `Đã chọn ${count} đối tượng` : 'Chưa chọn đối tượng nào'), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      onClick: onClose
    }, "H\u1EE7y"), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      disabled: count === 0,
      onClick: () => onAdd(count),
      iconLeft: /*#__PURE__*/React.createElement(Icon, {
        name: "plus",
        size: 16
      })
    }, "Th\xEAm ", count > 0 ? count : '', " \u0111\u1ED1i t\u01B0\u1EE3ng")))));
  }
  function ObjectGrid({
    onOpenChecklist
  }) {
    const cols = ['STT', 'Mã đối tượng', 'Tên tiếng Việt / Anh', 'Thông số kỹ thuật', 'Chỉ số định lượng', 'Độ KĐBĐ (U)', 'Bằng chứng', 'Trạng thái'];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        overflow: 'hidden',
        background: 'var(--surface-card)'
      }
    }, /*#__PURE__*/React.createElement("table", {
      style: {
        width: '100%',
        borderCollapse: 'collapse',
        font: 'var(--text-sm)'
      }
    }, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", {
      style: {
        background: 'var(--surface-sunken)'
      }
    }, cols.map((c, i) => /*#__PURE__*/React.createElement("th", {
      key: i,
      style: {
        textAlign: i === 0 ? 'center' : 'left',
        padding: '10px 12px',
        font: 'var(--fw-semibold) var(--text-2xs)/1.2 var(--font-sans)',
        letterSpacing: 'var(--ls-wide)',
        textTransform: 'uppercase',
        color: 'var(--text-muted)',
        whiteSpace: 'nowrap'
      }
    }, c)))), /*#__PURE__*/React.createElement("tbody", null, OBJECTS.map((o, i) => /*#__PURE__*/React.createElement("tr", {
      key: o.code,
      style: {
        borderTop: '1px solid var(--border-subtle)',
        background: i % 2 ? 'var(--surface-inset)' : 'transparent'
      }
    }, /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px',
        textAlign: 'center',
        color: 'var(--text-faint)',
        font: 'var(--font-mono)'
      }
    }, i + 1), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px',
        whiteSpace: 'nowrap'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--fw-semibold) var(--text-xs) var(--font-mono)',
        color: 'var(--brand)'
      }
    }, o.code)), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px',
        maxWidth: 200
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--fw-medium) var(--text-sm)/1.3 var(--font-sans)',
        color: 'var(--text-strong)'
      }
    }, o.vi), /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--text-faint)',
        fontStyle: 'italic'
      }
    }, o.en)), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px',
        font: 'var(--text-xs)/1.5 var(--font-sans)',
        color: 'var(--text-body)',
        maxWidth: 190
      }
    }, o.spec), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px',
        font: 'var(--fw-medium) var(--text-xs)/1.5 var(--font-mono)',
        color: 'var(--text-body)',
        whiteSpace: 'nowrap'
      }
    }, o.q1), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px',
        font: 'var(--fw-medium) var(--text-xs) var(--font-mono)',
        color: 'var(--text-body)',
        whiteSpace: 'nowrap'
      }
    }, o.u), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px'
      }
    }, o.file ? /*#__PURE__*/React.createElement("a", {
      href: "#",
      onClick: e => e.preventDefault(),
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        font: 'var(--text-xs)',
        color: 'var(--brand)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "paperclip",
      size: 13
    }), o.file.length > 18 ? o.file.slice(0, 16) + '…' : o.file) : /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 4,
        font: 'var(--text-xs)',
        color: 'var(--amber-600)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "triangle-alert",
      size: 13
    }), "Thi\u1EBFu")), /*#__PURE__*/React.createElement("td", {
      style: {
        padding: '11px 12px'
      }
    }, /*#__PURE__*/React.createElement(StatusBadge, {
      status: o.status,
      size: "sm"
    })))))));
  }
  function Declaration({
    record,
    onBack,
    onOpenChecklist
  }) {
    const [tab, setTab] = React.useState('objects');
    const [modal, setModal] = React.useState(false);
    const [toast, setToast] = React.useState(null);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        padding: '20px 28px',
        maxWidth: 1280,
        margin: '0 auto'
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: onBack,
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        border: 'none',
        background: 'none',
        cursor: 'pointer',
        font: 'var(--type-label)',
        color: 'var(--text-muted)',
        padding: 0,
        marginBottom: 14
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "arrow-left",
      size: 16
    }), "Quay l\u1EA1i danh s\xE1ch"), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        padding: '20px 22px',
        marginBottom: 20,
        boxShadow: 'var(--shadow-sm)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'flex-start',
        justifyContent: 'space-between',
        gap: 24
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginBottom: 6
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--fw-bold) var(--text-lg)/1 var(--font-mono)',
        color: 'var(--brand)'
      }
    }, record.id), /*#__PURE__*/React.createElement(Tag, {
      tone: "neutral"
    }, record.agency), /*#__PURE__*/React.createElement(Tag, {
      tone: "outline"
    }, record.action)), /*#__PURE__*/React.createElement("h1", {
      style: {
        font: 'var(--type-h2)',
        marginBottom: 14
      }
    }, record.name), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 26,
        flexWrap: 'wrap'
      }
    }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "eyebrow",
      style: {
        marginBottom: 5
      }
    }, "L\u1EDBp 1 \xB7 H\u1ED3 s\u01A1"), /*#__PURE__*/React.createElement(StatusBadge, {
      status: record.status,
      pulse: record.status === 'progress'
    })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "eyebrow",
      style: {
        marginBottom: 5
      }
    }, "L\u1EDBp 2 \xB7 \u0110\u1ED1i t\u01B0\u1EE3ng"), /*#__PURE__*/React.createElement(StatusBadge, {
      status: "approved"
    }, "\u0110\u1EE7 \u0111i\u1EC1u ki\u1EC7n n\u1ED9i b\u1ED9")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      className: "eyebrow",
      style: {
        marginBottom: 5
      }
    }, "L\u1EDBp 3 \xB7 C\xF4ng b\u1ED1"), /*#__PURE__*/React.createElement(StatusBadge, {
      status: "draft"
    }, "\u0110ang l\u1EADp")))), /*#__PURE__*/React.createElement("div", {
      style: {
        width: 240,
        flexShrink: 0,
        display: 'flex',
        flexDirection: 'column',
        gap: 14
      }
    }, /*#__PURE__*/React.createElement(ProgressMeter, {
      label: "\u0110i\u1EC3m checklist",
      value: record.score || 0,
      threshold: 85
    }), /*#__PURE__*/React.createElement(ProgressMeter, {
      label: "Ho\xE0n thi\u1EC7n d\u1EEF li\u1EC7u",
      value: 92,
      threshold: 80,
      unit: "%"
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      size: "sm",
      block: true
    }, "L\u01B0u nh\xE1p"), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      size: "sm",
      block: true,
      iconLeft: /*#__PURE__*/React.createElement(Icon, {
        name: "send",
        size: 15
      })
    }, "Tr\xECnh so\xE1t x\xE9t"))))), /*#__PURE__*/React.createElement("div", {
      style: {
        marginBottom: 18
      }
    }, /*#__PURE__*/React.createElement(Tabs, {
      value: tab,
      onChange: setTab,
      tabs: [{
        id: 'info',
        label: 'Thông tin hồ sơ'
      }, {
        id: 'objects',
        label: 'Đối tượng năng lực',
        count: OBJECTS.length
      }, {
        id: 'check',
        label: 'Checklist đánh giá',
        count: 6
      }, {
        id: 'log',
        label: 'Nhật ký',
        icon: /*#__PURE__*/React.createElement(Icon, {
          name: "history",
          size: 15
        })
      }]
    })), tab === 'objects' && /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 12
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--text-muted)'
      }
    }, "D\u1EEF li\u1EC7u k\u1EF9 thu\u1EADt \u0111\u01B0\u1EE3c k\u1EBF th\u1EEBa & snapshot t\u1EEB Danh m\u1EE5c ph\u01B0\u01A1ng ti\u1EC7n \u0111o"), /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      size: "sm",
      iconLeft: /*#__PURE__*/React.createElement(Icon, {
        name: "plus",
        size: 15
      }),
      onClick: () => setModal(true)
    }, "Th\xEAm \u0111\u1ED1i t\u01B0\u1EE3ng t\u1EEB Danh m\u1EE5c PT\u0110")), /*#__PURE__*/React.createElement(ObjectGrid, {
      onOpenChecklist: onOpenChecklist
    })), tab === 'check' && /*#__PURE__*/React.createElement("div", {
      style: {
        textAlign: 'center',
        padding: '40px 0'
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      onClick: onOpenChecklist,
      iconLeft: /*#__PURE__*/React.createElement(Icon, {
        name: "clipboard-check",
        size: 16
      })
    }, "M\u1EDF m\xE0n h\xECnh ch\u1EA5m \u0111i\u1EC3m checklist")), tab === 'info' && /*#__PURE__*/React.createElement(InfoTab, {
      record: record
    }), tab === 'log' && /*#__PURE__*/React.createElement(LogTab, null), modal && /*#__PURE__*/React.createElement(MappingModal, {
      onClose: () => setModal(false),
      onAdd: n => {
        setModal(false);
        setToast(`Đã thêm ${n} đối tượng từ Danh mục PTĐ`);
        setTimeout(() => setToast(null), 2600);
      }
    }), toast && /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'fixed',
        bottom: 24,
        left: '50%',
        transform: 'translateX(-50%)',
        zIndex: 1000,
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        background: 'var(--slate-900)',
        color: '#fff',
        padding: '11px 16px',
        borderRadius: 'var(--radius-md)',
        boxShadow: 'var(--shadow-lg)',
        font: 'var(--type-label)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "circle-check",
      size: 18,
      style: {
        color: 'var(--green-500)'
      }
    }), toast));
  }
  function InfoTab({
    record
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        padding: 24,
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: 18,
        maxWidth: 720
      }
    }, /*#__PURE__*/React.createElement(Input, {
      label: "M\xE3 h\u1ED3 s\u01A1",
      value: record.id,
      locked: true,
      mono: true
    }), /*#__PURE__*/React.createElement(Select, {
      label: "C\u01A1 quan ti\u1EBFp nh\u1EADn",
      value: record.agency,
      options: ['Bộ KH&CN', 'Bộ TN&MT']
    }), /*#__PURE__*/React.createElement(Select, {
      label: "Lo\u1EA1i h\xE0nh \u0111\u1ED9ng",
      value: record.action,
      options: ['Công bố lần đầu', 'Điều chỉnh bổ sung', 'Báo cáo duy trì']
    }), /*#__PURE__*/React.createElement(Input, {
      label: "Ng\xE0y kh\u1EDFi t\u1EA1o",
      value: record.updated
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        gridColumn: '1 / -1'
      }
    }, /*#__PURE__*/React.createElement(Input, {
      label: "T\xEAn n\u0103ng l\u1EF1c c\xF4ng b\u1ED1",
      value: record.name
    })));
  }
  function LogTab() {
    const items = [{
      t: '08/06 14:22',
      who: 'Nguyễn Thị Lan',
      act: 'Tải lên bằng chứng QA/QC cho P21.MT.042',
      ip: '10.0.4.21'
    }, {
      t: '08/06 11:05',
      who: 'Trần Văn Minh',
      act: 'Duyệt kế hoạch đánh giá, phân công chuyên gia',
      ip: '10.0.4.08'
    }, {
      t: '07/06 16:40',
      who: 'Nguyễn Thị Lan',
      act: 'Mapping 12 đối tượng từ Danh mục PTĐ',
      ip: '10.0.4.21'
    }, {
      t: '07/06 09:12',
      who: 'Hệ thống',
      act: 'Tạo mã hồ sơ P21-2026-001, khóa quyền chỉnh sửa',
      ip: 'system'
    }];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        overflow: 'hidden'
      }
    }, items.map((it, i) => /*#__PURE__*/React.createElement("div", {
      key: i,
      style: {
        display: 'flex',
        gap: 14,
        padding: '13px 18px',
        borderTop: i ? '1px solid var(--border-subtle)' : 'none'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--fw-medium) var(--text-xs) var(--font-mono)',
        color: 'var(--text-faint)',
        width: 84,
        flexShrink: 0
      }
    }, it.t), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--type-body)',
        color: 'var(--text-strong)'
      }
    }, it.act), /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--text-muted)',
        marginTop: 2
      }
    }, it.who, " \xB7 IP ", it.ip)))));
  }
  window.MLDeclaration = Declaration;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/DeclarationScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/PublicLookupScreen.jsx
try { (() => {
/* ManLab UI kit — public capability lookup (QR portal, citizen-facing) */
(function () {
  const Icon = window.MLIcon;
  const DS = window.ManLabDesignSystem_019e1f;
  const {
    StatusBadge,
    Tag,
    Button
  } = DS;

  // Deterministic faux-QR matrix (decorative mock, fixed pattern)
  function QR({
    size = 132
  }) {
    const N = 25;
    const cells = [];
    const finder = (r, c) => r < 7 && c < 7 || r < 7 && c >= N - 7 || r >= N - 7 && c < 7;
    const inFinderRing = (r, c) => {
      const blocks = [[0, 0], [0, N - 7], [N - 7, 0]];
      return blocks.some(([br, bc]) => {
        const dr = r - br,
          dc = c - bc;
        if (dr < 0 || dr > 6 || dc < 0 || dc > 6) return false;
        const edge = dr === 0 || dr === 6 || dc === 0 || dc === 6;
        const core = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;
        return edge || core;
      });
    };
    let seed = 7;
    const rand = () => {
      seed = seed * 1103515245 + 12345 & 0x7fffffff;
      return seed >> 8 & 1;
    };
    for (let r = 0; r < N; r++) for (let c = 0; c < N; c++) {
      let on = finder(r, c) ? inFinderRing(r, c) : rand() === 1;
      cells.push(on);
    }
    return /*#__PURE__*/React.createElement("div", {
      style: {
        width: size,
        height: size,
        display: 'grid',
        gridTemplateColumns: `repeat(${N}, 1fr)`,
        gap: 0,
        background: '#fff',
        padding: 6,
        borderRadius: 8,
        border: '1px solid var(--border-subtle)'
      }
    }, cells.map((on, i) => /*#__PURE__*/React.createElement("div", {
      key: i,
      style: {
        background: on ? 'var(--slate-900)' : 'transparent'
      }
    })));
  }
  function PublicLookup({
    onBack
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        minHeight: '100%',
        background: 'var(--surface-page)',
        display: 'flex',
        flexDirection: 'column'
      }
    }, /*#__PURE__*/React.createElement("header", {
      style: {
        background: 'var(--slate-900)',
        padding: '14px 28px',
        display: 'flex',
        alignItems: 'center',
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: "../assets/logo-mark.svg",
      alt: "",
      style: {
        width: 30,
        height: 30
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--fw-extra) 17px/1 var(--font-sans)',
        letterSpacing: '-0.02em'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: '#fff'
      }
    }, "Man"), /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--blue-300)'
      }
    }, "Lab"), /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--fw-medium) var(--text-xs)/1 var(--font-sans)',
        color: 'var(--slate-400)',
        marginLeft: 10
      }
    }, "C\u1ED5ng tra c\u1EE9u n\u0103ng l\u1EF1c c\xF4ng khai")), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("button", {
      onClick: onBack,
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        border: '1px solid rgba(255,255,255,0.2)',
        background: 'transparent',
        color: 'var(--slate-300)',
        borderRadius: 'var(--radius-md)',
        padding: '6px 12px',
        font: 'var(--type-label)',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "arrow-left",
      size: 15
    }), "V\u1EC1 ph\u1EA7n m\u1EC1m")), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        padding: '40px 24px',
        display: 'flex',
        justifyContent: 'center'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: '100%',
        maxWidth: 680
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        textAlign: 'center',
        marginBottom: 26
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'inline-flex',
        alignItems: 'center',
        gap: 7,
        padding: '5px 12px',
        borderRadius: 999,
        background: 'var(--teal-50)',
        color: 'var(--teal-700)',
        font: 'var(--type-label)',
        marginBottom: 12
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "shield-check",
      size: 15
    }), "N\u0103ng l\u1EF1c \u0111\u01B0\u1EE3c x\xE1c th\u1EF1c"), /*#__PURE__*/React.createElement("h1", {
      style: {
        font: 'var(--fw-extra) 30px/1.15 var(--font-sans)',
        letterSpacing: '-0.025em',
        color: 'var(--text-strong)'
      }
    }, "T\u1ED5ng ch\u1EA5t r\u1EAFn l\u01A1 l\u1EEDng (TSS) trong n\u01B0\u1EDBc"), /*#__PURE__*/React.createElement("p", {
      style: {
        font: 'var(--type-body)',
        color: 'var(--text-muted)',
        marginTop: 6,
        fontStyle: 'italic'
      }
    }, "Total Suspended Solids in water")), /*#__PURE__*/React.createElement("div", {
      style: {
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-xl)',
        overflow: 'hidden',
        boxShadow: 'var(--shadow-md)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 22,
        padding: 24,
        borderBottom: '1px solid var(--border-subtle)'
      }
    }, /*#__PURE__*/React.createElement(QR, null), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        marginBottom: 12
      }
    }, /*#__PURE__*/React.createElement(StatusBadge, {
      status: "public",
      pulse: true
    }, "C\xF2n hi\u1EC7u l\u1EF1c"), /*#__PURE__*/React.createElement(Tag, {
      tone: "brand",
      mono: true,
      size: "sm"
    }, "P21.MT.042")), /*#__PURE__*/React.createElement(Row, {
      label: "T\u1ED5 ch\u1EE9c",
      value: "Vi\u1EC7n \u0110o l\u01B0\u1EDDng & Th\u1EED nghi\u1EC7m"
    }), /*#__PURE__*/React.createElement(Row, {
      label: "Ph\u01B0\u01A1ng ph\xE1p",
      value: "TCVN 6625:2000",
      mono: true
    }), /*#__PURE__*/React.createElement(Row, {
      label: "N\u1EC1n m\u1EABu",
      value: "N\u01B0\u1EDBc m\u1EB7t, n\u01B0\u1EDBc th\u1EA3i"
    }), /*#__PURE__*/React.createElement(Row, {
      label: "Gi\u1EDBi h\u1EA1n",
      value: "LOD 2 mg/L \xB7 LOQ 5 mg/L",
      mono: true
    }), /*#__PURE__*/React.createElement(Row, {
      label: "\u0110\u1ED9 K\u0110B\u0110 (U)",
      value: "8.5% (k=2, P=95%)",
      mono: true
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 0
      }
    }, /*#__PURE__*/React.createElement(Cell, {
      label: "S\u1ED1 c\xF4ng b\u1ED1",
      value: "08/2026/TNMT-CB"
    }), /*#__PURE__*/React.createElement(Cell, {
      label: "Hi\u1EC7u l\u1EF1c t\u1EEB",
      value: "02/06/2026",
      border: true
    }), /*#__PURE__*/React.createElement(Cell, {
      label: "C\u01A1 quan ti\u1EBFp nh\u1EADn",
      value: "B\u1ED9 TN&MT",
      border: true
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        marginTop: 18,
        font: 'var(--type-caption)',
        color: 'var(--text-faint)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "history",
      size: 14
    }), "Tra c\u1EE9u l\xFAc 10/06/2026 \xB7 D\u1EEF li\u1EC7u \u0111\u1ED3ng b\u1ED9 tr\u1EF1c ti\u1EBFp t\u1EEB h\u1EC7 th\u1ED1ng ManLab P21"))));
  }
  function Row({
    label,
    value,
    mono
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 12,
        padding: '5px 0'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 104,
        flexShrink: 0,
        font: 'var(--type-caption)',
        color: 'var(--text-muted)'
      }
    }, label), /*#__PURE__*/React.createElement("span", {
      style: {
        font: mono ? 'var(--fw-medium) var(--text-sm) var(--font-mono)' : 'var(--fw-medium) var(--text-sm) var(--font-sans)',
        color: 'var(--text-strong)'
      }
    }, value));
  }
  function Cell({
    label,
    value,
    border
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        padding: '14px 18px',
        borderLeft: border ? '1px solid var(--border-subtle)' : 'none'
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "eyebrow",
      style: {
        marginBottom: 5
      }
    }, label), /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--fw-semibold) var(--text-sm)/1.2 var(--font-sans)',
        color: 'var(--text-strong)'
      }
    }, value));
  }
  window.MLPublicLookup = PublicLookup;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/PublicLookupScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/Shell.jsx
try { (() => {
/* ManLab UI kit — app shell: Sidebar + Topbar */
(function () {
  const Icon = window.MLIcon;
  const DS = window.ManLabDesignSystem_019e1f;
  const {
    Avatar,
    IconButton
  } = DS;
  const NAV = [{
    id: 'dashboard',
    label: 'Tổng quan',
    icon: 'layout-dashboard'
  }, {
    id: 'records',
    label: 'Hồ sơ P21',
    icon: 'clipboard-check',
    badge: 7
  }, {
    id: 'devices',
    label: 'Danh mục phương tiện đo',
    icon: 'gauge'
  }, {
    id: 'publish',
    label: 'Công bố / Thông báo',
    icon: 'qr-code'
  }, {
    id: 'log',
    label: 'Nhật ký hệ thống',
    icon: 'history'
  }];
  function Sidebar({
    route,
    onNavigate
  }) {
    return /*#__PURE__*/React.createElement("aside", {
      style: {
        width: 'var(--sidebar-w)',
        flexShrink: 0,
        background: 'var(--slate-900)',
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        color: 'var(--slate-300)'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        padding: '17px 18px',
        borderBottom: '1px solid rgba(255,255,255,0.07)'
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: "../assets/logo-mark.svg",
      alt: "",
      style: {
        width: 32,
        height: 32
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        font: 'var(--fw-extra) 19px/1 var(--font-sans)',
        letterSpacing: '-0.02em'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: '#fff'
      }
    }, "Man"), /*#__PURE__*/React.createElement("span", {
      style: {
        color: 'var(--blue-300)'
      }
    }, "Lab"))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: '8px 0',
        fontSize: 'var(--text-2xs)',
        fontWeight: 600,
        letterSpacing: 'var(--ls-caps)',
        textTransform: 'uppercase',
        color: 'var(--slate-500)',
        padding: '16px 18px 8px'
      }
    }, "P21 \xB7 Ki\u1EC3m so\xE1t s\u1EF1 ph\xF9 h\u1EE3p"), /*#__PURE__*/React.createElement("nav", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 2,
        padding: '0 10px',
        flex: 1
      }
    }, NAV.map(n => {
      const on = route === n.id;
      return /*#__PURE__*/React.createElement("button", {
        key: n.id,
        onClick: () => onNavigate(n.id),
        style: {
          display: 'flex',
          alignItems: 'center',
          gap: 11,
          padding: '9px 11px',
          borderRadius: 'var(--radius-md)',
          border: 'none',
          cursor: 'pointer',
          textAlign: 'left',
          width: '100%',
          background: on ? 'rgba(92,135,246,0.16)' : 'transparent',
          color: on ? '#fff' : 'var(--slate-300)',
          font: `${on ? 'var(--fw-semibold)' : 'var(--fw-medium)'} var(--text-sm)/1.2 var(--font-sans)`,
          transition: 'background var(--dur-fast) var(--ease-standard)'
        },
        onMouseEnter: e => {
          if (!on) e.currentTarget.style.background = 'rgba(255,255,255,0.05)';
        },
        onMouseLeave: e => {
          if (!on) e.currentTarget.style.background = 'transparent';
        }
      }, /*#__PURE__*/React.createElement(Icon, {
        name: n.icon,
        size: 18,
        style: {
          color: on ? 'var(--blue-300)' : 'var(--slate-400)'
        }
      }), /*#__PURE__*/React.createElement("span", {
        style: {
          flex: 1
        }
      }, n.label), n.badge && /*#__PURE__*/React.createElement("span", {
        style: {
          font: 'var(--fw-semibold) 11px/1 var(--font-mono)',
          background: 'var(--blue-600)',
          color: '#fff',
          padding: '2px 6px',
          borderRadius: 999
        }
      }, n.badge));
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: 12,
        borderTop: '1px solid rgba(255,255,255,0.07)'
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => onNavigate('settings'),
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 11,
        padding: '9px 11px',
        borderRadius: 'var(--radius-md)',
        border: 'none',
        cursor: 'pointer',
        width: '100%',
        background: 'transparent',
        color: 'var(--slate-300)',
        font: 'var(--fw-medium) var(--text-sm)/1 var(--font-sans)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "settings",
      size: 18,
      style: {
        color: 'var(--slate-400)'
      }
    }), "C\u1EA5u h\xECnh h\u1EC7 th\u1ED1ng")));
  }
  function Topbar({
    title,
    crumb,
    onPublicView
  }) {
    return /*#__PURE__*/React.createElement("header", {
      style: {
        height: 'var(--topbar-h)',
        flexShrink: 0,
        background: 'var(--surface-card)',
        borderBottom: '1px solid var(--border-subtle)',
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        padding: '0 24px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 1,
        minWidth: 0
      }
    }, crumb && /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--type-caption)',
        color: 'var(--text-faint)'
      }
    }, crumb), /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--fw-semibold) var(--text-md)/1.1 var(--font-sans)',
        color: 'var(--text-strong)',
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        textOverflow: 'ellipsis'
      }
    }, title)), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        height: 'var(--control-md)',
        padding: '0 11px',
        width: 240,
        background: 'var(--surface-sunken)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-md)'
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "search",
      size: 16,
      style: {
        color: 'var(--text-faint)'
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--type-body)',
        color: 'var(--text-faint)'
      }
    }, "Tra c\u1EE9u h\u1ED3 s\u01A1, m\xE3 PT\u0110\u2026")), /*#__PURE__*/React.createElement(IconButton, {
      label: "C\u1ED5ng tra c\u1EE9u c\xF4ng khai",
      variant: "secondary",
      onClick: onPublicView
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "qr-code",
      size: 18
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement(IconButton, {
      label: "Th\xF4ng b\xE1o"
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "bell",
      size: 18
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        position: 'absolute',
        top: 5,
        right: 6,
        width: 7,
        height: 7,
        borderRadius: 999,
        background: 'var(--red-500)',
        border: '2px solid var(--surface-card)'
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        width: 1,
        height: 24,
        background: 'var(--border-subtle)'
      }
    }), /*#__PURE__*/React.createElement(Avatar, {
      name: "Ph\u1EA1m H\u1ED3ng Qu\xE2n",
      role: "L\xE3nh \u0111\u1EA1o Vi\u1EC7n",
      size: "sm"
    }));
  }
  window.MLShell = {
    Sidebar,
    Topbar
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/Shell.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/app.jsx
try { (() => {
/* ManLab UI kit — app router */
(function () {
  const {
    Sidebar,
    Topbar
  } = window.MLShell;
  const Dashboard = window.MLDashboard;
  const Declaration = window.MLDeclaration;
  const Checklist = window.MLChecklist;
  const PublicLookup = window.MLPublicLookup;
  const TITLES = {
    dashboard: {
      title: 'Tổng quan',
      crumb: 'P21 · Kiểm soát sự phù hợp'
    },
    records: {
      title: 'Hồ sơ P21',
      crumb: 'P21 · Kiểm soát sự phù hợp'
    },
    devices: {
      title: 'Danh mục phương tiện đo',
      crumb: 'Master data'
    },
    publish: {
      title: 'Công bố / Thông báo',
      crumb: 'P21'
    },
    log: {
      title: 'Nhật ký hệ thống',
      crumb: 'Audit trail'
    },
    settings: {
      title: 'Cấu hình hệ thống',
      crumb: 'Super Admin'
    }
  };
  function App() {
    const [route, setRoute] = React.useState('dashboard'); // sidebar route
    const [view, setView] = React.useState('list'); // list | record | checklist | public
    const [record, setRecord] = React.useState(null);
    const openRecord = r => {
      setRecord(r);
      setView('record');
    };
    if (view === 'public') {
      return /*#__PURE__*/React.createElement(PublicLookup, {
        onBack: () => setView(record ? 'record' : 'list')
      });
    }
    let body;
    if (view === 'record') body = /*#__PURE__*/React.createElement(Declaration, {
      record: record,
      onBack: () => setView('list'),
      onOpenChecklist: () => setView('checklist')
    });else if (view === 'checklist') body = /*#__PURE__*/React.createElement(Checklist, {
      record: record,
      onBack: () => setView('record')
    });else body = /*#__PURE__*/React.createElement(Dashboard, {
      onOpen: openRecord
    });
    const meta = view === 'list' ? TITLES[route] : {
      title: record ? record.id : 'Hồ sơ',
      crumb: 'Hồ sơ P21 · ' + (record ? record.name : '')
    };
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        height: '100vh',
        overflow: 'hidden'
      }
    }, /*#__PURE__*/React.createElement(Sidebar, {
      route: view === 'list' ? route : 'records',
      onNavigate: r => {
        setRoute(r);
        setView('list');
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement(Topbar, {
      title: meta.title,
      crumb: meta.crumb,
      onPublicView: () => setView('public')
    }), /*#__PURE__*/React.createElement("main", {
      style: {
        flex: 1,
        overflowY: 'auto',
        background: 'var(--surface-page)'
      }
    }, body)));
  }
  ReactDOM.createRoot(document.getElementById('root')).render(/*#__PURE__*/React.createElement(App, null));
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/data.jsx
try { (() => {
/* ManLab UI kit — mock data (Vietnamese). Mirrors the P21 spec. */
(function () {
  const RECORDS = [{
    id: 'P21-2026-001',
    name: 'Công bố năng lực đo lường khối lượng & dung tích',
    agency: 'Bộ KH&CN',
    action: 'Công bố lần đầu',
    status: 'progress',
    objects: 12,
    score: 88,
    owner: 'Nguyễn Thị Lan',
    updated: '08/06/2026'
  }, {
    id: 'P21-2026-002',
    name: 'Thông báo phạm vi quan trắc môi trường nước',
    agency: 'Bộ TN&MT',
    action: 'Điều chỉnh bổ sung',
    status: 'review',
    objects: 8,
    score: 91,
    owner: 'Trần Văn Minh',
    updated: '06/06/2026'
  }, {
    id: 'P21-2026-003',
    name: 'Năng lực thử nghiệm chất lượng không khí xung quanh',
    agency: 'Bộ TN&MT',
    action: 'Công bố lần đầu',
    status: 'public',
    objects: 15,
    score: 95,
    owner: 'Phạm Hồng Quân',
    updated: '02/06/2026'
  }, {
    id: 'P21-2026-004',
    name: 'Hiệu chuẩn phương tiện đo áp suất',
    agency: 'Bộ KH&CN',
    action: 'Báo cáo duy trì',
    status: 'pending',
    objects: 6,
    score: null,
    owner: 'Lê Thu Hà',
    updated: '05/06/2026'
  }, {
    id: 'P21-2026-005',
    name: 'Kiểm định đồng hồ đo nước lạnh cấp B',
    agency: 'Bộ KH&CN',
    action: 'Công bố lần đầu',
    status: 'draft',
    objects: 4,
    score: null,
    owner: 'Nguyễn Thị Lan',
    updated: '09/06/2026'
  }, {
    id: 'P21-2025-0042',
    name: 'Quan trắc tiếng ồn & độ rung khu công nghiệp',
    agency: 'Bộ TN&MT',
    action: 'Công bố lần đầu',
    status: 'suspended',
    objects: 9,
    score: 86,
    owner: 'Trần Văn Minh',
    updated: '28/05/2026'
  }, {
    id: 'P21-2025-0039',
    name: 'Phân tích kim loại nặng trong nước thải',
    agency: 'Bộ TN&MT',
    action: 'Điều chỉnh bổ sung',
    status: 'approved',
    objects: 11,
    score: 90,
    owner: 'Phạm Hồng Quân',
    updated: '21/05/2026'
  }];
  const OBJECTS = [{
    code: 'P21.DL.001',
    vi: 'Tủ chuẩn dung tích',
    en: 'Standard Volumetric Tank',
    group: 'Đo lường',
    spec: 'Dải đo (1 – 50) L · Cấp chính xác 0.05',
    q1: 'MPE: ±0.02%',
    u: 'U = 0.015% (k=2)',
    file: 'Giấy_hiệu_chuẩn_2026.pdf',
    status: 'approved'
  }, {
    code: 'P21.DL.014',
    vi: 'Quả cân chuẩn F1',
    en: 'Standard Weight Class F1',
    group: 'Đo lường',
    spec: 'Dải đo (1 mg – 20 kg) · Cấp F1',
    q1: 'MPE: ±0.5 mg',
    u: 'U = 0.3 mg (k=2)',
    file: 'Chung_chi_kiem_dinh_F1.pdf',
    status: 'public'
  }, {
    code: 'P21.MT.042',
    vi: 'Tổng chất rắn lơ lửng (TSS)',
    en: 'Total Suspended Solids in water',
    group: 'QTMT',
    spec: 'Nền mẫu: nước mặt, nước thải · TCVN 6625:2000',
    q1: 'LOD 2 mg/L · LOQ 5 mg/L',
    u: 'U = 8.5% (k=2)',
    file: 'Ho_so_phe_duyet_PP_TSS.pdf',
    status: 'progress'
  }, {
    code: 'P21.MT.043',
    vi: 'Nhu cầu oxy hóa học (COD)',
    en: 'Chemical Oxygen Demand',
    group: 'QTMT',
    spec: 'Nền mẫu: nước thải · SMEWW 5220C',
    q1: 'LOD 5 mg/L · LOQ 15 mg/L',
    u: 'U = 6.2% (k=2)',
    file: 'Ho_so_phe_duyet_PP_COD.pdf',
    status: 'progress'
  }, {
    code: 'P21.MT.051',
    vi: 'Bụi tổng lơ lửng (TSP)',
    en: 'Total Suspended Particulates',
    group: 'QTMT',
    spec: 'Nền mẫu: không khí xung quanh · TCVN 5067:1995',
    q1: 'LOD 4 µg/m³ · LOQ 12 µg/m³',
    u: 'U = 9.1% (k=2)',
    file: '',
    status: 'draft'
  }, {
    code: 'P21.DL.022',
    vi: 'Áp kế chuẩn số',
    en: 'Digital Reference Manometer',
    group: 'Đo lường',
    spec: 'Dải đo (0 – 700) kPa · Cấp 0.05',
    q1: 'MPE: ±0.05% FS',
    u: 'U = 0.03% (k=2)',
    file: 'Hieu_chuan_apke_2026.pdf',
    status: 'rejected'
  }];
  const CHECKLIST = [{
    n: 1,
    text: 'Tư cách pháp nhân và phạm vi đăng ký hoạt động phù hợp.',
    critical: false,
    weight: 10,
    result: 'Đạt',
    file: 'Quyet_dinh_thanh_lap.pdf'
  }, {
    n: 2,
    text: 'Thiết bị/Chuẩn đo lường có chứng chỉ kiểm định/hiệu chuẩn hợp lệ còn thời hạn.',
    critical: true,
    weight: 20,
    result: 'Đạt',
    file: 'Giay_hieu_chuan_2026.pdf'
  }, {
    n: 3,
    text: 'Phương pháp/Quy trình thử nghiệm đã được phê duyệt nội bộ hoặc công nhận ISO 17025.',
    critical: true,
    weight: 20,
    result: 'Đạt',
    file: 'Ho_so_phe_duyet_PP.pdf'
  }, {
    n: 4,
    text: 'Nhân sự vận hành đáp ứng năng lực, được đào tạo và có quyết định phân công.',
    critical: true,
    weight: 15,
    result: 'Đạt',
    file: 'QD_phan_cong.pdf'
  }, {
    n: 5,
    text: 'Đã hoàn thành hồ sơ đánh giá Độ không đảm bảo đo (U) hoặc LOD/LOQ.',
    critical: false,
    weight: 15,
    result: 'Đạt',
    file: 'Bao_cao_U_LODLOQ.pdf'
  }, {
    n: 6,
    text: 'Đã thực hiện đầy đủ các biện pháp Bảo đảm chất lượng (QA/QC) đạt yêu cầu.',
    critical: true,
    weight: 20,
    result: 'Không đạt',
    file: ''
  }];
  const PEOPLE = [{
    name: 'Nguyễn Thị Lan',
    role: 'Người thực hiện'
  }, {
    name: 'Trần Văn Minh',
    role: 'Lãnh đạo phòng'
  }, {
    name: 'Phạm Hồng Quân',
    role: 'Lãnh đạo Viện'
  }];
  window.MLData = {
    RECORDS,
    OBJECTS,
    CHECKLIST,
    PEOPLE
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/data.jsx", error: String((e && e.message) || e) }); }

// ui_kits/manlab-p21/icons.jsx
try { (() => {
/* ManLab UI kit — inline Lucide icon set (stroke 1.75, currentColor).
   Paths mirror the Lucide library, the design system's chosen icon set. */
(function () {
  const P = {
    'layout-dashboard': '<rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/>',
    'clipboard-check': '<rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="m9 14 2 2 4-4"/>',
    'gauge': '<path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/>',
    'beaker': '<path d="M4.5 3h15"/><path d="M6 3v16a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V3"/><path d="M6 14h12"/>',
    'microscope': '<path d="M6 18h8"/><path d="M3 22h18"/><path d="M14 22a7 7 0 1 0 0-14h-1"/><path d="M9 14h2"/><path d="M9 12a2 2 0 0 1-2-2V6h6v4a2 2 0 0 1-2 2Z"/><path d="M12 6V3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3"/>',
    'shield-check': '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
    'file-signature': '<path d="M20 19.5v.5a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h7.5L20 8.5"/><path d="M14 2v6h6"/><path d="M2 21h6"/><path d="M5.99 18.5a1.4 1.4 0 0 0-2.5-1.3"/>',
    'qr-code': '<rect width="5" height="5" x="3" y="3" rx="1"/><rect width="5" height="5" x="16" y="3" rx="1"/><rect width="5" height="5" x="3" y="16" rx="1"/><path d="M21 16h-3a2 2 0 0 0-2 2v3"/><path d="M21 21v.01"/><path d="M12 7v3a2 2 0 0 1-2 2H7"/><path d="M3 12h.01"/><path d="M12 3h.01"/><path d="M12 16v.01"/><path d="M16 12h1"/><path d="M21 12v.01"/><path d="M12 21v-1"/>',
    'lock': '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
    'circle-check': '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
    'circle-x': '<circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/>',
    'triangle-alert': '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
    'history': '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/>',
    'link': '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
    'paperclip': '<path d="m16 6-8.4 8.6a2 2 0 0 0 2.8 2.8l8.4-8.6a4 4 0 0 0-5.6-5.6l-8.4 8.6a6 6 0 0 0 8.4 8.6"/>',
    'users': '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    'bell': '<path d="M10.268 21a2 2 0 0 0 3.464 0"/><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"/>',
    'search': '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    'filter': '<polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>',
    'calendar-clock': '<path d="M21 7.5V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h3.5"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h5"/><path d="M17.5 17.5 16 16.3V14"/><circle cx="16" cy="16" r="6"/>',
    'building': '<rect width="16" height="20" x="4" y="2" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/>',
    'settings': '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
    'download': '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>',
    'chevron-right': '<path d="m9 18 6-6-6-6"/>',
    'chevron-down': '<path d="m6 9 6 6 6-6"/>',
    'plus': '<path d="M5 12h14"/><path d="M12 5v14"/>',
    'check': '<path d="M20 6 9 17l-5-5"/>',
    'x': '<path d="M18 6 6 18"/><path d="M6 6l12 12"/>',
    'more-horizontal': '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
    'arrow-right': '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
    'arrow-left': '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>',
    'eye': '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/>',
    'file-check': '<path d="M16 22H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8.5L20 7.5V20a2 2 0 0 1-2 2"/><path d="M14 2v6h6"/><path d="m9 15 2 2 4-4"/>',
    'circle-alert': '<circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/>',
    'flask-conical': '<path d="M14 2v6a2 2 0 0 0 .245.96l5.51 10.08A2 2 0 0 1 18 22H6a2 2 0 0 1-1.755-2.96l5.51-10.08A2 2 0 0 0 10 8V2"/><path d="M6.453 15h11.094"/><path d="M8.5 2h7"/>',
    'scale': '<path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/>',
    'log-out': '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>',
    'send': '<path d="M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z"/><path d="m21.854 2.147-10.94 10.939"/>',
    'shield': '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>'
  };
  function Icon({
    name,
    size = 18,
    strokeWidth = 1.75,
    style = {},
    className = ''
  }) {
    const d = P[name] || P['circle-alert'];
    return React.createElement('svg', {
      width: size,
      height: size,
      viewBox: '0 0 24 24',
      fill: 'none',
      stroke: 'currentColor',
      strokeWidth,
      strokeLinecap: 'round',
      strokeLinejoin: 'round',
      className,
      style: {
        flexShrink: 0,
        ...style
      },
      dangerouslySetInnerHTML: {
        __html: d
      }
    });
  }
  window.MLIcon = Icon;
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/manlab-p21/icons.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Avatar = __ds_scope.Avatar;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Tag = __ds_scope.Tag;

__ds_ns.ProgressMeter = __ds_scope.ProgressMeter;

__ds_ns.StatusBadge = __ds_scope.StatusBadge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Checkbox = __ds_scope.Checkbox;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Select = __ds_scope.Select;

__ds_ns.Tabs = __ds_scope.Tabs;

})();
