import { defineConfig } from "vite";

export default defineConfig({
  root: "src",
  build: {
    outDir: "../dist",
  },
  server: {
    open: true,
  },
  publicDir: "../public",
});

// import { defineConfig } from "vite";

// export default defineConfig({
//   build: {
//     outDir: "dist",
//   },
//   server: {
//     open: true,
//   },
// });
