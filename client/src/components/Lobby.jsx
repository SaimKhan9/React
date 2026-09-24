import React, { useState, useEffect, useRef } from "react";
import {
  Code2,
  Video,
  VideoOff,
  Mic,
  MicOff,
  Sparkles,
  ArrowRight,
  ShieldCheck,
  Zap,
  Globe,
  Sun,
  Moon
} from "lucide-react";
import Footer from "./Footer";

export default function Lobby({ onJoin, initialRoomId, initialRole, theme, onToggleTheme }) {
  const [tab, setTab] = useState(initialRole === "candidate" ? "join" : "create");
  const [name, setName] = useState(
    initialRole === "candidate" ? "Sara Ali" : "Ahmed Khan"
  );
  const [interviewTitle, setInterviewTitle] = useState("Senior Full-Stack Engineer – Technical Round");
  const [joinRoomId, setJoinRoomId] = useState(initialRoomId || "");
  const [joinRole, setJoinRole] = useState(initialRole || "candidate");

  // Media preview state
  const [previewStream, setPreviewStream] = useState(null);
  const [isCameraActive, setIsCameraActive] = useState(true);
  const [isMicActive, setIsMicActive] = useState(true);
  const [audioLevel, setAudioLevel] = useState(0);
  const [mediaError, setMediaError] = useState(null);

  const videoRef = useRef(null);
  const audioContextRef = useRef(null);
  const analyserRef = useRef(null);
  const animFrameRef = useRef(null);
  const isJoiningRef = useRef(false);

  useEffect(() => {
    if (initialRoomId) {
      setJoinRoomId(initialRoomId);
      setTab("join");
    }
    if (initialRole) {
      setJoinRole(initialRole);
    }
  }, [initialRoomId, initialRole]);

  // Initialize preview camera and microphone
  useEffect(() => {
    let streamInstance = null;

    async function initMediaPreview() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { width: { ideal: 640 }, height: { ideal: 480 } },
          audio: true
        });
        streamInstance = stream;
        setPreviewStream(stream);
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          videoRef.current.play().catch(() => {});
        }

        // Setup audio meter
        try {
          const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
          audioContextRef.current = audioCtx;
          const analyser = audioCtx.createAnalyser();
          analyser.fftSize = 256;
          analyserRef.current = analyser;

          const source = audioCtx.createMediaStreamSource(stream);
          source.connect(analyser);

          const dataArray = new Uint8Array(analyser.frequencyBinCount);
          const checkVolume = () => {
            if (!analyserRef.current) return;
            analyserRef.current.getByteFrequencyData(dataArray);
            const avg = dataArray.reduce((acc, v) => acc + v, 0) / dataArray.length;
            setAudioLevel(Math.min(100, Math.round((avg / 128) * 100)));
            animFrameRef.current = requestAnimationFrame(checkVolume);
          };
          checkVolume();
        } catch (e) {
          console.warn("Audio meter init failed:", e);
        }
      } catch (err) {
        console.warn("Media access warning:", err);
        setMediaError(err.name === "NotAllowedError" ? "Camera/Mic permission denied" : "Camera/Mic unavailable");
      }
    }

    initMediaPreview();

    return () => {
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
      if (audioContextRef.current) audioContextRef.current.close().catch(() => {});
      // Always stop the preview stream on unmount — App.jsx gets a fresh stream independently
      if (streamInstance) {
        streamInstance.getTracks().forEach((track) => track.stop());
      }
    };
  }, []);

  const toggleCam = () => {
    if (previewStream) {
      const vidTrack = previewStream.getVideoTracks()[0];
      if (vidTrack) {
        vidTrack.enabled = !vidTrack.enabled;
        setIsCameraActive(vidTrack.enabled);
      }
    }
  };

  const toggleMic = () => {
    if (previewStream) {
      const audTrack = previewStream.getAudioTracks()[0];
      if (audTrack) {
        audTrack.enabled = !audTrack.enabled;
        setIsMicActive(audTrack.enabled);
      }
    }
  };

  const handleStart = (e) => {
    e.preventDefault();
    if (!name.trim()) return;

    isJoiningRef.current = true;

    if (tab === "create") {
      const generatedRoomId = "IV-" + Math.random().toString(36).substring(2, 8).toUpperCase();
      onJoin({
        roomId: generatedRoomId,
        name: name.trim(),
        role: "interviewer",
        title: interviewTitle.trim(),
        mediaStream: previewStream,
        isMuted: !isMicActive,
        isCamOff: !isCameraActive
      });
    } else {
      let cleanRoomId = joinRoomId.trim();
      if (cleanRoomId.includes("room=")) {
        const match = cleanRoomId.match(/room=([A-Za-z0-9\-_]+)/);
        if (match) cleanRoomId = match[1];
      }
      if (!cleanRoomId) return;

      onJoin({
        roomId: cleanRoomId,
        name: name.trim(),
        role: joinRole,
        title: "Technical Interview",
        mediaStream: previewStream,
        isMuted: !isMicActive,
        isCamOff: !isCameraActive
      });
    }
  };

  const isDark = theme === "dark";

  return (
    <div className={`relative min-h-screen w-full flex flex-col justify-between items-center transition-colors duration-200 overflow-x-hidden ${
      isDark ? "bg-[#0d1117] text-[#e6edf3]" : "bg-[#f6f8fa] text-[#1f2328]"
    }`}>
      {/* Top Navbar with Dark Mode Toggle */}
      <header className="w-full max-w-6xl px-4 sm:px-8 py-4 flex items-center justify-between z-20">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-sky-500 flex items-center justify-center text-white font-bold shadow-sm shadow-sky-500/20">
            <Code2 className="w-4 h-4 stroke-[2.5]" />
          </div>
          <span className="font-bold text-sm tracking-tight">
            Dev<span className="text-sky-500">Arena</span> Live
          </span>
        </div>

        <button
          onClick={onToggleTheme}
          className={`flex items-center gap-2 px-3 py-1.5 rounded-xl border text-xs font-semibold shadow-sm transition-all ${
            isDark
              ? "bg-[#161b22] border-[#30363d] text-[#e6edf3] hover:bg-[#21262d]"
              : "bg-white border-[#d0d7de] text-[#1f2328] hover:bg-[#f3f4f6]"
          }`}
          title="Toggle Dark / Light Mode"
        >
          {isDark ? (
            <>
              <Sun className="w-4 h-4 text-amber-400" />
              <span>Light Mode</span>
            </>
          ) : (
            <>
              <Moon className="w-4 h-4 text-sky-600" />
              <span>Dark Mode</span>
            </>
          )}
        </button>
      </header>

      {/* Dynamic Background Glows */}
      <div className="absolute top-1/4 -left-48 w-96 h-96 bg-sky-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 -right-48 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl pointer-events-none" />

      {/* Center Main Cards Content */}
      <main className="w-full flex items-center justify-center p-4 sm:p-6 my-auto z-10">
        <div className="relative w-full max-w-4xl grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
        {/* Left Column: Media Check Preview */}
        <div className="lg:col-span-5 flex flex-col items-center">
          <div className={`w-full max-w-sm rounded-2xl p-4 shadow-xl border ${
            isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
          }`}>
            <div className={`text-xs font-semibold uppercase tracking-wider mb-3 flex items-center justify-between ${
              isDark ? "text-[#8b949e]" : "text-[#656d76]"
            }`}>
              <span>AV Device Check</span>
              <span className="flex items-center gap-1.5 text-emerald-500 font-medium">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                Live Preview
              </span>
            </div>

            {/* Video Preview Box */}
            <div className="relative w-full aspect-video rounded-xl bg-black border border-[#30363d] overflow-hidden flex items-center justify-center group shadow-inner">
              <video
                ref={videoRef}
                autoPlay
                playsInline
                muted
                className={`w-full h-full object-cover scale-x-[-1] transition-opacity duration-300 ${
                  isCameraActive && !mediaError ? "opacity-100" : "opacity-0"
                }`}
              />

              {(!isCameraActive || mediaError) && (
                <div className={`absolute inset-0 flex flex-col items-center justify-center gap-2 ${
                  isDark ? "bg-[#161b22] text-[#8b949e]" : "bg-[#f6f8fa] text-[#656d76]"
                }`}>
                  <div className={`w-14 h-14 rounded-full flex items-center justify-center text-2xl border ${
                    isDark ? "bg-[#21262d] border-[#30363d]" : "bg-white border-[#d0d7de]"
                  }`}>
                    {tab === "create" ? "👔" : "🧑‍💻"}
                  </div>
                  <span className="text-xs font-medium">
                    {mediaError || "Camera is turned off"}
                  </span>
                </div>
              )}

              {/* Bottom Quick Controls */}
              <div className="absolute bottom-3 flex items-center gap-2 bg-black/75 backdrop-blur-md px-3 py-1.5 rounded-xl border border-white/10 shadow-lg">
                <button
                  type="button"
                  onClick={toggleMic}
                  className={`p-2 rounded-lg transition-colors ${
                    isMicActive
                      ? "text-white hover:bg-white/20"
                      : "text-rose-400 bg-rose-500/20"
                  }`}
                  title={isMicActive ? "Mute Microphone" : "Unmute Microphone"}
                >
                  {isMicActive ? <Mic className="w-4 h-4" /> : <MicOff className="w-4 h-4" />}
                </button>

                <button
                  type="button"
                  onClick={toggleCam}
                  className={`p-2 rounded-lg transition-colors ${
                    isCameraActive
                      ? "text-white hover:bg-white/20"
                      : "text-rose-400 bg-rose-500/20"
                  }`}
                  title={isCameraActive ? "Turn Off Camera" : "Turn On Camera"}
                >
                  {isCameraActive ? <Video className="w-4 h-4" /> : <VideoOff className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Mic Level Meter */}
            <div className="mt-3.5 flex items-center gap-2.5">
              <span className={`text-[11px] font-mono shrink-0 ${isDark ? "text-[#8b949e]" : "text-[#656d76]"}`}>
                Mic Level:
              </span>
              <div className={`flex-1 h-1.5 rounded-full overflow-hidden ${isDark ? "bg-[#21262d]" : "bg-gray-200"}`}>
                <div
                  className="h-full bg-emerald-500 transition-all duration-75"
                  style={{ width: `${isMicActive ? audioLevel : 0}%` }}
                />
              </div>
            </div>
          </div>

          <div className={`mt-4 flex items-center gap-4 text-xs ${isDark ? "text-[#8b949e]" : "text-[#656d76]"}`}>
            <span className="flex items-center gap-1.5">
              <ShieldCheck className="w-4 h-4 text-sky-500" />
              End-to-End P2P
            </span>
            <span className="flex items-center gap-1.5">
              <Zap className="w-4 h-4 text-amber-500" />
              Multi-Participant Ready
            </span>
          </div>
        </div>

        {/* Right Column: Room Config Card */}
        <div className="lg:col-span-7">
          <div className={`border rounded-3xl p-6 sm:p-8 shadow-2xl backdrop-blur-md ${
            isDark ? "bg-[#161b22] border-[#30363d]" : "bg-white border-[#d0d7de]"
          }`}>
            {/* Header Brand */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-sky-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-sky-500/20 text-white font-bold">
                  <Code2 className="w-6 h-6 stroke-[2.5]" />
                </div>
                <div>
                  <h1 className="text-xl font-bold tracking-tight">
                    Dev<span className="text-sky-500">Arena</span> Live
                  </h1>
                  <p className={`text-xs ${isDark ? "text-[#8b949e]" : "text-[#656d76]"}`}>
                    Multi-Person IDE • P2P Video Call • Judge0 Engine
                  </p>
                </div>
              </div>
              <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-sky-500/10 text-sky-500 border border-sky-500/20">
                <Sparkles className="w-3 h-3" />
                Production v2.0
              </span>
            </div>

            {/* Mode Tabs */}
            <div className={`flex p-1 rounded-xl border mb-6 ${
              isDark ? "bg-[#0d1117] border-[#30363d]" : "bg-[#f6f8fa] border-[#d0d7de]"
            }`}>
              <button
                type="button"
                onClick={() => setTab("create")}
                className={`flex-1 py-2.5 text-xs font-semibold rounded-lg transition-all ${
                  tab === "create"
                    ? isDark
                      ? "bg-[#21262d] text-[#e6edf3] shadow-sm"
                      : "bg-white text-[#1f2328] shadow-sm"
                    : isDark
                    ? "text-[#8b949e] hover:text-[#e6edf3]"
                    : "text-[#656d76] hover:text-[#1f2328]"
                }`}
              >
                ⚡ Create Interview
              </button>
              <button
                type="button"
                onClick={() => setTab("join")}
                className={`flex-1 py-2.5 text-xs font-semibold rounded-lg transition-all ${
                  tab === "join"
                    ? isDark
                      ? "bg-[#21262d] text-[#e6edf3] shadow-sm"
                      : "bg-white text-[#1f2328] shadow-sm"
                    : isDark
                    ? "text-[#8b949e] hover:text-[#e6edf3]"
                    : "text-[#656d76] hover:text-[#1f2328]"
                }`}
              >
                🔗 Join Interview
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleStart} className="space-y-4">
              <div>
                <label className={`block text-xs font-semibold uppercase tracking-wider mb-1.5 ${
                  isDark ? "text-[#8b949e]" : "text-[#656d76]"
                }`}>
                  Your Name
                </label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Alex Johnson"
                  className={`w-full px-3.5 py-2.5 rounded-xl text-sm outline-none border transition-colors ${
                    isDark
                      ? "bg-[#0d1117] border-[#30363d] text-[#e6edf3] placeholder-[#484f58] focus:border-sky-500"
                      : "bg-[#f6f8fa] border-[#d0d7de] text-[#1f2328] placeholder-gray-400 focus:border-sky-600"
                  }`}
                />
              </div>

              {tab === "create" ? (
                <div>
                  <label className={`block text-xs font-semibold uppercase tracking-wider mb-1.5 ${
                    isDark ? "text-[#8b949e]" : "text-[#656d76]"
                  }`}>
                    Interview Title / Role
                  </label>
                  <input
                    type="text"
                    value={interviewTitle}
                    onChange={(e) => setInterviewTitle(e.target.value)}
                    placeholder="e.g. Senior Backend Engineer - Round 2"
                    className={`w-full px-3.5 py-2.5 rounded-xl text-sm outline-none border transition-colors ${
                      isDark
                        ? "bg-[#0d1117] border-[#30363d] text-[#e6edf3] placeholder-[#484f58] focus:border-sky-500"
                        : "bg-[#f6f8fa] border-[#d0d7de] text-[#1f2328] placeholder-gray-400 focus:border-sky-600"
                    }`}
                  />
                </div>
              ) : (
                <div className="space-y-3">
                  <div>
                    <label className={`block text-xs font-semibold uppercase tracking-wider mb-1.5 ${
                      isDark ? "text-[#8b949e]" : "text-[#656d76]"
                    }`}>
                      Interview Room ID or Link
                    </label>
                    <input
                      type="text"
                      required
                      value={joinRoomId}
                      onChange={(e) => setJoinRoomId(e.target.value)}
                      placeholder="e.g. IV-A9X2Z1 or paste full link"
                      className={`w-full px-3.5 py-2.5 rounded-xl text-sm font-mono outline-none border transition-colors ${
                        isDark
                          ? "bg-[#0d1117] border-[#30363d] text-sky-400 placeholder-[#484f58] focus:border-sky-500"
                          : "bg-[#f6f8fa] border-[#d0d7de] text-sky-600 placeholder-gray-400 focus:border-sky-600"
                      }`}
                    />
                  </div>

                  {/* Multi-Person Role Selection */}
                  <div>
                    <label className={`block text-xs font-semibold uppercase tracking-wider mb-1.5 ${
                      isDark ? "text-[#8b949e]" : "text-[#656d76]"
                    }`}>
                      Joining As
                    </label>
                    <div className="grid grid-cols-3 gap-2">
                      {[
                        { id: "candidate", label: "🧑‍💻 Candidate" },
                        { id: "interviewer", label: "👔 Interviewer" },
                        { id: "observer", label: "👁️ Observer" }
                      ].map((r) => (
                        <button
                          key={r.id}
                          type="button"
                          onClick={() => setJoinRole(r.id)}
                          className={`py-2 px-2 text-xs font-semibold rounded-xl border transition-all ${
                            joinRole === r.id
                              ? isDark
                                ? "bg-sky-500/15 border-sky-500 text-sky-400"
                                : "bg-sky-50 border-sky-600 text-sky-700"
                              : isDark
                              ? "bg-[#0d1117] border-[#30363d] text-[#8b949e]"
                              : "bg-[#f6f8fa] border-[#d0d7de] text-[#656d76]"
                          }`}
                        >
                          {r.label}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              <button
                type="submit"
                className="w-full mt-2 py-3 px-4 bg-sky-500 hover:bg-sky-400 text-[#0d1117] font-bold text-sm rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-sky-500/25 transition-all active:scale-[0.99]"
              >
                <span>
                  {tab === "create" ? "Launch Interview & Get Link" : "Enter Interview Session"}
                </span>
                <ArrowRight className="w-4 h-4 stroke-[2.5]" />
              </button>
            </form>

            {/* Quick feature row */}
            <div className={`mt-6 pt-5 border-t grid grid-cols-3 gap-2 text-center text-[11px] ${
              isDark ? "border-[#30363d] text-[#8b949e]" : "border-[#d0d7de] text-[#656d76]"
            }`}>
              <div className="flex flex-col items-center">
                <Globe className="w-4 h-4 text-sky-500 mb-1" />
                <span>Monaco VS Code</span>
              </div>
              <div className="flex flex-col items-center">
                <Video className="w-4 h-4 text-emerald-500 mb-1" />
                <span>Multi-Peer WebRTC</span>
              </div>
              <div className="flex flex-col items-center">
                <Zap className="w-4 h-4 text-purple-500 mb-1" />
                <span>Judge0 Execution</span>
              </div>
            </div>
          </div>
        </div>
        </div>
      </main>

      {/* Professional Talview Footer with Sayim Khan's Developer Links */}
      <Footer theme={theme} />
    </div>
  );
}

