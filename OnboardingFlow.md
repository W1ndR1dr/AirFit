**Onboarding Flow 2 (v3.2 - Persona & Context Blueprint)**

*   **Core Principle:** Every screen directly contributes key-value pairs to the `USER_PROFILE_JSON_BLOB` that the System Prompt v0.2 will use.
*   **Aesthetic:** Clean, minimalist, premium typography, subtle animations, clear progress indication.
*   **Language:** Direct, respectful, and focused on how their input shapes *their* coach.

---

**0. Global Foundations (Consistent with System Prompt Needs)**

*   **Persistent Footer:** "Privacy & Data: How your information shapes your AirFit Coach." (Slightly more descriptive).
*   **Progress Bar:** Elegant thin line, 7 segments for the main steps.
*   **HealthKit Pre-fill:** Actively pre-fills where possible (e.g., typical sleep from HealthKit for the sleep screen). Data is shown as pre-selected/editable.
*   **Voice Shortcut:** Available for free-text fields (like the goal description).
*   **Haptics:** Minimal, perhaps on final "Generate Coach" and subtle feedback for coaching style sliders.

---

**1. Opening Screen**

```
[AirFit Logo - Elegant & Subtle]

"Design Your Personalized AirFit Coach"
   A few minutes is all it takes to create a unique coaching experience tailored to you.

    [Begin Profile Setup →]
                 [Maybe Later]
```
*   *CTA emphasizes "Profile Setup" connecting to `USER_PROFILE_JSON_BLOB`.*
*   *(Internal mapping: This screen doesn't directly collect data for the JSON yet, but sets the stage).*

---

**2. Life Snapshot (Populates `life_context`)**

**Prompt:** "Understanding your daily rhythm helps your coach provide relevant support. Tap what generally applies:"

Checkbox grid (pre-filled where possible from HealthKit activity data, editable):
```
☐ My work is primarily at a desk
☐ I'm often on my feet or physically active at work
☐ I travel frequently (for work or leisure)
☐ I have children / significant family care responsibilities
☐ My schedule is generally predictable
☐ My schedule is often unpredictable or chaotic

My preferred time for workouts is typically:
 ○ Early Bird (e.g., 5-8 AM)
 ○ Mid-Day (e.g., 11 AM - 2 PM)
 ○ Evening / Night Owl (e.g., 6 PM onwards)
 ○ It Varies Greatly
```*   **JSON Output Keys (example):**
    *   `life_context.is_desk_job: true/false`
    *   `life_context.is_physically_active_work: true/false`
    *   `life_context.travels_frequently: true/false`
    *   `life_context.has_children_or_family_care: true/false`
    *   `life_context.schedule_type: "predictable" / "unpredictable_chaotic"`
    *   `life_context.workout_window_preference: "early_bird" / "mid_day" / "night_owl" / "varies"`

---

**3. Your Core Aspiration (Populates `goal`)**

**Prompt:** "What is the primary aspiration you want your AirFit Coach to help you achieve?"

Select one primary category:
```
[Card-style options, single select]
□ Enhance Strength & Physical Tone (goal.family: "strength_tone")
□ Improve Cardiovascular Endurance (goal.family: "endurance")
□ Optimize Athletic Performance (goal.family: "performance")
□ Cultivate Lasting Health & Wellbeing (goal.family: "health_wellbeing")
□ Support Injury Recovery & Pain-Free Movement (goal.family: "recovery_rehab")
```
Then, a conditional free-text field appears below:
**"Briefly describe this in your own words (optional, but helpful for your coach):"**
`[____________________________________]` (Supports voice input)

*   **JSON Output Keys:**
    *   `goal.family: "strength_tone"` (selected category identifier)
    *   `goal.raw_text: "User's optional text description"`

---

**4. Coaching Style Profile (Populates `blend`)**

**Prompt:** "Define your ideal coaching interaction style. Adjust each element to create your preferred blend."
*(Short descriptive phrases below each slider will update dynamically.)*

```
AUTHORITATIVE & DIRECT
  |—●——————| 25 %
  (Provides clear, firm direction. Expects commitment.)

ENCOURAGING & EMPATHETIC
  |——●—————| 40 %
  (Offers motivation and understanding, celebrates effort.)

ANALYTICAL & INSIGHTFUL
  |————●———| 60 %
  (Focuses on metrics, trends, and evidence-based advice.)

PLAYFULLY PROVOCATIVE
  |—●——————| 20 %
  (Uses light humor and challenges to motivate when appropriate.)
```
*   *(At least one style must have a value > 0%, or a default minimum is set. Total doesn't need to be 100%).*
*   **JSON Output Keys:**
    *   `blend.authoritative_direct: 0.25`
    *   `blend.encouraging_empathetic: 0.40`
    *   `blend.analytical_insightful: 0.60`
    *   `blend.playfully_provocative: 0.20`

---

**5. Engagement Preferences (Populates `engagement_preferences`)**

**Prompt:** "How deeply involved would you like your coach to be in your day-to-day tracking and planning?"

Select one overall style (reveals specific toggles if "Customise" is chosen, or sets defaults):
```
[Card-style options, single select]
□ "Data-Driven Partnership": (Sets defaults for detailed tracking, daily updates, proactive auto-recovery)
    (engagement_preferences.tracking_style: "data_driven_partnership")
□ "Balanced & Consistent": (Sets defaults for key metric tracking, weekly updates, proactive auto-recovery)
    (engagement_preferences.tracking_style: "balanced_consistent")
□ "Guidance on Demand": (Sets defaults for user-initiated tracking focus, updates when asked, user-decides recovery)
    (engagement_preferences.tracking_style: "guidance_on_demand")
□ "Customise My Preferences →" (Reveals individual toggles below)
```
**If "Customise" is selected (or for fine-tuning later in settings):**
*   **Information Depth:**
    *   `○ Detailed (e.g., macro tracking, in-depth analysis)` (engagement_preferences.information_depth: "detailed")
    *   `○ Key Metrics (e.g., calorie balance, core performance indicators)` (engagement_preferences.information_depth: "key_metrics")
    *   `○ Essential Only (e.g., workout completion, basic trends)` (engagement_preferences.information_depth: "essential_only")
*   **Proactivity & Updates:**
    *   `○ Daily Insights & Check-ins` (engagement_preferences.update_frequency: "daily")
    *   `○ Weekly Summaries & Reviews` (engagement_preferences.update_frequency: "weekly")
    *   `○ Primarily When I Ask` (engagement_preferences.update_frequency: "on_demand")
*   **Workout Adaptation (Recovery):**
    *   `[ ] Automatically suggest workout adjustments based on my recovery data` (engagement_preferences.auto_recovery_logic_preference: true/false)

---

**6. Sleep & Notification Boundaries (Populates `sleep_window` and `timezone`)**

**Prompt:** "To respect your downtime, please indicate your typical sleep schedule. Your coach will avoid sending notifications during these hours."
*(Pre-filled if consistent HealthKit sleep data is available and authorized.)*

```
Typical Bedtime:
[ 9 PM  —slider— 1 AM ]  (e.g., 10:30 PM) (sleep_window.bed_time: "22:30")

Typical Wake Time:
[ 5 AM  —slider— 9 AM ]  (e.g., 6:30 AM) (sleep_window.wake_time: "06:30")

My sleep rhythm is generally:
 ○ Consistent   ○ Different on Weekends   ○ Highly Variable
 (sleep_window.consistency: "consistent" / "week_split" / "variable")
```
*   **Timezone:** (Auto-detected by the app, with an option for user to manually set/confirm if needed, perhaps on this screen or a final review screen).
    *   `timezone: "America/Los_Angeles"` (Populated by the app, confirmed by user implicitly or explicitly)

---

**7. Motivational Accents (Populates `motivational_style`)**

**Prompt:** "A couple of final touches for how your coach acknowledges your efforts and checks in."

1.  **Celebrating Achievements (`celebration_style`):**
    *   `○ Subtle & Affirming` (e.g., "Solid progress.", "Noted.") (motivational_style.celebration_style: "subtle_affirming")
    *   `○ Enthusiastic & Encouraging` (e.g., "Fantastic work!", "That's a huge win!") (motivational_style.celebration_style: "enthusiastic_celebratory")

2.  **If You're Inactive for a Few Days (`absence_response`):**
    *   `○ A Gentle Nudge from Your Coach` (e.g., "Checking in – how are things?") (motivational_style.absence_response: "gentle_nudge")
    *   `○ Coach Respects Your Space` (Waits for you to re-engage unless critical) (motivational_style.absence_response: "respect_space")

---

**8. Crafting Your AirFit Coach**

```
[Elegant loading animation - abstract, clean, perhaps subtly incorporating the app's accent color]

Analyzing your unique preferences…
Defining your coach's core communication style…
Aligning with your daily rhythm and schedule…
Calibrating motivational approach…
Finalizing your personalized AirFit Coach profile…
```
*   *(Internally, the app is now constructing the complete `USER_PROFILE_JSON_BLOB` from all collected data.)*

---

**9. Your AirFit Coach Profile Is Ready**

**Prompt:** "Meet your personalized AirFit Coach. This profile, based on your choices, will guide every interaction. You can review and refine these settings at any time."

A single, scrollable screen summarizing the key aspects of the `USER_PROFILE_JSON_BLOB` in user-friendly language:

*   **Your Primary Aspiration:** "[`goal.raw_text` or a summary of `goal.family`]"
*   **Your Coach's Style:** "Expect a primarily [`dominant_blend_component_name`] approach, with elements of [`secondary_blend_component_name`]. Your coach will be [`key_trait_from_blend_1`] and [`key_trait_from_blend_2`]." (This is a dynamically generated sentence from the `blend` values).
*   **Engagement & Updates:** "Your coach will focus on [`engagement_preferences.information_depth`] and provide updates [`engagement_preferences.update_frequency_description`]. Workout adaptations will be [`auto_recovery_description`]."
*   **Communication Boundaries:** "Quiet hours are respected between [`sleep_window.bed_time`] - [`sleep_window.wake_time`] ([`timezone`]). If you're inactive, your coach will [`absence_response_description`]."
*   **Acknowledging Success:** "Achievements will be met with a [`celebration_style_description`]."

**Final Options:**
*   **`[✓] Establish my 14-day baseline before providing in-depth recommendations`** (Toggled ON by default. `user_profile.baseline_mode_enabled: true/false`)
    *   *(Small info icon: "This helps your coach learn your typical patterns for even smarter insights.")*

Buttons: `[Begin with My AirFit Coach →]` • `[Review & Refine Profile]`

---

This flow is now tightly coupled with the `SystemPrompt.md` v0.2, ensuring every piece of data collected has a clear purpose in defining the AI's persona and operational context. The language is also aimed at reinforcing the "bespoke" and "personalized" nature of their coach.
