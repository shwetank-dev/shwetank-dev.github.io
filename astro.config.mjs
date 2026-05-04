// @ts-check
import { defineConfig } from "astro/config";

// https://astro.build/config
export default defineConfig({
	site: "https://shwetank-dev.github.io",
	prefetch: {
		prefetchAll: true,
	},
});
