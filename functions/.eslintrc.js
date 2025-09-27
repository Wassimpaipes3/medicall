module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": ["error", "double"], // keep double quotes
    "import/no-unresolved": 0,
    "indent": ["error", 2], // 2 spaces
    "max-len": "off", // 🚀 disable long-line errors
    "require-jsdoc": "off", // 🚀 disable JSDoc requirement
    "@typescript-eslint/no-unused-vars": ["warn"], // unused vars → warning only
  },
};
