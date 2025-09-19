import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import axios from 'axios';
import cron from 'node-cron';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;

// API Configuration
const BHASHINI_API_KEY = process.env.BHASHINI_API_KEY || 'your-bhashini-api-key';
const OPENWEATHER_API_KEY = process.env.OPENWEATHER_API_KEY || 'your-openweather-api-key';
const MANDI_API_KEY = process.env.MANDI_API_KEY || 'your-mandi-api-key';

// Cache for API responses
const cache = {
  weather: new Map(),
  mandi: new Map(),
  translations: new Map()
};

// Cache TTL (Time To Live) in milliseconds
const CACHE_TTL = {
  weather: 30 * 60 * 1000, // 30 minutes
  mandi: 60 * 60 * 1000,   // 1 hour
  translations: 24 * 60 * 60 * 1000 // 24 hours
};

// Utility function to check cache
function getCachedData(key, type) {
  const cached = cache[type].get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL[type]) {
    return cached.data;
  }
  return null;
}

// Utility function to set cache
function setCachedData(key, data, type) {
  cache[type].set(key, {
    data,
    timestamp: Date.now()
  });
}

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    ok: true, 
    service: 'farmer-assistant-backend',
    timestamp: new Date().toISOString(),
    cache: {
      weather: cache.weather.size,
      mandi: cache.mandi.size,
      translations: cache.translations.size
    }
  });
});

// ==================== BHASHINI API ROUTES ====================

// Translation endpoint
app.post('/api/v1/translate', async (req, res) => {
  try {
    const { text, sourceLang = 'en', targetLang = 'hi' } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required for translation' });
    }

    const cacheKey = `${text}_${sourceLang}_${targetLang}`;
    const cached = getCachedData(cacheKey, 'translations');
    
    if (cached) {
      return res.json(cached);
    }

    // Bhashini API call
    const response = await axios.post('https://api.bhashini.gov.in/translate', {
      text: text,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang
    }, {
      headers: {
        'Authorization': `Bearer ${BHASHINI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    const result = {
      originalText: text,
      translatedText: response.data.translatedText,
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
      confidence: response.data.confidence || 0.95
    };

    setCachedData(cacheKey, result, 'translations');
    res.json(result);

  } catch (error) {
    console.error('Translation error:', error.message);
    res.status(500).json({ 
      error: 'Translation failed',
      message: error.message,
      fallback: text // Return original text as fallback
    });
  }
});

// Text-to-Speech endpoint
app.post('/api/v1/tts', async (req, res) => {
  try {
    const { text, language = 'hi', voice = 'female' } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required for TTS' });
    }

    const response = await axios.post('https://api.bhashini.gov.in/tts', {
      text: text,
      language: language,
      voice: voice
    }, {
      headers: {
        'Authorization': `Bearer ${BHASHINI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 15000
    });

    res.json({
      audioUrl: response.data.audioUrl,
      text: text,
      language: language,
      voice: voice
    });

  } catch (error) {
    console.error('TTS error:', error.message);
    res.status(500).json({ 
      error: 'Text-to-speech failed',
      message: error.message
    });
  }
});

// ==================== WEATHER API ROUTES ====================

// Weather data endpoint
app.get('/api/v1/weather', async (req, res) => {
  try {
    const { lat, lng } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitude and longitude are required' });
    }

    const cacheKey = `${lat}_${lng}`;
    const cached = getCachedData(cacheKey, 'weather');
    
    if (cached) {
      return res.json(cached);
    }

    // OpenWeatherMap API call
    const weatherResponse = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${OPENWEATHER_API_KEY}&units=metric`
    );

    const forecastResponse = await axios.get(
      `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lng}&appid=${OPENWEATHER_API_KEY}&units=metric`
    );

    const weatherData = {
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      current: {
        tempC: Math.round(weatherResponse.data.main.temp),
        condition: weatherResponse.data.weather[0].main,
        humidity: weatherResponse.data.main.humidity,
        windSpeed: weatherResponse.data.wind.speed,
        advice: generateWeatherAdvice(weatherResponse.data)
      },
      forecast: forecastResponse.data.list.slice(0, 5).map(item => ({
        day: new Date(item.dt * 1000).toLocaleDateString('en', { weekday: 'short' }),
        tempC: Math.round(item.main.temp),
        condition: item.weather[0].main,
        date: new Date(item.dt * 1000).toISOString()
      }))
    };

    setCachedData(cacheKey, weatherData, 'weather');
    res.json(weatherData);

  } catch (error) {
    console.error('Weather API error:', error.message);
    
    // Fallback to mock data
    const mockWeather = {
      lat: parseFloat(req.query.lat) || 30.9010,
      lng: parseFloat(req.query.lng) || 75.8573,
      current: {
        tempC: 28,
        condition: 'Sunny',
        humidity: 65,
        windSpeed: 5.2,
        advice: 'Good weather for farming activities'
      },
      forecast: [
        { day: 'Mon', tempC: 30, condition: 'Sunny', date: new Date().toISOString() },
        { day: 'Tue', tempC: 29, condition: 'Cloudy', date: new Date().toISOString() },
        { day: 'Wed', tempC: 27, condition: 'Rain', date: new Date().toISOString() }
      ]
    };
    
    res.json(mockWeather);
  }
});

// Weather alerts endpoint
app.get('/api/v1/weather/alerts', async (req, res) => {
  try {
    const { lat, lng } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitude and longitude are required' });
    }

    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/onecall?lat=${lat}&lon=${lng}&appid=${OPENWEATHER_API_KEY}&exclude=minutely,hourly,daily`
    );

    const alerts = response.data.alerts || [];
    
    res.json({
      alerts: alerts.map(alert => ({
        title: alert.event,
        description: alert.description,
        severity: alert.tags[0] || 'moderate',
        startTime: new Date(alert.start * 1000).toISOString(),
        endTime: new Date(alert.end * 1000).toISOString()
      }))
    });

  } catch (error) {
    console.error('Weather alerts error:', error.message);
    res.json({ alerts: [] });
  }
});

