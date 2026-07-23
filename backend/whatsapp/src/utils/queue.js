const queue = [];
let processing = false;
let messagesThisHour = 0;
let hourResetTimer = null;

function resetHourCounter() {
  messagesThisHour = 0;
  hourResetTimer = setTimeout(resetHourCounter, 60 * 60 * 1000);
}

function gaussianDelay(min, max) {
  // Box-Muller transform for gaussian-distributed delay
  const u1 = Math.random();
  const u2 = Math.random();
  const z = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
  const mean = (min + max) / 2;
  const stddev = (max - min) / 4;
  const delay = Math.round(mean + z * stddev);
  return Math.max(min, Math.min(max, delay));
}

export async function enqueueMessage(sock, phone, message, referralId = null) {
  return new Promise((resolve, reject) => {
    queue.push({ sock, phone, message, referralId, resolve, reject });
    processQueue();
  });
}

async function processQueue() {
  if (processing || queue.length === 0) return;
  processing = true;

  while (queue.length > 0) {
    if (messagesThisHour >= 60) {
      console.log('[Queue] Rate limit reached (60 msgs/hour). Waiting...');
      await sleep(60000);
      continue;
    }

    const item = queue.shift();
    try {
      const jid = normalizeJid(item.phone);
      const result = await item.sock.sendMessage(jid, { text: item.message });
      messagesThisHour++;

      if (!hourResetTimer) resetHourCounter();

      const messageId = result?.key?.id || null;
      item.resolve({ success: true, message_id: messageId, jid });
      console.log(`[Queue] Sent to ${item.phone} | ID: ${messageId}`);
    } catch (err) {
      console.error(`[Queue] Failed to send to ${item.phone}:`, err.message);
      item.resolve({ success: false, message_id: null, error: err.message });
    }

    // Anti-ban delay between messages
    if (queue.length > 0) {
      const delay = gaussianDelay(1500, 3000);
      await sleep(delay);
    }
  }

  processing = false;
}

function normalizeJid(phone) {
  // Remove +, spaces, dashes
  let cleaned = phone.replace(/[^0-9]/g, '');

  // Already has @s.whatsapp.net
  if (phone.includes('@s.whatsapp.net')) return phone;

  // Ensure country code (default Cameroon +237)
  if (cleaned.length <= 9) {
    cleaned = '237' + cleaned;
  }

  return cleaned + '@s.whatsapp.net';
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}
