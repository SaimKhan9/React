import React, { useEffect, useRef, useState } from "react";
import {
  Mic, MicOff, Video, VideoOff, ScreenShare,
  MonitorOff, Users, Pin, PinOff, Monitor
} from "lucide-react";

/* ─────────────────────────────────────────────
   Single Participant Video Tile
───────────────────────────────────────────── */
function ParticipantTile({
  name,
  role,
  isSelf,
  stream,
  isMuted,
  isCamOff,
  isScreenSharing,
  isDark,
  isPinned,
  onPin,
}) {
  const videoRef = useRef(null);
  const audioCtxRef = useRef(null);
  const animRef = useRef(null);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [isVideoReady, setIsVideoReady] = useState(false);

  // Attach media stream to video element
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    if (stream) {
      video.srcObject = stream;
      video.muted = isSelf; // Mute self to prevent feedback loop; remote audio plays through unmuted video element
      const playPromise = video.play();
      if (playPromise !== undefined) {
        playPromise.catch((e) => {
          if (e.name !== "AbortError") {
            console.warn("[Video/Audio] Autoplay note:", e.message);
          }
        });
      }
      setIsVideoReady(true);
    } else {
      video.srcObject = null;
      setIsVideoReady(false);
    }

    // Auto-resume audio/video if browser policy deferred it
    const unlockMedia = () => {
      if (video && video.paused && stream) {
        video.play().catch(() => {});
      }
    };
    document.addEventListener("click", unlockMedia, { once: true });

    const handleTrackChange = () => {
      if (video && stream) {
        video.srcObject = stream;
        video.play().catch(() => {});
      }
    };

    if (stream) {
      stream.addEventListener("addtrack", handleTrackChange);
      stream.addEventListener("removetrack", handleTrackChange);
    }

    return () => {
      document.removeEventListener("click", unlockMedia);
      if (stream) {
        stream.removeEventListener("addtrack", handleTrackChange);
        stream.removeEventListener("removetrack", handleTrackChange);
      }
    };
  }, [stream, isSelf]);

  // Speech Detection via Web Audio API (Speaking Glow Ring)
  useEffect(() => {
    if (!stream || isMuted) {
      setIsSpeaking(false);
      return;
    }

    const audioTracks = stream.getAudioTracks();
    if (!audioTracks.length || !audioTracks[0].enabled) {
      setIsSpeaking(false);
      return;
    }

    let audioCtx;
    let analyser;

    try {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      audioCtxRef.current = audioCtx;
      analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      const src = audioCtx.createMediaStreamSource(stream);
      src.connect(analyser);

      const data = new Uint8Array(analyser.frequencyBinCount);
      const tick = () => {
        analyser.getByteFrequencyData(data);
        const avg = data.reduce((a, b) => a + b, 0) / data.length;
        setIsSpeaking(avg > 10);
        animRef.current = requestAnimationFrame(tick);
      };
      tick();
    } catch (e) {
      console.warn("[Audio meter] setup warning:", e);
    }

    return () => {
      if (animRef.current) cancelAnimationFrame(animRef.current);
      if (audioCtx) audioCtx.close().catch(() => {});
    };
  }, [stream, isMuted]);

  const roleConfig = {
    interviewer: { label: "Interviewer", emoji: "👔", color: "text-sky-400", bg: "bg-sky-500/20 border-sky-500/40" },
    candidate:   { label: "Candidate",   emoji: "🧑‍💻", color: "text-emerald-400", bg: "bg-emerald-500/20 border-emerald-500/40" },
    observer:    { label: "Observer",    emoji: "👁️", color: "text-amber-400", bg: "bg-amber-500/20 border-amber-500/40" },
  };
  const cfg = roleConfig[role] || roleConfig.candidate;

  // Video is active if stream exists and camera is on (or if screen sharing)
  const hasLiveVideo = stream && (isScreenSharing || (!isCamOff && isVideoReady));

  return (
    <div className={`relative rounded-2xl overflow-hidden flex-1 min-h-0 select-none transition-all duration-300 ${
      isSpeaking ? "ring-2 ring-sky-400 ring-offset-2 ring-offset-black/50" : "ring-1 ring-white/5"
    } ${isDark ? "bg-[#0d1117]" : "bg-[#1a1d23]"}`}>

      {/* Video Element (handles video & audio for remote peer) */}
      <video
        ref={videoRef}
        autoPlay
        playsInline
        className={`absolute inset-0 w-full h-full transition-opacity duration-300 ${
          hasLiveVideo ? "opacity-100" : "opacity-0"
        } ${
          isScreenSharing
            ? "object-contain bg-black"
            : `object-cover ${isSelf ? "scale-x-[-1]" : ""}`
        }`}
      />

      {/* Screen Sharing Watermark Badge */}
      {isScreenSharing && (
        <div className="absolute top-2 left-2 z-10">
          <span className="flex items-center gap-1.5 px-2 py-1 rounded-lg text-[10px] font-bold bg-sky-500/90 text-[#0d1117] shadow-lg backdrop-blur-sm">
            <Monitor className="w-3.5 h-3.5 stroke-[2.5]" />
            <span>Screen Share</span>
          </span>
        </div>
      )}

      {/* Avatar Fallback (when camera is turned off and not screen sharing) */}
      {!hasLiveVideo && (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-gradient-to-br from-[#161b22] to-[#0d1117]">
          <div className={`w-14 h-14 rounded-2xl flex items-center justify-center text-2xl border ${cfg.bg} shadow-lg`}>
            {cfg.emoji}
          </div>
          <div className="text-center">
            <p className="text-white text-xs font-semibold truncate max-w-[130px]">{name}</p>
            <p className={`text-[10px] font-medium mt-0.5 ${cfg.color}`}>{cfg.label}</p>
          </div>
          {isCamOff && (
            <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/5 border border-white/10">
              <VideoOff className="w-3 h-3 text-rose-400" />
              <span className="text-[10px] text-rose-400">Camera Off</span>
            </div>
          )}
        </div>
      )}

      {/* Speaking Indicator Pulse Effect */}
      {isSpeaking && !isMuted && (
        <div className="absolute inset-0 pointer-events-none rounded-2xl ring-inset ring-2 ring-sky-400/30 animate-pulse" />
      )}

      {/* Bottom Information Overlay */}
      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/85 via-black/45 to-transparent pt-8 pb-2 px-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1.5 min-w-0">
            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${cfg.bg} ${cfg.color} shrink-0`}>
              {cfg.emoji} {isSelf ? "You" : cfg.label}
            </span>
            <span className="text-white text-xs font-medium truncate">{name}</span>
          </div>

          <div className="flex items-center gap-1 shrink-0 ml-2">
            {isMuted && (
              <div className="p-1 rounded-lg bg-rose-500/25 border border-rose-500/30" title="Muted">
                <MicOff className="w-3 h-3 text-rose-400" />
              </div>
            )}
            {isSpeaking && !isMuted && (
              <div className="flex items-center gap-0.5" title="Speaking">
                {[1, 2, 3].map((i) => (
                  <div
                    key={i}
                    className="w-0.5 bg-emerald-400 rounded-full animate-bounce"
                    style={{ height: `${6 + i * 3}px`, animationDelay: `${i * 90}ms` }}
                  />
                ))}
              </div>
            )}
            {onPin && (
              <button
                onClick={onPin}
                className="p-1 rounded-lg bg-white/10 hover:bg-white/20 text-white/70 hover:text-white transition-colors"
                title={isPinned ? "Unpin" : "Pin (Expand view)"}
              >
                {isPinned ? <PinOff className="w-3 h-3" /> : <Pin className="w-3 h-3" />}
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Live Badge for self webcam */}
      {isSelf && stream && !isScreenSharing && (
        <div className="absolute top-2 left-2">
          <span className="flex items-center gap-1 px-1.5 py-0.5 rounded-md text-[9px] font-bold bg-rose-500 text-white shadow">
            <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse" />
            LIVE
          </span>
        </div>
      )}
    </div>
  );
}

/* ─────────────────────────────────────────────
   Main VideoPanel Component
───────────────────────────────────────────── */
export default function VideoPanel({
  localStream,
  remotePeers,
  myName,
  myRole,
  isMuted,
  isCamOff,
  isScreenSharing,
  theme,
  onToggleMic,
  onToggleCam,
  onScreenShare,
}) {
  const isDark = theme === "dark";
  const [pinnedId, setPinnedId] = useState(null);

  const allParticipants = [
    {
      id: "self",
      name: myName || "You",
      role: myRole,
      stream: localStream,
      isMuted,
      isCamOff,
      isScreenSharing,
      isSelf: true,
    },
    ...remotePeers.map((p) => ({ ...p, isSelf: false })),
  ];

  // Auto-pin peer if they start sharing their screen
  useEffect(() => {
    const screenSharingPeer = allParticipants.find((p) => p.isScreenSharing);
    if (screenSharingPeer) {
      setPinnedId(screenSharingPeer.id);
    }
  }, [isScreenSharing, remotePeers]);

  const pinned = pinnedId ? allParticipants.find((p) => p.id === pinnedId) : null;
  const rest = pinned ? allParticipants.filter((p) => p.id !== pinnedId) : [];
  const totalCount = allParticipants.length;

  return (
    <aside className={`w-56 xl:w-64 flex flex-col shrink-0 border-r ${
      isDark ? "bg-[#0d1117] border-[#1c2128]" : "bg-[#13161b] border-[#1c2128]"
    }`}>
      {/* Header */}
      <div className={`flex items-center justify-between px-3 py-2.5 border-b ${
        isDark ? "border-[#1c2128]" : "border-[#1c2128]"
      }`}>
        <div className="flex items-center gap-2">
          <Users className="w-3.5 h-3.5 text-sky-400" />
          <span className="text-xs font-semibold text-white/80">Participants</span>
          <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-sky-500/20 text-sky-400 font-bold border border-sky-500/20">
            {totalCount}
          </span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
          <span className="text-[10px] text-emerald-400 font-medium">Live Call</span>
        </div>
      </div>

      {/* Video & Screen Share Grid */}
      <div className="flex-1 flex flex-col gap-2 p-2 overflow-y-auto min-h-0">
        {pinned ? (
          <>
            {/* Pinned / Screen Share Tile (Larger view) */}
            <div className="flex flex-col" style={{ flex: 3, minHeight: "180px" }}>
              <ParticipantTile
                {...pinned}
                isDark={isDark}
                isPinned
                onPin={() => setPinnedId(null)}
              />
            </div>
            {/* Other participants stacked below */}
            {rest.map((p) => (
              <div key={p.id} className="flex flex-col" style={{ flex: 1, minHeight: "90px" }}>
                <ParticipantTile
                  {...p}
                  isDark={isDark}
                  isPinned={false}
                  onPin={() => setPinnedId(p.id)}
                />
              </div>
            ))}
          </>
        ) : (
          allParticipants.map((p) => (
            <div
              key={p.id}
              className="flex flex-col"
              style={{
                flex: 1,
                minHeight: totalCount <= 2 ? "140px" : totalCount <= 3 ? "100px" : "80px",
                maxHeight: totalCount === 1 ? "260px" : undefined,
              }}
            >
              <ParticipantTile
                {...p}
                isDark={isDark}
                isPinned={false}
                onPin={allParticipants.length > 1 ? () => setPinnedId(p.id) : null}
              />
            </div>
          ))
        )}
      </div>

      {/* Bottom Media Controls (Mic, Cam, Screen Share) */}
      <div className={`flex items-center justify-around px-2 py-3 border-t ${
        isDark ? "border-[#1c2128]" : "border-[#1c2128]"
      }`}>
        {/* Toggle Microphone */}
        <button
          onClick={onToggleMic}
          title={isMuted ? "Unmute Microphone" : "Mute Microphone"}
          className={`flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${
            isMuted
              ? "bg-rose-500/20 text-rose-400 border border-rose-500/30 hover:bg-rose-500/30"
              : "bg-white/5 text-white/80 hover:bg-white/10 hover:text-white border border-white/5"
          }`}
        >
          {isMuted ? <MicOff className="w-4 h-4" /> : <Mic className="w-4 h-4" />}
          <span className="text-[9px] font-medium">{isMuted ? "Unmute" : "Mute"}</span>
        </button>

        {/* Toggle Camera */}
        <button
          onClick={onToggleCam}
          title={isCamOff ? "Turn On Camera" : "Turn Off Camera"}
          className={`flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${
            isCamOff
              ? "bg-rose-500/20 text-rose-400 border border-rose-500/30 hover:bg-rose-500/30"
              : "bg-white/5 text-white/80 hover:bg-white/10 hover:text-white border border-white/5"
          }`}
        >
          {isCamOff ? <VideoOff className="w-4 h-4" /> : <Video className="w-4 h-4" />}
          <span className="text-[9px] font-medium">{isCamOff ? "Cam On" : "Cam Off"}</span>
        </button>

        {/* Screen Sharing (Both Interviewer and Candidate) */}
        <button
          onClick={onScreenShare}
          title={isScreenSharing ? "Stop Screen Share" : "Share Your Screen"}
          className={`flex flex-col items-center gap-1 p-2 rounded-xl transition-all ${
            isScreenSharing
              ? "bg-sky-500/20 text-sky-400 border border-sky-500/30 hover:bg-sky-500/30 animate-pulse"
              : "bg-white/5 text-white/80 hover:bg-white/10 hover:text-white border border-white/5"
          }`}
        >
          {isScreenSharing ? <MonitorOff className="w-4 h-4 text-sky-400" /> : <ScreenShare className="w-4 h-4" />}
          <span className="text-[9px] font-medium">{isScreenSharing ? "Stop Share" : "Screen Share"}</span>
        </button>
      </div>
    </aside>
  );
}