// ==================== MANDI API ROUTES ====================

// Market prices endpoint
app.get('/api/v1/mandi/prices', async (req, res) => {
  try {
    const { state, district, crop, limit = 10 } = req.query;
    
    const cacheKey = `${state}_${district}_${crop}_${limit}`;
    const cached = getCachedData(cacheKey, 'mandi');
    
    if (cached) {
      return res.json(cached);
    }

    // Mandi API call (using a mock implementation as real API details may vary)
    const mandiData = await fetchMandiPrices(state, district, crop, limit);
    
    setCachedData(cacheKey, mandiData, 'mandi');
    res.json(mandiData);

  } catch (error) {
    console.error('Mandi API error:', error.message);
    
    // Fallback to mock data
    const mockMandiData = {
      state: req.query.state || 'Punjab',
      district: req.query.district || 'Ludhiana',
      crop: req.query.crop || 'Wheat',
      prices: [
        {
          mandiName: 'Ludhiana Mandi',
          crop: 'Wheat',
          variety: 'HD-2967',
          minPrice: 2100,
          maxPrice: 2200,
          modalPrice: 2150,
          unit: 'Quintal',
          date: new Date().toISOString()
        },
        {
          mandiName: 'Khanna Mandi',
          crop: 'Wheat',
          variety: 'PBW-343',
          minPrice: 2080,
          maxPrice: 2180,
          modalPrice: 2130,
          unit: 'Quintal',
          date: new Date().toISOString()
        }
      ],
      lastUpdated: new Date().toISOString()
    };
    
    res.json(mockMandiData);
  }
});

// Market trends endpoint
app.get('/api/v1/mandi/trends', async (req, res) => {
  try {
    const { crop, state, days = 30 } = req.query;
    
    if (!crop) {
      return res.status(400).json({ error: 'Crop parameter is required' });
    }

    const trends = await fetchMarketTrends(crop, state, parseInt(days));
    res.json(trends);

  } catch (error) {
    console.error('Market trends error:', error.message);
    res.status(500).json({ error: 'Failed to fetch market trends' });
  }
});

