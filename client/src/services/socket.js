import { io } from "socket.io-client";

// Connect to backend server (default http://localhost:5000)
const SERVER_URL = import.meta.env.VITE_SERVER_URL || "http://localhost:5000";

class SocketService {
  constructor() {
    this.socket = null;
  }

  connect() {
    if (!this.socket) {
      this.socket = io(SERVER_URL, {
        transports: ["websocket", "polling"],
        reconnectionAttempts: 5,
        reconnectionDelay: 1000,
        timeout: 10000
      });

      this.socket.on("connect", () => {
        console.log("Connected to DevArena Live server with ID:", this.socket.id);
      });

      this.socket.on("connect_error", (err) => {
        console.warn("Socket connection error:", err.message);
      });
    }
    return this.socket;
  }

  getSocket() {
    if (!this.socket) {
      return this.connect();
    }
    return this.socket;
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }
}

export const socketService = new SocketService();
export default socketService;

