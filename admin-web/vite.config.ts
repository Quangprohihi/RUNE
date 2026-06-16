/// <reference types="vitest/config" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/console/',
  plugins: [react()],
  // Build into the mounted backend dir so the running Docker container serves it at /console.
  build: { outDir: '../backend/admin-web/dist', emptyOutDir: true },
  server: {
    port: 5173,
    proxy: {
      '/admin/api': { target: 'http://localhost:3000', changeOrigin: true },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
    css: false,
  },
});
