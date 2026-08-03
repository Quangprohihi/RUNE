const STAR_PATH = 'M12 2.6l2.9 5.88 6.5.95-4.7 4.58 1.11 6.47L12 17.43l-5.81 3.05 1.11-6.47-4.7-4.58 6.5-.95z';

/**
 * Số sao đánh giá. `value` có thể lẻ (3.6) — sao cuối được cắt theo phần thập phân
 * bằng một lớp phủ có width tính theo %, nên trung bình hiển thị đúng chứ không làm tròn.
 */
export function Stars({ value, size = 14, gap = 2 }: { value: number; size?: number; gap?: number }) {
  const label = `${value} trên 5 sao`;
  return (
    <span role="img" aria-label={label} style={{ display: 'inline-flex', gap, lineHeight: 0, flex: 'none' }}>
      {[0, 1, 2, 3, 4].map((i) => {
        const fill = Math.max(0, Math.min(1, value - i));
        return (
          <span key={i} style={{ position: 'relative', width: size, height: size, display: 'inline-block' }}>
            <svg width={size} height={size} viewBox="0 0 24 24" style={{ position: 'absolute', inset: 0 }}>
              <path d={STAR_PATH} fill="var(--slate-200)" />
            </svg>
            {fill > 0 && (
              <span style={{ position: 'absolute', inset: 0, width: `${fill * 100}%`, overflow: 'hidden' }}>
                <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
                  <path d={STAR_PATH} fill="var(--amber-500)" />
                </svg>
              </span>
            )}
          </span>
        );
      })}
    </span>
  );
}
