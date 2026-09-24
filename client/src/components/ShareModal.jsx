import React, { useState } from "react";
import { Copy, Check, Link2, X, Users } from "lucide-react";

export default function ShareModal({ isOpen, onClose, roomId, role, theme }) {
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const isDark = theme === "dark";

  // Candidate invite URL
  const candidateUrl = `${window.location.origin}${window.location.pathname}?room=${roomId}&role=candidate`;

  const handleCopy = () => {
    navigator.clipboard.writeText(candidateUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in duration-150">
      <div className={`relative w-full max-w-md border rounded-2xl shadow-2xl p-6 overflow-hidden ${
        isDark ? "bg-[#161b22] border-[#30363d] text-[#e6edf3]" : "bg-white border-[#d0d7de] text-[#1f2328]"
      }`}>
        <div className={`flex items-center justify-between pb-4 border-b ${
          isDark ? "border-[#30363d]" : "border-[#d0d7de]"
        }`}>
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-sky-500/10 text-sky-500 border border-sky-500/20">
              <Link2 className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-base">
                Share Interview Link
              </h3>
              <p className={`text-xs ${isDark ? "text-[#8b949e]" : "text-[#656d76]"}`}>
                Invite candidates or observers to join live
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className={`p-1.5 rounded-lg transition-colors ${
              isDark ? "text-[#8b949e] hover:text-[#e6edf3] hover:bg-[#21262d]" : "text-gray-400 hover:text-black hover:bg-gray-100"
            }`}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="mt-5 space-y-4">
          <div>
            <label className={`block text-xs font-semibold uppercase tracking-wider mb-1.5 ${
              isDark ? "text-[#8b949e]" : "text-[#656d76]"
            }`}>
              Participant Join URL
            </label>
            <div className={`flex items-center gap-2 p-2 border rounded-xl transition-colors ${
              isDark ? "bg-[#0d1117] border-[#30363d]" : "bg-[#f6f8fa] border-[#d0d7de]"
            }`}>
              <input
                type="text"
                readOnly
                value={candidateUrl}
                className="flex-1 bg-transparent text-xs font-mono text-sky-500 outline-none px-2 select-all"
              />
              <button
                onClick={handleCopy}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-sky-500 hover:bg-sky-400 text-white font-semibold text-xs rounded-lg transition-all active:scale-95 shadow-sm"
              >
                {copied ? (
                  <>
                    <Check className="w-3.5 h-3.5" />
                    <span>Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3.5 h-3.5" />
                    <span>Copy</span>
                  </>
                )}
              </button>
            </div>
          </div>

          <div className={`border rounded-xl p-3.5 space-y-2 text-xs ${
            isDark ? "bg-[#1f242c]/70 border-[#30363d]/80 text-[#8b949e]" : "bg-gray-50 border-gray-200 text-[#656d76]"
          }`}>
            <div className={`flex items-center gap-2 font-bold ${isDark ? "text-[#e6edf3]" : "text-[#1f2328]"}`}>
              <Users className="w-4 h-4 text-emerald-500" />
              <span>Multi-Person Real-Time Sync</span>
            </div>
            <p className="leading-relaxed">
              Anyone with this link can join the session as a candidate, co-interviewer, or observer. Video, code editing, terminal execution, and chat will instantly synchronize across all participants.
            </p>
          </div>
        </div>

        <div className="mt-6 flex justify-end">
          <button
            onClick={onClose}
            className={`w-full py-2.5 px-4 text-xs font-semibold rounded-xl border transition-colors ${
              isDark
                ? "bg-[#21262d] hover:bg-[#30363d] text-[#e6edf3] border-[#30363d]"
                : "bg-gray-100 hover:bg-gray-200 text-[#1f2328] border-gray-300"
            }`}
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
