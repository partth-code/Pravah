# Farmer Assistant Backend API

A comprehensive Node.js backend API for the Farmer Assistant application, providing integration with Bhashini API, Weather APIs, and Mandi APIs.

## Features

- 🌤️ **Weather API Integration** - Real-time weather data and forecasts
- 🗣️ **Bhashini API Integration** - Translation and Text-to-Speech services
- 🌾 **Mandi API Integration** - Market prices and trends
- 📊 **Caching System** - Intelligent caching for better performance
- 🔄 **Error Handling** - Robust error handling with fallbacks
- 📱 **RESTful APIs** - Clean and consistent API endpoints

## API Endpoints

### Weather APIs
- `GET /api/v1/weather?lat={lat}&lng={lng}` - Get current weather and forecast
- `GET /api/v1/weather/alerts?lat={lat}&lng={lng}` - Get weather alerts

### Bhashini APIs
- `POST /api/v1/translate` - Translate text between languages
- `POST /api/v1/tts` - Convert text to speech

### Mandi APIs
- `GET /api/v1/mandi/prices?state={state}&district={district}&crop={crop}` - Get market prices
- `GET /api/v1/mandi/trends?crop={crop}&state={state}&days={days}` - Get market trends

### Existing APIs
- `GET /api/v1/profile` - Get user and farm profile
- `GET /api/v1/tasks` - Get farming tasks
- `GET /api/v1/policies` - Get government policies
- `GET /api/v1/leaderboard` - Get leaderboard data
- `POST /api/v1/tasks/mark` - Mark task as complete
- `POST /api/v1/detect-disease` - Disease detection

## Environment Variables

Create a `.env` file in the backend directory with the following variables:

```env
# Server Configuration
PORT=4000

# API Keys
BHASHINI_API_KEY=your-bhashini-api-key-here
OPENWEATHER_API_KEY=your-openweather-api-key-here
MANDI_API_KEY=your-mandi-api-key-here

# Cache Configuration
WEATHER_CACHE_TTL=1800000
MANDI_CACHE_TTL=3600000
TRANSLATION_CACHE_TTL=86400000

# API Timeouts (in milliseconds)
API_TIMEOUT=10000
TTS_TIMEOUT=15000

# Logging
LOG_LEVEL=info
```

## Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file with your API keys

3. Start the development server:
```bash
npm run dev
```

4. Start the production server:
```bash
npm start
```

## API Usage Examples

### Weather API
```bash
curl "http://localhost:4000/api/v1/weather?lat=30.9010&lng=75.8573"
```

### Translation API
```bash
curl -X POST "http://localhost:4000/api/v1/translate" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello", "sourceLang": "en", "targetLang": "hi"}'
```

### Mandi Prices API
```bash
curl "http://localhost:4000/api/v1/mandi/prices?state=Punjab&district=Ludhiana&crop=Wheat"
```

## Caching

The API implements intelligent caching for:
- Weather data (30 minutes TTL)
- Mandi prices (1 hour TTL)
- Translations (24 hours TTL)

Cache cleanup runs automatically every hour.

## Error Handling

- All APIs include comprehensive error handling
- Fallback to mock data when external APIs fail
- Proper HTTP status codes and error messages
- Timeout protection for external API calls

## Health Check

Check API health at: `GET /health`

Returns:
```json
{
  "ok": true,
  "service": "farmer-assistant-backend",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "cache": {
    "weather": 5,
    "mandi": 3,
    "translations": 10
  }
}
```

## Development

- Uses ES6 modules
- Includes nodemon for development
- Comprehensive logging
- CORS enabled for frontend integration

## Production Considerations

- Set up proper API keys for production
- Configure rate limiting
- Set up monitoring and logging
- Use a proper database for persistent storage
- Implement authentication and authorization