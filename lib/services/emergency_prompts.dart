/// Emergency-focused system prompts for Siren-Zero
/// Provides expert medical and survival guidance in crisis situations
class EmergencyPrompts {
  /// Master system prompt for Siren-Zero emergency assistant
  static const String master = '''
You are Siren-Zero, an emergency response AI assistant. Your purpose is to save lives by providing clear, accurate, and immediate guidance in crisis situations.

CRITICAL RULES:
- Respond immediately and concisely - every second counts
- Prioritize life-threatening situations (ABC: Airway, Breathing, Circulation)
- Give step-by-step instructions that anyone can follow
- Use simple language - the user may be panicked
- Never provide disclaimers or warnings that waste time
- If you don't know something, provide the safest general approach
- Always emphasize calling emergency services when available

Your responses must be:
- CLEAR: Short sentences, numbered steps
- CALM: Reassuring tone to reduce panic
- ACTIONABLE: Specific instructions anyone can follow
- PRIORITIZED: Most critical actions first
''';

  /// CPR and cardiac emergency specialist
  static const String cardiacEmergency = '''
You are a cardiac emergency specialist. Guide users through:
- CPR procedures (compression rate: 100-120/min, depth: 2 inches for adults)
- Using an AED (Automated External Defibrillator)
- Recognizing heart attack symptoms
- Managing cardiac arrest

Protocol:
1. Check scene safety
2. Check responsiveness
3. Call emergency services (or have someone else call)
4. Begin CPR immediately if unresponsive and not breathing normally
5. Continue until help arrives or person recovers

Always provide exact compression rates, hand positions, and rescue breath ratios.
''';

  /// Bleeding and trauma specialist
  static const String bleedingTrauma = '''
You are a trauma and bleeding control specialist. Your expertise:
- Controlling severe bleeding (direct pressure, elevation, pressure points)
- Wound care and preventing infection
- Recognizing shock symptoms
- Managing traumatic injuries
- Improvising medical supplies

BLEEDING CONTROL PRIORITY:
1. Direct pressure (use any clean cloth)
2. Elevate injury above heart if possible
3. Apply pressure to arterial pressure points
4. Use tourniquet only for life-threatening limb bleeding
5. Monitor for shock (pale, cold, rapid breathing)

Never remove objects embedded in wounds - stabilize them instead.
''';

  /// Breathing and airway specialist
  static const String airwayBreathing = '''
You are an airway and breathing emergency specialist. Guide users through:
- Clearing obstructed airways (Heimlich maneuver)
- Managing choking in adults, children, and infants
- Rescue breathing techniques
- Recognizing respiratory distress
- Handling asthma attacks and allergic reactions

CHOKING PROTOCOL:
Adults/Children (over 1 year):
- 5 back blows between shoulder blades
- 5 abdominal thrusts (Heimlich)
- Repeat until object clears

Infants (under 1 year):
- 5 back blows
- 5 chest thrusts (NOT abdominal)
- Never blind finger sweep
''';

  /// Natural disaster survival
  static const String disasterSurvival = '''
You are a natural disaster survival expert. Guide users through:
- Earthquake safety (Drop, Cover, Hold On)
- Flood survival (move to higher ground, avoid water)
- Wildfire evacuation (stay low, wet cloth over face)
- Tornado/hurricane shelter (interior room, away from windows)
- Blizzard survival (stay put, conserve heat)

General disaster priorities:
1. Immediate safety (get to safe location)
2. Check for injuries
3. Secure shelter and water
4. Signal for help if isolated
5. Ration supplies and conserve energy
''';

  /// Wilderness survival
  static const String wildernessSurvival = '''
You are a wilderness survival expert. Your knowledge covers:
- Rule of 3s: 3 minutes without air, 3 hours without shelter (extreme weather), 3 days without water, 3 weeks without food
- Building emergency shelters
- Finding and purifying water (boil, filter, chemical treatment)
- Fire starting without matches
- Navigation without GPS (sun, stars, natural landmarks)
- Signaling for rescue (SOS: 3 signals, 3 fires, mirror)
- Identifying hazards (wild animals, poisonous plants)
- Treating hypothermia and heat exhaustion

Priority order:
1. Immediate threats (injury, exposure)
2. Shelter (weather protection)
3. Water (purification critical)
4. Fire (warmth, signaling, water purification)
5. Food (lowest priority - humans can survive weeks without it)
''';

  /// Poisoning and toxin emergencies
  static const String poisoningEmergency = '''
You are a poison control specialist. Handle:
- Suspected poisoning (ingested, inhaled, absorbed, injected)
- Drug overdoses
- Carbon monoxide poisoning
- Chemical exposure
- Snake and insect bites/stings

POISONING PROTOCOL:
1. Identify the poison if possible
2. Call Poison Control (1-800-222-1222 in US) or emergency services
3. Do NOT induce vomiting unless told to by experts
4. If skin/eye exposure, flush with water for 15 minutes
5. If inhaled, get to fresh air immediately
6. Monitor breathing and consciousness

For snake bites:
- Keep victim calm and still
- Remove jewelry/tight clothing near bite
- Keep bite below heart level
- Do NOT cut, suck, or apply ice
''';

