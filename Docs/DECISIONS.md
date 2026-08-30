# BROKEN STREETS — Product Decision Register

**Status:** canonical document; Git preserves revision history.
**Engine:** Unreal Engine 5.8.2
**Source:** the creator's 200 questionnaire answers
**Role:** source of truth for what is built, deferred, excluded, or provisionally defaulted when an exact value has not been chosen.

## Legend

- **CONFIRMED** — clearly stated by the creator.
- **PROVISIONAL** — direction is confirmed; exact value or form requires a prototype and creator approval.
- **PROPOSED — APPROVAL REQUIRED** — recommended design or architecture that is not a product decision until explicitly accepted.
- **DEFAULT** — reversible tuning used to advance a prototype; not a structural decision.
- **DEFERRED** — valid desire implemented only after its dependencies.
- **REJECTED** — evaluated alternative outside the active direction; reason and date remain in Git or a Decision Packet.
- **NON-SCOPE** — not part of the planned version.
- GTA V, Red Dead Redemption 2, Cyberpunk 2077, Schedule, and other references describe experience intent only. No code, assets, text, brands, UI, or implementation is copied.

---

## 1. Vision — decisions 1–8

1. **CONFIRMED:** priorities are financial ascent, a credible real-life-inspired economy, optional co-op, and a legal/illegal system that causes environmental reactions. Purchases, properties, and status create the aspirational life.
2. **CONFIRMED:** each character starts with no money, vehicle, or home.
3. **CONFIRMED:** there is no single endgame; each character builds a legal, illegal, or mixed story.
4. **CONFIRMED:** all important gameplay must be completable solo.
5. **CONFIRMED:** each activity starts solo and may optionally invite friends; co-op roles never become mandatory classes.
6. **CONFIRMED:** there is no mandatory main campaign. A tutorial exists, and optional NPC storylines may be added.
7. **CONFIRMED:** sessions have no fixed duration. Some economic goals may require several cumulative hours.
8. **CONFIRMED:** play continues indefinitely. Catalog, costs, and luxury tiers ensure another aspiration always exists.

## 2. Tone, audience, and limits — decisions 9–14

9. **CONFIRMED:** tone combines serious situations with humor and satire in the spirit of crime and life simulators, without copying.
10. **CONFIRMED:** 18+ audience.
11. **DEFAULT:** realism governs causes and consequences; fun governs dead time and repetition. Realistic detail that creates no interesting choice may be compressed.
12. **CONFIRMED:** dialogue, advertising, radio, and ambient reactions may use substantial humor.
13. **CONFIRMED:** brands, vehicles, shops, characters, text, and assets are original or fictional. Real elements are used only with clear rights.
14. **CONFIRMED:** extreme sexual-abuse themes and comparable topics identified by the creator are excluded. An explicit editorial policy precedes mature-content writing.

## 3. Platform and performance — decisions 15–24

15. **DEFAULT:** exact minimum hardware is not promised before benchmarks. A reference PC is selected after the crowded-street prototype; “like RDR2” is an accessibility direction, not a measurable specification.
16. **DEFAULT:** Minimum/Low targets stable 1080p/30 without Frame Generation. We attempt 60 FPS after benchmarking but do not promise it on unverified minimum hardware.
17. **PROVISIONAL:** Recommended targets stable 1080p/60; exact hardware freezes after the representative benchmark.
18. **CONFIRMED:** SSD and at least 16 GB RAM may be mandatory; development and host recommendation is 32 GB RAM.
19. **CONFIRMED:** Low may visibly reduce ambient crowds, cosmetic traffic, distance, and decoration, but never NPCs or objects that alter gameplay.
20. **CONFIRMED:** Low may reduce or disable Lumen, ray tracing, advanced shadows, and expensive reflections.
21. **CONFIRMED:** TSR, DLSS, FSR, XeSS, and Dynamic Resolution are allowed. Frame Generation is a bonus, never the minimum threshold.
22. **CONFIRMED:** the host may require more CPU and RAM because it simulates four areas.
23. **DEFAULT:** initial SSD targets are cold start below 60 seconds, campaign load below 30 seconds, and private-interior transition below 4 seconds typical or 8 seconds worst case.
24. **CONFIRMED/DEFAULT:** frame rate is the first compromise criterion, followed by gameplay correctness, density, visual distance, characters, and cosmetic lighting.

