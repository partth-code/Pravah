import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;

// Health
app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'farmer-assistant-backend' });
});

// Mock routes
app.get('/api/v1/weather', (req, res) => {
  const { lat, lng } = req.query;
  res.json({
    lat, lng,
    current: { tempC: 30, condition: 'Sunny', advice: 'Light irrigation suggested' },
    forecast: [
      { day: 'Mon', tempC: 31, condition: 'Sunny' },
      { day: 'Tue', tempC: 29, condition: 'Cloudy' },
      { day: 'Wed', tempC: 28, condition: 'Rain' }
    ]
  });
});

// Profile (user + farm)
app.get('/api/v1/profile', (req, res) => {
  res.json({
    user: {
      userId: 'user_001',
      name: 'Ravi Kumar',
      phone: '+91 9876543210',
      language: 'hi',
      farmProfileId: 'farm_001',
      aadhaarHash: '****1234',
      uniqueFarmId: 'FARM_001_2024',
      uniqueFarmerId: 'FARMER_001_2024',
    },
    farm: {
      farmId: 'farm_001',
      userId: 'user_001',
      state: 'Punjab',
      district: 'Ludhiana',
      lat: 30.9010,
      lng: 75.8573,
      soilType: 'Loamy',
      area: 2.5,
      waterLevel: 'Good',
      primaryCrop: 'Wheat',
    }
  });
});

// Tasks list
app.get('/api/v1/tasks', (req, res) => {
  const today = new Date();
  const tomorrow = new Date();
  tomorrow.setDate(today.getDate() + 1);
  res.json({
    results: [
      {
        taskId: 'task_001',
        farmId: 'farm_001',
        date: today.toISOString(),
        title: 'Irrigation check',
        status: 'pending',
        points: 5,
        priority: 'high',
      },
      {
        taskId: 'task_002',
        farmId: 'farm_001',
        date: tomorrow.toISOString(),
        title: 'Pest monitoring',
        status: 'pending',
        points: 3,
        priority: 'medium',
      },
    ],
  });
});

app.get('/api/v1/policies', (req, res) => {
  const { query = '', state = '', crop = '' } = req.query;
  res.json({
    query, state, crop,
    results: [
      { policyId: 'p1', title: 'Seed Subsidy', eligibility: 'Small/marginal farmers', requiredDocs: ['ID', 'Bank'] },
      { policyId: 'p2', title: 'Irrigation Support', eligibility: 'All farmers', requiredDocs: ['ID'] }
    ]
  });
});

app.get('/api/v1/leaderboard', (req, res) => {
  const { scope = 'village', id = 'default' } = req.query;
  res.json({ scope, id, entries: [
    { userId: 'u1', name: 'Ravi', points: 120, rank: 1 },
    { userId: 'u2', name: 'Lakshmi', points: 110, rank: 2 },
    { userId: 'u3', name: 'Aman', points: 95, rank: 3 }
  ]});
});

app.post('/api/v1/tasks/mark', (req, res) => {
  const { taskId, status } = req.body || {};
  const pointsAwarded = status === 'done' ? 5 : 0;
  res.json({ ok: true, taskId, status, pointsAwarded });
});

app.post('/api/v1/detect-disease', (req, res) => {
  res.json({
    labels: [
      { tag: 'leaf_blight', confidence: 0.82 },
      { tag: 'rust', confidence: 0.12 },
      { tag: 'healthy', confidence: 0.06 }
    ],
    remedies: [
      { type: 'organic', steps: ['Neem spray 3%', 'Isolate infected leaves'], dosage: '2 L/acre' },
      { type: 'chemical', steps: ['Copper oxychloride spray'], dosage: '1.5 g/L' }
    ]
  });
});

app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`);
});