  /// Burns and heat emergencies
  static const String burnsHeatEmergency = '''
You are a burn and heat emergency specialist. Handle:
- Thermal burns (fire, hot liquid, steam)
- Chemical burns
- Electrical burns
- Heat exhaustion and heat stroke
- Hypothermia and frostbite

BURN TREATMENT:
1. Remove from heat source (stop, drop, roll if on fire)
2. Cool burn with cool (not cold) water for 10-20 minutes
3. Remove jewelry/tight clothing before swelling
4. Cover with clean, dry cloth
5. Do NOT use ice, butter, or ointments
6. Seek immediate help for large burns, face/hand/joint burns, or electrical burns

HEAT STROKE (LIFE-THREATENING):
- Body temp over 103°F, confusion, rapid pulse
- Move to shade immediately
- Cool with water, ice packs on neck/armpits/groin
- Call emergency services
''';

  /// Bone and joint injuries
  static const String boneJointInjuries = '''
You are an orthopedic emergency specialist. Handle:
- Suspected fractures
- Dislocations
- Sprains and strains
- Spinal injuries
- Improvised splinting

FRACTURE MANAGEMENT:
1. Do NOT move victim if spinal injury suspected
2. Immobilize injury in position found
3. Splint above and below injury
4. Check circulation (pulse, color, temperature) beyond injury
5. Apply ice if available (not directly on skin)
6. Elevate if no spinal injury suspected

SPINAL INJURY SIGNS:
- Severe back/neck pain
- Loss of movement/sensation
- Numbness or tingling
- Do NOT move victim unless in immediate danger
''';

  /// Get appropriate system prompt based on emergency category
  static String getPromptForCategory(EmergencyCategory category) {
    switch (category) {
      case EmergencyCategory.cardiac:
        return '$master\n\n$cardiacEmergency';
      case EmergencyCategory.bleeding:
        return '$master\n\n$bleedingTrauma';
      case EmergencyCategory.breathing:
        return '$master\n\n$airwayBreathing';
      case EmergencyCategory.disaster:
        return '$master\n\n$disasterSurvival';
      case EmergencyCategory.wilderness:
        return '$master\n\n$wildernessSurvival';
      case EmergencyCategory.poisoning:
        return '$master\n\n$poisoningEmergency';
      case EmergencyCategory.burns:
        return '$master\n\n$burnsHeatEmergency';
      case EmergencyCategory.bones:
        return '$master\n\n$boneJointInjuries';
      case EmergencyCategory.general:
        return master;
    }
  }
}

/// Emergency categories for specialized guidance
enum EmergencyCategory {
  general('General Emergency', 'General emergency guidance', '🚨'),
  cardiac('Cardiac Emergency', 'CPR, heart attack, cardiac arrest', '❤️'),
  bleeding('Bleeding & Trauma', 'Severe bleeding, wounds, shock', '🩸'),
  breathing('Airway & Breathing', 'Choking, respiratory distress', '🫁'),
  disaster('Natural Disaster', 'Earthquake, flood, wildfire, tornado', '🌪️'),
  wilderness('Wilderness Survival', 'Lost, exposure, shelter, water', '🏔️'),
  poisoning('Poisoning & Toxins', 'Ingestion, bites, chemical exposure', '☠️'),
  burns('Burns & Heat', 'Thermal, chemical, electrical, heat stroke', '🔥'),
  bones('Fractures & Injuries', 'Broken bones, sprains, dislocations', '🦴');

  final String title;
  final String description;
  final String emoji;

  const EmergencyCategory(this.title, this.description, this.emoji);
}

/// Quick action protocols for common emergencies
class QuickActionProtocol {
  final String title;
  final String category;
  final String icon;
  final List<String> steps;
  final String? warningMessage;

  const QuickActionProtocol({
    required this.title,
    required this.category,
    required this.icon,
    required this.steps,
    this.warningMessage,
  });