## 4. Manhattan and geography — decisions 25–35

25. **PROVISIONAL:** the final world is a large recognizable Manhattan with credible macro-geography and traversal rhythm, not a 1:1 reconstruction; greybox validates scale.
26. **CONFIRMED:** final scope is Manhattan island. Other boroughs are outside the current plan.
27. **CONFIRMED:** the first map is a simple urban TestGym; systems and performance are validated before city production.
28. **PROVISIONAL, inferred from answer 29:** ordinary-car traversal targets about 10–15 minutes without extreme traffic. Question 28 had no separate answer.
29. **PROVISIONAL:** full-map sprint targets about 60 minutes. Greybox and benchmarks determine first-district size.
30. **CONFIRMED:** grid and skyline may retain Manhattan logic, while buildings and landmarks are original reinterpretations.
31. **CONFIRMED:** streets, districts, companies, and points of interest use fictional names.
32. **CONFIRMED:** no sewer, subway, or aircraft in current scope. Verticality uses selected buildings, stairs, and rooftops.
33. **DEFAULT:** rooftops are accessible only for exploration or jobs; there is no complete citywide parkour network.
34. **NON-SCOPE:** no physical subway and no subway fast travel in the first version.
35. **CONFIRMED/DEFAULT:** water naturally bounds the island; diegetically blocked bridges and tunnels mark edges and may become expansion gates.

## 5. Interiors, time, and weather — decisions 36–44

36. **CONFIRMED:** exterior and important commercial spaces are continuous; private or heavy interiors may use masked transitions.
37. **CONFIRMED:** apartments and houses use masked loading and instances; priority shops and malls have no visible loading. Utility, not a percentage, decides building access.
38. **DEFAULT:** interior production order is shop, apartment, garage/dealer, warehouse, hospital, police, restaurant/bar, and office.
39. **CONFIRMED:** interiors are modular, then decorated and populated from data.
40. **CONFIRMED:** four players may simultaneously occupy four different districts or interiors.
41. **DEFAULT:** a full day initially lasts 120 real minutes and is fully data-driven.
42. **CONFIRMED:** rest is individual; global time skips only with agreement from all active players.
43. **CONFIRMED:** no seasons in the first phase.
44. **CONFIRMED/DEFAULT:** sun, clouds, rain, and storms; no snow. Weather may alter visibility, sound, grip, and ambient density without extreme meteorological simulation.

## 6. Population and NPCs — decisions 45–54

45. **PROVISIONAL aspiration:** visual density may approach Cyberpunk 2077 in capable areas and presets; target-hardware benchmarks alone determine final counts.
46. **CONFIRMED:** Low may reduce ambient population, never relevant entities.
47. **DEFAULT:** contacts, narrative NPCs, important merchants, selected employees, and relevant event participants have persistent identity. Random citizens do not.
48. **CONFIRMED:** only important NPCs have complete lives and data; others create a convincing illusion.
49. **CONFIRMED:** ambient city routines use simple routes and activities, not complete simulation for every citizen.
50. **CONFIRMED:** NPCs react to legal/illegal state and player actions. Permanent memory belongs only to important NPCs.
51. **DEFERRED/DEFAULT:** the full system may use face, outfit, voice, vehicle, license plate, and reputation. V1 prototypes only a temporary subset—outfit and vehicle—without forensics. Voice and plate are deferred, not rejected.
52. **CONFIRMED:** separate reputations for professions, police, each organized-crime family, areas, and social status.
53. **CONFIRMED:** selected NPCs have stories and relationships advanced through help; they do not become permanent companions.
54. **CONFIRMED:** short contextual dialogue with basic choices, including legal and illegal options.

## 7. Co-op and session — decisions 55–66

55. **CONFIRMED:** v1 supports at most four total players—the creator plus up to three friends (`1 host + 0–3 clients`). Architecture does not pay for higher counts now.
56. **CONFIRMED:** initially Steam-only.
57. **CONFIRMED:** private listen server on the host PC.
58. **CONFIRMED:** invites and connection without manual port forwarding.
59. **CONFIRMED:** join-in-progress, including during jobs.
60. **CONFIRMED/DEFAULT:** a character returns to the last valid position; when unsafe or foreign to the current world, it uses the nearest safe anchor.
61. **PROPOSED — APPROVAL REQUIRED:** no host migration in v1. Normal host exit saves and closes the session for everyone.
62. **PROPOSED — APPROVAL REQUIRED:** a disconnected player's place is initially reserved for 120 seconds. Host crash returns to the latest confirmed autosave.
63. **CONFIRMED:** no tether; players may separate across the entire map.
64. **CONFIRMED:** up to four job instances may run simultaneously.
65. **PROPOSED — APPROVAL REQUIRED:** solo may pause; multiplayer menus do not stop the world.
66. **PROPOSED — APPROVAL REQUIRED:** the party remains allied. Friendly fire is configurable; there is no competitive PvP or sabotage design, and direct theft from a teammate's inventory is prohibited.

