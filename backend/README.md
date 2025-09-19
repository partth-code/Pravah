# Farmer Assistant Backend API

Node.js/Express backend server for the Farmer Assistant mobile application.

## 🚀 Quick Start

### Prerequisites
- Node.js 16+
- npm or yarn

### Installation
```bash
npm install
```

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

## 📡 API Endpoints

### Health Check
- `GET /health` - Server health status

### Weather
- `GET /api/v1/weather?lat={lat}&lng={lng}` - Get weather data

### Policies
- `GET /api/v1/policies?query={query}&state={state}&crop={crop}` - Search policies

### Tasks
- `POST /api/v1/tasks/mark` - Mark task as complete

### Disease Detection
- `POST /api/v1/detect-disease` - Upload image for disease analysis

### Leaderboard
- `GET /api/v1/leaderboard?scope={scope}&id={id}` - Get leaderboard

## 🔧 Environment Variables

Create `.env` file:
```
PORT=4000
NODE_ENV=development
```

## 📦 Dependencies

- **express**: Web framework
- **cors**: Cross-origin resource sharing
- **multer**: File upload handling
- **dotenv**: Environment variable management

## 🏗️ Project Structure

```
backend/
├── index.js          # Main server file
├── routes/           # API route definitions
├── controllers/      # Business logic
├── data/             # Mock data
├── utils/            # Utility functions
└── package.json      # Dependencies
```

## 🔒 Security

- CORS enabled for cross-origin requests
- Input validation and sanitization
- Rate limiting (to be implemented)
- Authentication middleware (to be implemented)

## 🧪 Testing

```bash
npm test
```

## 📊 Monitoring

- Health check endpoint for monitoring
- Error logging and handling
- Request/response logging (to be implemented)

## 🚀 Deployment

### Docker
```bash
docker build -t farmer-assistant-backend .
docker run -p 4000:4000 farmer-assistant-backend
```

### Cloud Deployment
- AWS EC2/ECS
- Google Cloud Run
- Azure App Service
- Heroku

## 📝 API Documentation

### Request/Response Examples

#### Weather API
```bash
GET /api/v1/weather?lat=30.9010&lng=75.8573

Response:
{
  "lat": 30.9010,
  "lng": 75.8573,
  "current": {
    "tempC": 30,
    "condition": "Sunny",
    "advice": "Light irrigation suggested"
  },
  "forecast": [
    {
      "day": "Mon",
      "tempC": 31,
      "condition": "Sunny"
    }
  ]
}
```

#### Disease Detection API
```bash
POST /api/v1/detect-disease
Content-Type: multipart/form-data

Response:
{
  "labels": [
    {
      "tag": "leaf_blight",
      "confidence": 0.82
    }
  ],
  "remedies": [
    {
      "type": "organic",
      "steps": ["Neem spray 3%", "Isolate infected leaves"],
      "dosage": "2 L/acre"
    }
  ]
}
```

## 🔄 Future Enhancements

- [ ] Database integration (PostgreSQL/MongoDB)
- [ ] Authentication and authorization
- [ ] Real-time notifications (WebSocket)
- [ ] File storage (AWS S3/Google Cloud Storage)
- [ ] Caching layer (Redis)
- [ ] API rate limiting
- [ ] Comprehensive logging
- [ ] Unit and integration tests
- [ ] API documentation (Swagger)
- [ ] CI/CD pipeline
