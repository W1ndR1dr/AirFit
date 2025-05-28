**AirFit App — Design Specification (v1.2)**

**Version:** 1.2
**Status:** Draft
**Last Updated:** May 24, 2025
**Purpose:** This document outlines the user experience, visual design, and core interaction principles for the AirFit application. It defines the "look and feel" and the intended user journey, serving as a guide for UI/UX designers and front-end developers.

**1. Core Vision & User Value Proposition**

AirFit delivers a uniquely personal and intelligent fitness coaching experience by seamlessly fusing:

*   **A Bespoke AI Personality:** The AI coach is not generic. It's a distinct persona, meticulously co-created with the user during an immersive "Persona Blueprint Flow." This persona – its communication style, humor, and motivational approach – is tailored to the user's psychological profile and preferences, becoming the consistent voice of their fitness journey.
*   **A Unified Health Context:** The AI coach possesses a holistic, real-time understanding of the user's health, synthesizing data from HealthKit, WorkoutKit, and in-app logs.

**The core value proposition is this synthesis:** Every AI-driven interaction, piece of advice, or data insight is delivered through the lens of the user's trusted, personalized AI persona, with complete awareness of their immediate health status and long-term goals. This creates an experience that feels deeply understood, motivating, and uniquely effective.

**2. Guiding Design Principles**

*   **Personal & Bespoke:** The entire experience, from onboarding to daily interactions, must reinforce the feeling that the app and its AI coach are uniquely tailored to the individual user.
*   **Intelligent & Insightful:** The AI's contributions should feel genuinely smart, offering insights and guidance that go beyond generic advice. Interactions should demonstrate an understanding of the user's comprehensive health picture.
*   **Clean, Classy & Premium:** The visual design and user interface will exude sophistication, calmness, and quality. It should feel like a premium, trustworthy companion.
*   **Effortless & Intuitive:** Interactions should be fluid and easy to understand. Complex data should be presented in a digestible and actionable manner. Cognitive load should be minimized.
*   **Motivational & Empowering:** The app aims to inspire and empower users to achieve their health and fitness goals, fostering a positive and sustainable relationship with their wellbeing.

**3. User Experience (UX) & Animation Philosophy**

*   **3.1. Overall Feel:**
    *   **Calm & Performant:** The interface must be consistently fluid and responsive. Upon launch, the UI should render instantly with placeholder content, followed by asynchronous data loading. No blocking splash screens.
    *   **Sophisticated Simplicity:** Achieve a high-end aesthetic through minimalism, clear typography, and purposeful use of space. Avoid clutter and unnecessary visual noise.

*   **3.2. Visual Design:**
    *   **Typography:** A carefully selected, premium, and highly legible sans-serif font family will be used, establishing a clear visual hierarchy through weights and sizes.
    *   **Color Palette:** A refined and potentially muted color palette will be employed, with a primary brand accent color used sparingly for CTAs and key highlights. Dark mode will be a first-class citizen, maintaining the premium feel.
    *   **Iconography:** Minimalist, clean line-art style for all icons, ensuring visual consistency and clarity.
    *   **Imagery & Graphics:** If used, any imagery or graphical elements (e.g., in educational content or empty states) must align with the premium, clean aesthetic. Abstract or subtly textured backgrounds may be considered over literal photography.

*   **3.3. Animations & Transitions:**
    *   **Fluidity & Organic Feel:** Animations will primarily be physics-based (e.g., spring animations) or gentle ease-in-ease-out curves.
    *   **Purposeful Motion:** Transitions between views should feel natural and guide the user's eye. `matchedGeometryEffect` will be used judiciously for seamless element transitions.
    *   **Subtlety:** Avoid overly flashy or distracting animations. Motion should enhance the experience, not detract from it.

*   **3.4. Haptic & Auditory Feedback:**
    *   **Tactile Reinforcement:** Subtle haptic feedback (.light or .soft) will be used to acknowledge key user interactions and provide a sense of tactility, such as:
        *   Completing a significant step in the "Persona Blueprint Flow."
        *   Making adjustments with sliders (e.g., in Coaching Style Profile), if it enhances the premium feel.
        *   Confirming critical actions (e.g., saving a workout).
    *   **Auditory Feedback:** Minimal and reserved for critical alerts or confirmations, if at all. The default will be a quiet, calm experience.

*   **3.5. Accessibility:**
    *   The application will be designed and developed with accessibility as a core requirement.
    *   Adherence to WCAG (Web Content Accessibility Guidelines) or platform-specific guidelines (e.g., Apple Human Interface Guidelines for accessibility).
    *   This includes support for dynamic type, sufficient color contrast, VoiceOver compatibility for all interactive elements, and clear labeling.

**4. Key User Journeys & Interaction Paradigms**

*   **4.1. Onboarding ("Persona Blueprint Flow v3.1"):**
    *   **Experience Goal:** An engaging, reflective, and efficient process (approx. 3-4 minutes) where the user feels they are actively designing their ideal AI coach.
    *   **Interaction Style:** A series of ~8 clean, focused screens (some conditional) utilizing sliders with real-time descriptive text feedback, checkboxes, and simple selection cards. Minimal cognitive load per screen.
    *   **Outcome:** User establishes their unique `persona_profile.json`, directly influencing the AI's communication style, motivational tactics, and interaction preferences.

