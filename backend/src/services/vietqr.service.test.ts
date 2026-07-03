import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { buildVietQrImageUrl, getVietqrConfig } from './vietqr.service';

describe('vietqr.service', () => {
  const OLD_ENV = process.env;
  beforeEach(() => {
    process.env = {
      ...OLD_ENV,
      VIETQR_BANK_BIN: '970426',
      VIETQR_ACCOUNT_NO: '6102062004',
      VIETQR_ACCOUNT_NAME: 'VU NGOC QUANG',
      VIETQR_BANK_NAME: 'MSB',
    };
  });
  afterEach(() => {
    process.env = OLD_ENV;
  });

  it('builds a compact2 image URL with amount, content and account name', () => {
    const url = buildVietQrImageUrl({ amountVnd: 29000, addInfo: '1720000123456' });
    expect(url).toContain('https://img.vietqr.io/image/970426-6102062004-compact2.png');
    expect(url).toContain('amount=29000');
    expect(url).toContain('addInfo=1720000123456');
    expect(url).toContain('accountName=VU+NGOC+QUANG');
  });

  it('reads all four config fields', () => {
    expect(getVietqrConfig()).toEqual({
      bankBin: '970426',
      accountNo: '6102062004',
      accountName: 'VU NGOC QUANG',
      bankName: 'MSB',
    });
  });

  it('throws a 500 when a config var is missing', () => {
    delete process.env.VIETQR_BANK_BIN;
    expect(() => getVietqrConfig()).toThrowError(/VIETQR_BANK_BIN/);
  });
});
