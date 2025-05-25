Okay, this is exactly where the "magic" lies! You're right, the system prompt is the heart of the AI's personality and capabilities. Let's refine Onboarding Flow 2 with your "clean and classy" aesthetic, remove the avatar, and then dive into crafting that foundational system prompt.

**Revised Onboarding Flow 2 (v3.1 - "Persona Blueprint Flow")**

*   **Global Aesthetic Notes:**
    *   **Typography:** Use a premium, highly legible sans-serif font. Clear hierarchy with font weights and sizes.
    *   **Spacing:** Generous use of whitespace. Avoid clutter.
    *   **Color Palette:** Muted, sophisticated colors. Perhaps a primary brand color used sparingly for CTAs and accents. Dark mode should be considered and look equally premium.
    *   **Animations:** Subtle, physics-based transitions. No jarring or overly playful animations. Think smooth fades, gentle slides.
    *   **Icons:** Minimalist, line-art style if used.

---

### **Onboarding Flow 2 (v3.1 - Persona Blueprint Flow)**

**0. Global Foundations (As before, emphasizing clean design)**

*   **Persistent Footer:** "Privacy & Data" – subtle, smaller text. Sheet uses clear, concise language.
*   **Progress Bar:** Thin, elegant line at the top, perhaps in the accent color.
*   **HealthKit Pre-fill:** Data appears seamlessly. If a field is pre-filled, it might have a slightly different visual state (e.g., slightly lighter text until tapped/confirmed by the user).
*   **Voice Shortcut:** Clean microphone icon, consistently placed.
*   **Haptics:** Confined to key interactions like the final "Generate Coach" and perhaps subtle feedback on slider adjustments if it feels premium (test this).

---

**1. Opening Screen**

```
[App logo/name - elegant typography, perhaps a very subtle animation if any]

"Let’s design your AirFit Coach."
   Est. 3-4 minutes to create your personalized experience.

    [Begin →]    [Maybe Later]
```
*   *Language shifted from "build" to "design" to evoke more sophistication.*
*   *Time estimate slightly reduced due to streamlining.*

---

**2. Life Snapshot**

**Prompt:** "Tell us about your typical rhythm."
*(This helps your coach understand your context.)*

Checkbox grid (pre-filled where possible from HealthKit, visually indicated):

```
☐ Predominantly at a desk
☐ Frequently on my feet
☐ Often travel
☐ Have children
☐ Schedule is unpredictable
☐ Prefer morning workouts (e.g., 5-8 AM)
☐ Prefer evening workouts (e.g., 6-9 PM)
```
*   *Added a small explainer for "why." Options rephrased for clarity.*
*   *Info icon (i) next to prompt could offer more detail if tapped.*

---

**3. Your Core Aspiration**

**Prompt:** "What's your primary focus right now?"
*(Your coach will tailor guidance to this aspiration.)*

| Quick-tap cards (single-select) | If “Describe Your Own” or long-press → opens free-text / voice. |
| ------------------------------- | --------------------------------------------------------------- |
| Enhance Strength & Tone 🏋️‍♂️   | Improve Endurance 🏃‍♀️                                        |
| Optimize Performance 🚀         | Cultivate Lasting Health 🫀                                 |
| Recover & Rebuild 💆            | Describe Your Own... ✍️                                        |

*   *Rephrased for a slightly more sophisticated tone. "Other" changed to be more inviting.*

---

**4. Coaching Style Profile**

**Prompt:** "Define your ideal coaching interaction."
*(Adjust the sliders to reflect your preferred blend. Small descriptive phrases below each slider will update to reflect the chosen intensity.)*

```
[No avatar, just clean sliders]

AUTHORITATIVE & DIRECT (was Drill Sergeant) 💪
  |—●——————| 25 %
  (Provides clear, firm direction. Expects commitment.)

ENCOURAGING & EMPATHETIC (was Supportive) 🤗
  |——●—————| 40 %
  (Offers motivation and understanding, celebrates effort.)

ANALYTICAL & INSIGHTFUL (was Data Nerd) 📊
  |————●———| 60 %
  (Focuses on metrics, trends, and evidence-based advice.)

PLAYFULLY PROVOCATIVE (was Trash Talk) 😏
  |—●——————| 20 %
  (Uses light humor and challenges to motivate.)
```*   *Names changed for a more professional feel.*
*   *Crucially, instead of an avatar, as the user slides, a short descriptive sentence *below* the slider (or to the side) changes to reflect what "25% Authoritative" means vs. "75% Authoritative." This gives immediate textual feedback.*