// ==================== EXISTING ROUTES (UPDATED) ====================

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
  
  // Comprehensive mock policies data
  const allPolicies = [
    {
      policyId: 'p1',
      title: 'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
      description: 'Direct income support of ₹6,000 per year to all landholding farmer families',
      eligibility: 'All landholding farmer families',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Mobile Number'],
      states: ['All States', 'All Union Territories'],
      tags: ['Income Support', 'Direct Benefit Transfer', 'Central Scheme'],
      applicationDeadline: '2024-12-31',
      benefits: '₹6,000 per year in 3 installments of ₹2,000 each',
      contactInfo: 'Toll-free: 1800-180-1551',
      website: 'https://pmkisan.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p2',
      title: 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
      description: 'Crop insurance scheme to provide financial support to farmers in case of crop failure',
      eligibility: 'All farmers growing notified crops',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Crop Details'],
      states: ['All States', 'All Union Territories'],
      tags: ['Crop Insurance', 'Risk Management', 'Central Scheme'],
      applicationDeadline: '2024-03-31',
      benefits: 'Premium subsidy up to 90%, compensation for crop loss',
      contactInfo: 'Toll-free: 1800-180-1551',
      website: 'https://pmfby.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p3',
      title: 'Soil Health Card Scheme',
      description: 'Issue soil health cards to farmers every 2 years with crop-wise recommendations',
      eligibility: 'All farmers',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Soil Sample'],
      states: ['All States', 'All Union Territories'],
      tags: ['Soil Health', 'Scientific Farming', 'Central Scheme'],
      applicationDeadline: '2024-12-31',
      benefits: 'Free soil testing, personalized recommendations',
      contactInfo: 'Toll-free: 1800-180-1551',
      website: 'https://soilhealth.dac.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p4',
      title: 'Punjab Kisan Vikas Yojana',
      description: 'State-specific scheme for agricultural development and farmer welfare',
      eligibility: 'Farmers in Punjab with landholding up to 5 acres',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Income Certificate'],
      states: ['Punjab'],
      tags: ['State Scheme', 'Small Farmers', 'Development'],
      applicationDeadline: '2024-06-30',
      benefits: 'Subsidy up to ₹50,000 for farm equipment',
      contactInfo: 'Punjab Agriculture Department: 0172-2700000',
      website: 'https://agripunjab.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p5',
      title: 'Kerala Organic Farming Mission',
      description: 'Promote organic farming practices and provide certification support',
      eligibility: 'Farmers practicing organic farming in Kerala',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Organic Farming Certificate', 'Bank Account Details'],
      states: ['Kerala'],
      tags: ['Organic Farming', 'State Scheme', 'Sustainability'],
      applicationDeadline: '2024-08-31',
      benefits: 'Certification support, marketing assistance, subsidy up to ₹25,000',
      contactInfo: 'Kerala Agriculture Department: 0471-2320000',
      website: 'https://keralaagriculture.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p6',
      title: 'Maharashtra Baliraja Krishi Pump Yojana',
      description: 'Free electricity for agricultural pumps to farmers',
      eligibility: 'Farmers with agricultural connections in Maharashtra',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Electricity Connection Details'],
      states: ['Maharashtra'],
      tags: ['Electricity', 'State Scheme', 'Irrigation'],
      applicationDeadline: '2024-12-31',
      benefits: 'Free electricity up to 5 HP for agricultural pumps',
      contactInfo: 'Maharashtra State Electricity Distribution Co.: 1800-212-3435',
      website: 'https://www.mahadiscom.in',
      status: 'Active'
    },
    {
      policyId: 'p7',
      title: 'Tamil Nadu Free Laptop Scheme for Farmers',
      description: 'Free laptops to farmers for digital agriculture and online services',
      eligibility: 'Farmers with landholding up to 2 acres in Tamil Nadu',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Income Certificate'],
      states: ['Tamil Nadu'],
      tags: ['Digital India', 'State Scheme', 'Technology'],
      applicationDeadline: '2024-05-31',
      benefits: 'Free laptop with pre-installed agricultural software',
      contactInfo: 'Tamil Nadu Agriculture Department: 044-28520000',
      website: 'https://www.tn.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p8',
      title: 'Gujarat Krishi Mahotsav',
      description: 'Annual agricultural festival with subsidies and farmer support programs',
      eligibility: 'All farmers in Gujarat',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details'],
      states: ['Gujarat'],
      tags: ['State Scheme', 'Festival', 'Comprehensive Support'],
      applicationDeadline: '2024-04-30',
      benefits: 'Multiple subsidies, free seeds, agricultural equipment support',
      contactInfo: 'Gujarat Agriculture Department: 079-23250000',
      website: 'https://gujaratagriculture.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p9',
      title: 'Rajasthan Mukhyamantri Krishi Saathi Yojana',
      description: 'Comprehensive agricultural support scheme for small and marginal farmers',
      eligibility: 'Small and marginal farmers in Rajasthan',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Income Certificate'],
      states: ['Rajasthan'],
      tags: ['Small Farmers', 'State Scheme', 'Comprehensive Support'],
      applicationDeadline: '2024-07-31',
      benefits: 'Subsidy up to ₹75,000 for farm equipment and inputs',
      contactInfo: 'Rajasthan Agriculture Department: 0141-2220000',
      website: 'https://agriculture.rajasthan.gov.in',
      status: 'Active'
    },
    {
      policyId: 'p10',
      title: 'Karnataka Raitha Siri Scheme',
      description: 'Direct benefit transfer for paddy and other crops',
      eligibility: 'Farmers growing paddy and other notified crops in Karnataka',
      requiredDocs: ['Aadhaar Card', 'Land Records', 'Bank Account Details', 'Crop Details'],
      states: ['Karnataka'],
      tags: ['Direct Benefit Transfer', 'State Scheme', 'Paddy'],
      applicationDeadline: '2024-09-30',
      benefits: '₹5,000 per acre for paddy cultivation',
      contactInfo: 'Karnataka Agriculture Department: 080-22200000',
      website: 'https://raitamitra.karnataka.gov.in',
      status: 'Active'
    }
  ];

  // Filter policies based on query parameters
  let filteredPolicies = allPolicies;

  if (query) {
    const searchQuery = query.toLowerCase();
    filteredPolicies = filteredPolicies.filter(policy => 
      policy.title.toLowerCase().includes(searchQuery) ||
      policy.description.toLowerCase().includes(searchQuery) ||
      policy.tags.some(tag => tag.toLowerCase().includes(searchQuery))
    );
  }

  if (state && state !== 'All States') {
    filteredPolicies = filteredPolicies.filter(policy => 
      policy.states.includes(state) || policy.states.includes('All States')
    );
  }

  if (crop) {
    filteredPolicies = filteredPolicies.filter(policy => 
      policy.description.toLowerCase().includes(crop.toLowerCase()) ||
      policy.tags.some(tag => tag.toLowerCase().includes(crop.toLowerCase()))
    );
  }

  res.json({
    query, 
    state, 
    crop,
    total: filteredPolicies.length,
    results: filteredPolicies
  });
});

