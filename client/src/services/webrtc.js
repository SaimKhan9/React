// WebRTC Peer-to-Peer Mesh Manager — Complete with Track Replacement & Multi-Media Support

const ICE_SERVERS = {
  iceServers: [
    { urls: "stun:stun.l.google.com:19302" },
    { urls: "stun:stun1.l.google.com:19302" },
    { urls: "stun:stun2.l.google.com:19302" },
    { urls: "stun:stun3.l.google.com:19302" },
    { urls: "stun:stun4.l.google.com:19302" },
  ],
  iceCandidatePoolSize: 10,
};

export class WebRTCManager {
  constructor(socket, roomId, onRemoteStream, onConnectionStateChange) {
    this.socket = socket;
    this.roomId = roomId;
    this.onRemoteStream = onRemoteStream;
    this.onConnectionStateChange = onConnectionStateChange;
    this.peers = new Map();             // targetSocketId -> RTCPeerConnection
    this.remoteStreams = new Map();     // targetSocketId -> MediaStream
    this.queuedCandidates = new Map();  // targetSocketId -> RTCIceCandidateInit[]
    this.localStream = null;
    this.pendingOffers = [];            // offers received before localStream ready

    this._setupSocketListeners();
  }

  /** Set initial or updated local media stream */
  setLocalStream(stream) {
    this.localStream = stream;

    // Attach or replace local tracks on all existing peer connections
    this.peers.forEach((pc) => {
      if (!stream) return;
      stream.getTracks().forEach((track) => {
        const senders = pc.getSenders();
        const existing = senders.find((s) => s.track && s.track.kind === track.kind);
        if (existing) {
          existing.replaceTrack(track).catch((err) => {
            console.warn("[WebRTC] replaceTrack error:", err);
          });
        } else {
          try {
            pc.addTrack(track, stream);
          } catch (e) {
            console.warn("[WebRTC] addTrack warning:", e);
          }
        }
      });
    });

    // Flush any pending offers received before stream was ready
    if (this.pendingOffers.length > 0) {
      const queued = [...this.pendingOffers];
      this.pendingOffers = [];
      queued.forEach(({ sender, sdp }) => {
        this.handleOffer(sender, sdp);
      });
    }
  }

  /** Dynamically replace the video track (Webcam <-> Screen Share) without renegotiation */
  replaceVideoTrack(newVideoTrack) {
    this.peers.forEach((pc) => {
      const senders = pc.getSenders();
      const videoSender = senders.find((s) => s.track && s.track.kind === "video");
      if (videoSender && newVideoTrack) {
        videoSender.replaceTrack(newVideoTrack).catch((err) => {
          console.warn("[WebRTC] replaceVideoTrack error:", err);
        });
      }
    });
  }

  /** Dynamically replace audio track */
  replaceAudioTrack(newAudioTrack) {
    this.peers.forEach((pc) => {
      const senders = pc.getSenders();
      const audioSender = senders.find((s) => s.track && s.track.kind === "audio");
      if (audioSender && newAudioTrack) {
        audioSender.replaceTrack(newAudioTrack).catch((err) => {
          console.warn("[WebRTC] replaceAudioTrack error:", err);
        });
      }
    });
  }

  _createPeerConnection(targetId) {
    if (this.peers.has(targetId)) {
      return this.peers.get(targetId);
    }

    const pc = new RTCPeerConnection(ICE_SERVERS);
    this.peers.set(targetId, pc);
    this.queuedCandidates.set(targetId, []);

    // Ensure a persistent MediaStream container for this remote peer
    if (!this.remoteStreams.has(targetId)) {
      this.remoteStreams.set(targetId, new MediaStream());
    }
    const remoteStream = this.remoteStreams.get(targetId);

    // Add existing local tracks to new connection
    if (this.localStream) {
      this.localStream.getTracks().forEach((track) => {
        try {
          pc.addTrack(track, this.localStream);
        } catch (e) {
          console.warn(`[WebRTC] Failed to add ${track.kind} track to peer ${targetId}:`, e);
        }
      });
    }

    // Remote track received
    pc.ontrack = (event) => {
      console.log(`[WebRTC] ✅ ontrack from ${targetId}: kind=${event.track.kind}`);

      if (event.streams && event.streams[0]) {
        event.streams[0].getTracks().forEach((track) => {
          if (!remoteStream.getTracks().some((t) => t.id === track.id)) {
            remoteStream.addTrack(track);
          }
        });
      } else if (event.track) {
        if (!remoteStream.getTracks().some((t) => t.id === event.track.id)) {
          remoteStream.addTrack(event.track);
        }
      }

      if (this.onRemoteStream) {
        this.onRemoteStream(targetId, new MediaStream(remoteStream.getTracks()));
      }
    };

    // Local ICE candidate -> relay via socket
    pc.onicecandidate = (event) => {
      if (event.candidate) {
        this.socket.emit("webrtc-ice-candidate", {
          roomId: this.roomId,
          target: targetId,
          candidate: event.candidate.toJSON ? event.candidate.toJSON() : event.candidate,
        });
      }
    };

    // Connection state changes
    pc.onconnectionstatechange = () => {
      const state = pc.connectionState;
      console.log(`[WebRTC] Peer ${targetId} state: ${state}`);
      if (this.onConnectionStateChange) {
        this.onConnectionStateChange(targetId, state);
      }
      if (state === "failed") {
        console.warn(`[WebRTC] Peer ${targetId} failed, restarting ICE...`);
        pc.restartIce();
      }
    };

    return pc;
  }

