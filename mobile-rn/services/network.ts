import NetInfo from "@react-native-community/netinfo";

let _isOnline = true;

export const initNetworkListener = (onStateChange?: (online: boolean) => void) => {
  NetInfo.addEventListener((state) => {
    _isOnline = state.isConnected ?? false;
    onStateChange?.(_isOnline);
  });
};

export const isOnline = async (): Promise<boolean> => {
  const state = await NetInfo.fetch();
  return state.isConnected ?? false;
};

export const getIsOnline = () => _isOnline;
