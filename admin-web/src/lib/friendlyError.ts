export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

export function friendlyError(err: unknown): string {
  if (err instanceof ApiError) {
    if (err.status === 401) return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    if (err.status === 403) return 'Tài khoản không đủ quyền cho thao tác này.';
    if (err.status === 404) return 'Không tìm thấy dữ liệu.';
    if (err.status >= 500) return 'Máy chủ gặp sự cố. Vui lòng thử lại sau.';
    if (err.message) return err.message;
  }
  if (err instanceof Error && err.message) {
    if (err.message.includes('Failed to fetch') || err.message.includes('NetworkError')) {
      return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    }
    return err.message;
  }
  if (typeof err === 'string' && err) return err;
  return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
}