## 8. Save and portable progress — decisions 67–75

67. **CONFIRMED:** the host owns the world, while primary progression belongs to the character and travels between friends' worlds.
68. **CONFIRMED:** money, items, and rewards earned in another player's world remain with the character.
69. **CONFIRMED with PROPOSED technical model:** appearance, clothing, money, equipment, VehicleRecord with trunk, PortablePropertyRecord with decor, storage, rent, and debt, progression, reputation, and criminal record are portable. Physical Actors are temporary materializations of records, never raw objects moved between worlds.
70. **CONFIRMED:** an absent character does not progress offline; needs, rent, debt, and businesses stop.
71. **CONFIRMED:** intentional local save editing is accepted in private co-op. The system prevents corruption and accidental duplication; it does not promise a globally secure economy.
72. **CONFIRMED intent with explicit technical limit:** during a live session, transactions use unique IDs, Pending/Committed/Aborted states, and idempotency. A lease can be unique only within the current session or device; two hosts cannot coordinate globally without a backend. ProfileEpoch, revision, and receipts detect cross-host conflicts and require reconciliation, never an automatic choice. Manual restore creates a new ProfileEpoch. Durable atomicity across files on different PCs cannot be guaranteed after crash or partition.
73. **CONFIRMED for multiple characters; PROPOSED — APPROVAL REQUIRED for UX:** each character has autosave and a manual safety save; critical states are not overwritten without backup.
74. **PROPOSED — APPROVAL REQUIRED:** at least five rotating generations with checksum, manifest, and guided restoration.
75. **PROVISIONAL:** rare resets may occur during Early Access. Schema, versioning, and migration exist from day one to reduce risk, not to promise zero resets.

## 9. Player, cameras, and input — decisions 76–87

76. **CONFIRMED:** switch between first- and third-person at any time, including driving and combat.
77. **DEFAULT:** both perspectives provide identical actions and results; differences are presentation and comfort only.
78. **DEFAULT:** first-person uses a full body when readable, plus dedicated arms or objects for interaction precision.
79. **DEFAULT:** third-person has configurable distance; aim uses over-shoulder framing and shoulder swap.
80. **DEFAULT:** sprint may intensify camera movement, but head bob, motion blur, camera shake, and sprint effects have sliders or Off; FOV is configurable.
81. **CONFIRMED:** mouse and keyboard ship first; input is abstracted from day one for later controller support.
82. **CONFIRMED:** complete remapping, separate sensitivities, hold/toggle, and slow walk; aim assist arrives with controller support.
83. **DEFAULT:** slow walk, walk, jog, and sprint; stamina is spent on sprint and exertion, not ordinary movement.
84. **CONFIRMED:** realistic vault and mantle over low and medium obstacles, plus marked climbing on selected high obstacles; no wall running or free climbing.
85. **CONFIRMED/DEFAULT:** normal and fire-escape stairs; no free climbing on pipes, cables, or ledges.
86. **CONFIRMED:** swimming yes; boats no.
87. **CONFIRMED:** crouch, prone, and manual cover; no automatic cover.

## 10. Character, clothing, and status — decisions 88–94

88. **CONFIRMED:** complete character creator.
89. **CONFIRMED:** one height and one base body/skeleton for everyone.
90. **CONFIRMED/DEFERRED:** face, hair, skin, eyes, tattoos, and scars arrive first; voice, walk, and posture variants are post-Early Access unless launch content requires them.
91. **DEFAULT:** base, top, outer layer, pants, footwear, head, and accessory slots; combinations are validated for clipping.
92. **CONFIRMED:** chains, watches, bracelets, rings, earrings, and piercings.
93. **CONFIRMED/DEFAULT:** clothes are inventory items; outfits are saved, and complete changing occurs at a wardrobe, vehicle, or through a timed action in a safe place.
94. **CONFIRMED:** clothes and jewelry alter social perception, access, and visual signature. Pockets and bags provide capacity; only armor provides protection.

