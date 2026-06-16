interface SegOption<T extends string> { value: T; label: string; }

interface SegmentedControlProps<T extends string> {
  variant?: 'lite' | 'dark';
  value: T;
  options: SegOption<T>[];
  onChange: (value: T) => void;
}

export function SegmentedControl<T extends string>({
  variant = 'lite', value, options, onChange,
}: SegmentedControlProps<T>) {
  return (
    <div className={`zz-seg zz-seg--${variant}`}>
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          className={`zz-seg__opt${o.value === value ? ' zz-seg__opt--on' : ''}`}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
