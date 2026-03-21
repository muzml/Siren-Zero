# Siren-Zero Quick Start Guide

## First Time Setup (5 minutes)

### 1. Install the App
```bash
cd Siren-Zero
flutter pub get
flutter run
```

### 2. Download AI Models (One-time, ~580MB)

On first launch:
1. Tap the yellow **"SETUP"** button in the offline status banner
2. Download each model:
   - **Language Model (LLM)** - ~400MB
   - **Speech-to-Text (STT)** - ~80MB
   - **Text-to-Speech (TTS)** - ~100MB
3. Wait for downloads to complete (progress bar shows status)
4. Status banner will turn green: "100% OFFLINE READY"

> **Note**: Models are cached locally. You only need to download once!

---

## Using Siren-Zero

### Quick Emergency Actions (1 tap)

For immediate critical emergencies:
1. Tap one of the red emergency buttons:
   - **CPR** - Cardiac arrest, heart attack
   - **BLEEDING** - Severe bleeding, wounds
   - **CHOKING** - Airway obstruction
   - **BURN** - Thermal, chemical, electrical burns

2. Describe the emergency in text or voice
3. Follow step-by-step instructions

### Emergency Categories (Browse)

For specific emergency types:
1. Scroll to "EMERGENCY CATEGORIES"
2. Select category:
   - ❤️ **Cardiac Emergency** - CPR, heart attack
   - 🩸 **Bleeding & Trauma** - Severe bleeding, wounds
   - 🫁 **Airway & Breathing** - Choking, respiratory distress
   - 🌪️ **Natural Disaster** - Earthquake, flood, tornado
   - 🏔️ **Wilderness Survival** - Lost, exposure, shelter
   - ☠️ **Poisoning & Toxins** - Bites, ingestion
   - 🔥 **Burns & Heat** - Burns, heat stroke, hypothermia
   - 🦴 **Fractures & Injuries** - Broken bones, sprains
   - 🚨 **General Emergency** - First response, triage

3. Chat or voice interact with the AI

### Voice Assistant (Hands-Free)

Perfect when you can't use your hands:
1. Tap **"Voice Assistant"** in the Tools section
2. Tap the **blue microphone button** to start
3. Speak your emergency (e.g., "Person unconscious and not breathing")
4. AI will respond with voice instructions
5. Tap the **red stop button** when done

**Voice Features:**
- Automatic speech detection (no button holding)
- Hands-free continuous conversation
- Clear, spoken instructions
- Background audio level indicator

### Protocol Library (Step-by-Step)

For quick reference guides:
1. Tap **"Protocol Library"** in Tools
2. Browse protocols:
   - Adult CPR
   - Severe bleeding control
   - Choking (adults & infants)
   - Heart attack response
   - Earthquake safety
   - Allergic reaction/EpiPen
   - Burns treatment
   - Hypothermia

3. Tap any protocol to view detailed steps
4. Follow numbered instructions

---

## Example Scenarios

### Scenario 1: CPR Emergency

**Situation**: Person collapsed, not breathing

**Action**:
1. Tap **"CPR"** quick action button
2. Siren-Zero asks: "Is the person conscious? Are they breathing?"
3. You type: "No, unconscious and not breathing"
4. Siren-Zero provides:
   ```
   IMMEDIATE ACTION REQUIRED:
   
   1. Call 911 now or have someone else call
   2. Place heel of hand on center of chest
   3. Place other hand on top, interlock fingers
   4. Push hard and fast: 100-120 compressions per minute
   5. Push down 2 inches (5 cm) deep
   6. After 30 compressions, give 2 rescue breaths
   7. Continue until help arrives or person recovers
   ```

5. Ask follow-up: "How do I give rescue breaths?"
6. Get detailed instructions

### Scenario 2: Wilderness Emergency

**Situation**: Lost hiker, getting cold, no cell service

**Action**:
1. Select **"Wilderness Survival"** category
2. Ask: "How do I build an emergency shelter?"
3. Siren-Zero provides:
   ```
   Emergency Shelter Priority (Rule of 3s):
   You can survive 3 hours in harsh weather without shelter.
   
   Quick Shelter Options:
   
   1. Natural shelter (cave, rock overhang):
      - Check for animals first
      - Insulate ground with leaves/branches
      - Block wind opening with debris
   
   2. Debris hut:
      - Find fallen tree or large branch as ridgepole
      - Lean sticks against it at 45-degree angle
      - Cover with leaves, bark, grass (2-3 feet thick)
      - Stuff interior with dry leaves for insulation
   
   3. Snow cave (winter):
      - Dig into snowbank (4+ feet deep)
      - Create small entrance, larger chamber
      - Poke ventilation hole in roof
   ```

