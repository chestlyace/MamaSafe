module.exports = {
  testEnvironment: "node",
  testPathIgnorePatterns: ["/node_modules/", "__tests__/jest-setup\\.js$", "__tests__/mocks/"],
  transformIgnorePatterns: [
    "node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@sentry/react-native|native-base|react-native-svg|react-native-chart-kit|nativewind|tailwindcss|i18next|react-i18next|zustand|axios|react-native-css-interop)",
  ],
  transform: {
    "^.+\\.tsx?$": [
      "ts-jest",
      {
        diagnostics: false,
        tsconfig: {
          module: "commonjs",
          moduleResolution: "node",
          jsx: "react-jsx",
          esModuleInterop: true,
          strict: true,
          skipLibCheck: true,
          target: "es2020",
        },
      },
    ],
    "^.+\\.jsx?$": "babel-jest",
  },
  setupFiles: [
    "<rootDir>/__tests__/jest-setup.js",
    "@react-native/jest-preset/jest/setup.js",
  ],
  moduleFileExtensions: ["ts", "tsx", "js", "jsx", "json"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/$1",
    "^react-native-css-interop(/.*)?$": "<rootDir>/__tests__/mocks/react-native-css-interop.js",
    "^react-native/Libraries/Utilities/Platform$": "<rootDir>/__tests__/mocks/Platform.js",
  },
};
