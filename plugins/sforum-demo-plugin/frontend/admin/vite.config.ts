import { fileURLToPath, URL } from 'node:url'
import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [vue()],
  build: {
    emptyOutDir: true,
    cssCodeSplit: false,
    rollupOptions: {
      input: fileURLToPath(new URL('./src/admin.ts', import.meta.url)),
      preserveEntrySignatures: 'exports-only',
      output: {
        format: 'es',
        entryFileNames: 'dashboard.mjs',
        assetFileNames: 'dashboard[extname]'
      }
    }
  }
})
