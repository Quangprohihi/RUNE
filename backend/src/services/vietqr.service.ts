function requiredEnv(name: string) {
  const value = process.env[name];
  if (!value) {
    throw Object.assign(new Error(`${name} is not configured`), { status: 500 });
  }
  return value;
}

export function getVietqrConfig() {
  return {
    bankBin: requiredEnv('VIETQR_BANK_BIN'),
    accountNo: requiredEnv('VIETQR_ACCOUNT_NO'),
    accountName: requiredEnv('VIETQR_ACCOUNT_NAME'),
    bankName: requiredEnv('VIETQR_BANK_NAME'),
  };
}

export function buildVietQrImageUrl({
  amountVnd,
  addInfo,
}: {
  amountVnd: number;
  addInfo: string;
}) {
  const { bankBin, accountNo, accountName } = getVietqrConfig();
  const params = new URLSearchParams({
    amount: String(amountVnd),
    addInfo,
    accountName,
  });
  return `https://img.vietqr.io/image/${bankBin}-${accountNo}-compact2.png?${params.toString()}`;
}
