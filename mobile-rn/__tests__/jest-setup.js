global.__DEV__ = true;

// Mock Platform for react-native
global.Platform = { OS: "ios", select: (obj) => obj.ios };