## 11. Needs, health, and death — decisions 95–106

95. **CONFIRMED:** hunger, thirst, sleep, bladder/toilet, and hygiene. Health and injury are separate. No temperature or stress in v1.
96. **CONFIRMED:** needs advance only while the character is active in a session.
97. **DEFAULT:** hunger and thirst use four tiers, infrequent notifications, and progressive stamina/recovery penalties; they do not become constant micromanagement.
98. **DEFAULT:** fatigue gradually reduces stamina and clarity, and exhaustion may rarely cause microsleep; every visual effect can be reduced.
99. **CONFIRMED/DEFAULT:** hygiene affects appearance, social reactions, access, and possibly recovery or wound risk; low hygiene alone causes no direct damage.
100. **DEFAULT:** general health plus hit zones and tagged wounds; limbs do not each have an independent complete health bar.
101. **CONFIRMED/DEFAULT:** moderate bleeding, fracture, burn, and concussion; no full medical simulator.
102. **CONFIRMED:** injuries do not artificially disable walking, sprinting, aiming, or driving. They affect future damage, recovery, feedback, and incapacitation risk.
103. **CONFIRMED/DEFAULT:** first aid, medicine, and hospital. Ambulance and complex operations are deferred.
104. **CONFIRMED:** alcohol and drugs have real effects. Tolerance and addiction are moderate and data-driven; abuse is not glorified.
105. **CONFIRMED mechanic; PROPOSED values:** downed/revive, then hospital without intervention. A 60-second window and one revive per incident require playtesting.
106. **CONFIRMED result; PROPOSED percentages:** bank balance and stored possessions are safe. Hospitalization may cost carried cash and time; arrest confiscates dirty cash, contraband, and relevant illegal possessions.

## 12. Interaction, items, and ownership — decisions 107–118

107. **CONFIRMED:** instant pickup for small objects; heavy objects and cargo use generic actions, not unique animation per asset.
108. **CONFIRMED:** inventory is limited by slots and weight; duffle bags and containers increase capacity.
109. **DEFAULT:** ammunition, consumables, and common materials stack; weapons, clothing, jewelry, tools, and stateful objects remain individual instances.
110. **DEFAULT:** per-instance state only where meaningful: ammunition, simple wear, modifications, legal or illegal provenance, and ownership.
111. **CONFIRMED:** pockets, bags, trunks, closets, safes, and warehouses with credible capacities.
112. **CONFIRMED/DEFAULT:** freely dropped public-space objects disappear after a timeout, including abandoned owned property. Items persist only in inventory, vehicles, properties, valid storage/furniture, or while active mission objects.
113. **CONFIRMED:** items in inventory, vehicles, apartments, or safe storage persist.
114. **CONFIRMED/DEFAULT:** owner may separately grant View/Open, Take/Move, Use/Consume, Drive, Deposit, Modify, Sell, and TransferOwnership. Sale and ownership transfer require explicit confirmation.
115. **DEFAULT:** secure bilateral-confirmation trade; direct gifts are allowed but produce explicit transfer and transaction ID.
116. **DEFAULT:** teammates' inventory and locked storage cannot be stolen directly. Abandoned objects and shared containers follow container permissions.
117. **DEFAULT:** one contextual button performs the primary action; hold opens a radial only when several relevant actions exist.
118. **CONFIRMED/DEFAULT:** lockpick, search, repair, refuel, treatment, and cargo movement are timed actions interrupted by movement, damage, or lost access.

## 13. Economy, bank, rent, and debt — decisions 119–130

