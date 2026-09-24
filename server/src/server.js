import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import { getOrCreateRoom, getRoom, removeParticipant, serializeRoom } from './rooms.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const clientDistPath = path.join(__dirname, '../../client/dist');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  },
  pingTimeout: 60000,
  pingInterval: 25000
});

app.use(cors());
app.use(express.json());

// Serve frontend static build if present
if (fs.existsSync(clientDistPath)) {
  app.use(express.static(clientDistPath));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now() });
});

// Judge0 API code execution endpoint (50+ languages, real execution)
app.post('/api/execute', async (req, res) => {
  const { language_id, source_code, stdin } = req.body;

  if (!language_id || !source_code) {
    return res.status(400).json({ error: 'language_id and source_code are required.' });
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 20000);

    // Encode source_code and stdin to base64 to avoid UTF-8 / emoji decoding issues
    const base64Source = Buffer.from(source_code, 'utf8').toString('base64');
    const base64Stdin = stdin ? Buffer.from(stdin, 'utf8').toString('base64') : '';

    const judgeRes = await fetch('https://ce.judge0.com/submissions?base64_encoded=true&wait=true', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        language_id,
        source_code: base64Source,
        stdin: base64Stdin,
        redirect_stderr_to_stdout: false
      }),
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!judgeRes.ok) {
      const errText = await judgeRes.text();
      return res.status(judgeRes.status).json({ error: 'Judge0 API error', details: errText });
    }

    const data = await judgeRes.json();

    // Decode base64 outputs back to clean UTF-8 strings
    const decoded = {
      ...data,
      stdout: data.stdout ? Buffer.from(data.stdout, 'base64').toString('utf8') : null,
      stderr: data.stderr ? Buffer.from(data.stderr, 'base64').toString('utf8') : null,
      compile_output: data.compile_output ? Buffer.from(data.compile_output, 'base64').toString('utf8') : null,
      message: data.message ? Buffer.from(data.message, 'base64').toString('utf8') : null
    };

    return res.json(decoded);
  } catch (err) {
    console.error('Execution error:', err);
    return res.status(500).json({
      error: 'Execution failed or timed out',
      message: err.message
    });
  }
});

// Get room details
app.get('/api/rooms/:roomId', (req, res) => {
  const room = getRoom(req.params.roomId);
  if (!room) {
    return res.status(404).json({ error: 'Room not found' });
  }
  res.json(serializeRoom(room));
});