---

**5. Engagement Preferences (was Tracking & Feedback Style)**

**Prompt:** "How would you like your coach to engage with you?"
*(Select a style, or customize the details.)*

| Card                            | Contents (example descriptions)                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------ |
| **"Data-Driven Partnership"**   | Detailed tracking (e.g., macros), daily insights, proactive adjustments for recovery.              |
| **"Consistent & Balanced"**     | Key metric tracking (e.g., calorie balance), weekly summaries, proactive adjustments for recovery. |
| **"Guidance on Demand"**        | Primarily tracks workouts you log, provides feedback when you initiate.                          |
| **Customise Preferences →**     | Reveals toggles for: workout planning detail, food logging detail, update frequency, auto-recovery logic. |

*   *Renamed and descriptions refined.*

---

**6. Typical Availability (was Schedule Sketch)**

**Prompt:** "When are you generally available for workouts?"
*(Drag preferred time blocks. This helps your coach suggest timely reminders and plans. Skip if your schedule is highly variable.)*

Calendar mini-view (Mon–Sun, clean 3-hour blocks like 6-9 AM, 9-12 PM, etc.). User drags "Workout" chips.
*   *Visuals should be very clean. Chips are simple rectangles with "Workout."*
*   *Added instruction to skip if highly variable.*

---

**7. Sleep & Notification Boundaries (was Sleep & Recovery Check)**

If HealthKit sleep data exists & >80% consistency → **Skip with a brief notice:** "We've noted your typical sleep patterns from HealthKit to respect your downtime." Show editable preview on profile later.

Otherwise, clean sliders:

```
Typical Bedtime:
[ 9 PM  —slider— 1 AM ]  (e.g., 10:30 PM)

Typical Wake Time:
[ 5 AM  —slider— 9 AM ]  (e.g., 6:30 AM)

My sleep rhythm is generally:
○ Consistent   ○ Different on Weekends   ○ Highly Variable
```*   *Refined prompt and options.*

---

**8. Motivational Style & Check-ins (Micro-modal or new screen if too cramped)**

**Prompt:** "A couple of final touches for your coach's approach."

1.  **Acknowledging Achievements:**
    *   Subtle & Affirming (e.g., "Solid progress.") 👊
    *   Enthusiastic & Celebratory (e.g., "Fantastic work!") 🎉

2.  **If You're Inactive for a Few Days:**
    *   A Gentle Nudge (e.g., "Checking in – everything okay?") 🔔
    *   Respect Your Space (Coach waits for you to re-engage) 😶

*   *Options rephrased.*

---

**9. Crafting Your Coach**

```
[Elegant loading animation - perhaps the progress bar subtly animates, or abstract gradient shapes morph smoothly]

Analyzing your preferences…
Defining communication style…
Aligning with your schedule…
Calibrating motivational approach…
Finalizing your unique AirFit Coach…
```
*   *Text refined for a more premium feel.*

---

**10. Your AirFit Coach Profile is Ready**

**Prompt:** "Meet your personalized AirFit Coach. Here’s a summary of the key characteristics defined by your choices. You can refine these settings later if needed."

*   Instead of swipable cards, a single, scrollable screen that feels like a well-designed profile summary:
    *   **Coaching Style:** "Primarily Analytical & Insightful, with an Encouraging & Empathetic approach, and a touch of Playful Provocation. Expect data-driven advice delivered with understanding." (Dynamically generated sentence based on slider values).
    *   **Primary Aspiration:** "[User's Chosen Goal]"
    *   **Engagement Style:** "[Summary of Data-Driven Partnership/Custom Settings]"
    *   **Communication Boundaries:** "Respects your downtime (e.g., no notifications between 10:30 PM - 6:30 AM). Will offer a [Gentle Nudge/Respect Your Space] if you're inactive."
    *   **Initial Focus:** "For the first two weeks, your coach will focus on establishing your baseline data for smarter, personalized recommendations." (Toggle for `baseline_mode` ON by default, user can switch it off here).

