import React, { useState, useRef, useEffect } from "react";
import Editor from "@monaco-editor/react";
import {
  Play,
  RotateCcw,
  Edit3,
  Check,
  BookOpen,
  Sparkles,
  ChevronDown,
  Loader2
} from "lucide-react";
import { LANGUAGES, getLanguageById } from "../constants/languages";
import { PRESET_PROBLEMS } from "../constants/problems";

export default function EditorPanel({
  code,
  languageId,
  question,
  role,
  peerTyping,
  isRunning,
  theme,
  onCodeChange,
  onLanguageChange,
  onQuestionChange,
  onRunCode,
  onResetCode
}) {
  const [isEditingQuestion, setIsEditingQuestion] = useState(false);
  const [questionText, setQuestionText] = useState(question);
  const [showPresets, setShowPresets] = useState(false);

  const editorRef = useRef(null);
  const monacoRef = useRef(null);

  const isDark = theme === "dark";
  const currentLang = getLanguageById(languageId);

  // Update question state when incoming prop changes
  useEffect(() => {
    setQuestionText(question);
  }, [question]);

  // Update Monaco theme when theme prop changes
  useEffect(() => {
    if (monacoRef.current) {
      monacoRef.current.editor.setTheme(isDark ? "devarena-dark" : "vs");
    }
  }, [isDark]);

  const handleEditorDidMount = (editor, monaco) => {
    editorRef.current = editor;
    monacoRef.current = monaco;

    // Custom dark theme
    monaco.editor.defineTheme("devarena-dark", {
      base: "vs-dark",
      inherit: true,
      rules: [
        { token: "comment", foreground: "7d8590", fontStyle: "italic" },
        { token: "keyword", foreground: "ff7b72" },
        { token: "string", foreground: "a5d6ff" },
        { token: "number", foreground: "79c0ff" },
        { token: "type", foreground: "ffa657" }
      ],
      colors: {
        "editor.background": "#0d1117",
        "editor.foreground": "#e6edf3",
        "editorLineNumber.foreground": "#484f58",
        "editorLineNumber.activeForeground": "#58a6ff",
        "editorCursor.foreground": "#58a6ff",
        "editor.lineHighlightBackground": "#161b22",
        "editor.selectionBackground": "#264f78",
        "editorIndentGuide.background": "#21262d",
        "editorIndentGuide.activeBackground": "#30363d"
      }
    });

    monaco.editor.setTheme(isDark ? "devarena-dark" : "vs");
  };

  const handleSaveQuestion = () => {
    setIsEditingQuestion(false);
    onQuestionChange(questionText);
  };

  const selectPresetProblem = (preset) => {
    setQuestionText(preset.description);
    onQuestionChange(preset.description);
    setShowPresets(false);
  };

  return (
    <div className={`flex-1 flex flex-col min-w-0 overflow-hidden transition-colors ${
      isDark ? "bg-[#0d1117]" : "bg-white"
    }`}>
      {/* Question Header Bar */}
      <div className={`px-4 py-2.5 border-b flex items-start gap-3 shrink-0 ${
        isDark ? "bg-[#161b22] border-[#30363d]" : "bg-[#f6f8fa] border-[#d0d7de]"
      }`}>
        <div className="flex items-center gap-1.5 px-2 py-0.5 rounded bg-purple-500/10 border border-purple-500/20 text-purple-500 text-[10px] font-bold uppercase tracking-wider shrink-0 mt-0.5">
          <BookOpen className="w-3.5 h-3.5" />
          <span>Task</span>
        </div>

        {/* Question Text / Input */}
        <div className="flex-1 min-w-0">
          {isEditingQuestion ? (
            <textarea
              value={questionText}
              onChange={(e) => setQuestionText(e.target.value)}
              className={`w-full text-xs rounded-xl p-2.5 outline-none border resize-none font-sans leading-relaxed ${
                isDark
                  ? "bg-[#0d1117] border-[#30363d] text-[#e6edf3] focus:border-sky-500"
                  : "bg-white border-[#d0d7de] text-[#1f2328] focus:border-sky-600"
              }`}
              rows={3}
              autoFocus
            />
          ) : (
            <p className={`text-xs leading-relaxed select-text font-medium ${
              isDark ? "text-[#e6edf3]" : "text-[#1f2328]"
            }`}>
              {question}
            </p>
          )}
        </div>

        {/* Interviewer Controls for Question */}
        {role === "interviewer" && (
          <div className="relative flex items-center gap-1.5 shrink-0">
            {isEditingQuestion ? (
              <button
                onClick={handleSaveQuestion}
                className="flex items-center gap-1 px-3 py-1 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold rounded-lg shadow-sm transition-colors"
              >
                <Check className="w-3.5 h-3.5" />
                <span>Save</span>
              </button>
            ) : (
              <>
                <button
                  onClick={() => setIsEditingQuestion(true)}
                  className={`flex items-center gap-1 px-2.5 py-1 border rounded-lg text-xs font-semibold transition-colors ${
                    isDark
                      ? "bg-[#21262d] hover:bg-[#30363d] border-[#30363d] text-[#8b949e] hover:text-[#e6edf3]"
                      : "bg-white hover:bg-gray-100 border-[#d0d7de] text-[#656d76] hover:text-[#1f2328]"
                  }`}
                  title="Edit question statement"
                >
                  <Edit3 className="w-3 h-3" />
                  <span>Edit</span>
                </button>

                <button
                  onClick={() => setShowPresets(!showPresets)}
                  className={`flex items-center gap-1 px-2.5 py-1 border rounded-lg text-xs font-semibold transition-colors ${
                    isDark
                      ? "bg-[#21262d] hover:bg-[#30363d] border-[#30363d] text-[#8b949e] hover:text-[#e6edf3]"
                      : "bg-white hover:bg-gray-100 border-[#d0d7de] text-[#656d76] hover:text-[#1f2328]"
                  }`}
                  title="Choose from preset questions"
                >
                  <Sparkles className="w-3 h-3 text-amber-500" />
                  <span>Presets</span>
                  <ChevronDown className="w-3 h-3" />
                </button>

                {/* Presets dropdown */}
                {showPresets && (
                  <div className={`absolute right-0 top-8 z-30 w-72 border rounded-2xl shadow-2xl p-2 space-y-1 ${
                    isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
                  }`}>
                    <div className={`px-2 py-1 text-[10px] font-semibold uppercase tracking-wider ${
                      isDark ? "text-[#8b949e]" : "text-[#656d76]"
                    }`}>
                      Standard Interview Questions
                    </div>
                    {PRESET_PROBLEMS.map((preset) => (
                      <button
                        key={preset.id}
                        onClick={() => selectPresetProblem(preset)}
                        className={`w-full text-left p-2 rounded-xl text-xs transition-colors ${
                          isDark ? "text-[#e6edf3] hover:bg-[#21262d]" : "text-[#1f2328] hover:bg-gray-100"
                        }`}
                      >
                        <div className="font-semibold text-sky-500">{preset.title}</div>
                        <div className={`text-[11px] line-clamp-1 ${isDark ? "text-[#8b949e]" : "text-[#656d76]"}`}>
                          {preset.description}
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </div>

      {/* Editor Toolbar */}
      <div className={`h-11 border-b px-3 flex items-center justify-between gap-3 shrink-0 select-none ${
        isDark ? "bg-[#161b22]/90 border-[#30363d]" : "bg-[#f6f8fa] border-[#d0d7de]"
      }`}>
        {/* Left: Language Selector */}
        <div className="flex items-center gap-2">
          <select
            value={languageId}
            onChange={(e) => onLanguageChange(e.target.value)}
            className={`px-3 py-1 rounded-xl text-xs font-mono font-medium outline-none border cursor-pointer ${
              isDark
                ? "bg-[#0d1117] border-[#30363d] text-[#e6edf3] focus:border-sky-500"
                : "bg-white border-[#d0d7de] text-[#1f2328] focus:border-sky-600"
            }`}
          >
            {LANGUAGES.map((lang) => (
              <option key={lang.id} value={lang.id}>
                {lang.icon} {lang.name}
              </option>
            ))}
          </select>

          <button
            onClick={onResetCode}
            className={`flex items-center gap-1 px-2.5 py-1 border rounded-xl text-xs font-medium transition-colors ${
              isDark
                ? "bg-[#21262d] hover:bg-[#30363d] border-[#30363d] text-[#8b949e] hover:text-[#e6edf3]"
                : "bg-white hover:bg-gray-100 border-[#d0d7de] text-[#656d76] hover:text-[#1f2328]"
            }`}
            title="Reset to starter code"
          >
            <RotateCcw className="w-3 h-3" />
            <span className="hidden sm:inline">Reset</span>
          </button>
        </div>

        {/* Center: Live Typing Activity Indicator */}
        <div className="text-[11px] font-mono flex items-center gap-1.5">
          {peerTyping ? (
            <span className="text-emerald-500 font-semibold flex items-center gap-1 animate-pulse">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              Peer is typing...
            </span>
          ) : (
            <span className={isDark ? "text-[#484f58]" : "text-gray-400"}>
              Collaborative Live Sync
            </span>
          )}
        </div>

        {/* Right: Execute Code Button */}
        <button
          onClick={onRunCode}
          disabled={isRunning}
          className={`flex items-center gap-1.5 px-4 py-1.5 rounded-xl text-xs font-bold transition-all shadow-md active:scale-95 ${
            isRunning
              ? "bg-emerald-600/50 text-white cursor-not-allowed"
              : "bg-emerald-500 hover:bg-emerald-400 text-[#0d1117] shadow-emerald-500/20"
          }`}
        >
          {isRunning ? (
            <>
              <Loader2 className="w-3.5 h-3.5 animate-spin" />
              <span>Running...</span>
            </>
          ) : (
            <>
              <Play className="w-3.5 h-3.5 fill-current" />
              <span>Run Code</span>
            </>
          )}
        </button>
      </div>

      {/* Monaco Code Editor */}
      <div className="flex-1 relative overflow-hidden">
        <Editor
          height="100%"
          language={currentLang.monacoLang}
          value={code}
          onChange={(val) => onCodeChange(val || "")}
          onMount={handleEditorDidMount}
          theme={isDark ? "devarena-dark" : "vs"}
          options={{
            fontSize: 13.5,
            fontFamily: "'JetBrains Mono', 'Fira Code', monospace",
            fontLigatures: true,
            tabSize: 4,
            minimap: { enabled: false },
            scrollBeyondLastLine: false,
            automaticLayout: true,
            lineNumbers: "on",
            renderLineHighlight: "all",
            cursorBlinking: "smooth",
            cursorSmoothCaretAnimation: "on",
            padding: { top: 12, bottom: 12 }
          }}
        />
      </div>
    </div>
  );
}
