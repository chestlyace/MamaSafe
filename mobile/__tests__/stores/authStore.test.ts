import AsyncStorage from "@react-native-async-storage/async-storage";
import { useAuthStore } from "../../stores/authStore";

jest.mock("@react-native-async-storage/async-storage", () =>
  require("@react-native-async-storage/async-storage/jest/async-storage-mock")
);

jest.mock("../../services/api", () => ({
  login: jest.fn(),
}));

jest.mock("expo-router", () => ({
  router: { replace: jest.fn() },
}));

import { login as apiLogin } from "../../services/api";
const mockLogin = apiLogin as jest.MockedFunction<typeof apiLogin>;

describe("AuthStore", () => {
  beforeEach(() => {
    AsyncStorage.clear();
    useAuthStore.setState({ token: null, user: null, isLoading: false });
    jest.clearAllMocks();
  });

  it("should have correct initial state", () => {
    const state = useAuthStore.getState();
    expect(state.token).toBeNull();
    expect(state.isLoading).toBe(false);
  });

  it("should login successfully", async () => {
    mockLogin.mockResolvedValueOnce({
      access_token: "test-token",
      token_type: "bearer",
    });

    await useAuthStore.getState().login("admin", "admin");

    const state = useAuthStore.getState();
    expect(state.token).toBe("test-token");
    expect(mockLogin).toHaveBeenCalledWith("admin", "admin");
  });

  it("should throw on login failure", async () => {
    mockLogin.mockRejectedValueOnce({
      response: { data: { detail: "Invalid credentials" } },
    });

    await expect(
      useAuthStore.getState().login("wrong", "wrong")
    ).rejects.toThrow("Invalid credentials");
    expect(useAuthStore.getState().token).toBeNull();
  });

  it("should logout", async () => {
    useAuthStore.setState({
      token: "test",
      user: { id: 1, username: "admin", role: "admin" },
    });
    await useAuthStore.getState().logout();
    expect(useAuthStore.getState().token).toBeNull();
  });
});
