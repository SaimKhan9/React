import React, { useState } from "react";
import {
  Terminal,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Loader2,
  Copy,
  Check,
  Maximize2,
  Minimize2,
  Cpu
} from "lucide-react";

export default function OutputPanel({ outputData, isRunning, onClear, theme }) {
  const [copied, setCopied] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const [activeTab, setActiveTab] = useState("tests"); // "tests" | "raw"

  const isDark = theme === "dark";

  const handleCopy = () => {
    if (!outputData) return;
    const text = [
      outputData.stdout,
      outputData.stderr,
      outputData.compileError
    ].filter(Boolean).join("\n");
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const getStatusBadge = () => {
    if (isRunning) {
      return (
        <span className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-mono font-medium bg-sky-500/10 text-sky-500 border border-sky-500/20">
          <Loader2 className="w-3 h-3 animate-spin" />
          Running on Judge0 Engine...
        </span>
      );
    }

    if (!outputData) {
      return (
        <span className={`text-[11px] font-mono ${isDark ? "text-[#8b949e]" : "text-[#656d76]"}`}>
          Ready to execute
        </span>
      );
    }

    const { status } = outputData;
    if (status === "success") {
      return (
        <span className="flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-mono font-semibold bg-emerald-500/10 text-emerald-500 border border-emerald-500/20">
          <CheckCircle2 className="w-3.5 h-3.5" />
          Execution Finished (0)
        </span>
      );
    } else if (status === "compile_error") {
      return (
        <span className="flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-mono font-semibold bg-amber-500/10 text-amber-500 border border-amber-500/20">
          <AlertTriangle className="w-3.5 h-3.5" />
          Compilation Error
        </span>
      );
    } else {
      return (
        <span className="flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-mono font-semibold bg-rose-500/10 text-rose-500 border border-rose-500/20">
          <XCircle className="w-3.5 h-3.5" />
          Runtime Error
        </span>
      );
    }
  };

  // Parse lines to detect individual test passes or fails
  const renderFormattedTests = (stdoutText) => {
    if (!stdoutText) return null;
    const lines = stdoutText.split("\n");

    return (
      <div className="space-y-1.5 font-mono text-xs">
        {lines.map((line, idx) => {
          if (!line.trim()) return null;
          const isPass = line.includes("PASS") || line.includes("✅") || line.includes("True") || line.includes("true");
          const isFail = line.includes("FAIL") || line.includes("❌") || line.includes("False") || line.includes("false");

          return (
            <div
              key={idx}
              className={`p-2 rounded-lg border flex items-center justify-between text-xs transition-colors ${
                isPass
                  ? isDark
                    ? "bg-emerald-950/20 border-emerald-500/30 text-emerald-300"
                    : "bg-emerald-50 border-emerald-300 text-emerald-800"
                  : isFail
                  ? isDark
                    ? "bg-rose-950/20 border-rose-500/30 text-rose-300"
                    : "bg-rose-50 border-rose-300 text-rose-800"
                  : isDark
                  ? "bg-[#161b22] border-[#30363d] text-[#e6edf3]"
                  : "bg-white border-[#d0d7de] text-[#1f2328]"
              }`}
            >
              <span className="select-text whitespace-pre-wrap">{line}</span>
              {isPass && (
                <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-emerald-500/20 text-emerald-500 shrink-0 ml-2">
                  PASS
                </span>
              )}
              {isFail && (
                <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-rose-500/20 text-rose-500 shrink-0 ml-2">
                  FAIL
                </span>
              )}
            </div>
          );
        })}
      </div>
    );
  };

  return (
    <div
      className={`border-t flex flex-col shrink-0 overflow-hidden select-text transition-all duration-200 ${
        isExpanded ? "h-80" : "h-52"
      } ${isDark ? "bg-[#0d1117] border-[#30363d]" : "bg-[#f6f8fa] border-[#d0d7de]"}`}
    >
      {/* Terminal Title Bar */}
      <div className={`h-9 border-b px-3 flex items-center justify-between shrink-0 select-none ${
        isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
      }`}>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 font-semibold text-xs text-sky-500">
            <Terminal className="w-4 h-4" />
            <span>Output Console</span>
          </div>

          <div className="h-3.5 w-px bg-gray-600/30" />

          {/* Mode Tabs */}
          <div className="flex items-center gap-1">
            <button
              onClick={() => setActiveTab("tests")}
              className={`px-2.5 py-0.5 text-xs font-semibold rounded-md transition-colors ${
                activeTab === "tests"
                  ? isDark
                    ? "bg-[#21262d] text-[#e6edf3]"
                    : "bg-gray-100 text-[#1f2328]"
                  : isDark
                  ? "text-[#8b949e] hover:text-[#e6edf3]"
                  : "text-[#656d76] hover:text-[#1f2328]"
              }`}
            >
              Test Results
            </button>
            <button
              onClick={() => setActiveTab("raw")}
              className={`px-2.5 py-0.5 text-xs font-semibold rounded-md transition-colors ${
                activeTab === "raw"
                  ? isDark
                    ? "bg-[#21262d] text-[#e6edf3]"
                    : "bg-gray-100 text-[#1f2328]"
                  : isDark
                  ? "text-[#8b949e] hover:text-[#e6edf3]"
                  : "text-[#656d76] hover:text-[#1f2328]"
              }`}
            >
              Raw Terminal
            </button>
          </div>

          <div className="ml-2">{getStatusBadge()}</div>
        </div>

        {/* Right Action Buttons */}
        <div className="flex items-center gap-1.5">
          {outputData && (
            <button
              onClick={handleCopy}
              className={`flex items-center gap-1 px-2 py-0.5 rounded text-xs transition-colors ${
                isDark
                  ? "text-[#8b949e] hover:text-[#e6edf3] hover:bg-[#21262d]"
                  : "text-[#656d76] hover:text-[#1f2328] hover:bg-gray-100"
              }`}
              title="Copy output"
            >
              {copied ? <Check className="w-3 h-3 text-emerald-500" /> : <Copy className="w-3 h-3" />}
              <span>{copied ? "Copied" : "Copy"}</span>
            </button>
          )}

          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className={`p-1 rounded text-xs transition-colors ${
              isDark
                ? "text-[#8b949e] hover:text-[#e6edf3] hover:bg-[#21262d]"
                : "text-[#656d76] hover:text-[#1f2328] hover:bg-gray-100"
            }`}
            title={isExpanded ? "Collapse height" : "Expand height"}
          >
            {isExpanded ? <Minimize2 className="w-3.5 h-3.5" /> : <Maximize2 className="w-3.5 h-3.5" />}
          </button>

          <button
            onClick={onClear}
            className={`flex items-center gap-1 px-2 py-0.5 rounded text-xs transition-colors ${
              isDark
                ? "text-[#8b949e] hover:text-[#e6edf3] hover:bg-[#21262d]"
                : "text-[#656d76] hover:text-[#1f2328] hover:bg-gray-100"
            }`}
            title="Clear console"
          >
            <Trash2 className="w-3 h-3" />
            <span>Clear</span>
          </button>
        </div>
      </div>

      {/* Terminal Content Area */}
      <div className="flex-1 p-3 overflow-y-auto font-mono text-xs leading-relaxed">
        {isRunning && (
          <div className="flex items-center gap-2 text-sky-500 animate-pulse">
            <Loader2 className="w-4 h-4 animate-spin" />
            <span>Transmitting code to Judge0 execution engine and verifying test cases...</span>
          </div>
        )}

        {!isRunning && !outputData && (
          <div className={`p-4 rounded-xl border border-dashed text-center flex flex-col items-center justify-center gap-1.5 ${
            isDark ? "border-[#30363d] text-[#8b949e]" : "border-[#d0d7de] text-[#656d76]"
          }`}>
            <span className="text-xl">⚡</span>
            <span className="font-semibold text-xs">Ready to Run</span>
            <span className="text-[11px] opacity-75">
              Click "▶ Run Code" above to execute your solution and see live test results.
            </span>
          </div>
        )}

        {!isRunning && outputData && (
          <div className="space-y-3">
            {/* Compile Errors */}
            {outputData.compileError && (
              <div className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-400 whitespace-pre-wrap">
                <div className="font-bold flex items-center gap-1.5 text-rose-500 mb-1">
                  <AlertTriangle className="w-4 h-4" />
                  <span>Compilation Diagnostic:</span>
                </div>
                {outputData.compileError}
              </div>
            )}

            {/* Standard Error */}
            {outputData.stderr && (
              <div className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-400 whitespace-pre-wrap">
                <div className="font-bold flex items-center gap-1.5 text-rose-500 mb-1">
                  <XCircle className="w-4 h-4" />
                  <span>Runtime Error / Traceback:</span>
                </div>
                {outputData.stderr}
              </div>
            )}

            {/* Formatted Test Results View */}
            {activeTab === "tests" && outputData.stdout && (
              <div className="space-y-2">
                <div className={`text-[11px] font-semibold uppercase tracking-wider ${
                  isDark ? "text-[#8b949e]" : "text-[#656d76]"
                }`}>
                  Test Suite Assertions:
                </div>
                {renderFormattedTests(outputData.stdout)}
              </div>
            )}

            {/* Raw View */}
            {activeTab === "raw" && outputData.stdout && (
              <div className={`p-3 rounded-xl border whitespace-pre-wrap select-text ${
                isDark ? "bg-[#161b22] border-[#30363d] text-[#e6edf3]" : "bg-white border-[#d0d7de] text-[#1f2328]"
              }`}>
                {outputData.stdout}
              </div>
            )}

            {/* Benchmark Footer */}
            {outputData.status === "success" && (
              <div className="pt-2 flex items-center gap-4 text-[11px] text-emerald-500 font-mono">
                <span className="flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Exit code: 0 (OK)</span>
                </span>
                <span className="flex items-center gap-1 opacity-80">
                  <Cpu className="w-3.5 h-3.5" />
                  <span>Execution time: {outputData.execTime || "0.2s"}</span>
                </span>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