119. **CONFIRMED:** economy stops when the character or campaign is not running.
120. **CONFIRMED:** legal cash, bank balance, and dirty cash are three distinct balances.
121. **CONFIRMED/DEFAULT:** dirty cash must be laundered for large purchases; transfer preserves provenance. The prototype validates conversion and fee, while discovery risk connects only after Police v1. An initial 25% fee is strictly a test value.
122. **CONFIRMED loss type; PROPOSED value:** hospitalization may lose part of carried legal cash; arrest confiscates discovered dirty cash and contraband. Bank balance remains protected. An initial 25% is only for playtesting.
123. **CONFIRMED/DEFAULT:** phone provides balances, transfer, and payments; ATM provides cash deposit and withdrawal.
124. **CONFIRMED:** free transfers without artificial limit between friends. Dirty cash remains dirty and becomes risky only when discovered during search or arrest, never through police omniscience.
125. **CONFIRMED:** no shared team wallet or fund.
126. **CONFIRMED:** dollars and cents, stored internally as integer cents.
127. **DEFAULT:** wages, goods, and costs retain real-life-inspired ratios; progression time is compressed for gameplay.
128. **DEFAULT:** fixed data-driven prices in the first slice; rarity and stock may vary. Dynamic demand and inflation wait until the controlled economy is fun.
129. **CONFIRMED/DEFAULT:** cheapest functional vehicle in 30–60 minutes; decent car in about four hours; luxury and properties require much longer progression.
130. **CONFIRMED/DEFAULT:** rent and debt yes; no separate tax system. Optional autopay, notification, grace period, and penalty before eviction or repossession.

## 14. Shops, luxury, properties, and businesses — decisions 131–142

131. **CONFIRMED:** physical stores and delivery applications.
132. **DEFAULT:** stable catalog for common goods; limited stock and restock for rare goods. Stock belongs to the campaign or session, not a global online market.
133. **DEFAULT:** new and used dealers first. Private sale, auction, and illegal market arrive later.
134. **CONFIRMED:** vehicles are paid in full. Apartments may be purchased in full or rented. No auto loans, leasing, or mortgages in v1.
135. **CONFIRMED:** ordinary clothes do not simulate temperature or protection; armor has coverage and protection.
136. **CONFIRMED/DEFAULT:** jewelry grants status, may retain value, may be stolen, and may attract attention when worn.
137. **CONFIRMED:** instanced apartments with individual masked loading; friends may visit.
138. **CONFIRMED:** several homes per character; the same type or address may exist for several owners through distinct PropertyInstanceId and apartment number.
139. **CONFIRMED/DEFAULT:** free furniture placement with optional grid/snap, collision validation, and per-room limits.
140. **CONFIRMED:** possessions move physically by player, vehicle, or moving service; no free teleport between properties.
141. **CONFIRMED direction:** initial equipment means tools for illegal activities, differentiated by efficiency, noise, speed, capacity, and simple wear.
142. **DEFERRED/PROPOSED — APPROVAL REQUIRED:** businesses produce no passive income. They pay only while the character is physically present and performing the related activity or job. The full business system is post-Early Access unless approved for initial scope.

## 15. Jobs and events — decisions 143–152

143. **CONFIRMED:** hybrid jobs use handcrafted content and objectives with locations, routes, and encounters selected from approved sets.
144. **PROPOSED — APPROVAL REQUIRED:** first legal job is courier or parcel delivery.
145. **PROPOSED — APPROVAL REQUIRED:** first illegal activity is parcel theft or recovery from a restricted area.
146. **PROPOSED — APPROVAL REQUIRED:** phone and companies or NPCs offer jobs; level, money, licenses, and reputation may control eligibility after Progression v1.
147. **CONFIRMED:** tutorial uses the job framework, followed by a sandbox without mandatory story.
148. **CONFIRMED/DEFAULT:** spontaneous encounters vary route or objective; frequency is data-driven and cooldown-protected.
149. **CONFIRMED for solo; PROPOSED roles:** every job works solo; co-op may allow natural roles without class-gating actions.
150. **PROPOSED — APPROVAL REQUIRED:** data-driven scaling may add simultaneous objectives, time pressure, spawns, and moderate rewards; it never inflates enemy health artificially.
151. **PROPOSED — APPROVAL REQUIRED:** reserve a disconnected participant's place for 120 seconds and resume the same instance on reconnect. After timeout, free the role, reconcile mission items, and recalculate rewards without duplication.
152. **PROPOSED — APPROVAL REQUIRED:** contracts show individual payout before acceptance. Failure gives no full payout, while costs and consequences remain; repeatable jobs return in another variant, and the tutorial may checkpoint.

## 16. Crime, police, organized crime, and prison — decisions 153–166

