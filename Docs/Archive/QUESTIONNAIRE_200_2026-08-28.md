# Non-normative archive — initial questionnaire

> This document preserves the original research questions in English. Consolidated answers and their status exist only in `Docs/DECISIONS.md`. Never treat a question here as a decision and never ask the creator to repeat the questionnaire.

# BROKEN STREETS — Complete Design Questionnaire

**Version:** 1.0
**Total:** 200 questions
**Purpose:** convert the Broken Streets vision into a coherent design before system implementation.

## How to answer

- `[B]` means the answer may change architecture, performance, or implementation order.
- Answers may be sent in batches such as `1–25` or `26–50`.
- Include the question number and choice or explanation.
- If unknown, answer `I DON'T KNOW`; Codex will present options, tradeoffs, and a recommendation.
- Answer `DECIDE FOR ME` when the recommended solution should be chosen.
- Previous answers informed these questions; justification need not be repeated unless clarification is requested.

---

## 1. Central vision — questions 1–8

1. **[B]** Rank these promises: aspirational life, financial ascent, legal/illegal career, and shared co-op stories.
2. What is the starting situation: no money/home, modest apartment, cheap car, debt, or something else?
3. What is the endgame fantasy: wealthy collector, entrepreneur, criminal leader, respected legal citizen, or a mixture?
4. **[B]** Must the entire experience be completable solo, or may some activities require at least two players?
5. **[B]** Is co-op only shared play, or should every major activity contain specialized team roles and advantages?
6. Do you want a main campaign, separate storylines, or a systems-driven sandbox?
7. How long is a satisfying session: 30–60 minutes, 1–2 hours, 3–4 hours, or no target?
8. After maximum success, does play continue indefinitely, start New Game Plus, end, or remain open?

## 2. Tone, audience, and limits — questions 9–14

9. Is the tone harsh and serious, realistic with occasional humor, satirical, or activity-dependent?
10. What age rating and levels of graphic violence, drugs, alcohol, gambling, nudity, and language are intended?
11. When realism conflicts with fun, choose strict realism, simplified realism, or case-by-case fun?
12. How much humor should exist in dialogue, advertising, radio, events, and NPC reactions?
13. **[B]** Use fictional brands, stores, and vehicles only, or pursue real licenses where possible?
14. Which themes, activities, crimes, or mission types must never appear?

## 3. Platform, performance, and scalability — questions 15–24

15. **[B]** What is the weakest target PC: CPU, GPU, RAM, VRAM, and SSD/HDD? If unknown, may a reference PC be selected after the first benchmark?
16. **[B]** Is stable `1080p/30 FPS` acceptable on minimum hardware, or are 45 or 60 FPS required?
17. **[B]** Is Recommended `1080p/60`, `1440p/60`, `1440p/90`, or another target?
18. **[B]** May SSD and at least 16 GB RAM be mandatory?
19. **[B]** May Low visibly reduce pedestrians, traffic, draw distance, and cosmetic objects while preserving gameplay?
20. **[B]** May Low reduce or disable Lumen, ray tracing, advanced shadows, and expensive reflections?
21. Are TSR, DLSS, FSR, XeSS, and Dynamic Resolution allowed without requiring Frame Generation for minimum performance?
22. **[B]** May the host require more CPU and RAM because it simulates all four areas?
23. What are acceptable startup, campaign-load, and interior-entry times?
24. Rank compromise priorities: FPS, city density, realistic lighting, character quality, and view distance.

## 4. NYC, geography, and map size — questions 25–35

25. **[B]** Should Manhattan be recognizable but compressed, geographically close, or a fictional NYC assembled from recognizable areas?
26. **[B]** Final scope: Manhattan only, or Brooklyn, Queens, Bronx, and Staten Island too?
27. **[B]** What first area should be completed?
28. **[B]** How many minutes should ordinary-car traversal take without extreme traffic?
29. How many minutes should walking across the first complete district take?
30. How faithfully should the real street grid remain, and which landmarks must be recognizable?
31. Use real street and district names or fictional NYC-inspired names?
32. How much verticality: streets and buildings, rooftops, fire escapes, subway, tunnels, and sewer?
33. Should rooftops form a true exploration network or exist only in selected buildings and missions?
34. Is the subway physical, masked fast travel, or both?
35. How is the map bounded and later expanded: bridges, tunnels, ferries, subway, or updates to one World?

