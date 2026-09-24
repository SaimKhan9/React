import React, { useState, useEffect } from "react";
import {
  Code2,
  Copy,
  Check,
  Share2,
  Clock,
  PhoneOff,
  Sun,
  Moon,
  Users
} from "lucide-react";

export default function Topbar({
  roomId,
  role,
  title,
  participantCount = 1,
  theme,
  onToggleTheme,
  onOpenShare,
  onEndSession
}) {
  const [copied, setCopied] = useState(false);
  const [seconds, setSeconds] = useState(0);

  const isDark = theme === "dark";

  // Stopwatch timer
  useEffect(() => {
    const timer = setInterval(() => {
      setSeconds((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTime = (totalSec) => {
    const mins = Math.floor(totalSec / 60);
    const secs = totalSec % 60;
    return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  };

  const copyRoomId = () => {
    navigator.clipboard.writeText(roomId);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <header className={`h-14 border-b px-4 flex items-center justify-between gap-3 shrink-0 select-none z-20 transition-colors ${
      isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
    }`}>
      {/* Left: Branding & Room Tag */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-sky-500 flex items-center justify-center text-white font-bold shadow-sm shadow-sky-500/20">
            <Code2 className="w-4 h-4 stroke-[2.5]" />
          </div>
          <span className="font-bold text-sm tracking-tight hidden sm:inline">
            Dev<span className="text-sky-500">Arena</span> Live
          </span>
        </div>

        <div className={`h-4 w-px hidden sm:block ${isDark ? "bg-[#30363d]" : "bg-[#d0d7de]"}`} />

        {/* Room ID Badge */}
        <button
          onClick={copyRoomId}
          className={`flex items-center gap-1.5 px-2.5 py-1 rounded-md border text-xs font-mono transition-colors ${
            isDark
              ? "bg-[#0d1117] border-[#30363d] text-[#8b949e] hover:text-[#e6edf3]"
              : "bg-[#f6f8fa] border-[#d0d7de] text-[#656d76] hover:text-[#1f2328]"
          }`}
          title="Click to copy Room ID"
        >
          <span>{roomId}</span>
          {copied ? (
            <Check className="w-3 h-3 text-emerald-500" />
          ) : (
            <Copy className="w-3 h-3 opacity-60" />
          )}
        </button>

        {/* Role Badge */}
        <span
          className={`px-2.5 py-0.5 rounded-full text-[11px] font-semibold tracking-wide border ${
            role === "interviewer"
              ? "bg-purple-500/10 text-purple-400 border-purple-500/20"
              : role === "observer"
              ? "bg-amber-500/10 text-amber-500 border-amber-500/20"
              : "bg-emerald-500/10 text-emerald-500 border-emerald-500/20"
          }`}
        >
          {role === "interviewer" ? "👔 Interviewer" : role === "observer" ? "👁️ Observer" : "🧑‍💻 Candidate"}
        </span>
      </div>

      {/* Middle: Multi-Participant Live Counter */}
      <div className={`hidden md:flex items-center gap-2 px-3 py-1 rounded-full border text-xs ${
        isDark ? "bg-[#0d1117] border-[#30363d]" : "bg-[#f6f8fa] border-[#d0d7de]"
      }`}>
        <span
          className={`w-2 h-2 rounded-full ${
            participantCount > 1
              ? "bg-emerald-400 animate-pulse"
              : "bg-amber-400 animate-ping"
          }`}
        />
        <div className="flex items-center gap-1.5">
          <Users className="w-3 h-3 text-sky-500" />
          <span className="font-medium">
            {participantCount > 1
              ? `${participantCount} People Connected Live`
              : "Waiting for other participants..."}
          </span>
        </div>
      </div>

      {/* Right: Theme Toggle, Timer, Share, End */}
      <div className="flex items-center gap-2">
        {/* Dark / Light Mode Toggle */}
        <button
          onClick={onToggleTheme}
          className={`p-1.5 rounded-lg border transition-all ${
            isDark
              ? "bg-[#21262d] border-[#30363d] text-amber-400 hover:bg-[#30363d]"
              : "bg-gray-100 border-[#d0d7de] text-sky-600 hover:bg-gray-200"
          }`}
          title={isDark ? "Switch to Light Mode" : "Switch to Dark Mode"}
        >
          {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
        </button>

        {/* Stopwatch */}
        <div className={`flex items-center gap-1.5 px-2.5 py-1 border rounded-md font-mono text-xs ${
          isDark ? "bg-[#0d1117] border-[#30363d] text-[#e6edf3]" : "bg-[#f6f8fa] border-[#d0d7de] text-[#1f2328]"
        }`}>
          <Clock className="w-3.5 h-3.5 text-rose-500 animate-pulse" />
          <span>{formatTime(seconds)}</span>
        </div>

        {/* Share Button */}
        <button
          onClick={onOpenShare}
          className={`flex items-center gap-1.5 px-3 py-1 border rounded-md text-xs font-semibold transition-colors ${
            isDark
              ? "bg-[#21262d] hover:bg-[#30363d] border-[#30363d] text-[#e6edf3]"
              : "bg-[#f6f8fa] hover:bg-[#eaeef2] border-[#d0d7de] text-[#1f2328]"
          }`}
        >
          <Share2 className="w-3.5 h-3.5 text-sky-500" />
          <span className="hidden sm:inline">Invite Link</span>
        </button>

        {/* Developer Profile Badge (Sayim Khan) */}
        <div className={`flex items-center gap-2 px-2.5 py-1 border rounded-lg text-xs shadow-sm ${
          isDark ? "bg-[#0d1117] border-[#30363d]" : "bg-[#f6f8fa] border-[#d0d7de]"
        }`}>
          <span className="text-[10px] font-bold text-sky-400">Sayim Khan:</span>
          
          {/* LinkedIn */}
          <a
            href="https://www.linkedin.com/in/sayim-khan-3b1253404/"
            target="_blank"
            rel="noopener noreferrer"
            className="w-5 h-5 rounded flex items-center justify-center bg-[#0A66C2] text-white transition-transform hover:scale-115 active:scale-95"
            title="Sayim Khan on LinkedIn"
          >
            <svg className="w-3 h-3 fill-current" viewBox="0 0 24 24">
              <path d="M19 3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14m-.5 15.5v-5.3a3.26 3.26 0 0 0-3.26-3.26c-.85 0-1.84.52-2.28 1.3v-1.11h-2.79v8.37h2.79v-4.93c0-.77.62-1.4 1.39-1.4a1.4 1.4 0 0 1 1.4 1.4v4.93h2.75M6.88 8.56a1.68 1.68 0 0 0 1.68-1.68c0-.93-.75-1.69-1.68-1.69a1.69 1.69 0 0 0-1.69 1.69c0 .93.76 1.68 1.69 1.68m1.39 9.94v-8.37H5.5v8.37h2.77z"/>
            </svg>
          </a>

          {/* GitHub */}
          <a
            href="https://github.com/SaimKhan9"
            target="_blank"
            rel="noopener noreferrer"
            className={`w-5 h-5 rounded flex items-center justify-center border transition-transform hover:scale-115 active:scale-95 ${
              isDark ? "bg-[#161b22] border-[#30363d] text-white hover:bg-white/20" : "bg-[#24292e] text-white"
            }`}
            title="Sayim Khan on GitHub (SaimKhan9)"
          >
            <svg className="w-3 h-3 fill-current" viewBox="0 0 24 24">
              <path d="M12 2A10 10 0 0 0 2 12c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.46-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.1-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0 0 12 2z"/>
            </svg>
          </a>

          {/* Gmail */}
          <a
            href="mailto:sayimkhan09@gmail.com"
            className="w-5 h-5 rounded flex items-center justify-center bg-[#EA4335] text-white transition-transform hover:scale-115 active:scale-95"
            title="Email Sayim Khan (sayimkhan09@gmail.com)"
          >
            <svg className="w-3 h-3 fill-current" viewBox="0 0 24 24">
              <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
            </svg>
          </a>
        </div>

        {/* End Interview */}
        <button
          onClick={onEndSession}
          className="flex items-center gap-1.5 px-3 py-1 bg-rose-600/15 hover:bg-rose-600/25 text-rose-500 border border-rose-500/30 rounded-md text-xs font-semibold transition-colors"
        >
          <PhoneOff className="w-3.5 h-3.5" />
          <span className="hidden sm:inline">End</span>
        </button>
      </div>
    </header>
  );
}
