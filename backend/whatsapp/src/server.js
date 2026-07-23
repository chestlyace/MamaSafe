import express from 'express';
import QRCode from 'qrcode';
import config from './config.js';
import { getSock, getConnectionStatus, requestPairingCode } from './index.js';
import { enqueueMessage } from './utils/queue.js';
import { formatReferralMessage } from './utils/format.js';

const app = express();
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  const status = getConnectionStatus();
  res.json({
    ok: status.status === 'connected',
    connection: status.status,
    user: status.user?.name || null,
    uptime: process.uptime(),
  });
});

// Send a message
app.post('/send', async (req, res) => {
  try {
    const { phone, message, referral_id } = req.body;

    if (!phone || !message) {
      return res.status(400).json({ error: 'phone and message are required' });
    }

    const status = getConnectionStatus();
    if (status.status !== 'connected') {
      return res.status(503).json({ error: 'WhatsApp not connected', connection: status.status });
    }

    const result = await enqueueMessage(getSock(), phone, message, referral_id);
    res.json(result);
  } catch (err) {
    console.error('[Server] Send error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Send formatted referral notification
app.post('/send-referral', async (req, res) => {
  try {
    const { phone, referral_data, referral_id } = req.body;

    if (!phone || !referral_data) {
      return res.status(400).json({ error: 'phone and referral_data are required' });
    }

    const status = getConnectionStatus();
    if (status.status !== 'connected') {
      return res.status(503).json({ error: 'WhatsApp not connected', connection: status.status });
    }

    const message = formatReferralMessage(referral_data);
    const result = await enqueueMessage(getSock(), phone, message, referral_id);
    res.json(result);
  } catch (err) {
    console.error('[Server] Send-referral error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Request pairing code
app.post('/pair', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ error: 'phone is required' });
    }
    const code = await requestPairingCode(phone);
    res.json({ code });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get QR code for linking
app.get('/qr', async (req, res) => {
  try {
    const status = getConnectionStatus();
    if (status.status === 'connected') {
      return res.json({ connected: true, user: status.user?.name || null });
    }
    if (!status.qr) {
      return res.json({ connected: false, qr: null, status: status.status });
    }
    const dataUrl = await QRCode.toDataURL(status.qr, { width: 300, margin: 2 });
    res.json({ connected: false, qr: dataUrl, status: status.status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(config.port, () => {
  console.log(`[Server] HTTP API listening on http://localhost:${config.port}`);
});