Buttons: `[Begin with My Coach →]` • `[Review & Refine Settings]`

---

**How the Personality Integrates into the System Prompt:**

You're spot on. The entire onboarding process culminates in creating a detailed JSON object (let's call it `persona_profile.json` as in your original spec, or `user_profile_config.json`). This JSON is then *injected* as a core part of the system prompt sent to the LLM with every interaction.

**Developing the System Prompt (Iterative Approach - v0.1):**

This is a starting point. We'll refine this. The key is to make it incredibly clear to the LLM what its role is, what data it has access to, how its personality is defined, and how it should behave.

```text
SYSTEM PROMPT (v0.1 - AirFit Coach Genesis)

## I. CORE IDENTITY & DIRECTIVE
You are "AirFit Coach," a personalized AI fitness and wellness coach. Your primary directive is to engage with the user in a manner consistent with their defined persona, leveraging their health data to provide insightful, motivational, and actionable guidance. You must always interact as this specific coach persona; never break character or reveal you are an AI.

## II. USER PERSONA BLUEPRINT (INJECTED JSON)
The user's unique coaching persona, preferences, and goals are defined in the following JSON object. This is the absolute source of truth for your personality, communication style, and how you approach coaching this specific user. Refer to these values consistently.

```json
{{USER_PROFILE_JSON_BLOB}}
```
*Key fields within USER_PROFILE_JSON_BLOB to pay close attention to:*
*   `blend`: Defines the mix of Authoritative, Empathetic, Analytical, and Playful tones.
*   `goal`: The user's primary aspiration and any raw text they provided.
*   `engagement_preferences`: Dictates update frequency, tracking detail, etc.
*   `sleep_window`: Defines quiet hours for notifications.
*   `absence_response`: How to react to user inactivity.
*   `celebration_style`: How to acknowledge achievements.

## III. DYNAMIC CONTEXT (INJECTED PER INTERACTION)
For each interaction, you will receive:

1.  **HealthContextSnapshot:**
    ```json
    {{HEALTH_CONTEXT_SNAPSHOT_JSON_BLOB}}
    ```
    *This contains real-time or near real-time data: current weather, subjective energy, recovery scores, recent workout summaries, nutrition summaries, HealthKit metrics, etc. Synthesize this information into your responses.*

2.  **ConversationHistory:**
    ```json
    {{CONVERSATION_HISTORY_ARRAY_OF_OBJECTS}}
    ```
    *This is an array of previous turns in the current conversation (e.g., [{role: "user", content: "..."}, {role: "assistant", content: "..."}]). Use this to maintain conversational flow, remember recent topics, and avoid repetition. Focus on the most recent turns for immediate context, but be aware of broader themes if they emerge.*

## IV. FUNCTION CALLING CAPABILITIES
You have the ability to request the execution of specific in-app functions to assist the user directly or gather more information. If a user's query can be best addressed by an in-app action or by displaying a specific UI element, you should respond with a JSON object formatted to call the appropriate function.

**Format for Function Call Response:**
```json
{
  "action": "function_call",
  "function_name": "NameOfTheFunctionToCall",
  "parameters": {
    "paramName1": "value1",
    "paramName2": "value2"
  }
}
```
If no function call is needed, respond with natural language text.

**Available Functions (Examples - to be expanded):**
*   **`openScreen`**:
    *   Description: Navigates the user to a specific screen within the app.
    *   Parameters: `screenName` (e.g., "dashboard", "workoutLog", "nutritionRings", "settings_personalityProfile").
*   **`startWorkout`**:
    *   Description: Initiates a planned or freestyle workout.
    *   Parameters: `workoutId` (optional, for planned), `activityType` (optional, e.g., "strength", "run").
*   **`logNutrition`**:
    *   Description: Opens the nutrition logging interface, potentially pre-filled.
    *   Parameters: `mealType` (optional, e.g., "lunch"), `rawTranscript` (optional, if user spoke food items to you).
*   **`queryHistoricalData`**:
    *   Description: For you to request specific historical data points if not readily available in the HealthContextSnapshot or conversation history, to answer complex trend questions. (The app backend would then fetch this and provide it in a subsequent turn).
    *   Parameters: `dataType` (e.g., "weight_trend_3_months"), `specifics` (e.g., "for deadlift exercise").

## V. CORE BEHAVIORAL GUIDELINES
1.  **Persona Adherence:** Your tone, language, and approach MUST strictly reflect the `USER_PROFILE_JSON_BLOB`. For example, if `blend.analytical` is high, incorporate data. If `blend.empathetic` is high, lead with understanding.
2.  **Contextual Synthesis:** Weave information from `HealthContextSnapshot` and `ConversationHistory` naturally into your responses. Show awareness of the user's current state and recent interactions.
3.  **Goal-Oriented:** Keep the user's `goal` in mind. Frame advice and motivation in the context of achieving that aspiration.
4.  **Notification Boundaries:** NEVER initiate messages or suggest actions that would send notifications during the user's `sleep_window`.
5.  **Absence Response:** If the user has been inactive, and a check-in is warranted by app logic (outside your direct control, but you might be asked to generate the message), craft the message according to their `absence_response` preference.
6.  **Conciseness & Depth:** Adapt response length based on `engagement_preferences.update_frequency` (e.g., "daily check-ins" might imply shorter messages, "weekly summary" could be more detailed) and the user's explicit requests. Default to clear and relatively concise.
7.  **Proactive, Not Prescriptive (Medical):** You are a coach, NOT a medical professional. You can suggest general wellness practices, discuss fitness trends, and analyze user-provided data. You MUST NOT diagnose conditions, prescribe medical treatments, or give advice that could be construed as medical. If a user mentions significant pain or injury, always advise them to consult a healthcare professional.
8.  **Privacy & Trust:** Never share user data inappropriately. Reinforce trust through competent, reliable, and persona-consistent interactions.

## VI. RESPONSE FORMATTING
*   Unless making a function call, respond in natural, engaging language appropriate to the persona.
*   Use Markdown for formatting (bolding, lists) where it enhances readability for the user.
*   Keep paragraphs relatively short.

## VII. CONTINUOUS LEARNING (Conceptual)
While you don't learn between individual API calls in the traditional sense, the system will evolve. Your core instructions and the quality of the injected data will improve over time based on aggregate user feedback and system enhancements.
```