4. Ask: "What about staying warm overnight?"
5. Get hypothermia prevention guidance

### Scenario 3: Voice-Guided Emergency

**Situation**: Treating bleeding wound, hands occupied

**Action**:
1. Tap **"Voice Assistant"**
2. Tap blue microphone
3. Speak: "Severe bleeding from arm cut"
4. Siren-Zero speaks:
   ```
   [VOICE] Okay, listen carefully. First, is the bleeding 
   spurting or steady flow?
   ```

5. You: "Spurting blood"
6. Siren-Zero:
   ```
   [VOICE] That's arterial bleeding. This is critical. 
   Apply direct pressure immediately with a clean cloth. 
   Press firmly on the wound. Don't lift to check. 
   Keep pressure for at least 10 minutes...
   ```

7. Continue hands-free conversation

---

## Tips for Best Results

### For AI Chat
- **Be specific**: "Cut on forearm, bleeding heavily" vs "cut"
- **Describe context**: "In wilderness, 3 hours from hospital"
- **Ask follow-ups**: Don't hesitate to ask clarifying questions
- **Switch categories**: If needed, use category menu (top right)

### For Voice Assistant
- **Speak clearly**: Normal speaking voice, don't rush
- **Wait for response**: AI will process after you stop speaking
- **Quiet environment**: Background noise can affect transcription
- **Short phrases**: Break complex questions into parts

### For Protocol Library
- **Bookmark mentally**: Note which protocols you might need
- **Practice before emergency**: Familiarize yourself with steps
- **Read warnings**: Red warning boxes contain critical info

---

## Offline Usage

### ✅ Works Offline (after setup):
- All AI chat interactions
- Voice assistant
- Protocol library
- Emergency guidance
- Medical knowledge

### ❌ Requires Internet (one-time):
- Initial model downloads
- App updates

### Storage Requirements:
- App: ~50MB
- AI Models: ~580MB
- Total: ~630MB

---

## Troubleshooting

### "Models not downloading"
- **Check internet connection** (required for initial download)
- **Ensure 1GB+ free storage**
- **Try restarting app**

### "Voice not working"
- **Grant microphone permission** in device settings
- **Ensure STT and TTS models are downloaded**
- **Check for background noise**

### "AI responses are slow"
- **Normal**: First response takes 1-2 seconds
- **Low RAM devices**: Close other apps
- **Consider**: Smaller models may be slower on older devices

### "App crashes on model load"
- **Insufficient RAM**: Device may have <4GB RAM
- **Clear app cache** and reload
- **Close all background apps**

---

## Emergency Contacts

### Always Call Emergency Services First!

**If you have cell service or WiFi:**
- **US/Canada**: 911
- **UK**: 999
- **EU**: 112
- **Australia**: 000

**Use Siren-Zero when:**
- No cell service (wilderness, disaster)
- Waiting for ambulance (need immediate guidance)
- No nearby help available
- Communication blackout

---

## Advanced Tips

### Optimize for Speed
1. Pre-load all models before going off-grid
2. Keep app running in background (models stay loaded)
3. Test voice assistant before emergencies

### Customize for Your Needs
1. Add your own protocols to Protocol Library
2. Fine-tune system prompts for your region
3. Train on local medical guidelines

### Prepare for Disasters
1. Download models **before** the disaster
2. Keep phone charged (portable battery)
3. Familiarize yourself with key protocols
4. Share Siren-Zero with family/friends

---

## Getting Help

- **GitHub Issues**: [Report bugs](https://github.com/yourusername/siren-zero/issues)
- **Documentation**: See README.md for detailed info
- **Emergency Medical Training**: Take certified first aid courses

---

## Remember

Siren-Zero is a **backup tool** for when professional help isn't available.

**Always prioritize:**
1. ☎️ Calling emergency services
2. 🏥 Getting professional medical care
3. 🧠 Using your best judgment
4. 📚 Taking first aid training

**Siren-Zero provides guidance, not medical diagnosis or treatment.**

---

Stay safe, stay prepared. 🚨
