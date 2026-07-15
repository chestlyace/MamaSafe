import AsyncStorage from "@react-native-async-storage/async-storage";

jest.mock("@react-native-async-storage/async-storage", () =>
  require("@react-native-async-storage/async-storage/jest/async-storage-mock")
);

jest.mock("axios", () => {
  const mockPost = jest.fn();
  const mockGet = jest.fn();
  const mockUse = jest.fn();
  const mockAxiosInstance = {
    interceptors: {
      request: { use: mockUse },
      response: { use: mockUse },
    },
    post: mockPost,
    get: mockGet,
  };
  return {
    __esModule: true,
    default: {
      create: jest.fn(() => mockAxiosInstance),
      post: mockPost,
      get: mockGet,
    },
    create: jest.fn(() => mockAxiosInstance),
    post: mockPost,
    get: mockGet,
  };
});

describe("API Client", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("calls login endpoint", async () => {
    const axios = require("axios");
    const client = axios.default.create();
    client.post.mockResolvedValueOnce({
      data: { access_token: "token123", token_type: "bearer" },
    });

    const { login } = require("../../services/api");
    const result = await login("admin", "admin");

    expect(result.access_token).toBe("token123");
  });
});
