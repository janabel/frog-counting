import { defineConfig } from "vite";
import { NodeGlobalsPolyfillPlugin } from '@esbuild-plugins/node-globals-polyfill'
import wasm from 'vite-plugin-wasm';

export default defineConfig({
  root: "src",
  build: {
    outDir: "../dist",
  },
  server: {
    open: true,
    watch: {
      exclude: ['../prover-files/**']
    }
  },
  publicDir: "../public",
  plugins: [
    wasm()
  ],
  optimizeDeps: {
    esbuildOptions: {
        // Node.js global to browser globalThis
        define: {
            global: 'globalThis'
        },
        // Enable esbuild polyfill plugins
        plugins: [
            NodeGlobalsPolyfillPlugin({
                buffer: true
            })
        ]
    }
  }
});