import express from 'express';

export function errorHandler(
  error: Error & { status?: number },
  _req: express.Request,
  res: express.Response,
  _next: express.NextFunction,
) {
  const status = error.status ?? 500;
  if (status >= 500) console.error(error);
  res.status(status).json({ message: error.message || 'Server error' });
}