## 5. Interiors, time, weather, and world state — questions 36–44

36. **[B]** Must city and interiors be continuous, or may complex interiors use short transitions?
37. **[B]** Approximately what share of buildings is accessible at launch: 5%, 10%, 25%, most, or only gameplay-relevant locations?
38. Which interiors have priority: apartments, stores, restaurants, clubs, offices, warehouses, hospitals, police stations, or others?
39. Are intelligently recombined modular interiors acceptable, or must every important interior be unique?
40. **[B]** Can four players simultaneously occupy four completely different interiors or districts?
41. **[B]** How long is a complete in-game day: 48, 72, 96, 120 minutes, or another duration?
42. **[B]** Is sleep individual with global time skipping only when everyone sleeps or votes?
43. Are there seasons, and are they dynamic or fixed per campaign/area?
44. Which weather appears and affects gameplay: rain, storms, fog, heat, snow, ice, or local flooding?

## 6. Population, AI, and social simulation — questions 45–54

45. **[B]** Which game best represents desired population density: GTA V, Spider-Man, Cyberpunk 2077, or another?
46. **[B]** May low settings reduce visual crowd and traffic without removing witnesses, police, or gameplay-relevant NPCs?
47. **[B]** Which NPCs have permanent identity: contacts, neighbors, merchants, employees, important witnesses, random citizens?
48. **[B]** Does every citizen need a real home, job, money, and needs, or only important NPCs while others create an illusion?
49. How detailed are routines: simple route, home–work–store schedule, or complex varied life?
50. What do NPCs remember, and for how long: help, insult, theft, violence, debt, and reputation?
51. How may a player be recognized: face, clothing, voice, car, license plate, or reputation?
52. Is social reputation global or separated by district, profession, police, organized crime, and class?
53. Which NPC relationships exist: friendship, rivalry, romance, family, mentorship, and employment?
54. Preferred conversations: short contextual lines, choice dialogue, cinematics, or a mixture?

## 7. Private co-op and session — questions 55–66

55. **[B]** Is four players an absolute limit, or should architecture permit later expansion?
56. **[B]** Initially Steam-only, or cross-store PC invitations through a shared service?
57. **[B]** Confirm one player creates a session, their PC runs a listen server, and others join through private invitation?
58. **[B]** Must connection work without router configuration or manual port forwarding?
59. **[B]** May friends join after session start and during a job, or only in lobby or between activities?
60. Where does a joining friend appear: last location, home, near host, or nearest safe group point?
61. **[B]** For v1, may normal host exit save and close the session for everyone without host migration?
62. On host crash, how long is reconnection allowed and which valid autosave is restored?
63. **[B]** Is there no distance limit, allowing every player to remain in a different area?
64. **[B]** May four independent jobs run simultaneously, or is there one main campaign job plus individual side activities?
65. In multiplayer, is global pause unanimous, host-only, or absent?
66. **[B]** Are players always allies, or may the host configure friendly fire, theft, sabotage, or optional PvP?

## 8. Save, progression, and trust — questions 67–75

67. **[B]** Accept the recommended model: host campaign owns the world, with a separate economic and persistent record per friend?
68. **[B]** Are money and possessions exclusive to one campaign, or do they follow the player into others' campaigns?
69. **[B]** What travels between worlds: appearance, clothing, money, equipment, vehicles, properties, reputation, criminal record?
70. **[B]** When a campaign is not running, do time, needs, rent, taxes, interest, and businesses stop completely?
71. **[B]** In private co-op, is it acceptable that the campaign owner can technically edit local saves while the game prevents mistakes and accidental duplication?
72. **[B]** If a player disconnects during transfer, trade, or purchase, should the operation cancel completely and roll back?
73. Multiple campaign slots, manual saves plus autosave, or autosave checkpoints only?
74. Automatic safety copies and restoration to recent valid saves?
75. **[B]** During Early Access, promise all save compatibility or allow rare resets when safe migration is impossible?

## 9. Player, cameras, input, and movement — questions 76–87

