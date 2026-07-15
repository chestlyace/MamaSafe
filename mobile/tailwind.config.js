/** @type {import('tailwindcss').Config} */
module.exports = {
  presets: [require("nativewind/preset")],
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        "rose-primary": "#E8637A",
        "rose-hover": "#D4526A",
        "rose-light": "#FDF2F4",
        surface: "#FAFAFA",
        canvas: "#F8F6FA",
        border: "#E8E5EC",
        "text-heading": "#3D3847",
        "text-body": "#5C5566",
        "text-muted": "#8E8696",
      },
      fontFamily: {
        inter: ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold"],
      },
      borderRadius: {
        xl: "0.75rem",
        "2xl": "1rem",
      },
    },
  },
  plugins: [],
};