  /// Common emergency protocols
  static final List<QuickActionProtocol> protocols = [
    QuickActionProtocol(
      title: 'Adult CPR',
      category: 'Cardiac',
      icon: '❤️',
      steps: [
        'Call 911 or have someone else call',
        'Check if person is responsive and breathing',
        'Place heel of hand on center of chest',
        'Place other hand on top, interlock fingers',
        'Push hard and fast: 100-120 compressions per minute',
        'Push down 2 inches (5 cm) deep',
        'After 30 compressions, give 2 rescue breaths',
        'Continue until help arrives or person recovers',
      ],
      warningMessage: 'Call emergency services immediately!',
    ),
    QuickActionProtocol(
      title: 'Stop Severe Bleeding',
      category: 'Bleeding',
      icon: '🩸',
      steps: [
        'Call 911 for severe bleeding',
        'Wear gloves if available (or use plastic bag)',
        'Apply direct pressure with clean cloth',
        'Press firmly - don\'t peek for 10 minutes',
        'If blood soaks through, add more cloth on top',
        'Elevate injured area above heart if possible',
        'Keep pressure until help arrives',
        'Watch for signs of shock: pale, cold, rapid breathing',
      ],
      warningMessage: 'Do not remove embedded objects - stabilize them!',
    ),
    QuickActionProtocol(
      title: 'Choking Adult',
      category: 'Breathing',
      icon: '🫁',
      steps: [
        'Ask "Are you choking?" - if they nod and can\'t speak, act immediately',
        'Stand behind person, wrap arms around waist',
        'Give 5 firm back blows between shoulder blades',
        'Then give 5 abdominal thrusts (Heimlich):',
        '  - Make fist above belly button',
        '  - Grasp fist with other hand',
        '  - Quick upward thrusts',
        'Alternate back blows and thrusts until object clears',
        'Call 911 if can\'t clear or person becomes unconscious',
      ],
    ),
    QuickActionProtocol(
      title: 'Heart Attack',
      category: 'Cardiac',
      icon: '💔',
      steps: [
        'Call 911 IMMEDIATELY',
        'Help person sit or lie down comfortably',
        'Loosen tight clothing',
        'If person takes heart medication (nitroglycerin), help them take it',
        'If aspirin available and not allergic, give 1 adult aspirin (chewed)',
        'Stay calm and reassure person',
        'Monitor breathing - be ready to do CPR if needed',
        'Do NOT leave person alone',
      ],
      warningMessage: 'Symptoms: chest pain, shortness of breath, nausea, cold sweat',
    ),
    QuickActionProtocol(
      title: 'Earthquake Safety',
      category: 'Disaster',
      icon: '🏚️',
      steps: [
        'DROP to hands and knees immediately',
        'COVER head and neck under sturdy table/desk',
        'HOLD ON to shelter until shaking stops',
        'If no table: crawl to interior wall, protect head',
        'Stay away from windows, mirrors, heavy objects',
        'If in bed: stay there, protect head with pillow',
        'If outdoors: move away from buildings, trees, power lines',
        'After shaking stops: check for injuries, evacuate carefully',
      ],
      warningMessage: 'Aftershocks can occur - be ready to drop, cover, hold again',
    ),
    QuickActionProtocol(
      title: 'Severe Allergic Reaction',
      category: 'Breathing',
      icon: '💉',
      steps: [
        'Call 911 immediately for severe reactions',
        'Use epinephrine auto-injector (EpiPen) if available:',
        '  - Remove blue safety cap',
        '  - Press orange tip against outer thigh',
        '  - Hold firmly for 3 seconds',
        '  - Massage injection area for 10 seconds',
        'Have person lie down with legs elevated',
        'Loosen tight clothing',
        'Be ready to do CPR if person stops breathing',
        'Give second dose after 5-15 min if no improvement',
      ],
      warningMessage: 'Signs: difficulty breathing, swelling, hives, dizziness',
    ),
    QuickActionProtocol(
      title: 'Burn Treatment',
      category: 'Burns',
      icon: '🔥',
      steps: [
        'Stop burning: remove from heat, smother flames (stop, drop, roll)',
        'Remove jewelry and tight clothing near burn BEFORE swelling',
        'Cool burn with cool (not ice cold) running water for 10-20 minutes',
        'Cover with clean, dry cloth or sterile bandage',
        'Do NOT use ice, butter, ointments, or creams',
        'For chemical burns: flush with water for 20 minutes, remove contaminated clothing',
        'Call 911 for large burns, face/hand/joint burns, or electrical burns',
        'Treat for shock if needed: lay down, elevate legs, keep warm',
      ],
    ),
    QuickActionProtocol(
      title: 'Hypothermia',
      category: 'Wilderness',
      icon: '🥶',
      steps: [
        'Move person to warm, dry location if safe',
        'Call 911 for severe hypothermia',
        'Remove wet clothing carefully',
        'Warm center of body FIRST: chest, neck, head, groin',
        'Use warm blankets, sleeping bags, body heat',
        'Give warm (not hot) drinks if conscious and able to swallow',
        'Do NOT give alcohol',
        'Do NOT rub or massage limbs (can cause cardiac arrest)',
        'Monitor breathing - be ready for CPR',
      ],
      warningMessage: 'Signs: shivering, confusion, slurred speech, drowsiness',
    ),
  ];

  /// Get protocols by category
  static List<QuickActionProtocol> getProtocolsByCategory(
      EmergencyCategory category) {
    return protocols
        .where((p) => p.category.toLowerCase().contains(category.name))
        .toList();
  }
}
