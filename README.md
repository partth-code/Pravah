# Farmer Assistant - Mobile App

A comprehensive Flutter mobile application designed for smallholder and regional farmers, featuring AI-powered disease detection, policy discovery, task management, and community insights.

## 🌟 Features

### Core Functionality
- **AI-Powered Disease Detection**: Camera-based plant disease identification with treatment recommendations
- **Policy Dashboard**: Search and discover government policies and subsidies
- **Task Management**: Daily farming tasks with gamification and progress tracking
- **Weather Integration**: Real-time weather data with farming advice
- **AI Chatbot**: Context-aware assistant for farming queries
- **Progress Roadmap**: Visual timeline of farming activities
- **Gamification**: Points system and leaderboards for motivation

### User Experience
- **Multi-language Support**: Hindi, English, Tamil, Telugu
- **Offline Capability**: Core features work without internet
- **Accessibility**: Voice input/output, high contrast, large touch targets
- **Responsive Design**: Optimized for various screen sizes

## 🏗️ Architecture

### Frontend (Flutter)
```
lib/
├── models/           # Data models and API response classes
├── services/         # API service and state management
├── screens/          # Feature screens (Profile, Policy, Disease, etc.)
├── widgets/          # Reusable UI components
└── main.dart         # App entry point and navigation
```

### Backend (Node.js/Express)
```
backend/
├── index.js          # Express server setup
├── routes/           # API route definitions
├── controllers/      # Business logic controllers
├── data/             # Mock data and database models
└── utils/            # Utility functions
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Node.js (16+)
- Android Studio / VS Code
- Git

### Backend Setup
```bash
cd backend
npm install
npm run dev
```
Backend runs on `http://localhost:4000`

### Frontend Setup
```bash
cd frontend/farmer_assistant
flutter pub get
flutter run
```

## 📱 Screenshots

### Home Screen
- Weather card with current conditions and farming advice
- Today's tasks with priority indicators
- Quick action chips for common operations

### Disease Detection
- Camera integration for plant photo capture
- AI-powered disease identification
- Treatment recommendations (organic/chemical)
- Confidence scores and alternative diagnoses

### Policy Dashboard
- Searchable policy database
- Eligibility criteria and required documents
- AI-generated summaries
- Bookmark and application tracking

### Profile Management
- User and farm information
- Identity verification (Aadhaar, Farm ID)
- Language and notification settings
- Farm details with visual cards

## 🔧 API Endpoints

### Weather
- `GET /api/v1/weather?lat={lat}&lng={lng}` - Current weather and forecast

### Policies
- `GET /api/v1/policies?query={query}&state={state}&crop={crop}` - Search policies

### Tasks
- `POST /api/v1/tasks/mark` - Mark task as complete
- `GET /api/v1/tasks?farmId={id}` - Get farm tasks

### Disease Detection
- `POST /api/v1/detect-disease` - Upload image for disease analysis

### Leaderboard
- `GET /api/v1/leaderboard?scope={village|district|state}` - Get rankings

## 🎨 Design System

### Colors
- Primary Green: `#2E8B57` (actions, success)
- Accent Gradient: `#1FA2FF → #12D8A5` (AI features)
- Secondary Blue: `#2C7BD1` (info highlights)
- Neutral Dark: `#0F1724` (text)
- Neutral Gray: `#E6EEF2` (cards background)
- Error/Alert: `#E53E3E`

### Typography
- Headline: 20-28sp (Roboto/Inter, weight 600-700)
- Body: 14-16sp (weight 400-500)
- Button: 16sp (weight 600)

### Spacing
- Base spacing: 8px grid
- Card radius: 12-16px
- Button radius: 999px (pills), 12px (small)

## 🤖 AI Integration

### Disease Detection
- Uses fine-tuned CNN models (MobileNetV3/EfficientNet-lite)
- Returns top-3 disease labels with confidence scores
- Provides localized treatment recommendations

### Policy Matching
- Semantic search using embeddings
- Vector database for policy similarity
- Eligibility-based filtering

### Chatbot
- Context-aware responses using farm profile
- Weather, market prices, and regional trends integration
- Multi-language support with local terminology

## 📊 State Management

Uses Provider pattern for state management:
- `StateService`: Central state management
- `ApiService`: HTTP client and API integration
- Reactive UI updates with `Consumer` widgets

## 🔒 Security & Privacy

- TLS encryption for all API communications
- Aadhaar data hashed and stored securely
- Granular consent for data sharing
- Local storage for sensitive information
- Role-based access control

## 🌐 Localization

Supported languages:
- English (en)
- Hindi (hi)
- Tamil (ta)
- Telugu (te)

Date/time formats adapt to locale preferences.

## 📱 Platform Support

- **Android**: API level 21+ (Android 5.0)
- **iOS**: iOS 11.0+
- **Web**: Modern browsers with camera support
- **Windows**: Windows 10+ (desktop app)

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### E2E Tests
- Onboarding flow
- Disease detection workflow
- Policy search and application
- Task completion and gamification

## 📈 Analytics

Tracked events:
- `task_completed` - Task completion with points awarded
- `policy_viewed` - Policy page visits
- `disease_reported` - Disease detection usage
- `chat_query` - AI chatbot interactions
- `streak_milestone` - Gamification achievements

## 🚀 Deployment

### Backend
- Deploy to cloud platforms (AWS, GCP, Azure)
- Use containerization (Docker)
- Set up CI/CD pipelines
- Configure environment variables

### Frontend
- Build for production: `flutter build apk --release`
- Deploy to app stores (Google Play, App Store)
- Set up crash reporting (Firebase Crashlytics)
- Configure analytics (Firebase Analytics)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- Open source AI/ML community
- Agricultural extension officers for domain expertise
- Smallholder farmers for user feedback

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Email: support@farmerassistant.app
- Documentation: [docs.farmerassistant.app](https://docs.farmerassistant.app)

---

**Built with ❤️ for farmers worldwide**