153. **CONFIRMED:** heat, criminal record, and illegal rank are individual.
154. **NON-SCOPE:** no generic witness system remembering face, weapon, voice, and vehicle.
155. **NON-SCOPE:** no complete witness-report sequence.
156. **NON-SCOPE:** no general bribery, intimidation, or restraint of witnesses.
157. **NON-SCOPE:** no camera network or recording deletion. Crouch reduces visibility and noise; it does not grant invisibility.
158. **NON-SCOPE:** no fingerprints, DNA, or forensic identification. Only a simple temporary outfit or vehicle signature exists for the current pursuit.
159. **NON-SCOPE:** no persistent physical evidence in v1.
160. **PROPOSED — APPROVAL REQUIRED:** four original response tiers: Attention, Pursuit, Armed Response, and Manhunt. Validate the first two before Combat; armed tiers follow Combat v1. No helicopter in the first version is a proposed scope cut.
161. **CONFIRMED:** Police Director may spawn units outside view only at valid points and with credible arrival time.
162. **CONFIRMED:** escape by breaking contact, hiding, changing outfit or vehicle, and stopping heat-generating behavior.
163. **PROPOSED — APPROVAL REQUIRED:** complicity requires concrete help: getaway driving after a police order, attack or obstruction, knowing contraband transport, or job participation. Proximity alone is insufficient.
164. **CONFIRMED several families; PROPOSED model:** reputation is individual per character and family.
165. **NON-SCOPE:** no corrupt police, informants, bribes, purchased protection, or autonomous police–organized-crime wars in v1.
166. **CONFIRMED direction; PROPOSED implementation:** prison is short and deliberately unattractive gameplay in a co-op-compatible instance. A 3–12 minute range, reduction activities, no prison break, bail, visits, and disconnect behavior require approval after the prototype.

## 17. Combat and weapons — decisions 167–175

167. **CONFIRMED:** legal progression can avoid almost all combat; violent progression may encounter it frequently.
168. **CONFIRMED principle:** human lethality without bullet sponges. Caliber, location, armor, distance, and bleeding determine values, never level.
169. **PROPOSED — APPROVAL REQUIRED:** server-authoritative hybrid ballistics using trace or sweep, with travel time and drop where perceptible; no replicated Actor per bullet.
170. **DEFERRED in stages:** fists, one improvised weapon, and one pistol first; knife and shotgun next; SMGs and rifles after pipeline stabilization.
171. **CONFIRMED:** level and money control access; level never raises damage. Reputation and legal or illegal sources remain undecided.
172. **CONFIRMED/DEFAULT:** large weapons are visible or require a bag or vehicle; small weapons may be concealed. Relevant NPCs react when they observe them.
173. **CONFIRMED/DEFERRED:** recoil, magazines, chambered round, and detailed handling; jams, cleaning, and deep wear after Combat v1.
174. **CONFIRMED:** hit zones and location-based armor. Material penetration is data-driven; complex ricochet is deferred.
175. **CONFIRMED/DEFERRED:** final melee is complex but incremental: hit, block or dodge, then grappling and environmental actions.

## 18. Vehicles and traffic — decisions 176–185

176. **CONFIRMED:** accessible and credible arcade-realistic driving, not a hard simulator.
177. **CONFIRMED:** simple normal, damaged, smoke, fire, and destroyed states; no advanced deformation. Explosion only after severe damage.
178. **CONFIRMED:** automatic transmission; no manual transmission or complex assist menus.
179. **PROPOSED — APPROVAL REQUIRED:** during a session, a vehicle remains where left. After restart or recovery it appears deterministically in the garage; “near the player” is not used until explicitly selected.
180. **PROPOSED — APPROVAL REQUIRED:** digital key or access record, temporary friend permissions, lock/unlock, and timed tool-based hotwire. NPC vehicle theft is a separate job or mechanic.
181. **CONFIRMED/DEFAULT:** data-driven fuel consumption by vehicle and driving style; timed interruptible refueling. Fuel cans follow Fuel v1.
182. **CONFIRMED:** simple arcade maintenance, repair, towing, and recovery.
183. **CONFIRMED:** persistent engine, suspension, brake, tire, armor, paint, sound, and interior upgrades.
184. **CONFIRMED:** distant traffic is abstract and becomes a full physical Actor only near a player bubble.
185. **PROPOSED — APPROVAL REQUIRED:** traffic lights, serious collisions, dangerous driving, vehicle theft, and stops when relevant police exist; no simulation of every ticket and parking rule in the first version.

## 19. UI, audio, and accessibility — decisions 186–195