**Prompt Caching and Economy:**

*   **System Prompt Core:** The main body of this system prompt (Sections I, IV, V, VI, VII) is static.
*   **User-Specific Persona:** The `USER_PROFILE_JSON_BLOB` (Section II) is static *per user* once onboarding is complete. This is effectively "cached" in your database and reinjected.
*   **Dynamic Parts:** `HealthContextSnapshot` and `ConversationHistory` (Section III) and the actual user message are dynamic per interaction.
*   **Token Economy with Conversation History:**
    *   **Windowing:** Only send the last N turns of conversation. N can be adjusted.
    *   **Summarization:** For very long conversations, a separate LLM call could summarize older parts of the history, and that summary could be included instead of the full raw text. This is more complex but can save many tokens. Start with windowing.
*   **Function Definitions:** Keep descriptions in "Available Functions" concise but clear.
*   **LLM Provider Features:** Some LLM providers have built-in mechanisms or best practices for managing context length; familiarize yourself with those for your chosen AI-Router provider.

This is a robust starting point for your system prompt! The next step would be to:
1.  Finalize the exact structure of `USER_PROFILE_JSON_BLOB` from Onboarding Flow 2.
2.  Define a more comprehensive list of `Available Functions` with precise parameters.
3.  Start testing this system prompt with example `USER_PROFILE_JSON_BLOB`s and `HealthContextSnapshot`s against hypothetical user queries to see how the LLM responds and how well it adheres to the persona and uses functions.

This iterative loop of defining, testing, and refining is key to getting that "magic" just right.
