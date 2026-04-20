import { ReactNode, ButtonHTMLAttributes } from "react";
import { motion } from "motion/react";
import { cn } from "../lib/utils";

interface GlassButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "ref"> {
  children: ReactNode;
  variant?: "primary" | "ghost" | "tinted" | "danger";
  size?: "sm" | "md" | "lg";
  icon?: ReactNode;
  fullWidth?: boolean;
}

const variantMap: Record<NonNullable<GlassButtonProps["variant"]>, string> = {
  primary:
    "bg-gradient-to-b from-indigo-500 to-violet-600 text-white shadow-[0_10px_25px_-10px_rgba(99,102,241,0.6)] hover:brightness-110",
  ghost:
    "bg-white/50 text-slate-700 border border-white/70 backdrop-blur-xl hover:bg-white/70",
  tinted:
    "bg-indigo-50/80 text-indigo-700 border border-indigo-100 backdrop-blur-xl hover:bg-indigo-100/80",
  danger:
    "bg-gradient-to-b from-rose-500 to-red-600 text-white shadow-[0_10px_25px_-10px_rgba(244,63,94,0.6)] hover:brightness-110",
};

const sizeMap: Record<NonNullable<GlassButtonProps["size"]>, string> = {
  sm: "px-4 py-2 text-sm rounded-full",
  md: "px-5 py-3 text-[15px] rounded-full",
  lg: "px-6 py-4 text-base rounded-2xl",
};

export default function GlassButton({
  children,
  variant = "primary",
  size = "md",
  icon,
  fullWidth,
  className,
  ...rest
}: GlassButtonProps) {
  return (
    <motion.button
      {...(rest as Omit<ButtonHTMLAttributes<HTMLButtonElement>, "ref">)}
      whileTap={{ scale: 0.96 }}
      whileHover={{ scale: 1.01 }}
      transition={{ type: "spring", stiffness: 380, damping: 28 }}
      className={cn(
        "font-semibold tracking-tight flex items-center justify-center gap-2 select-none transition-all",
        variantMap[variant],
        sizeMap[size],
        fullWidth && "w-full",
        className,
      )}
    >
      {icon}
      {children}
    </motion.button>
  );
}