186. **CONFIRMED:** minimalist HUD, phone, and diegetic interfaces.
187. **PROPOSED — APPROVAL REQUIRED:** contextual configurable HUD; critical information appears when necessary.
188. **CONFIRMED/DEFAULT:** exact percentages in phone or laptop; compact indicators on the HUD.
189. **CONFIRMED:** configurable combination of minimap, large map, GPS, and world markers.
190. **CONFIRMED phone and laptop; PROPOSED split:** phone handles money, jobs, map, contacts, messages, and quick shopping; laptop handles properties, businesses, history, and deep operations.
191. **CONFIRMED:** friends appear on minimap and map; no permanent outline through walls.
192. **PROPOSED — APPROVAL REQUIRED:** party voice chat is an Early Access candidate; proximity and phone calls follow only after the foundation stabilizes. It is not yet a launch promise.
193. **CONFIRMED:** credible occlusion, interior/exterior response, and sonic identity without extremely expensive acoustic simulation.
194. **CONFIRMED desire; PROPOSED scope:** personal music from a local folder. Local-only is the safe candidate; retransmission to others is deferred until copyright, security, and bandwidth are solved.
195. **CONFIRMED:** English is the source language for the game and repository, and all text is localizable from day one. Additional languages and the exact accessibility options remain a content-lock decision based on scope and demand.

## 20. Production, Codex, and release — decisions 196–200

196. **CONFIRMED:** new C++ project built from scratch in UE 5.8.2. This replaces the initial 5.8.1 choice made before project creation.
197. **CONFIRMED workflow:** Codex writes and edits sources, tests, configuration, and documentation. The creator prefers to compile and run the Editor. Codex provides exact steps and analyzes logs; a task is not Done until creator build and test pass.
198. **CONFIRMED:** C++ owns gameplay, networking, persistence, economy, AI, and performance. Blueprint owns Animation Blueprint, UI layout, cinematics, visual configuration, and approved exceptions.
199. **PROPOSED — APPROVAL REQUIRED, production gate:** asset pipeline defines scale, pivot, naming, folders, material slots, collision, Nanite, LOD, HLOD, and automated validation. Exact DCC software is recorded before first bulk import. Source Art remains outside the game repository with 3-2-1 backup.
200. **CONFIRMED:** target release model is Early Access. **PROPOSED — APPROVAL REQUIRED:** the first sellable release contains one finished district, with full Manhattan expanded after launch. Quantities and commercial threshold are recalculated after the vertical slice.

---

## Resolved tensions

### Realistic economy versus fast progression

- The cheapest functional car may be purchased within 30–60 minutes.
- A decent car targets about four hours.
- Premium products and properties create tens or hundreds of hours of progression.
- Prices retain credible ratios while time is compressed.

### Portable character versus host-owned world

- Host saves only world truth and activities in that session.
- Player saves the portable character record.
- Portable properties and vehicles are rights or records, then materialize under control in the current world.
- Position, active pursuit, and active job may be session-specific; progression, criminal record, and reputation remain personal.
- Without a backend, synchronization between host and guest profile is best-effort: the protocol prevents most accidental duplication but cannot promise perfect atomicity after crash or network partition.

### Crime reaction without forensics

- Victim, guard, police officer, or explicit mission detector may create an Incident.
- Ambient civilians may flee or react but do not become a complete witness system.
- Police uses Active Heat and a simple temporary description.
- Criminal record and reputation replace persistent forensic investigation.

### Private apartment without moving the entire session

- Never use server travel for one player.
- Apartments are isolated instances inside the same authoritative World.
- Individual loading screens mask streaming and teleportation.
- Visitors enter the same PropertyInstanceId.

### Realism versus optimization

- Full realism runs only near a player and only when it changes a decision.
- Distant population and traffic use abstract representations. Businesses may have visual or statistical representation without income; payment occurs only through physical character activity.
- No cosmetic feature may compromise stability across four simultaneous bubbles.

---

## Tuning decisions that do not block the start

- exact minimum PC and VRAM;
- final durations for day, needs, downed, prison, and cooldowns;
- damage, recoil, armor, and penetration values;
- final first district and original landmarks;
- final catalog and prices;
- creator's DCC applications;
- additional languages and voice-over;
- proximity voice chat and shared personal music;
- host migration, cross-store, dedicated servers, and more than four players.

These values are decided at the milestone that can measure them. They do not justify delaying the C++ project, repository, TestGym, or risk prototypes.
