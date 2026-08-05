import { Ionicons } from "@expo/vector-icons";

type IconName = keyof typeof Ionicons.glyphMap;

interface IconProps {
  name: IconName;
  size?: number;
  color?: string;
  className?: string;
}

export default function Icon({ name, size = 20, color = "#3D3847", className }: IconProps) {
  return <Ionicons name={name} size={size} color={color} className={className} />;
}
