import { describe, it, expect } from 'vitest';
import { ApiError, friendlyError } from './friendlyError';

describe('friendlyError', () => {
  it('maps known HTTP statuses to Vietnamese messages', () => {
    expect(friendlyError(new ApiError(401, 'x'))).toBe('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    expect(friendlyError(new ApiError(403, 'x'))).toBe('Tài khoản không đủ quyền cho thao tác này.');
    expect(friendlyError(new ApiError(500, 'x'))).toBe('Máy chủ gặp sự cố. Vui lòng thử lại sau.');
  });
  it('passes through a 4xx server message that is not 401/403/404', () => {
    expect(friendlyError(new ApiError(400, 'Thiếu tham số'))).toBe('Thiếu tham số');
  });
  it('detects network failures', () => {
    expect(friendlyError(new TypeError('Failed to fetch'))).toBe('Không kết nối được máy chủ. Kiểm tra mạng và thử lại.');
  });
  it('falls back for unknown shapes', () => {
    expect(friendlyError({})).toBe('Đã có lỗi xảy ra. Vui lòng thử lại.');
  });
});
