import React, { useState, useEffect, useRef, useCallback } from "react";
import Lobby from "./components/Lobby";
import Topbar from "./components/Topbar";
import VideoPanel from "./components/VideoPanel";
import EditorPanel from "./components/EditorPanel";
import OutputPanel from "./components/OutputPanel";
import RightSidebar from "./components/RightSidebar";
import ShareModal from "./components/ShareModal";
import Toast from "./components/Toast";
import socketService from "./services/socket";
import { WebRTCManager } from "./services/webrtc";
import { executeCode } from "./services/piston";
import { LANGUAGES, getLanguageById } from "./constants/languages";

export default function App() {
  // Theme state ('dark' | 'light')
  const [theme, setTheme] = useState(() => {
    return localStorage.getItem("devarena_theme") || "dark";
  });

  const toggleTheme = () => {
    const next = theme === "dark" ? "light" : "dark";
    setTheme(next);
    localStorage.setItem("devarena_theme", next);
  };

  // Query parameters check (?room=... &role=...)
  const searchParams = new URLSearchParams(window.location.search);
  const initialRoomId = searchParams.get("room") || "";
  const initialRole = searchParams.get("role") || "";

  // Session state
  const [inRoom, setInRoom] = useState(false);
  const [roomId, setRoomId] = useState("");
  const [name, setName] = useState("");
  const [role, setRole] = useState("interviewer");
  const [interviewTitle, setInterviewTitle] = useState("");

  // Local media state
  const [localStream, setLocalStream] = useState(null);
  const [isMuted, setIsMuted] = useState(false);
  const [isCamOff, setIsCamOff] = useState(false);
  const [isScreenSharing, setIsScreenSharing] = useState(false);

  // Multi-peer map: { [socketId]: { id, name, role, stream, isMuted, isCamOff, isScreenSharing } }
  const [remotePeers, setRemotePeers] = useState({});
  const [peerTyping, setPeerTyping] = useState(false);

  // Code & Editor state
  const [languageId, setLanguageId] = useState("python");
  const [code, setCode] = useState(LANGUAGES[0].sample);
  const [question, setQuestion] = useState(
    "Write a function to check if a string is a palindrome. Handle empty strings and make sure comparison is case-insensitive, ignoring whitespace."
  );

  // Execution state
  const [isRunning, setIsRunning] = useState(false);
  const [outputData, setOutputData] = useState(null);

  // Chat messages
  const [messages, setMessages] = useState([]);

  // Modal & Toast
  const [isShareModalOpen, setIsShareModalOpen] = useState(false);
  const [toast, setToast] = useState(null);

  // References
  const socketRef = useRef(null);
  const webrtcRef = useRef(null);
  const webcamStreamRef = useRef(null);
  const screenStreamRef = useRef(null);
  const codeDebounceRef = useRef(null);
  const typingTimeoutRef = useRef(null);
  const isLocalTypingRef = useRef(false);

  const showToast = useCallback((message, type = "info") => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 3500);
  }, []);

  // Handle joining room from Lobby
  const handleJoin = async (params) => {
    setRoomId(params.roomId);
    setName(params.name);
    setRole(params.role);
    setInterviewTitle(params.title);
    setIsMuted(params.isMuted);
    setIsCamOff(params.isCamOff);

    // Acquire a fresh webcam & mic stream with high-compatibility audio constraints
    let stream = null;
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 1280 }, height: { ideal: 720 }, facingMode: "user" },
        audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true }
      });
    } catch (err) {
      console.warn("getUserMedia with preferred constraints failed, trying standard fallback:", err);
      try {
        stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      } catch (e2) {
        console.warn("Could not acquire media stream:", e2);
      }
    }

    if (stream) {
      stream.getAudioTracks().forEach((t) => (t.enabled = !params.isMuted));
      stream.getVideoTracks().forEach((t) => (t.enabled = !params.isCamOff));
      webcamStreamRef.current = stream;
      setLocalStream(stream);
    }

    setInRoom(true);

    // Initialize Socket
    const socket = socketService.connect();
    socketRef.current = socket;

    // Initialize Multi-Peer WebRTC Mesh
    const webrtc = new WebRTCManager(
      socket,
      params.roomId,
      (targetId, rStream) => {
        console.log(`[App] Remote stream received from peer ${targetId}`);
        setRemotePeers((prev) => ({
          ...prev,
          [targetId]: {
            ...(prev[targetId] || { id: targetId, name: "Participant", role: "candidate" }),
            stream: rStream
          }
        }));
      },
      (targetId, state) => {
        console.log(`[App] Peer ${targetId} connection state: ${state}`);
        if (state === "disconnected" || state === "failed" || state === "closed") {
          setRemotePeers((prev) => {
            const next = { ...prev };
            if (next[targetId]) {
              next[targetId] = { ...next[targetId], stream: null };
            }
            return next;
          });
        }
      }
    );

    if (stream) {
      webrtc.setLocalStream(stream);
    }
    webrtcRef.current = webrtc;

    // Join room on backend
    socket.emit("join-room", {
      roomId: params.roomId,
      name: params.name,
      role: params.role
    });

    // Listen to initial room state
    socket.on("init-room-state", (roomData) => {
      if (roomData.code) setCode(roomData.code);
      if (roomData.language) setLanguageId(roomData.language);
      if (roomData.question) setQuestion(roomData.question);
      if (roomData.messages) setMessages(roomData.messages);
      if (roomData.output) setOutputData(roomData.output);

      // Register existing participants in UI. 
      // NOTE: We do NOT call createOffer here. The existing peers will receive
      // "peer-joined" and will initiate the WebRTC offer to us. We just wait.
      const initialPeers = {};
      if (roomData.participants) {
        roomData.participants.forEach((p) => {
          if (p.id !== roomData.selfId) {
            initialPeers[p.id] = {
              ...p,
              stream: null
            };
          }
        });
      }
      setRemotePeers(initialPeers);
    });

    // When another peer joins
    socket.on("peer-joined", ({ peer }) => {
      setRemotePeers((prev) => ({
        ...prev,
        [peer.id]: {
          ...peer,
          stream: null
        }
      }));
      showToast(`🟢 ${peer.name} (${peer.role}) joined the interview!`, "success");
      // Initiate WebRTC offer to new peer
      webrtc.createOffer(peer.id);
    });

    // Peer updated media state (mute / cam / screen share)
    socket.on("peer-media-state", ({ id, isMuted: peerMuted, isCamOff: peerCamOff, isScreenSharing: peerSharing }) => {
      setRemotePeers((prev) => {
        if (!prev[id]) return prev;
        const current = prev[id];
        if (peerSharing !== undefined && peerSharing !== current.isScreenSharing) {
          if (peerSharing) {
            showToast(`🖥️ ${current.name} started screen sharing`, "info");
          } else {
            showToast(`🖥️ ${current.name} stopped screen sharing`, "info");
          }
        }
        return {
          ...prev,
          [id]: {
            ...current,
            isMuted: peerMuted !== undefined ? peerMuted : current.isMuted,
            isCamOff: peerCamOff !== undefined ? peerCamOff : current.isCamOff,
            isScreenSharing: peerSharing !== undefined ? peerSharing : current.isScreenSharing
          }
        };
      });
    });

    // When a peer leaves
    socket.on("peer-left", ({ id, name: leftName }) => {
      showToast(`👋 ${leftName} left the room.`, "info");
      webrtc.removePeer(id);
      setRemotePeers((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });
    });

    // Live code sync updates
    socket.on("code-update", ({ code: remoteCode, senderId }) => {
      if (senderId !== socket.id) {
        setCode(remoteCode);
        setPeerTyping(true);
        clearTimeout(typingTimeoutRef.current);
        typingTimeoutRef.current = setTimeout(() => {
          setPeerTyping(false);
        }, 1200);
      }
    });

    // Language sync
    socket.on("language-update", ({ language, code: newCode }) => {
      setLanguageId(language);
      if (newCode) setCode(newCode);
      showToast(`Language switched to ${language}`, "info");
    });

    // Question sync
    socket.on("question-update", ({ question: newQuestion }) => {
      setQuestion(newQuestion);
      showToast("Question updated by interviewer", "info");
    });

    // Chat message received
    socket.on("chat-message", (newMsg) => {
      setMessages((prev) => [...prev, newMsg]);
    });

    // Shared execution start
    socket.on("execution-start", () => {
      setIsRunning(true);
      setOutputData(null);
    });

    // Shared execution result
    socket.on("execution-result", (result) => {
      setIsRunning(false);
      setOutputData(result.output);
    });
  };

  // Broadcast code changes with smooth debounce
  const handleCodeChange = (newCode) => {
    setCode(newCode);
    isLocalTypingRef.current = true;

    clearTimeout(codeDebounceRef.current);
    codeDebounceRef.current = setTimeout(() => {
      if (socketRef.current && inRoom) {
        socketRef.current.emit("code-change", {
          roomId,
          code: newCode
        });
      }
      isLocalTypingRef.current = false;
    }, 250);
  };

  // Change Language
  const handleLanguageChange = (newLangId) => {
    const langObj = getLanguageById(newLangId);
    setLanguageId(newLangId);
    setCode(langObj.sample);

    if (socketRef.current && inRoom) {
      socketRef.current.emit("language-change", {
        roomId,
        language: newLangId,
        code: langObj.sample
      });
    }
  };

  // Reset Code
  const handleResetCode = () => {
    const langObj = getLanguageById(languageId);
    setCode(langObj.sample);
    if (socketRef.current && inRoom) {
      socketRef.current.emit("code-change", {
        roomId,
        code: langObj.sample
      });
    }
    showToast("Code reset to starter template", "info");
  };

  // Edit Problem Statement
  const handleQuestionChange = (newQuestion) => {
    setQuestion(newQuestion);
    if (socketRef.current && inRoom) {
      socketRef.current.emit("question-change", {
        roomId,
        question: newQuestion
      });
    }
  };

  // Run Code via Judge0
  const handleRunCode = async () => {
    if (!code.trim()) {
      showToast("Please write code before running!", "error");
      return;
    }

    const currentLang = getLanguageById(languageId);
    setIsRunning(true);
    setOutputData(null);

    // Notify peers that execution has started
    if (socketRef.current) {
      socketRef.current.emit("execution-start", { roomId });
    }

    const startTime = performance.now();

    try {
      const data = await executeCode(currentLang, code);
      const endTime = performance.now();
      const execTime = data.time ? `${data.time}s` : `${((endTime - startTime) / 1000).toFixed(2)}s`;

      let resultStatus = "success";
      if (data.compile_output) {
        resultStatus = "compile_error";
      } else if (data.status && data.status.id && data.status.id > 3) {
        resultStatus = data.status.id === 6 ? "compile_error" : "runtime_error";
      } else if (data.stderr && !data.stdout) {
        resultStatus = "runtime_error";
      }

      const parsedOutput = {
        compileError: data.compile_output || null,
        stdout: data.stdout || null,
        stderr: data.stderr || null,
        status: resultStatus,
        execTime
      };

      setOutputData(parsedOutput);

      // Broadcast execution result to both participants
      if (socketRef.current) {
        socketRef.current.emit("execution-result", {
          roomId,
          output: parsedOutput,
          status: resultStatus
        });
      }

      showToast(
        resultStatus === "success" ? "Code executed successfully!" : "Execution finished with errors",
        resultStatus === "success" ? "success" : "error"
      );
    } catch (err) {
      console.error("Execution error:", err);
      const errorOutput = {
        compileError: null,
        stdout: null,
        stderr: `Execution error: ${err.message}`,
        status: "runtime_error",
        execTime: "0.0s"
      };
      setOutputData(errorOutput);

      if (socketRef.current) {
        socketRef.current.emit("execution-result", {
          roomId,
          output: errorOutput,
          status: "runtime_error"
        });
      }
      showToast("Failed to execute code: " + err.message, "error");
    } finally {
      setIsRunning(false);
    }
  };

  // Clear Output
  const handleClearOutput = () => {
    setOutputData(null);
  };

  // Send Chat Message
  const handleSendMessage = (text) => {
    if (socketRef.current && inRoom) {
      socketRef.current.emit("chat-message", {
        roomId,
        text,
        name,
        role
      });
    }
  };

  // Toggle Microphone
  const handleToggleMic = () => {
    const nextMuted = !isMuted;
    setIsMuted(nextMuted);

    if (webcamStreamRef.current) {
      webcamStreamRef.current.getAudioTracks().forEach((track) => {
        track.enabled = !nextMuted;
      });
    }
    if (localStream) {
      localStream.getAudioTracks().forEach((track) => {
        track.enabled = !nextMuted;
      });
    }

    if (socketRef.current) {
      socketRef.current.emit("media-state-change", {
        roomId,
        isMuted: nextMuted,
        isCamOff,
        isScreenSharing
      });
    }
    showToast(nextMuted ? "🔇 Microphone muted" : "🎙️ Microphone active", "info");
  };

  // Toggle Camera
  const handleToggleCam = () => {
    if (isScreenSharing) {
      showToast("Cannot toggle camera while screen sharing", "info");
      return;
    }
    const nextCamOff = !isCamOff;
    setIsCamOff(nextCamOff);

    if (webcamStreamRef.current) {
      webcamStreamRef.current.getVideoTracks().forEach((track) => {
        track.enabled = !nextCamOff;
      });
    }
    if (localStream) {
      localStream.getVideoTracks().forEach((track) => {
        track.enabled = !nextCamOff;
      });
    }

    if (socketRef.current) {
      socketRef.current.emit("media-state-change", {
        roomId,
        isMuted,
        isCamOff: nextCamOff,
        isScreenSharing
      });
    }
    showToast(nextCamOff ? "📷 Camera turned off" : "📷 Camera turned on", "info");
  };

  // Screen Share Handler (Both Interviewer and Candidate)
  const handleScreenShare = async () => {
    // If currently screen sharing -> stop and restore webcam video track
    if (isScreenSharing) {
      if (screenStreamRef.current) {
        screenStreamRef.current.getTracks().forEach((t) => t.stop());
        screenStreamRef.current = null;
      }
      const camTrack = webcamStreamRef.current?.getVideoTracks()[0];
      if (camTrack && webrtcRef.current) {
        webrtcRef.current.replaceVideoTrack(camTrack);
      }
      setLocalStream(webcamStreamRef.current);
      setIsScreenSharing(false);

      if (socketRef.current) {
        socketRef.current.emit("media-state-change", {
          roomId,
          isMuted,
          isCamOff,
          isScreenSharing: false
        });
      }
      showToast("Returned to camera view", "info");
      return;
    }

    // Start Screen Sharing
    try {
      const screenStream = await navigator.mediaDevices.getDisplayMedia({
        video: { cursor: "always" },
        audio: true
      });
      const screenVideoTrack = screenStream.getVideoTracks()[0];

      // Keep user's active microphone audio track alongside the screen video track
      const micTracks = webcamStreamRef.current ? webcamStreamRef.current.getAudioTracks() : [];
      const combinedStream = new MediaStream([screenVideoTrack, ...micTracks]);

      if (webrtcRef.current) {
        webrtcRef.current.replaceVideoTrack(screenVideoTrack);
      }

      screenStreamRef.current = screenStream;
      setLocalStream(combinedStream);
      setIsScreenSharing(true);

      if (socketRef.current) {
        socketRef.current.emit("media-state-change", {
          roomId,
          isMuted,
          isCamOff,
          isScreenSharing: true
        });
      }
      showToast("🖥️ Screen sharing started", "success");

      // Handle native browser "Stop sharing" float bar
      screenVideoTrack.onended = () => {
        if (screenStreamRef.current) {
          screenStreamRef.current.getTracks().forEach((t) => t.stop());
          screenStreamRef.current = null;
        }
        const camTrack = webcamStreamRef.current?.getVideoTracks()[0];
        if (camTrack && webrtcRef.current) {
          webrtcRef.current.replaceVideoTrack(camTrack);
        }
        setLocalStream(webcamStreamRef.current);
        setIsScreenSharing(false);

        if (socketRef.current) {
          socketRef.current.emit("media-state-change", {
            roomId,
            isMuted,
            isCamOff,
            isScreenSharing: false
          });
        }
        showToast("Screen sharing ended", "info");
      };
    } catch (err) {
      if (err.name !== "NotAllowedError") {
        console.warn("Screen share failed:", err);
      }
    }
  };

  // Submit Evaluation
  const handleSubmitEvaluation = (evaluation) => {
    if (socketRef.current) {
      socketRef.current.emit("submit-evaluation", {
        roomId,
        evaluation
      });
      showToast("Evaluation scorecard submitted!", "success");
    }
  };

  // End Interview Session
  const handleEndSession = () => {
    if (window.confirm("Are you sure you want to end this interview session?")) {
      if (localStream) {
        localStream.getTracks().forEach((track) => track.stop());
      }
      if (webrtcRef.current) {
        webrtcRef.current.destroy();
      }
      socketService.disconnect();
      setInRoom(false);
      setLocalStream(null);
      setRemotePeers({});
      showToast("Interview session ended.", "info");
    }
  };

  const isDark = theme === "dark";
  const remotePeersList = Object.values(remotePeers);
  const participantCount = 1 + remotePeersList.length;

  return (
    <div className={`w-full font-sans transition-colors ${
      !inRoom ? "min-h-screen overflow-y-auto overflow-x-hidden" : "h-screen w-screen flex flex-col overflow-hidden select-none"
    } ${isDark ? "bg-[#0d1117] text-[#e6edf3]" : "bg-[#f6f8fa] text-[#1f2328]"}`}>
      {/* Toast Alert */}
      <Toast toast={toast} onClose={() => setToast(null)} />

      {/* Share Modal */}
      <ShareModal
        isOpen={isShareModalOpen}
        onClose={() => setIsShareModalOpen(false)}
        roomId={roomId}
        role={role}
        theme={theme}
      />

      {!inRoom ? (
        <Lobby
          onJoin={handleJoin}
          initialRoomId={initialRoomId}
          initialRole={initialRole}
          theme={theme}
          onToggleTheme={toggleTheme}
        />
      ) : (
        <>
          {/* Main Topbar */}
          <Topbar
            roomId={roomId}
            role={role}
            title={interviewTitle}
            participantCount={participantCount}
            theme={theme}
            onToggleTheme={toggleTheme}
            onOpenShare={() => setIsShareModalOpen(true)}
            onEndSession={handleEndSession}
          />

          {/* Core Workspace Body */}
          <div className="flex-1 flex overflow-hidden">
            {/* Left: Dynamic Multi-Peer Video Grid */}
            <VideoPanel
              localStream={localStream}
              remotePeers={remotePeersList}
              myName={name}
              myRole={role}
              isMuted={isMuted}
              isCamOff={isCamOff}
              isScreenSharing={isScreenSharing}
              theme={theme}
              onToggleMic={handleToggleMic}
              onToggleCam={handleToggleCam}
              onScreenShare={handleScreenShare}
            />

            {/* Center: Monaco Editor & Output Terminal */}
            <main className="flex-1 flex flex-col min-w-0 overflow-hidden">
              <EditorPanel
                code={code}
                languageId={languageId}
                question={question}
                role={role}
                peerTyping={peerTyping}
                isRunning={isRunning}
                theme={theme}
                onCodeChange={handleCodeChange}
                onLanguageChange={handleLanguageChange}
                onQuestionChange={handleQuestionChange}
                onRunCode={handleRunCode}
                onResetCode={handleResetCode}
              />

              <OutputPanel
                outputData={outputData}
                isRunning={isRunning}
                onClear={handleClearOutput}
                theme={theme}
              />
            </main>

            {/* Right: Tabbed Sidebar (Chat / Notes / Eval) */}
            <RightSidebar
              role={role}
              messages={messages}
              theme={theme}
              onSendMessage={handleSendMessage}
              onSubmitEvaluation={handleSubmitEvaluation}
            />
          </div>
        </>
      )}
    </div>
  );
}