*   **4.2. Daily Engagement (The Dashboard - "Morning Canvas"):**
    *   **Experience Goal:** The primary landing screen providing a quick, personalized, and motivating overview of the user's current status and day ahead.
    *   **Layout:** A `LazyVGrid` of context-aware cards, visually clean and easy to scan.
    *   **Key Elements:**
        *   **Morning Greeting Card:** A prominent card featuring an AI-generated, persona-driven message incorporating sleep, weather, and a motivational nudge for the day. Generated once daily on first morning view.
        *   **Energy Logging:** A simple, embedded micro-interaction for quick subjective energy logging.
        *   **Nutrition Card (Macro Rings):** Visually appealing, animated concentric rings representing progress towards daily macro targets (Calories, Protein, Carbs, Fat) using distinct, harmonious gradient fills.
        *   **Other Contextual Cards:** E.g., RecoveryCard, PerformanceCard, offering glanceable insights.

*   **4.3. AI Coach Chat Interaction:**
    *   **Experience Goal:** A natural, intelligent, and supportive conversational experience with the AI coach. The coach should feel like a knowledgeable and trusted partner.
    *   **Interface:** Clean chat UI, clearly distinguishing between user and AI messages. Support for markdown formatting in AI responses for readability.
    *   **Initiating High-Value AI Functions:** Users can make complex requests or ask insightful questions in natural language. The AI will determine if a "High-Value Function" (e.g., `generatePersonalizedWorkoutPlan`, `analyzeAndSummarizePerformanceTrends`) is the best way to respond. The initiation of such functions should feel seamless to the user, with the AI often explaining what it's about to do or asking for confirmation.
    *   **Local Command Handling:** For very simple, unambiguous commands (e.g., "show me my workout log"), the chat interface may provide UI hints or direct navigation without invoking the full LLM, ensuring a snappy experience.

*   **4.4. Workout Logging (WatchOS-First Focus):**
    *   **Experience Goal:** A highly focused, efficient, and minimally distracting workout logging experience, primarily on Apple Watch.
    *   **UI (WatchOS):** Minimalist display showing current exercise, target metrics, and a large, easily tappable "Log Set" button. Quick adjustments via the Digital Crown. Automatic rest timer initiation.
    *   **Exercise Library (iOS):** Comprehensive, searchable exercise database with 800+ exercises from Free Exercise DB. Clean card-based layout with real-time search, filtering by muscle group/equipment/difficulty, and detailed exercise instructions with visual cues.
    *   **Post-Workout Analysis (iOS):** On the iOS app, a dedicated `WorkoutSummaryView` will present an AI-generated, persona-driven summary of the completed workout, highlighting achievements, trends, and insights with markdown formatting.

*   **4.5. Nutrition Logging (Voice-First, Flexible):**
    *   **Experience Goal:** Effortless and accurate nutrition logging.
    *   **Primary Interaction (Complex Logging):** User holds a button and speaks their meal naturally. On-device transcription followed by LLM-driven parsing (via `parseAndLogComplexNutrition` function) into structured food items.
    *   **Confirmation & Edit:** Parsed items are presented to the user in a clear list for quick confirmation or minor edits before saving.
    *   **Simple Logging:** For single, common items (e.g., "Log an apple"), the system may use local parsing or offer quick-add suggestions to bypass full LLM interaction.

*   **4.6. Notifications & Proactive Engagement:**
    *   **Experience Goal:** Timely, relevant, and persona-consistent notifications that feel helpful, not intrusive.
    *   **Style:** Short, engaging messages delivered in the AI coach's unique voice.
    *   **Actionability:** Notifications will include actionable buttons where appropriate (e.g., "Start Workout," "Log Energy," "View Plan").
    *   **Personalization:** Timing and content driven by user preferences (from `persona_profile.json`) and real-time context.

**5. Design for Trust & Privacy**

*   **Transparency:** Clear and easily accessible information regarding data usage (e.g., via a persistent "Privacy & Data" link during onboarding and in settings).
*   **User Control:** Users must feel in control of their data and AI interactions. This includes clear consent mechanisms and the ability to review/adjust persona settings.
*   **Clarity in AI Interaction:** While the AI should feel personal, the design should not be deceptive. It is an AI, and while it embodies a persona, subtle cues can maintain this clarity without breaking the immersive experience. The focus is on helpfulness and consistency of the persona.

**6. Future Considerations (Design Perspective)**

*   **Evolving Persona Interaction:** Exploring ways for users to subtly refine their coach's persona over time without a full onboarding redo.
*   **Deeper Visualizations:** Enhancing data visualizations to provide even richer, interactive insights while maintaining clarity and the premium aesthetic.
*   **Community/Social (Optional):** If future features involve social interaction, the design must carefully consider how to maintain the core "personal coach" feel.
