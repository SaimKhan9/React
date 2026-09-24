/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        dark: {
          bg: "#0d1117",
          panel: "#161b22",
          card: "#1f242c",
          hover: "#21262d",
          border: "#30363d",
          accent: "#58a6ff",
          green: "#3fb950",
          red: "#f85149",
          purple: "#bc8cff",
          yellow: "#e3b341",
          text: "#e6edf3",
          muted: "#8b949e",
          dimmed: "#484f58"
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace']
      }
    },
  },
  plugins: [],
}