  /** Send offer to a newly discovered peer */
  async createOffer(targetId) {
    if (!this.localStream) {
      console.warn(`[WebRTC] Cannot create offer: localStream not ready for ${targetId}`);
      return;
    }
    try {
      const pc = this._createPeerConnection(targetId);

      if (pc.signalingState !== "stable") {
        console.warn(`[WebRTC] Peer ${targetId} signaling state is '${pc.signalingState}', skipping offer`);
        return;
      }

      const offer = await pc.createOffer({
        offerToReceiveAudio: true,
        offerToReceiveVideo: true,
        iceRestart: false,
      });

      await pc.setLocalDescription(offer);

      this.socket.emit("webrtc-offer", {
        roomId: this.roomId,
        target: targetId,
        sdp: pc.localDescription,
      });
      console.log(`[WebRTC] 📤 Sent offer to ${targetId}`);
    } catch (err) {
      console.error(`[WebRTC] Error in createOffer for ${targetId}:`, err);
    }
  }

  /** Handle received offer from remote peer */
  async handleOffer(senderId, sdp) {
    if (!this.localStream) {
      console.warn(`[WebRTC] Local stream not ready; queuing offer from ${senderId}`);
      this.pendingOffers.push({ sender: senderId, sdp });
      return;
    }

    try {
      const pc = this._createPeerConnection(senderId);

      if (pc.signalingState !== "stable") {
        console.warn(`[WebRTC] Offer in non-stable state '${pc.signalingState}' from ${senderId}, rolling back`);
        await pc.setRemoteDescription(new RTCSessionDescription({ type: "rollback" }));
      }

      await pc.setRemoteDescription(new RTCSessionDescription(sdp));
      await this._flushCandidates(senderId, pc);

      const answer = await pc.createAnswer({
        offerToReceiveAudio: true,
        offerToReceiveVideo: true,
      });
      await pc.setLocalDescription(answer);

      this.socket.emit("webrtc-answer", {
        roomId: this.roomId,
        target: senderId,
        sdp: pc.localDescription,
      });
      console.log(`[WebRTC] 📤 Sent answer to ${senderId}`);
    } catch (err) {
      console.error(`[WebRTC] Error in handleOffer from ${senderId}:`, err);
    }
  }

  /** Handle received answer from remote peer */
  async handleAnswer(senderId, sdp) {
    try {
      const pc = this.peers.get(senderId);
      if (!pc) {
        console.warn(`[WebRTC] Answer from unknown peer ${senderId}`);
        return;
      }
      if (pc.signalingState !== "have-local-offer") {
        console.warn(`[WebRTC] Answer in unexpected state '${pc.signalingState}' from ${senderId}`);
        return;
      }

      await pc.setRemoteDescription(new RTCSessionDescription(sdp));
      await this._flushCandidates(senderId, pc);
      console.log(`[WebRTC] ✅ Remote description (answer) set for ${senderId}`);
    } catch (err) {
      console.error(`[WebRTC] Error in handleAnswer from ${senderId}:`, err);
    }
  }

  /** Handle received ICE candidate */
  async handleIceCandidate(senderId, candidate) {
    try {
      if (!candidate || !candidate.candidate) return;

      const pc = this.peers.get(senderId);
      if (pc && pc.remoteDescription && pc.remoteDescription.type) {
        await pc.addIceCandidate(new RTCIceCandidate(candidate));
      } else {
        const queue = this.queuedCandidates.get(senderId) || [];
        queue.push(candidate);
        this.queuedCandidates.set(senderId, queue);
      }
    } catch (err) {
      console.error(`[WebRTC] Error adding ICE candidate from ${senderId}:`, err);
    }
  }

  async _flushCandidates(peerId, pc) {
    const queue = this.queuedCandidates.get(peerId) || [];
    this.queuedCandidates.set(peerId, []);
    for (const c of queue) {
      try {
        if (c && c.candidate) {
          await pc.addIceCandidate(new RTCIceCandidate(c));
        }
      } catch (e) {
        console.warn(`[WebRTC] Failed to add queued ICE candidate for ${peerId}:`, e);
      }
    }
  }

  removePeer(targetId) {
    const pc = this.peers.get(targetId);
    if (pc) {
      pc.close();
      this.peers.delete(targetId);
      this.queuedCandidates.delete(targetId);
      this.remoteStreams.delete(targetId);
    }
  }

  _setupSocketListeners() {
    this.socket.on("webrtc-offer", async ({ sender, sdp }) => {
      console.log(`[WebRTC] 📥 Offer from ${sender}`);
      await this.handleOffer(sender, sdp);
    });

    this.socket.on("webrtc-answer", async ({ sender, sdp }) => {
      console.log(`[WebRTC] 📥 Answer from ${sender}`);
      await this.handleAnswer(sender, sdp);
    });

    this.socket.on("webrtc-ice-candidate", async ({ sender, candidate }) => {
      await this.handleIceCandidate(sender, candidate);
    });
  }

  destroy() {
    this.peers.forEach((pc) => pc.close());
    this.peers.clear();
    this.remoteStreams.clear();
    this.queuedCandidates.clear();
    this.pendingOffers = [];
    this.localStream = null;
  }
}
