import esbuild from "esbuild";
import NodeGlobalsPolyfillPlugin from "@esbuild-plugins/node-globals-polyfill";

esbuild
  .build({
    entryPoints: ["src/main.tsx"], // Adjust as necessary
    bundle: true,
    outfile: "dist/bundle.js", // Specify output path
    plugins: [NodeGlobalsPolyfillPlugin()],
    define: {
      "process.env.NODE_ENV": '"production"', // For environment variables
    },
  })
  .catch(() => process.exit(1));
