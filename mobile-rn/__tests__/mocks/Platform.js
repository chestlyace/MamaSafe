module.exports = {
  OS: "ios",
  select: (obj) => obj.ios || obj.default,
  isPad: false,
  isTV: false,
  isTesting: true,
  Version: 0,
  constants: {
    reactNativeVersion: { major: 0, minor: 86, patch: 0 },
  },
};