// Real-time socket handlers
io.on('connection', (socket) => {
  console.log(`[Socket Connected] ID: ${socket.id}`);

  // User joins interview room
  socket.on('join-room', ({ roomId, name, role }) => {
    if (!roomId) return;

    socket.join(roomId);
    socket.roomId = roomId;

    const room = getOrCreateRoom(roomId);
    const participant = {
      id: socket.id,
      name: name || (role === 'interviewer' ? 'Interviewer' : 'Candidate'),
      role: role || 'candidate',
      isMuted: false,
      isCamOff: false,
      joinedAt: Date.now()
    };

    room.participants.set(socket.id, participant);

    console.log(`[Join Room] ${participant.name} (${participant.role}) joined ${roomId}`);

    // Send the current room state back to the newly joined client
    socket.emit('init-room-state', {
      ...serializeRoom(room),
      selfId: socket.id
    });

    // Notify other peers in the room that a new user joined
    socket.to(roomId).emit('peer-joined', {
      peer: participant
    });
  });

  // WebRTC Signaling: Offer
  socket.on('webrtc-offer', ({ target, sdp }) => {
    console.log(`[WebRTC Offer] From ${socket.id} to ${target}`);
    io.to(target).emit('webrtc-offer', {
      sender: socket.id,
      sdp
    });
  });

  // WebRTC Signaling: Answer
  socket.on('webrtc-answer', ({ target, sdp }) => {
    console.log(`[WebRTC Answer] From ${socket.id} to ${target}`);
    io.to(target).emit('webrtc-answer', {
      sender: socket.id,
      sdp
    });
  });

  // WebRTC Signaling: ICE Candidate
  socket.on('webrtc-ice-candidate', ({ target, candidate }) => {
    io.to(target).emit('webrtc-ice-candidate', {
      sender: socket.id,
      candidate
    });
  });

  // Media state changes (Mute / Cam off / Screen share)
  socket.on('media-state-change', ({ roomId, isMuted, isCamOff, isScreenSharing }) => {
    const room = getRoom(roomId);
    if (room && room.participants.has(socket.id)) {
      const p = room.participants.get(socket.id);
      if (isMuted !== undefined) p.isMuted = isMuted;
      if (isCamOff !== undefined) p.isCamOff = isCamOff;
      if (isScreenSharing !== undefined) p.isScreenSharing = isScreenSharing;
      socket.to(roomId).emit('peer-media-state', {
        id: socket.id,
        isMuted: p.isMuted,
        isCamOff: p.isCamOff,
        isScreenSharing: p.isScreenSharing
      });
    }
  });

  // Real-time code change sync
  socket.on('code-change', ({ roomId, code }) => {
    const room = getRoom(roomId);
    if (room) {
      room.code = code;
      socket.to(roomId).emit('code-update', {
        code,
        senderId: socket.id
      });
    }
  });

  // Language change
  socket.on('language-change', ({ roomId, language, code }) => {
    const room = getRoom(roomId);
    if (room) {
      room.language = language;
      if (code) room.code = code;
      socket.to(roomId).emit('language-update', {
        language,
        code: room.code,
        senderId: socket.id
      });
    }
  });

  // Problem statement / question change
  socket.on('question-change', ({ roomId, question }) => {
    const room = getRoom(roomId);
    if (room) {
      room.question = question;
      socket.to(roomId).emit('question-update', {
        question,
        senderId: socket.id
      });
    }
  });

  // Chat messaging
  socket.on('chat-message', ({ roomId, text, name, role }) => {
    const room = getRoom(roomId);
    if (room && text && text.trim()) {
      const message = {
        id: 'msg-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6),
        sender: name || 'Participant',
        role: role || 'candidate',
        text: text.trim(),
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      room.messages.push(message);
      // Broadcast to EVERYONE in the room including sender
      io.in(roomId).emit('chat-message', message);
    }
  });

  // Broadcast code execution start
  socket.on('execution-start', ({ roomId }) => {
    socket.to(roomId).emit('execution-start', {
      senderId: socket.id
    });
  });

  // Broadcast code execution finished
  socket.on('execution-result', ({ roomId, output, status }) => {
    const room = getRoom(roomId);
    if (room) {
      room.output = { output, status, timestamp: Date.now() };
      socket.to(roomId).emit('execution-result', room.output);
    }
  });

  // Interviewer notes evaluation
  socket.on('submit-evaluation', ({ roomId, evaluation }) => {
    const room = getRoom(roomId);
    if (room) {
      room.evaluations.push({
        ...evaluation,
        submittedAt: Date.now()
      });
      socket.emit('evaluation-saved', { success: true });
    }
  });

  // Disconnection handler
  socket.on('disconnecting', () => {
    for (const roomId of socket.rooms) {
      if (roomId !== socket.id) {
        const removed = removeParticipant(roomId, socket.id);
        if (removed) {
          console.log(`[Disconnect] ${removed.name} left ${roomId}`);
          socket.to(roomId).emit('peer-left', {
            id: socket.id,
            name: removed.name,
            role: removed.role
          });
        }
      }
    }
  });

  socket.on('disconnect', () => {
    console.log(`[Socket Disconnected] ID: ${socket.id}`);
  });
});

// Wildcard route to handle React Router / SPA if dist exists
if (fs.existsSync(clientDistPath)) {
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api') || req.path.startsWith('/health')) {
      return next();
    }
    res.sendFile(path.join(clientDistPath, 'index.html'));
  });
}

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 DevArena Live server running on http://localhost:${PORT}`);
});
