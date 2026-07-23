import makeWASocket, {
  useMultiFileAuthState,
  DisconnectReason,
  fetchLatestBaileysVersion,
  makeCacheableSignalKeyStore,
} from '@whiskeysockets/baileys';
import pino from 'pino';
import config from './config.js';
import { handleMessage } from './handlers/message.js';
import './server.js';

const logger = pino({ level: 'silent' });

let sock = null;
let connectionStatus = 'disconnected';
let qrCode = null;
let pairingCode = null;

export function getSock() {
  return sock;
}

export function getConnectionStatus() {
  return {
    status: connectionStatus,
    qr: qrCode,
    user: sock?.user || null,
  };
}

export async function requestPairingCode(phoneNumber) {
  if (!sock) throw new Error('Socket not initialized');
  const code = await sock.requestPairingCode(phoneNumber);
  pairingCode = code;
  return code;
}

async function startSocket() {
  const { state, saveCreds } = await useMultiFileAuthState(config.authDir);
  const { version } = await fetchLatestBaileysVersion();

  sock = makeWASocket({
    version,
    auth: {
      creds: state.creds,
      keys: makeCacheableSignalKeyStore(state.keys, logger),
    },
    browser: ['MamaSafe', 'Safari', '3.0'],
    logger,
    generateHighQualityLinkPreview: false,
  });

  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      qrCode = qr;
      pairingCode = null;
      connectionStatus = 'waiting_qr';
      console.log('\n[WhatsApp] Scan the QR code above with your phone');
    }

    if (connection === 'close') {
      const statusCode = lastDisconnect?.error?.output?.statusCode;
      const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
      console.log(`[WhatsApp] Connection closed. Code: ${statusCode}. Reconnect: ${shouldReconnect}`);

      connectionStatus = 'disconnected';
      qrCode = null;

      if (shouldReconnect) {
        setTimeout(startSocket, 3000);
      } else {
        console.log('[WhatsApp] Logged out. Delete auth/ folder and restart to re-pair.');
        connectionStatus = 'logged_out';
      }
    }

    if (connection === 'open') {
      connectionStatus = 'connected';
      qrCode = null;
      pairingCode = null;
      console.log('[WhatsApp] Connected successfully!');
      console.log(`[WhatsApp] Logged in as: ${sock.user?.name || 'unknown'}`);
    }
  });

  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('messages.upsert', async (m) => {
    if (m.type !== 'notify') return;

    for (const msg of m.messages) {
      try {
        await handleMessage(sock, msg);
      } catch (err) {
        console.error('[WhatsApp] Error handling message:', err);
      }
    }
  });

  return sock;
}

startSocket().catch((err) => {
  console.error('[WhatsApp] Failed to start:', err);
  process.exit(1);
});
