module.exports = {
  root: true,
  env: {
    es2021: true,
    node: true,
  },
  extends: ["google"],
  parserOptions: {
    ecmaVersion: 12,
  },
  rules: {
    "quotes": ["error", "double"],
    "require-jsdoc": 0,
    "max-len": ["error", { "code": 120 }],
    "camelcase": "off",
  },
};