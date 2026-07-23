import 'dotenv/config';

export default {
  fastapiUrl: process.env.FASTAPI_URL || 'http://localhost:8000',
  port: parseInt(process.env.PORT || '3001', 10),
  authDir: process.env.AUTH_DIR || './auth',
  sessionName: process.env.SESSION_NAME || 'mamasafe',
  webhookSecret: process.env.WEBHOOK_SECRET || '',
  sendDelayMin: 1500,
  sendDelayMax: 3000,
  maxMessagesPerHour: 60,
};
