# AirFit Vision

## Core Concept

AirFit is an AI-native fitness and nutrition tracking app that provides a truly personalized AI coach. At its core, it's an intelligent system that maximizes context assembly from HealthKit data combined with selective user inputs that HealthKit can't capture (detailed nutrition tracking, workout set tracking, personal context).

The app creates a unique, coherent AI personality that adapts to each user's communication style, fitness level, and life context - not just another chatbot, but a coach that feels genuinely personalized and human.

## Key Differentiators

### 1. **Dynamic Persona System**
- Each user gets a completely unique AI coach through an intelligent 9-phase onboarding journey
- No templates or archetypes - every coach is genuinely unique with their own name, backstory, philosophy, and voice
- Generated through adaptive conversations that score context quality across 10 dimensions (goals, obstacles, preferences, lifestyle, etc.)
- The AI asks follow-up questions targeting gaps in understanding, ensuring it truly knows the user before creating their coach
- Maintains coherent personality across all interactions - from dashboard greetings to workout suggestions
- Adapts tone based on time of day, user's energy levels, stress, and recent progress

### 2. **Superior Voice Input**
- On-device voice transcription using WhisperKit as a text input alternative
- Much better accuracy than Apple's built-in transcription
- Beautiful voice visualization with real-time feedback
- Voice-to-text available everywhere - chat, notes, food logging
- Not a "voice mode" - just a convenient way to input text

### 3. **Intelligent Context Assembly**
- Pulls comprehensive data from HealthKit: activity, heart health, body composition, sleep
- Adds app-specific tracking: detailed nutrition, workout sets, muscle group volumes
- Optimizes context for AI efficiency while preserving coaching value
- Real-time adaptation based on current state (just woke up? low energy? stressed?)

## Core Features

### Dashboard
- **AI-Generated Content**: Dynamic insights that change based on context and time
- **Skeleton UI**: Instant rendering (< 0.5s app launch) with progressive content loading
- **Visual Progress**: Beautiful rings for calories, protein, and activity
- **Smart Quick Actions**: Context-aware suggestions ("Log Breakfast" in morning)
- **Time-Aware Greetings**: Your coach greets you differently throughout the day

### Chat Interface
- **Streaming Responses**: Real-time, token-by-token feedback for immediate interaction
- **Function Execution**: AI can generate workouts, set goals, analyze performance
- **Message Actions**: Copy, regenerate, schedule workouts directly from chat
- **Suggestion Chips**: Quick actions based on conversation context
- **Coherent Personality**: Every response maintains your coach's unique voice

### Nutrition Tracking
- **Natural Language**: "I had a burger and fries" → structured nutrition data
- **AI-Powered Parsing**: Complex meals parsed accurately with portion understanding
- **Macro Tracking**: Visual rings for protein, carbs, fats against personalized goals
- **HealthKit Sync**: Bidirectional sync with Apple Health
- **Confirmation Flow**: Review parsed data before logging

### Workout System
- **AI Generation**: Personalized workouts based on muscle balance, recovery, goals
- **Drag-and-Drop Builder**: Create custom workouts with intuitive interface
- **Muscle Volume Tracking**: Weekly volume per muscle group with AI recommendations
- **Strength Progression**: Track PRs, analyze trends, get contextual coaching
- **Exercise Database**: Pre-loaded, categorized exercises

### Apple Watch Companion
- **Full Workout Execution**: Start, pause, resume with real-time metrics
- **Set Logging**: Log weight, reps, RPE directly from wrist
- **Rest Timer**: Visual countdown between sets
- **AI Workouts on Watch**: Execute generated workouts with guided progression
- **Live Metrics**: Heart rate, calories, duration in real-time

### Body Progress
- **HealthKit Integration**: Pull body composition data automatically
- **Trend Visualization**: See changes over multiple time windows
- **Context for AI**: Body changes inform coaching recommendations
- **Privacy-First**: All data stays on device or in user's iCloud