76. **[B]** Can first- and third-person switch at any time, including vehicles and combat?
77. **[B]** Must both perspectives provide identical actions and gameplay advantages?
78. In first-person, show the full body or only hands and held objects?
79. Third-person camera: centered, over shoulder, or switchable left/right shoulder?
80. Which effects can be disabled: head bob, motion blur, camera shake, sprint blur, and FOV change?
81. **[B]** Must the first version fully support both mouse and keyboard and controller?
82. Which options are mandatory: full remapping, separate sensitivity, hold/toggle, slow walk, controller aim assist?
83. Which speeds exist and how important is stamina: slow walk, walk, jog, run, sprint?
84. **[B]** How much parkour: low obstacles, moderate urban climbing, or movement close to dedicated parkour games?
85. Can characters use fire escapes, pipes, ledges, and cables, or only prepared routes?
86. Are swimming, boats, and water travel required?
87. Crouch, prone, manual cover, automatic cover, or no complex cover?

## 10. Character creation, clothing, and status — questions 88–94

88. **[B]** Fully player-created character or customizable presets?
89. **[B]** Allow real height and body-shape variation despite clothing, animation, and collision cost?
90. What is customizable: face, hair, skin, eyes, tattoos, scars, voice, walk, and posture?
91. How many clothing layers may be worn: underwear, shirt, overshirt, jacket, pants, footwear, accessories?
92. Which jewelry slots: chains, watches, bracelets, rings, earrings, and piercings?
93. Saved outfits and quick changing only at wardrobe, anywhere from inventory, or at selected places?
94. Do clothes and jewelry affect only appearance, or also status, access, pockets, protection, and witness recognition?

## 11. Needs, health, injuries, and death — questions 95–106

95. **[B]** Confirm hunger, sleep, hygiene, and injury. Add thirst, temperature, toilet, stress, pain, disease, or addiction?
96. **[B]** Do needs advance only while the campaign and player are active, never from real offline time?
97. When does hunger appear, and do stages cause notification, stamina loss, slow recovery, weakness, or fainting?
98. What does sleep deprivation cause: slow reaction, reduced stamina, impaired vision, microsleep, or subtle effects?
99. What does hygiene affect: appearance, NPC reactions, location access, jobs, or health?
100. **[B]** Is health general or separated into head, torso, arm, and leg injuries?
101. Which injuries: bleeding, fracture, burn, concussion, infection, scar, and persistent pain?
102. Do injuries affect movement and actions: limp, poor aim, inability to sprint, lift, or drive?
103. Treatment methods: first aid, medicine, ambulance, hospital, surgery, and recovery over time?
104. Are alcohol, drugs, tolerance, withdrawal, and addiction real systems or narrative/economic elements?
105. **[B]** How does downed/revive work: duration, stabilizer, and number of revives before hospital?
106. **[B]** On death, keep account and stored goods but risk carried cash, contraband, abandoned items, time, and medical cost?

## 12. Interaction, items, inventory, and ownership — questions 107–118

107. **[B]** Does a small object enter inventory instantly, stay physically in hand, or vary by category?
108. **[B]** Is inventory limited by slots, weight, volume, a combination, or almost unlimited?
109. Which identical objects stack, and which categories remain individual instances?
110. What per-item state exists: quality, wear, dirt, ammunition, serial, provenance, and modifications?
111. Which containers exist: pockets, backpacks, trunks, closets, safes, and warehouses? Are capacities realistic?
112. **[B]** Do dropped objects remain forever or disappear under a clear rule when unimportant?
113. **[B]** Do purchased and found objects remain personal property in the campaign record?
114. **[B]** Which permissions may owners grant: use, move, consume, drive, deposit, modify, and sell?
115. Does player trade use a bilateral secure window, direct handoff, or both?
116. May players steal from one another, and can the host disable it?
117. Primary interaction: one contextual button, radial menu, or combination?
118. Which interruptible actions require time and animation: forcing doors, searching, repairing, refueling, treating, and moving objects?

## 13. Economy, bank, taxes, rent, and debt — questions 119–130

