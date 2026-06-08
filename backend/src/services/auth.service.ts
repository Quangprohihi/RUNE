import { issueTokenPair } from '../auth';

type BootstrapFn = (userId: string) => Promise<Record<string, unknown>>;

export async function issueAuthResponse(
  userId: string,
  bootstrap: BootstrapFn,
) {
  const tokens = await issueTokenPair(userId);
  const bootstrapData = await bootstrap(userId);
  return { ...tokens, ...bootstrapData };
}
