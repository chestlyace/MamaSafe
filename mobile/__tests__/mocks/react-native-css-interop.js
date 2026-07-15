const React = require("react");

module.exports = {
  StyleSheet: {
    create: (styles) => styles,
    flatten: (style) => style,
  },
  cssInterop: () => {},
  remapProps: () => {},
  useUnstableNativeVariable: () => null,
  getStyle: () => ({}),
  default: React,
};