119. **[B]** Does economic time stop completely when the host campaign is not running?
120. **[B]** Use cash, bank balance, and dirty money as three forms, or cash and bank only?
121. **[B]** Must dirty money be laundered for large purchases, and what risk should laundering create?
122. What exactly happens to carried cash on death, hospital, and arrest: total loss, percentage, confiscation, or recovery?
123. Is the entire bank accessible by phone anywhere, or do some operations require ATM or branch?
124. Are friend transfers free and unlimited, or capped, charged, and capable of attracting attention?
125. Besides personal accounts, is there a voluntary shared team, business, or property fund?
126. Use exact dollars and cents or round most prices and income?
127. Follow approximate real NYC prices or compress the economy for satisfying progression?
128. Fixed prices or variations by district, demand, rarity, reputation, season, and events?
129. After how many hours should the first car, good apartment, and luxury item be earned?
130. **[B]** Define tax, debt, and rent rules: manual or automatic payment, grace period, penalties, eviction, and repossession.

## 14. Shopping, luxury, properties, and businesses — questions 131–142

131. **[B]** Shopping in physical stores, delivery apps, or both? Which categories must be bought physically?
132. Real depleting and restocking inventory, or permanent catalog with rarity controlled by price and access?
133. Vehicle channels: new dealer, used, auction, private person, illegal market? Which enter v1?
134. For vehicles and properties: full payment, financing, leasing, rent, and mortgage?
135. Do clothes affect temperature, pockets, protection, status, recognition, and access, or only some?
136. Is jewelry status, investment, theft target, loan collateral, and/or attention magnet?
137. **[B]** Are apartments physical spaces with real views or separate spaces loaded on entry?
138. May a player own or rent several homes, and may several players separately buy the same property?
139. How deep is customization: presets, free furniture, finishes, and structural modification?
140. Do possessions move instantly or physically by player, vehicle, or moving service?
141. Which equipment categories come first, and how do efficiency, noise, capacity, reliability, wear, and status differ?
142. **[B]** Are businesses actively managed, passive only while the campaign runs, or progressing between sessions?

## 15. Jobs, missions, and events — questions 143–152

143. **[B]** Are jobs mostly handcrafted, system-generated, or hybrid?
144. First legal-job fantasy: delivery, taxi, mechanic, construction, cleaning, security, warehouse, or other?
145. First illegal fantasy: theft, burglary, vehicle theft, contraband, robbery, fraud, organized-crime recovery, or other?
146. How are jobs found: phone, apps, physical companies, NPCs, contacts, and reputation?
147. Does a main story lock systems and areas, or only provide context, characters, and rewards?
148. Which spontaneous events and frequency: accidents, robberies, checks, urgent requests, rare opportunities, conflicts?
149. **[B]** Do co-op jobs provide driver, lookout, negotiator, and operator roles, or may everyone do anything?
150. **[B]** How does a job scale from one to four players: simultaneous objectives, time, difficulty, enemies, and rewards?
151. **[B]** What happens when a player joins, disconnects, or returns during a job?
152. **[B]** How are rewards split, and what follows failure: equal, contribution, negotiation, checkpoint, persistent consequences, or reduced payment?

## 16. Crime, witnesses, police, organized crime, and prison — questions 153–166

153. **[B]** Are wanted state, criminal record, and consequences strictly individual, or can some crimes compromise the entire team?
154. What must a witness know: act, face, clothing, voice, weapon, vehicle, and plate?
155. Is reporting instant, or must a witness use a phone, escape, or reach police?
156. Can a witness be persuaded, bribed, threatened, or restrained, and what added consequences follow?
157. Are security cameras visible, avoidable, disableable, and are recordings erasable or recoverable?
158. Identification by face, voice, clothes, fingerprints, DNA, weapon, and plate? What do masks and gloves hide?
159. **[B]** Which physical evidence enters v1 and persists after area unload?
160. **[B]** Police response tiers: check, stop, pursuit, roadblocks, armed units, helicopter, and later investigation?
161. **[B]** Must police always travel from existing units, or may they spawn under control outside view?
162. How do escape and surrender work: break contact, change outfit or car, hide, address evidence, volunteer surrender?
163. When does helping a wanted friend create complicity: proximity, driving, concrete action, or ignoring an order?
164. One criminal organization or several families? Is reputation individual, shared, or both?
165. Include corrupt police, informants, bribes, protection, and autonomous police–crime conflicts?
166. **[B]** Is prison complete gameplay, a limited-activity area, short sequence, or time skip? Can friends help legally or illegally?

