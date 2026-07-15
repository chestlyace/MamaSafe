import { TouchableOpacity, Text, ActivityIndicator, type TouchableOpacityProps } from "react-native";

interface ButtonProps extends TouchableOpacityProps {
  variant?: "primary" | "secondary" | "ghost";
  loading?: boolean;
  children: string;
}

const VARIANTS = {
  primary: "bg-rose-primary active:bg-rose-hover",
  secondary: "border border-rose-primary bg-white active:bg-rose-light",
  ghost: "bg-transparent active:bg-gray-100",
};

const TEXT_VARIANTS = {
  primary: "text-white",
  secondary: "text-rose-primary",
  ghost: "text-text-body",
};

export default function Button({ variant = "primary", loading, children, disabled, ...props }: ButtonProps) {
  return (
    <TouchableOpacity
      className={`py-3.5 px-6 rounded-xl flex-row items-center justify-center gap-2 active:scale-[0.98] ${VARIANTS[variant]} ${(disabled || loading) ? "opacity-50" : ""}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? (
        <ActivityIndicator color={variant === "primary" ? "#fff" : "#E8637A"} />
      ) : (
        <Text className={`text-sm font-semibold ${TEXT_VARIANTS[variant]}`}>{children}</Text>
      )}
    </TouchableOpacity>
  );
}
