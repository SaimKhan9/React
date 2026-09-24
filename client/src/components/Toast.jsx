import React from "react";
import { CheckCircle2, AlertCircle, Info, X } from "lucide-react";

export default function Toast({ toast, onClose }) {
  if (!toast) return null;

  const { type = "info", message } = toast;

  const getIcon = () => {
    switch (type) {
      case "success":
        return <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />;
      case "error":
        return <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />;
      default:
        return <Info className="w-4 h-4 text-sky-400 shrink-0" />;
    }
  };

  const getBorder = () => {
    switch (type) {
      case "success":
        return "border-emerald-500/30 bg-emerald-950/40 text-emerald-200";
      case "error":
        return "border-rose-500/30 bg-rose-950/40 text-rose-200";
      default:
        return "border-sky-500/30 bg-[#161b22]/90 text-sky-200";
    }
  };

  return (
    <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 px-4 py-2.5 rounded-lg border shadow-2xl backdrop-blur-md animate-in fade-in slide-in-from-bottom-4 duration-200 select-none">
      <div className={`flex items-center gap-2.5 py-1 px-3 rounded-md border ${getBorder()}`}>
        {getIcon()}
        <span className="text-xs font-medium tracking-wide">{message}</span>
        {onClose && (
          <button
            onClick={onClose}
            className="ml-2 hover:opacity-75 transition-opacity"
          >
            <X className="w-3.5 h-3.5 opacity-60" />
          </button>
        )}
      </div>
    </div>
  );
}

