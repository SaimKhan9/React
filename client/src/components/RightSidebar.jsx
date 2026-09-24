import React, { useState, useEffect, useRef } from "react";
import {
  MessageSquare,
  Send,
  Sparkles,
  Users
} from "lucide-react";

export default function RightSidebar({
  role,
  messages = [],
  theme,
  onSendMessage
}) {
  const [inputText, setInputText] = useState("");
  const isDark = theme === "dark";
  const messagesEndRef = useRef(null);

  // Auto-scroll to latest message
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSend = (e) => {
    e.preventDefault();
    if (!inputText.trim()) return;
    onSendMessage(inputText.trim());
    setInputText("");
  };

  return (
    <aside className={`w-80 border-l flex flex-col shrink-0 overflow-hidden select-none transition-colors ${
      isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
    }`}>
      {/* Header */}
      <div className={`h-11 px-4 border-b flex items-center justify-between shrink-0 ${
        isDark ? "border-[#30363d] bg-[#161b22]" : "border-[#d0d7de] bg-[#f6f8fa]"
      }`}>
        <div className="flex items-center gap-2">
          <MessageSquare className="w-4 h-4 text-sky-500" />
          <span className={`text-xs font-bold ${isDark ? "text-[#e6edf3]" : "text-[#1f2328]"}`}>
            Live Room Chat
          </span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className={`text-[10px] font-mono px-2 py-0.5 rounded-full border ${
            isDark ? "bg-[#0d1117] border-[#30363d] text-[#8b949e]" : "bg-white border-[#d0d7de] text-[#656d76]"
          }`}>
            {messages.length} {messages.length === 1 ? "message" : "messages"}
          </span>
        </div>
      </div>

      {/* Messages Feed Area */}
      <div className={`flex-1 flex flex-col min-h-0 ${isDark ? "bg-[#0d1117]/60" : "bg-[#f6f8fa]/70"}`}>
        <div className="flex-1 p-3.5 overflow-y-auto space-y-3">
          {messages.length === 0 ? (
            <div className={`h-full flex flex-col items-center justify-center text-center p-6 gap-2 ${
              isDark ? "text-[#8b949e]" : "text-[#656d76]"
            }`}>
              <div className={`w-12 h-12 rounded-2xl flex items-center justify-center text-xl border ${
                isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
              }`}>
                💬
              </div>
              <p className="text-xs font-semibold">No messages yet</p>
              <p className="text-[11px] opacity-75 max-w-[200px]">
                Send a message to collaborate with candidate or interviewer in real-time.
              </p>
            </div>
          ) : (
            messages.map((msg) => (
              <div
                key={msg.id}
                className={`p-3 rounded-2xl border text-xs leading-relaxed transition-all ${
                  msg.role === "system"
                    ? isDark
                      ? "bg-[#161b22] border-[#30363d] text-[#8b949e] text-center"
                      : "bg-white border-[#d0d7de] text-[#656d76] text-center"
                    : msg.role === "interviewer"
                    ? isDark
                      ? "bg-purple-950/20 border-purple-500/25 text-[#e6edf3]"
                      : "bg-purple-50 border-purple-200 text-purple-950"
                    : isDark
                    ? "bg-[#1c2128] border-[#30363d] text-[#e6edf3]"
                    : "bg-white border-[#d0d7de] text-[#1f2328]"
                }`}
              >
                {msg.role !== "system" && (
                  <div className="flex items-center justify-between gap-2 mb-1.5">
                    <span
                      className={`font-bold text-[11px] flex items-center gap-1 ${
                        msg.role === "interviewer"
                          ? "text-purple-400"
                          : "text-emerald-500"
                      }`}
                    >
                      <span>{msg.role === "interviewer" ? "👔" : "🧑‍💻"}</span>
                      <span>{msg.sender}</span>
                      <span className="text-[9px] opacity-75 font-normal">
                        ({msg.role === "interviewer" ? "Interviewer" : "Candidate"})
                      </span>
                    </span>
                    <span className={`text-[10px] font-mono ${isDark ? "text-[#8b949e]" : "text-gray-400"}`}>
                      {msg.timestamp}
                    </span>
                  </div>
                )}
                <div className="whitespace-pre-wrap select-text leading-relaxed font-sans">{msg.text}</div>
              </div>
            ))
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Message Input Bar */}
        <form
          onSubmit={handleSend}
          className={`p-3 border-t flex items-center gap-2 ${
            isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
          }`}
        >
          <input
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            placeholder="Type a message..."
            className={`flex-1 px-3.5 py-2 rounded-xl text-xs outline-none border transition-colors ${
              isDark
                ? "bg-[#0d1117] border-[#30363d] text-[#e6edf3] placeholder-[#484f58] focus:border-sky-500"
                : "bg-[#f6f8fa] border-[#d0d7de] text-[#1f2328] placeholder-gray-400 focus:border-sky-600 shadow-inner"
            }`}
          />
          <button
            type="submit"
            disabled={!inputText.trim()}
            className="p-2.5 bg-sky-500 hover:bg-sky-400 disabled:opacity-40 disabled:cursor-not-allowed text-[#0d1117] rounded-xl transition-all active:scale-95 shadow-sm flex items-center justify-center"
            title="Send message"
          >
            <Send className="w-3.5 h-3.5 stroke-[2.5]" />
          </button>
        </form>
      </div>
    </aside>
  );
}
