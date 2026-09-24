# ⚡ DevArena Live — Professional Real-Time Collaborative Technical Interview Platform

A full-stack, production-grade technical interview web application built with **React.js**, **WebRTC**, **Monaco Editor (VS Code)**, **Socket.io**, and the **Judge0 / Piston Engine** for real multi-language code execution.

---

## 🌟 Tech Stack & Core Technologies

| Layer | Technology | Purpose |
|---|---|---|
| **Frontend UI** | **React.js (Vite)** + **Tailwind CSS** + **Lucide Icons** | Ultra-responsive, sleek dark theme with glassmorphism accents |
| **Code Editor** | **Monaco Editor** (`@monaco-editor/react`) | Full VS Code engine inside browser with syntax highlighting & bracket matching |
| **Video & Audio** | **WebRTC (P2P)** | Low-latency audio/video call, speaking detection ring, cam/mic controls, screen sharing |
| **Real-Time Sync** | **Socket.io** + **WebSockets** | Bi-directional live code synchronization, language sync, chat, and shared execution output |
| **Code Execution** | **Judge0 CE API** | Live sandboxed execution for 9+ languages (Python, JavaScript, TypeScript, C++, Java, Go, Rust, Ruby, PHP) |
| **Backend Server** | **Node.js** + **Express** + **Socket.io** | Room state management, WebRTC signaling relay, code execution proxy |

---

## 🚀 Features

1. **Interview Session Creation & Joining**:
   - **Interviewer**: Enter your name and interview title, instantly get an interview room with a unique room ID (e.g. `IV-7A9B2X`) and one-click shareable candidate link.
   - **Candidate**: Open the invite link to directly enter the session with zero signup required.
   - **Device Preview**: Test camera feed and live microphone volume level before entering.

2. **WebRTC Peer-to-Peer Video Call**:
   - Real-time video/audio streaming between Interviewer and Candidate.
   - Speaking indicator: Green glowing ring pulsates around the person currently speaking using Web Audio API analysis.
   - Toggle microphone (mute/unmute) and camera (on/off) with live status badges.
   - One-click screen sharing (`getDisplayMedia`).

3. **Monaco Code Editor**:
   - VS Code Monaco engine with custom high-contrast dark theme.
   - Multi-language support: Python 3, JavaScript (Node), TypeScript, C++ (GCC), Java (JDK), Go, Rust, Ruby, PHP.
   - Curated starter templates and test cases for each language.
   - Smooth bi-directional code synchronization with debounce to prevent cursor jumping.
   - "Peer is typing..." real-time presence indicators.

4. **Multi-Language Sandboxed Execution**:
   - Real execution powered by Judge0 CE.
   - Test output displayed in the terminal: standard output (`stdout`), standard error (`stderr`), and compiler messages (`compile_output`).
   - Execution status pill (Success, Compile Error, Runtime Error) with execution time benchmarks.
   - Output automatically synchronizes to both participants simultaneously.

5. **Interviewer Tools**:
   - **Customizable Question Bar**: Interviewer can edit the problem statement on the fly or pick from curated presets (Valid Palindrome, Two Sum, Valid Parentheses, Reverse Words, Maximum Subarray). Updates sync live to the candidate.
   - **Confidential Notes Panel**: Auto-saving private notes with structured interviewing prompts (approach, complexity, flags). Saved to local storage.
   - **Candidate Evaluation Scorecard**: 5-star rubric for Problem Solving, Code Quality, Algorithms, Communication, and Attitude, plus hiring verdict selector (Strong Hire, Hire, Leaning Hire, Leaning No Hire, No Hire).
   - **Live Interview Timer**: Shared elapsed session stopwatch.

---

## 🏃 Running the Application

### 1. Start the Backend Server (Port 5000)
```powershell
cd C:\Users\HP\codeinterview-live\server
npm install
npm start
```

### 2. Start the Frontend Application (Port 5173)
```powershell
cd C:\Users\HP\codeinterview-live\client
npm install
npm run dev
```

### 3. Open in Browser
- **Interviewer**: Open [http://localhost:5173/](http://localhost:5173/) and click **"⚡ Create Interview"**.
- **Candidate**: Open the generated invite link (or open an Incognito tab with [http://localhost:5173/?room=YOUR_ROOM_ID&role=candidate](http://localhost:5173/)).