## Technical Excellence

### Performance
- **Swift 6 Concurrency**: Proper actor isolation for thread safety
- **Lazy Loading**: Efficient resource usage with dependency injection
- **Background Sync**: Health data updates without blocking UI
- **Optimized Queries**: Smart SwiftData fetching patterns

### AI Architecture
- **Multi-Provider Support**: OpenAI, Anthropic, Google Gemini with fallback
- **Model Flexibility**: Users choose models based on preference/cost
- **Direct Function Execution**: No unnecessary abstraction layers
- **Token Optimization**: Intelligent context compression

### User Experience
- **Glass Morphism Design**: Beautiful blur effects throughout
- **Cascade Animations**: Letter-by-letter text reveals
- **Dynamic Gradients**: Colors evolve with time of day
- **Physics-Based Motion**: Natural spring animations
- **Full Accessibility**: VoiceOver support with proper labeling

## Privacy & Trust

- **On-Device Voice Processing**: Transcription happens locally
- **Minimal Data Collection**: Only what's needed for AI coaching
- **User Control**: Choose AI providers, delete data anytime
- **Transparent AI**: See what context is sent to AI

## The Onboarding Journey

The magic begins from the first launch. After granting health permissions, AirFit analyzes your HealthKit data and crafts an initial understanding - are you already active? Just starting out? Somewhere in between?

Then begins a conversation unlike any other fitness app. Your future AI coach interviews you, but it doesn't feel like a questionnaire. It's adaptive - if you mention struggling with consistency, it gently explores what's held you back. If you express ambitious goals, it digs into what success means to you.

Behind the scenes, the OnboardingIntelligence system scores the conversation across 10 dimensions:
- **Goal Clarity** (25%): What exactly do you want to achieve?
- **Obstacles** (25%): What's stopped you before?
- **Exercise Preferences** (15%): What activities bring you joy?
- **Current State** (10%): Your fitness baseline
- **Lifestyle** (10%): Your schedule and commitments
- Plus nutrition readiness, communication style, past patterns, energy rhythms, and support systems

The AI crafts follow-up questions targeting the lowest-scoring areas, ensuring it truly understands you. This continues until it reaches a quality threshold (0.8) or after 10 conversational turns - whichever comes first.

Then the synthesis begins. Using a frontier AI model, the system generates your completely unique coach in a single coherent pass:
- A creative name and archetype (never generic titles)
- A 100-150 word backstory explaining who they are and why they coach
- A comprehensive personality including speaking style, quirks, and coaching philosophy
- Voice characteristics: energy level, pace, warmth, vocabulary complexity
- Custom adaptation rules for different contexts
- Even a personalized nutrition philosophy

The result? Not a chatbot with your name inserted, but a coach that feels crafted just for you.

## The Daily Experience

Once onboarded, imagine opening AirFit in the morning. Your unique AI coach greets you with awareness of how you slept, your energy levels, and what's planned for the day. The greeting isn't generic - it's in your coach's distinct voice, whether that's an encouraging drill sergeant or a gentle yoga instructor.

You tell your coach what you had for breakfast using your voice, naturally describing your meal. The AI understands portions, preparation methods, and logs it accurately. Throughout the day, your coach is there - suggesting when to work out based on your recovery, celebrating PRs, adjusting plans when you're stressed.

This isn't just an app that tracks data. It's a coach that knows you, adapts to you, and helps you achieve your fitness goals with genuine intelligence and personality.

## Future Vision

While maintaining the core vision of personalized AI coaching, future enhancements could include:
- Group challenges with coach-mediated competition
- Meal photo analysis for easier nutrition tracking  
- Integration with more wearables beyond Apple Watch
- Coach knowledge expansion through specialized fitness domains
- Social features that maintain privacy while enabling community

The north star remains constant: Create an AI fitness coach so personalized, adaptive, and genuinely helpful that it becomes an indispensable part of users' fitness journeys.