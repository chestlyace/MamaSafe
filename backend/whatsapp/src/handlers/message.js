import config from '../config.js';
import axios from 'axios';

export async function handleMessage(sock, msg) {
  // Ignore own messages
  if (msg.key.fromMe) return;

  const from = msg.key.remoteJid;
  const text =
    msg.message?.conversation ||
    msg.message?.extendedTextMessage?.text ||
    '';

  if (!text) return;

  console.log(`[Message] From: ${from} | Text: ${text}`);

  // Check for referral reply keywords
  const normalized = text.trim().toUpperCase();

  const REPLY_KEYWORDS = ['RECEIVED', 'RECU', 'ARRIVED', 'PATIENT_ARRIVED'];
  const isReply = REPLY_KEYWORDS.some(kw => normalized.includes(kw));

  if (isReply) {
    await notifyFastAPI(from, text, msg);
  }
}

async function notifyFastAPI(fromNumber, text, msg) {
  try {
    const payload = {
      from_number: fromNumber,
      text: text,
      timestamp: msg.messageTimestamp?.toString() || new Date().toISOString(),
    };

    if (config.webhookSecret) {
      payload.secret = config.webhookSecret;
    }

    await axios.post(
      `${config.fastapiUrl}/api/v1/referrals/webhook/whatsapp`,
      payload,
      { timeout: 5000 }
    );
    console.log(`[Message] Notified FastAPI of reply from ${fromNumber}`);
  } catch (err) {
    console.error(`[Message] Failed to notify FastAPI:`, err.message);
  }
}
