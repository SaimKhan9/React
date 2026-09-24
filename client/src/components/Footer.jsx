import React, { useState } from "react";
import {
  Check,
  Copy,
  ExternalLink,
  Code2
} from "lucide-react";

export default function Footer({ theme }) {
  const isDark = theme === "dark";
  const [copiedEmail, setCopiedEmail] = useState(false);

  const handleCopyEmail = (e) => {
    e.preventDefault();
    navigator.clipboard.writeText("sayimkhan09@gmail.com");
    setCopiedEmail(true);
    setTimeout(() => setCopiedEmail(false), 2000);
  };

  return (
    <footer
      className={`w-full mt-10 border-t transition-colors select-none ${
        isDark ? "bg-[#090d12] border-[#21262d] text-[#8b949e]" : "bg-white border-[#e1e4e8] text-[#586069]"
      }`}
    >
      <div className="max-w-4xl mx-auto px-4 sm:px-6 py-8 flex flex-col items-center justify-center text-center space-y-6">
        
        {/* Developer Profile Header & Social Icons */}
        <div className="flex flex-col items-center space-y-3">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold uppercase tracking-widest text-sky-400">
              Developer Profile & Connect
            </span>
          </div>

          <h2 className={`text-base font-bold tracking-tight ${isDark ? "text-white" : "text-gray-900"}`}>
            Crafted with passion by <span className="text-sky-500">Sayim Khan</span>
          </h2>

          {/* Social Brand Buttons */}
          <div className="flex items-center justify-center gap-3 pt-1">
            {/* LinkedIn */}
            <a
              href="https://www.linkedin.com/in/sayim-khan-3b1253404/"
              target="_blank"
              rel="noopener noreferrer"
              className="w-10 h-10 rounded-xl flex items-center justify-center bg-[#0A66C2] text-white shadow-md transition-transform hover:scale-115 active:scale-95 cursor-pointer"
              title="Sayim Khan on LinkedIn"
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M19 3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14m-.5 15.5v-5.3a3.26 3.26 0 0 0-3.26-3.26c-.85 0-1.84.52-2.28 1.3v-1.11h-2.79v8.37h2.79v-4.93c0-.77.62-1.4 1.39-1.4a1.4 1.4 0 0 1 1.4 1.4v4.93h2.75M6.88 8.56a1.68 1.68 0 0 0 1.68-1.68c0-.93-.75-1.69-1.68-1.69a1.69 1.69 0 0 0-1.69 1.69c0 .93.76 1.68 1.69 1.68m1.39 9.94v-8.37H5.5v8.37h2.77z"/>
              </svg>
            </a>

            {/* GitHub */}
            <a
              href="https://github.com/SaimKhan9"
              target="_blank"
              rel="noopener noreferrer"
              className={`w-10 h-10 rounded-xl flex items-center justify-center border shadow-md transition-transform hover:scale-115 active:scale-95 cursor-pointer ${
                isDark ? "bg-[#161b22] border-[#30363d] text-white hover:bg-white/15" : "bg-[#24292e] border-transparent text-white hover:bg-[#1a1e22]"
              }`}
              title="Sayim Khan on GitHub (SaimKhan9)"
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M12 2A10 10 0 0 0 2 12c0 4.42 2.87 8.17 6.84 9.5.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34-.46-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.87 1.52 2.34 1.07 2.91.83.1-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.92 0-1.11.38-2 1.03-2.71-.1-.25-.45-1.29.1-2.64 0 0 .84-.27 2.75 1.02.79-.22 1.65-.33 2.5-.33.85 0 1.71.11 2.5.33 1.91-1.29 2.75-1.02 2.75-1.02.55 1.35.2 2.39.1 2.64.65.71 1.03 1.6 1.03 2.71 0 3.82-2.34 4.66-4.57 4.91.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0 0 12 2z"/>
              </svg>
            </a>

            {/* Gmail Web Compose */}
            <a
              href="https://mail.google.com/mail/?view=cm&fs=1&to=sayimkhan09@gmail.com"
              target="_blank"
              rel="noopener noreferrer"
              className="w-10 h-10 rounded-xl flex items-center justify-center bg-[#EA4335] text-white shadow-md transition-transform hover:scale-115 active:scale-95 cursor-pointer"
              title="Open Google Mail (sayimkhan09@gmail.com)"
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
              </svg>
            </a>
          </div>

          {/* Copy Email Pill */}
          <button
            onClick={handleCopyEmail}
            className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full border text-xs font-mono transition-all ${
              isDark
                ? "bg-[#161b22] border-[#30363d] text-sky-400 hover:text-sky-300 hover:border-sky-500"
                : "bg-gray-50 border-gray-200 text-sky-600 hover:text-sky-700 hover:border-sky-400"
            }`}
            title="Click to copy sayimkhan09@gmail.com"
          >
            <span>sayimkhan09@gmail.com</span>
            {copiedEmail ? (
              <span className="text-emerald-500 font-bold flex items-center gap-0.5 text-[11px]">
                <Check className="w-3 h-3 stroke-[3]" /> Copied!
              </span>
            ) : (
              <Copy className="w-3 h-3 opacity-60" />
            )}
          </button>
        </div>

        {/* Bottom Copyright & Legal Links */}
        <div className="w-full pt-4 border-t border-gray-500/15 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs">
          {/* Copyright */}
          <div className="flex items-center gap-2">
            <span>© 2026 DevArena Live</span>
            <span>•</span>
            <span className="font-semibold text-sky-400">Sayim Khan</span>
            <span>•</span>
            <span>All Rights Reserved</span>
          </div>

          {/* Legal / Policy Links */}
          <div className="flex items-center flex-wrap justify-center gap-3 text-[11px]">
            <span className="hover:underline cursor-pointer">Trust Center</span>
            <span>|</span>
            <span className="hover:underline cursor-pointer">Terms of Use</span>
            <span>|</span>
            <span className="hover:underline cursor-pointer">Privacy Policy</span>
            <span>|</span>
            <span className="hover:underline cursor-pointer">Security</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