app.get('/api/v1/leaderboard', (req, res) => {
  const { scope = 'village', id = 'default', limit = 50 } = req.query;
  
  // Enhanced mock leaderboard data
  const leaderboardData = {
    village: [
      { userId: 'u1', name: 'Ravi Kumar', points: 1250, rank: 1, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 45, streak: 12 },
      { userId: 'u2', name: 'Lakshmi Devi', points: 1180, rank: 2, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 42, streak: 8 },
      { userId: 'u3', name: 'Aman Singh', points: 1095, rank: 3, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 38, streak: 15 },
      { userId: 'u4', name: 'Priya Sharma', points: 1020, rank: 4, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 35, streak: 6 },
      { userId: 'u5', name: 'Rajesh Patel', points: 980, rank: 5, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 32, streak: 4 },
      { userId: 'u6', name: 'Sunita Mehta', points: 920, rank: 6, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 30, streak: 7 },
      { userId: 'u7', name: 'Vikram Singh', points: 875, rank: 7, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 28, streak: 3 },
      { userId: 'u8', name: 'Kavita Yadav', points: 820, rank: 8, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 25, streak: 5 },
      { userId: 'u9', name: 'Suresh Kumar', points: 780, rank: 9, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 22, streak: 2 },
      { userId: 'u10', name: 'Meera Devi', points: 740, rank: 10, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 20, streak: 1 }
    ],
    district: [
      { userId: 'd1', name: 'Ravi Kumar', points: 1250, rank: 1, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 45, streak: 12 },
      { userId: 'd2', name: 'Lakshmi Devi', points: 1180, rank: 2, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 42, streak: 8 },
      { userId: 'd3', name: 'Aman Singh', points: 1095, rank: 3, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 38, streak: 15 },
      { userId: 'd4', name: 'Priya Sharma', points: 1020, rank: 4, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 35, streak: 6 },
      { userId: 'd5', name: 'Rajesh Patel', points: 980, rank: 5, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 32, streak: 4 },
      { userId: 'd6', name: 'Sunita Mehta', points: 920, rank: 6, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 30, streak: 7 },
      { userId: 'd7', name: 'Vikram Singh', points: 875, rank: 7, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 28, streak: 3 },
      { userId: 'd8', name: 'Kavita Yadav', points: 820, rank: 8, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 25, streak: 5 },
      { userId: 'd9', name: 'Suresh Kumar', points: 780, rank: 9, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 22, streak: 2 },
      { userId: 'd10', name: 'Meera Devi', points: 740, rank: 10, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 20, streak: 1 }
    ],
    state: [
      { userId: 's1', name: 'Ravi Kumar', points: 1250, rank: 1, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 45, streak: 12 },
      { userId: 's2', name: 'Lakshmi Devi', points: 1180, rank: 2, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 42, streak: 8 },
      { userId: 's3', name: 'Aman Singh', points: 1095, rank: 3, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 38, streak: 15 },
      { userId: 's4', name: 'Priya Sharma', points: 1020, rank: 4, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 35, streak: 6 },
      { userId: 's5', name: 'Rajesh Patel', points: 980, rank: 5, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 32, streak: 4 },
      { userId: 's6', name: 'Sunita Mehta', points: 920, rank: 6, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 30, streak: 7 },
      { userId: 's7', name: 'Vikram Singh', points: 875, rank: 7, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 28, streak: 3 },
      { userId: 's8', name: 'Kavita Yadav', points: 820, rank: 8, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 25, streak: 5 },
      { userId: 's9', name: 'Suresh Kumar', points: 780, rank: 9, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 22, streak: 2 },
      { userId: 's10', name: 'Meera Devi', points: 740, rank: 10, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 20, streak: 1 }
    ],
    national: [
      { userId: 'n1', name: 'Ravi Kumar', points: 1250, rank: 1, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 45, streak: 12 },
      { userId: 'n2', name: 'Lakshmi Devi', points: 1180, rank: 2, level: 'Expert', badge: 'Gold', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 42, streak: 8 },
      { userId: 'n3', name: 'Aman Singh', points: 1095, rank: 3, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 38, streak: 15 },
      { userId: 'n4', name: 'Priya Sharma', points: 1020, rank: 4, level: 'Advanced', badge: 'Silver', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 35, streak: 6 },
      { userId: 'n5', name: 'Rajesh Patel', points: 980, rank: 5, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 32, streak: 4 },
      { userId: 'n6', name: 'Sunita Mehta', points: 920, rank: 6, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 30, streak: 7 },
      { userId: 'n7', name: 'Vikram Singh', points: 875, rank: 7, level: 'Intermediate', badge: 'Bronze', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 28, streak: 3 },
      { userId: 'n8', name: 'Kavita Yadav', points: 820, rank: 8, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 25, streak: 5 },
      { userId: 'n9', name: 'Suresh Kumar', points: 780, rank: 9, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 22, streak: 2 },
      { userId: 'n10', name: 'Meera Devi', points: 740, rank: 10, level: 'Beginner', badge: 'Rising', village: 'Ludhiana Village', state: 'Punjab', tasksCompleted: 20, streak: 1 }
    ]
  };

  const data = leaderboardData[scope] || leaderboardData.village;
  const limitedData = data.slice(0, parseInt(limit));

  res.json({ 
    scope, 
    id, 
    total: data.length,
    limit: parseInt(limit),
    entries: limitedData
  });
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

// ==================== UTILITY FUNCTIONS ====================

function generateWeatherAdvice(weatherData) {
  const temp = weatherData.main.temp;
  const humidity = weatherData.main.humidity;
  const condition = weatherData.weather[0].main.toLowerCase();
  
  if (condition.includes('rain')) {
    return 'Rain expected. Avoid irrigation and protect crops from waterlogging.';
  } else if (temp > 35) {
    return 'High temperature. Increase irrigation frequency and provide shade if possible.';
  } else if (temp < 15) {
    return 'Low temperature. Protect sensitive crops and reduce irrigation.';
  } else if (humidity > 80) {
    return 'High humidity. Monitor for fungal diseases and ensure good ventilation.';
  } else {
    return 'Good weather conditions for farming activities.';
  }
}

async function fetchMandiPrices(state, district, crop, limit) {
  // This is a mock implementation. Replace with actual Mandi API calls
  const mockPrices = [
    {
      mandiName: `${district} Mandi`,
      crop: crop || 'Wheat',
      variety: 'HD-2967',
      minPrice: Math.floor(Math.random() * 500) + 1800,
      maxPrice: Math.floor(Math.random() * 500) + 2000,
      modalPrice: Math.floor(Math.random() * 500) + 1900,
      unit: 'Quintal',
      date: new Date().toISOString()
    }
  ];
  
  return {
    state: state || 'Punjab',
    district: district || 'Ludhiana',
    crop: crop || 'Wheat',
    prices: mockPrices.slice(0, parseInt(limit)),
    lastUpdated: new Date().toISOString()
  };
}

async function fetchMarketTrends(crop, state, days) {
  // Mock implementation for market trends
  const trends = [];
  for (let i = days; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    trends.push({
      date: date.toISOString(),
      price: Math.floor(Math.random() * 200) + 1900,
      volume: Math.floor(Math.random() * 1000) + 500
    });
  }
  
  return {
    crop,
    state: state || 'Punjab',
    period: `${days} days`,
    trends,
    averagePrice: Math.floor(trends.reduce((sum, t) => sum + t.price, 0) / trends.length),
    priceChange: trends.length > 1 ? trends[trends.length - 1].price - trends[0].price : 0
  };
}

// ==================== CACHE CLEANUP ====================

// Clean up expired cache entries every hour
cron.schedule('0 * * * *', () => {
  const now = Date.now();
  
  Object.keys(cache).forEach(type => {
    const entries = Array.from(cache[type].entries());
    entries.forEach(([key, value]) => {
      if (now - value.timestamp > CACHE_TTL[type]) {
        cache[type].delete(key);
      }
    });
  });
  
  console.log('Cache cleanup completed');
});

// ==================== ERROR HANDLING ====================

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Farmer Assistant API listening on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🌤️  Weather API: http://localhost:${PORT}/api/v1/weather`);
  console.log(`🌾 Mandi API: http://localhost:${PORT}/api/v1/mandi/prices`);
  console.log(`🗣️  Translation API: http://localhost:${PORT}/api/v1/translate`);
});