## 17. Combat, weapons, and damage — questions 167–175

167. Can a legal career avoid almost all combat while a violent career encounters it frequently without changing base lethality?
168. **[B]** Define lethality: ordinary torso pistol hits tolerated by an unarmored person and headshot fatality frequency?
169. **[B]** Do bullets use velocity and drop, instant calculation at short range, or a hybrid?
170. Which initial weapons: fists, improvised weapons, knives, pistols, shotgun, SMG, and rifle?
171. How are weapons obtained and how rare: license, legal store, illegal market, theft, crafting, or reward?
172. Are weapons visible, concealed under clothes, or transported in bag or vehicle? What do civilians and police notice?
173. Handling depth: recoil, retained magazines, chambered round, jams, cleaning, and wear?
174. Location damage, real armor coverage, material penetration, and ricochet?
175. Melee depth: simple strikes, block/dodge, grappling, restraint, and environmental use?

## 18. Vehicles and traffic — questions 176–185

176. **[B]** Driving feel: arcade-realistic, accessible simulation, hard realism, or category-dependent?
177. **[B]** Is vehicle damage visual, mechanical, directional, or advanced physical deformation?
178. Automatic default with optional manual? Which ABS, traction, and stability assists may be disabled?
179. **[B]** Do personal cars remain exactly where parked with damage and fuel, or recover automatically to the garage?
180. How do keys, permissions, locking, forced entry, hotwire, and key theft work?
181. Does fuel vary by vehicle and driving style? Is refueling timed, interruptible, and compatible with fuel cans or help?
182. How deep are maintenance, failure, repair, insurance, towing, and destroyed-car recovery?
183. Which persistent upgrades: engine, suspension, brakes, tires, armor, paint, sound, interior?
184. **[B]** Is distant traffic simplified and promoted to full physical simulation near players?
185. Which road rules are enforced: speed, lights, cameras, parking, plates, stops, and confiscation?

## 19. UI, audio, voice chat, and accessibility — questions 186–195

186. **[B]** Minimal diegetic UI, phone-based UI, classic HUD, or combination?
187. Is HUD permanent, contextual, or fully configurable?
188. Do needs and state use exact percentages or natural labels such as hungry, tired, and injured?
189. Permanent minimap, large map, route GPS, world markers, or combination?
190. Is phone the main interface for jobs, bank, map, contacts, shopping, and messages?
191. How are friends shown: through-wall outline, marker, map, contextual ping, or no supernatural aid?
192. **[B]** Integrated voice chat: party channel, proximity, in-game phone, or combination?
193. Audio realism: wall occlusion, interior reverb, realistic distance, and district identity?
194. Music sources: ambience, vehicle and location radio, original tracks, and/or licensed music?
195. **[B]** Which launch languages and accessibility options: subtitles, speaker labels, large text, color-blind support, sound indicators, and reduced camera motion?

## 20. Production, assets, Codex, and release — questions 196–200

196. **[B]** Does the Unreal project already exist, where is it, what works, and are Visual Studio, SDKs, and the UE toolchain installed?
197. **[B]** May Codex directly edit the project, build, and run tests while the creator handles decisions, assets, and exactly explained visual Editor steps?
198. **[B]** Confirm C++ for gameplay, networking, save, economy, AI, and performance; Blueprint for animation, UI, cinematics, asset configuration, and approved exceptions?
199. **[B]** Which DCC applications are used, and is a mandatory scale, pivot, naming, folder, material, collision, Nanite/LOD/HLOD pipeline accepted with Source Art outside the game repository?
200. **[B]** Is the target Early Access or full release, and what minimum area, jobs, vehicles, properties, content hours, and stability justify charging money?

---

## Recommended answer order

- First answer every `[B]` question from 1–75 to define architecture and infrastructure.
- Then 76–142 for player, life, and economy.
- Then 143–185 for jobs, crime, combat, and vehicles.
- Finally 186–200 for presentation and production.

After each batch, Codex will:

- summarize decisions without misinterpretation;
- identify contradictions and tradeoffs;
- recommend answers for `I DON'T KNOW`;
- update the roadmap and system documents;
- separate v1 commitments from deferred work.
