# BROKEN STREETS — Registrul deciziilor de produs

**Status:** document canonic; Git păstrează istoricul versiunilor.
**Motor:** Unreal Engine 5.8.2
**Sursă:** cele 200 de răspunsuri oferite de creator
**Rol:** sursa de adevăr pentru ce construim, ce amânăm și ce regulă provizorie folosim când un răspuns nu a fixat o valoare exactă.

## Legendă

- **CONFIRMAT** — decizie exprimată clar de creator.
- **PROVIZORIU** — direcția este confirmată, dar valoarea sau forma exactă trebuie validată prin prototip și aprobată de creator.
- **PROPUS — NECESITĂ APROBARE** — soluție de design sau arhitectură recomandată de roadmap, dar care nu devine decizie de produs până nu este acceptată explicit.
- **DEFAULT** — valoare de tuning reversibilă folosită pentru a permite prototipului să avanseze; nu fixează o decizie structurală.
- **DEFERRED** — dorință validă, dar implementată numai după fundațiile de care depinde.
- **RESPINS** — alternativa a fost evaluată și nu face parte din direcția activă; motivul și data rămân în Git/Decision Packet.
- **NON-SCOPE** — nu intră în versiunea planificată.
- O referință precum GTA V, Red Dead Redemption 2, Cyberpunk 2077 sau Schedule este folosită numai pentru intenția de experiență. Nu se copiază cod, asset-uri, texte, mărci, UI sau implementări.

---

## 1. Viziune — deciziile 1–8

1. **CONFIRMAT:** prioritățile sunt ascensiunea financiară, o economie credibilă inspirată din viața reală, co-op-ul opțional și sistemul legal/ilegal la care mediul reacționează. Viața aspirațională este rezultatul cumpărăturilor, proprietăților și statutului.
2. **CONFIRMAT:** fiecare personaj începe fără bani, mașină și locuință.
3. **CONFIRMAT:** nu există un endgame unic; fiecare personaj își construiește propria poveste legală, ilegală sau mixtă.
4. **CONFIRMAT:** tot jocul important trebuie să poată fi parcurs solo.
5. **CONFIRMAT:** fiecare activitate poate fi pornită solo, iar prietenii pot fi invitați opțional; rolurile co-op nu devin clase obligatorii.
6. **CONFIRMAT:** nu există campanie principală obligatorie. Există tutorial; fire narative opționale pot fi adăugate prin NPC-uri.
7. **CONFIRMAT:** nu există o durată fixă pentru sesiune. Unele obiective economice pot necesita mai multe ore cumulate.
8. **CONFIRMAT:** jocul continuă nelimitat. Catalogul, costurile și treptele de lux sunt proiectate astfel încât jucătorul să aibă mereu o aspirație nouă.

## 2. Ton, public și limite — deciziile 9–14

9. **CONFIRMAT:** tonul combină situații serioase cu umor și satiră în spiritul jocurilor de crimă/life-sim, fără copiere.
10. **CONFIRMAT:** public 18+.
11. **DEFAULT:** realismul domină cauzele și consecințele; distracția domină timpii morți și operațiile repetitive. Orice detaliu realist care nu produce o alegere interesantă poate fi comprimat.
12. **CONFIRMAT:** dialogurile, reclamele, radioul și reacțiile ambientale pot folosi mult umor.
13. **CONFIRMAT:** mărci, vehicule, magazine, personaje, texte și asset-uri originale sau fictive. Un element real este folosit numai dacă drepturile sunt clare.
14. **CONFIRMAT:** sunt excluse temele de abuz sexual extrem și alte subiecte comparabile menționate de creator. Înaintea scrierii conținutului matur se creează o politică editorială explicită.

## 3. Platformă și performanță — deciziile 15–24

15. **DEFAULT:** configurația minimă exactă nu se promite înainte de benchmark. Se alege un PC-etalon după prototipul de stradă aglomerată; expresia „ca RDR2” este o direcție de accesibilitate hardware, nu o specificație măsurabilă.
16. **DEFAULT:** profilul Minimum/Low urmărește 1080p la 30 FPS stabil, fără Frame Generation. După benchmark încercăm 60 FPS, dar nu îl promitem pe hardware minim neverificat.
17. **PROVIZORIU:** ținta pentru configurația recomandată este 1080p la 60 FPS stabil; hardware-ul exact se fixează după benchmark-ul reprezentativ.
18. **CONFIRMAT:** SSD și minimum 16 GB RAM pot fi cerințe obligatorii; recomandarea de dezvoltare și host va fi 32 GB RAM.
19. **CONFIRMAT:** Low poate reduce vizibil mulțimea, traficul cosmetic, distanța și decorul, dar nu elimină NPC-uri sau obiecte care schimbă gameplay-ul.
20. **CONFIRMAT:** Low poate reduce ori dezactiva Lumen, ray tracing, umbre avansate și reflexii costisitoare.
21. **CONFIRMAT:** TSR, DLSS, FSR, XeSS și Dynamic Resolution sunt permise. Frame Generation este bonus, nu baza pragului minim.
22. **CONFIRMAT:** host-ul poate avea cerințe CPU/RAM mai ridicate deoarece simulează patru zone.
23. **DEFAULT:** ținte inițiale pe SSD minim: pornire rece sub 60 secunde, încărcarea campaniei sub 30 secunde, tranziția într-un interior sub 4 secunde tipic și sub 8 secunde în cel mai slab caz.
24. **CONFIRMAT/DEFAULT:** FPS este primul criteriu de compromis. După el păstrăm corectitudinea gameplay-ului, apoi densitatea, distanța vizuală, personajele și iluminarea cosmetică.

## 4. Manhattan și geografie — deciziile 25–35

25. **PROVIZORIU:** forma finală urmărește un Manhattan recognoscibil și mare, cu macro-geografie și ritm de traversare credibile, nu o reconstrucție 1:1 a fiecărei clădiri; scara exactă se validează prin greybox.
26. **CONFIRMAT:** scope-ul final este insula Manhattan. Celelalte boroughs nu intră în planul actual.
27. **CONFIRMAT:** prima hartă este un TestGym urban simplu; sistemele și performanța sunt validate înaintea producției orașului.
28. **PROVIZORIU, dedus din răspunsul 29:** traversarea finală cu o mașină obișnuită urmărește aproximativ 10–15 minute fără trafic extrem. Întrebarea 28 nu a primit un răspuns separat.
29. **PROVIZORIU:** întreaga hartă urmărește aproximativ 60 de minute de sprint. Dimensiunea primului district se stabilește prin greybox și benchmark, nu printr-o durată presupusă.
30. **CONFIRMAT:** gridul și silueta urbană pot păstra logica Manhattan-ului, dar clădirile și landmark-urile sunt reinterpretate original.
31. **CONFIRMAT:** străzile, cartierele, firmele și punctele de interes folosesc nume fictive.
32. **CONFIRMAT:** fără canalizare, metrou și avioane în scope-ul actual. Verticalitatea folosește clădiri, scări și acoperișuri selectate.
33. **DEFAULT:** acoperișurile sunt accesibile numai unde servesc explorării sau unui job; nu există o rețea completă de parkour pe toate clădirile.
34. **NON-SCOPE:** nici metrou fizic, nici fast travel prin metrou în prima versiune.
35. **CONFIRMAT/DEFAULT:** apa limitează natural insula; podurile și tunelurile blocate diegetic marchează marginea și pot deveni porți de extindere.

## 5. Interioare, timp și vreme — deciziile 36–44

36. **CONFIRMAT:** exteriorul și spațiile comerciale importante sunt continue; interioarele private sau grele pot folosi o tranziție mascată.
37. **CONFIRMAT:** apartamentele/casele folosesc loading mascat și instanțe; magazinele și mall-urile prioritare sunt fără loading vizibil. Accesibilitatea clădirilor este decisă prin utilitate, nu prin procent.
38. **DEFAULT:** ordinea interioarelor este magazin, apartament, garaj/dealer, depozit, spital, poliție, restaurant/bar și birou.
39. **CONFIRMAT:** interioarele sunt construite modular, apoi decorate și populate prin date.
40. **CONFIRMAT:** patru jucători pot sta simultan în patru cartiere sau interioare diferite.
41. **DEFAULT:** o zi completă durează inițial 120 de minute reale și este complet data-driven.
42. **CONFIRMAT:** odihna este individuală; saltul orei globale apare numai după acordul tuturor jucătorilor activi.
43. **CONFIRMAT:** fără anotimpuri în prima fază.
44. **CONFIRMAT/DEFAULT:** soare, nori, ploaie și furtuni; fără zăpadă. Vremea poate modifica vizibilitatea, sunetul, aderența și densitatea ambientală, fără simulare meteorologică extremă.

## 6. Populație și NPC-uri — deciziile 45–54

45. **PROVIZORIU ca aspirație:** densitate vizuală apropiată de Cyberpunk 2077 în zonele și presetările capabile; numărul final este stabilit exclusiv prin benchmark-ul pe hardware-ul țintă.
46. **CONFIRMAT:** Low poate reduce populația ambientală, nu entitățile relevante.
47. **DEFAULT:** au identitate persistentă contactele, NPC-urile narative, comercianții importanți, angajații selectați și participanții relevanți la un eveniment. Cetățenii aleatori nu persistă.
48. **CONFIRMAT:** numai NPC-urile importante au viață și date complete; restul oferă o iluzie convingătoare.
49. **CONFIRMAT:** rutine ambientale de tip oraș viu, cu trasee și activități simple, nu simularea completă a fiecărui cetățean.
50. **CONFIRMAT:** NPC-urile reacționează la starea legală/ilegală și la acțiunile jucătorului. Memoria permanentă este rezervată NPC-urilor importante.
51. **DEFERRED/DEFAULT:** sistemul complet poate folosi fața, ținuta, vocea, vehiculul, numărul de înmatriculare și reputația. V1 recunoaște doar un subset temporar validat prin prototip — ținută și vehicul — fără forensics; vocea și numărul sunt deferred, nu eliminate.
52. **CONFIRMAT:** reputații separate pentru profesii, poliție, fiecare familie mafiotă, zone și statut social.
53. **CONFIRMAT:** câteva NPC-uri au povești și relații care avansează când sunt ajutate; nu devin companions permanenți.
54. **CONFIRMAT:** dialog contextual scurt, cu decizii de bază, inclusiv alegeri legale/ilegale.

## 7. Co-op și sesiune — deciziile 55–66

55. **CONFIRMAT:** limita v1 este maximum patru jucători în total — creatorul plus maximum trei prieteni (`1 host + 0–3 clienți`). Arhitectura nu plătește acum costul generalizării la mai mulți.
56. **CONFIRMAT:** Steam-only inițial.
57. **CONFIRMAT:** listen server privat pe PC-ul host-ului.
58. **CONFIRMAT:** invitații și conectare fără port forwarding manual.
59. **CONFIRMAT:** join-in-progress, inclusiv în timpul joburilor.
60. **CONFIRMAT/DEFAULT:** personajul revine la ultima poziție validă; dacă poziția nu este sigură ori nu aparține lumii curente, apare la cel mai apropiat safe anchor.
61. **PROPUS — NECESITĂ APROBARE:** fără host migration în v1. Ieșirea normală a host-ului salvează și închide sesiunea pentru toți.
62. **PROPUS — NECESITĂ APROBARE:** la întrerupere, locul jucătorului este rezervat inițial 120 secunde. La crash al host-ului se revine la ultimul autosave confirmat.
63. **CONFIRMAT:** fără tether; jucătorii se pot separa pe toată harta.
64. **CONFIRMAT:** până la patru instanțe de job pot rula simultan.
65. **PROPUS — NECESITĂ APROBARE:** solo poate pune pauză; multiplayer nu oprește lumea când cineva deschide un meniu.
66. **PROPUS — NECESITĂ APROBARE:** grupul rămâne aliat. Friendly fire este configurabil; nu proiectăm sabotaj sau PvP competitiv, iar furtul direct din inventarul colegului este interzis.

## 8. Save și progres portabil — deciziile 67–75

67. **CONFIRMAT:** lumea aparține host-ului, dar progresul principal aparține personajului și călătorește între lumile prietenilor.
68. **CONFIRMAT:** banii, obiectele și recompensele obținute în lumea altuia rămân personajului.
69. **CONFIRMAT cu model tehnic PROPUS:** aspectul, hainele, banii, echipamentele, VehicleRecord cu portbagaj, PortablePropertyRecord cu decor/storage/rent/debt, progresia, reputația și cazierul sunt portabile. Actorii fizici sunt materializări temporare ale recordurilor, nu sunt transportați brut între lumi.
70. **CONFIRMAT:** nimic al personajului absent nu evoluează offline; nevoile, chiria, datoria și afacerile sunt oprite.
71. **CONFIRMAT:** trișarea intenționată prin editarea save-ului local este acceptată în co-op privat. Sistemul previne coruperea și duplicarea accidentală, nu promite economie globală securizată.
72. **CONFIRMAT ca intenție; limită tehnică explicită:** în sesiunea vie, tranzacțiile folosesc ID unic, stări Pending/Committed/Aborted și sunt idempotente. Lease-ul poate fi unic numai în sesiunea/dispozitivul curent; două host-uri fără backend nu se pot coordona global. Conflictele cross-host se detectează prin ProfileEpoch, revision și receipts și cer reconciliere, fără alegere automată. Restore-ul manual creează un ProfileEpoch nou. Nu se poate garanta atomicitate durabilă între fișiere aflate pe PC-uri diferite după crash/partition.
73. **CONFIRMAT pentru personaje multiple; PROPUS — NECESITĂ APROBARE pentru UX:** fiecare personaj folosește autosave și un save manual de siguranță; stările critice nu se suprascriu fără backup.
74. **PROPUS — NECESITĂ APROBARE:** minimum cinci generații rotative cu checksum, manifest și restaurare ghidată.
75. **PROVIZORIU:** resetări rare pot exista în Early Access. Schema, versionarea și migrările sunt construite din prima zi pentru a reduce probabilitatea, nu pentru a promite că resetările nu vor exista.

## 9. Player, camere și input — deciziile 76–87

76. **CONFIRMAT:** comutare oricând între first-person și third-person, inclusiv la condus și combat.
77. **DEFAULT:** perspectivele oferă aceleași acțiuni și rezultate; diferențele sunt numai de prezentare și confort.
78. **DEFAULT:** first-person folosește corp complet când este lizibil, plus brațe/obiecte dedicate pentru precizia interacțiunii.
79. **DEFAULT:** third-person are distanțe configurabile; în aim trece într-un framing peste umăr, cu shoulder swap.
80. **DEFAULT:** sprintul poate intensifica mișcarea camerei, dar head bob, motion blur, camera shake și sprint effects au slider sau Off; FOV este configurabil.
81. **CONFIRMAT:** mouse+tastatură se livrează prima; inputul este abstractizat din prima pentru controller ulterior.
82. **CONFIRMAT:** remapping complet, sensibilități separate, hold/toggle și mers lent; aim assist apare odată cu controllerul.
83. **DEFAULT:** mers lent, mers, jogging și sprint; stamina se consumă la sprint și eforturi, nu la deplasarea normală.
84. **CONFIRMAT:** vault/mantle realist peste obstacole joase și medii, plus urcare marcată pe obstacole înalte selectate; fără wall-running sau free-climbing.
85. **CONFIRMAT/DEFAULT:** scări normale și de incendiu pregătite; fără free-climbing pe țevi, cabluri și cornișe.
86. **CONFIRMAT:** înot da; bărci nu.
87. **CONFIRMAT:** crouch, prone și cover manual; fără cover automat.

## 10. Personaj, haine și statut — deciziile 88–94

88. **CONFIRMAT:** creator complet de personaj.
89. **CONFIRMAT:** o singură înălțime și același corp/skeleton de bază pentru toți.
90. **CONFIRMAT/DEFERRED:** față, păr, piele, ochi, tatuaje și cicatrici intră înainte; variantele de voce, mers și postură sunt post-Early Access dacă nu devin necesare pentru conținutul de lansare.
91. **DEFAULT:** sloturi pentru bază, top, strat exterior, pantaloni, încălțăminte, cap și accesorii; combinațiile sunt validate pentru clipping.
92. **CONFIRMAT:** lanț, ceas, brățări, inele, cercei și piercing-uri.
93. **CONFIRMAT/DEFAULT:** hainele sunt obiecte de inventar; outfit-urile se salvează, iar schimbarea completă se face la garderobă, vehicul sau printr-o acțiune temporizată într-un loc sigur.
94. **CONFIRMAT:** hainele și bijuteriile schimbă percepția socială, accesul și semnătura vizuală. Capacitatea vine din buzunare/genți; protecția vine numai din armură.

## 11. Nevoi, sănătate și moarte — deciziile 95–106

95. **CONFIRMAT:** foame, sete, somn, vezică/toaletă și igienă. Health și injury sunt sisteme separate. Fără temperatură și stres în v1.
96. **CONFIRMAT:** nevoile avansează numai cât personajul este activ în sesiune.
97. **DEFAULT:** foamea și setea au patru trepte, notificări rare și penalizări progresive la stamina/recuperare; nu devin micro-management la fiecare câteva minute.
98. **DEFAULT:** oboseala reduce treptat stamina și claritatea, iar epuizarea poate provoca micro-adormire rară; toate efectele vizuale pot fi reduse.
99. **CONFIRMAT/DEFAULT:** igiena afectează aspectul, reacțiile sociale, accesul și poate modifica recuperarea ori riscul unei răni; nu produce damage direct doar pentru că valoarea este mică.
100. **DEFAULT:** health general plus hit zones și răni etichetate; nu există câte un health bar complet independent pentru fiecare membru.
101. **CONFIRMAT/DEFAULT:** sângerare, fractură, arsură și comoție în formă moderată; fără simulator medical complet.
102. **CONFIRMAT:** rănile nu blochează artificial mersul, sprintul, țintirea sau condusul. Ele afectează damage-ul viitor, recuperarea, feedback-ul și riscul de incapacitate.
103. **CONFIRMAT/DEFAULT:** prim ajutor, medicamente și spital. Ambulanța și operațiile complexe sunt deferred.
104. **CONFIRMAT:** alcoolul și drogurile au efecte reale. Toleranța și dependența sunt sisteme moderate, data-driven; nu se glorifică abuzul.
105. **CONFIRMAT ca mecanică; PROPUS pentru valori:** există downed/revive și apoi spital dacă nu intervine nimeni. Fereastra de 60 secunde și regula unui singur revive per incident se validează prin playtest.
106. **CONFIRMAT ca rezultat; PROPUS pentru procente:** banca și bunurile depozitate sunt sigure. Spitalizarea poate pierde o parte din cash-ul purtat și timp; arestul confiscă bani murdari, contrabandă și bunuri ilegale relevante.

## 12. Interacțiune, obiecte și ownership — deciziile 107–118

107. **CONFIRMAT:** pickup instant pentru obiecte mici; obiectele grele/cargo folosesc acțiuni generice, nu animații unice pentru fiecare asset.
108. **CONFIRMAT:** inventar limitat prin sloturi și greutate; duffle bag și containerele cresc capacitatea.
109. **DEFAULT:** muniția, consumabilele și materialele comune se stivuiesc; armele, hainele, bijuteriile, uneltele și obiectele cu stare rămân instanțe individuale.
110. **DEFAULT:** stare individuală numai unde contează: muniție, uzură simplă, modificări, proveniență legală/ilegală și ownership.
111. **CONFIRMAT:** buzunare, genți, portbagaje, dulapuri, seifuri și depozite, cu capacități credibile.
112. **CONFIRMAT/DEFAULT:** obiectele lăsate liber în spațiul public dispar după timeout, inclusiv un bun owned abandonat. Persistă doar în inventar, vehicul, proprietate, storage/mobilier valid sau cât timp sunt obiecte de misiune active.
113. **CONFIRMAT:** ce se află în inventar, vehicul, apartament sau depozit sigur persistă.
114. **CONFIRMAT/DEFAULT:** ownerul poate acorda separat View/Open, Take/Move, Use/Consume, Drive, Deposit, Modify, Sell și TransferOwnership; vânzarea și transferul de ownership cer confirmare explicită.
115. **DEFAULT:** trade sigur cu confirmare bilaterală; gift direct este permis, dar produce transfer explicit și transaction ID.
116. **DEFAULT:** nu se poate fura direct din inventarul ori storage-ul încuiat al unui coleg. Obiectele abandonate sau puse într-un container comun respectă permisiunile acelui container.
117. **DEFAULT:** un buton contextual execută acțiunea principală; hold deschide un radial numai când există mai multe acțiuni relevante.
118. **CONFIRMAT/DEFAULT:** lockpick, căutare, repair, refuel, treatment și mutarea cargo sunt timed actions întreruptibile de mișcare, damage sau pierderea accesului.

## 13. Economie, bancă, chirie și datorie — deciziile 119–130

119. **CONFIRMAT:** economia se oprește când personajul/campania nu rulează.
120. **CONFIRMAT:** legal cash, bank balance și dirty cash sunt trei solduri distincte.
121. **CONFIRMAT/DEFAULT:** dirty cash trebuie spălat pentru cumpărături mari; transferul păstrează proveniența. Prototipul validează conversia și comisionul, iar riscul de descoperire se conectează abia după Police v1. Comisionul inițial de 25% este strict valoare de test.
122. **CONFIRMAT ca tip de pierdere; PROPUS pentru valoare:** spitalizarea poate pierde o parte din legal cash purtat; la arest dirty cash și contrabanda descoperită sunt confiscate. Banca rămâne protejată. Procentul inițial de 25% este doar pentru playtest.
123. **CONFIRMAT/DEFAULT:** telefonul oferă sold, transfer și plăți; ATM-ul permite depunere/retragere și operații cu numerar.
124. **CONFIRMAT:** transferuri gratuite și fără limită artificială între prieteni. Dirty cash rămâne dirty și devine risc numai când este descoperit printr-o percheziție/arest, nu prin omnisciența poliției.
125. **CONFIRMAT:** fără wallet sau fond comun de echipă.
126. **CONFIRMAT:** dolari și cenți, stocați intern ca număr întreg de cenți.
127. **DEFAULT:** raporturile dintre salarii, bunuri și costuri sunt inspirate din realitate; timpul de progres este comprimat pentru gameplay.
128. **DEFAULT:** prețuri fixe și data-driven în primul slice; raritatea și stocul pot varia. Cererea dinamică și inflația vin numai după ce economia controlată este distractivă.
129. **CONFIRMAT/DEFAULT:** cel mai ieftin vehicul funcțional în 30–60 minute; o mașină decentă în aproximativ patru ore; luxul și proprietățile cer progres mult mai lung.
130. **CONFIRMAT/DEFAULT:** chirie și datorii da; taxe ca sistem separat nu. Autopay opțional, notificare, perioadă de grație și penalizare înainte de evacuare/recuperare.

## 14. Magazine, lux, proprietăți și afaceri — deciziile 131–142

131. **CONFIRMAT:** magazine fizice și aplicații cu livrare.
132. **DEFAULT:** catalog stabil pentru bunuri comune; stoc limitat și restock pentru bunuri rare. Stocul este per campanie/sesiune, nu o piață online globală.
133. **DEFAULT:** dealer nou și second-hand intră primele. Privat, licitație și piață ilegală se adaugă ulterior.
134. **CONFIRMAT:** mașinile se cumpără integral. Apartamentele se cumpără integral sau se închiriază. Fără credit auto, leasing și ipotecă în v1.
135. **CONFIRMAT:** hainele normale nu simulează temperatura și nu protejează; armura are acoperire/protecție.
136. **CONFIRMAT/DEFAULT:** bijuteriile oferă statut, pot păstra valoare, pot fi furate și pot atrage atenție când sunt purtate.
137. **CONFIRMAT:** apartamente instanțiate, cu loading mascat individual; prietenii pot vizita.
138. **CONFIRMAT:** mai multe locuințe per personaj; același tip/adresă poate exista pentru mai mulți prin PropertyInstanceId și număr de apartament diferit.
139. **CONFIRMAT/DEFAULT:** mobilier plasat liber, cu grid/snap opțional, validare de coliziune și limite per cameră.
140. **CONFIRMAT:** bunurile sunt transportate fizic de jucător, vehicul sau serviciu de mutări; nu teleport gratuit între proprietăți.
141. **CONFIRMAT ca direcție:** primele echipamente sunt unelte pentru activități ilegale, diferențiate prin eficiență, zgomot, viteză, capacitate și uzură simplă.
142. **DEFERRED/PROPUS — NECESITĂ APROBARE:** afacerile nu produc venit pasiv. O afacere plătește numai când personajul este prezent fizic și execută activitatea/jobul aferent; sistemul complet de afaceri este post-Early Access dacă nu este aprobat pentru scope-ul inițial.

## 15. Joburi și evenimente — deciziile 143–152

143. **CONFIRMAT:** joburi hibride: conținut și obiective proiectate manual, dar locații, rute și encountere alese din seturi aprobate.
144. **PROPUS — NECESITĂ APROBARE:** primul job legal este curierat/livrare de colet.
145. **PROPUS — NECESITĂ APROBARE:** prima activitate ilegală este furt/recuperare de colet dintr-o zonă restricționată.
146. **PROPUS — NECESITĂ APROBARE:** telefonul și firmele/NPC-urile oferă joburi; level, bani, licențe și reputații pot controla eligibilitatea după regulile Progression v1.
147. **CONFIRMAT:** tutorialul folosește framework-ul de joburi, apoi sandbox fără poveste obligatorie.
148. **CONFIRMAT/DEFAULT:** encounterele spontane variază ruta sau obiectivul; frecvența este data-driven și protejată de cooldown.
149. **CONFIRMAT pentru solo; PROPUS pentru roluri:** toate joburile funcționează solo; co-op poate permite roluri naturale, dar nu blochează acțiuni prin clase.
150. **PROPUS — NECESITĂ APROBARE:** scalarea data-driven poate adăuga obiective simultane, presiune de timp, spawn-uri și recompense moderate; nu crește artificial health-ul adversarilor.
151. **PROPUS — NECESITĂ APROBARE:** loc rezervat inițial 120 secunde; la reconnect se reia aceeași instanță. După timeout, rolul se eliberează, mission items sunt reconciliate, iar reward-ul se recalculează fără duplicare.
152. **PROPUS — NECESITĂ APROBARE:** contractul afișează payout individual înainte de acceptare. La eșec nu există payout complet, costurile și consecințele rămân; joburile repetabile revin cu altă variantă, iar tutorialul poate avea checkpoint.

## 16. Crimă, poliție, mafie și închisoare — deciziile 153–166

153. **CONFIRMAT:** heat, cazierul și rangul ilegal sunt individuale.
154. **NON-SCOPE:** fără sistem generic în care martorul memorează fața, arma, vocea și vehiculul.
155. **NON-SCOPE:** fără secvență completă de raportare a martorilor.
156. **NON-SCOPE:** fără sistem general de mituire, amenințare sau imobilizare a martorilor.
157. **NON-SCOPE:** fără rețea de camere și ștergere a înregistrărilor. Crouch reduce vizibilitatea și zgomotul, nu acordă invizibilitate.
158. **NON-SCOPE:** fără amprente, ADN și identificare criminalistică. Există numai o semnătură temporară simplă de ținută/vehicul pentru urmărirea curentă.
159. **NON-SCOPE:** fără dovezi fizice persistente în v1.
160. **PROPUS — NECESITĂ APROBARE:** patru trepte proprii de răspuns: Attention, Pursuit, Armed Response și Manhunt. Primele două se validează înainte de Combat; treptele armate se adaugă după Combat v1. Fără elicopter în prima versiune este o tăiere de scope propusă.
161. **CONFIRMAT:** Police Director poate genera unități în afara privirii, numai în puncte valide și cu timp de sosire credibil.
162. **CONFIRMAT:** se scapă prin ruperea contactului, ascundere, schimbarea ținutei/vehiculului și oprirea faptelor care cresc heat-ul.
163. **PROPUS — NECESITĂ APROBARE:** complicitatea apare numai după ajutor concret: getaway driving după ordinul poliției, atac/obstrucție, transport conștient de contrabandă ori participare la job; simpla proximitate nu este suficientă.
164. **CONFIRMAT pentru mai multe familii; PROPUS pentru model:** reputația este individuală pentru fiecare personaj și familie.
165. **NON-SCOPE:** fără polițiști corupți, informatori, mită, protecție cumpărată și războaie autonome poliție–mafie în v1.
166. **CONFIRMAT ca direcție; PROPUS pentru implementare:** închisoarea este gameplay scurt și deliberat neatractiv, într-o instanță compatibilă co-op. Intervalul 3–12 minute, activitățile de reducere și excluderea prison break-ului necesită aprobare după prototip; bail, vizite și comportamentul la disconnect se decid atunci.

## 17. Combat și arme — deciziile 167–175

167. **CONFIRMAT:** traseul legal poate evita aproape total lupta; traseul violent o poate face frecvent.
168. **CONFIRMAT ca principiu:** letalitate umană, fără bullet sponges. Valorile provin din calibru, zonă, armură, distanță și sângerare, nu din level.
169. **PROPUS — NECESITĂ APROBARE:** balistică hibridă server-authoritative prin trace/sweep, cu timp de zbor și cădere unde sunt perceptibile; fără Actor replicat pentru fiecare glonț.
170. **DEFERRED în trepte:** întâi pumni, o armă improvizată și un pistol; apoi cuțit și shotgun; SMG și puști după stabilizarea pipeline-ului.
171. **CONFIRMAT:** level-ul și banii controlează accesul; level-ul nu crește damage-ul. Reputația și sursele legale/ilegale rămân de decis.
172. **CONFIRMAT/DEFAULT:** armele mari sunt vizibile sau cer geantă/vehicul; armele mici pot fi ascunse. NPC-urile relevante reacționează când le observă.
173. **CONFIRMAT/DEFERRED:** recoil, magazii, glonț pe țeavă și handling detaliat; blocajele, curățarea și uzura profundă vin după combat v1.
174. **CONFIRMAT:** hit zones și armură pe zone. Penetrarea materialelor este data-driven; ricoșeul complex este deferred.
175. **CONFIRMAT/DEFERRED:** melee final este complex, dar se dezvoltă incremental: hit, block/dodge, apoi grappling și environmental actions.

## 18. Vehicule și trafic — deciziile 176–185

176. **CONFIRMAT:** condus arcade-realist, accesibil și credibil, nu simulator dur.
177. **CONFIRMAT:** damage simplu cu stări normal, damaged, smoke, fire și destroyed; fără deformare avansată. Explozia apare numai după damage sever.
178. **CONFIRMAT:** transmisie automată; fără sistem manual ori meniuri complexe de asistențe.
179. **PROPUS — NECESITĂ APROBARE:** în timpul sesiunii vehiculul rămâne unde este lăsat. După relansare ori recovery este disponibil determinist în garaj; alternativa „aproape de jucător” nu este folosită până nu este aleasă explicit.
180. **PROPUS — NECESITĂ APROBARE:** cheie digitală/record de acces, permisiuni temporare pentru prieteni, lock/unlock și hotwire temporizat cu unealtă. Furtul auto de la NPC este un job/mecanică separată.
181. **CONFIRMAT/DEFAULT:** consum data-driven pe vehicul și stil de condus; alimentare temporizată și întreruptibilă. Canistrele vin după fuel v1.
182. **CONFIRMAT:** mentenanță, reparație, tractare și recuperare arcade/simple.
183. **CONFIRMAT:** upgrade-uri persistente pentru motor, suspensie, frâne, anvelope, blindaj, vopsea, sunet și interior.
184. **CONFIRMAT:** traficul îndepărtat este abstract; devine Actor fizic complet numai lângă o bulă de jucător.
185. **PROPUS — NECESITĂ APROBARE:** semafoare, coliziuni grave, condus periculos, furt auto și opriri când există poliție relevantă; fără simularea fiecărei amenzi și parcări în prima versiune.

## 19. UI, audio și accesibilitate — deciziile 186–195

186. **CONFIRMAT:** HUD minimalist, telefon și interfețe diegetice.
187. **PROPUS — NECESITĂ APROBARE:** HUD contextual și configurabil; informația critică apare când este necesară.
188. **CONFIRMAT/DEFAULT:** procente exacte în telefon/laptop; HUD-ul folosește indicatori compacți.
189. **CONFIRMAT:** minimap, hartă mare, GPS și world markers într-o combinație configurabilă.
190. **CONFIRMAT pentru telefon+laptop; PROPUS pentru împărțire:** telefonul gestionează bani, joburi, hartă, contacte, mesaje și cumpărături rapide; laptopul gestionează proprietăți, afaceri, istoric și operații profunde.
191. **CONFIRMAT:** prietenii apar pe minimap și hartă; fără contur permanent prin pereți.
192. **PROPUS — NECESITĂ APROBARE:** voice chat de grup este candidat pentru Early Access; proximitatea și apelurile prin telefon vin numai după stabilizarea bazei. Nu este încă o promisiune de lansare.
193. **CONFIRMAT:** ocluzie, interior/exterior și identitate sonoră credibile, fără simulare acustică extrem de costisitoare.
194. **CONFIRMAT ca dorință; PROPUS pentru scope:** muzică personală din folder local. Varianta local-only este candidata sigură; retransmiterea către ceilalți este amânată până la o soluție juridică, de securitate și bandwidth compatibilă cu regula de copyright.
195. **CONFIRMAT numai pentru pregătirea arhitecturii:** toate textele trebuie să fie localizabile din prima zi. English ca limbă-sursă, Romanian ca a doua limbă și lista exactă de opțiuni de accesibilitate sunt propuneri ce necesită aprobare înainte de content lock.

## 20. Producție, Codex și lansare — deciziile 196–200

196. **CONFIRMAT:** proiect C++ nou, creat de la zero în UE 5.8.2. Această versiune înlocuiește alegerea inițială 5.8.1 înainte de crearea proiectului.
197. **CONFIRMAT ca workflow:** Codex scrie și modifică sursele, testele, configul și documentația. Creatorul preferă să compileze și să ruleze Editorul. Codex oferă pași exacți și analizează logurile; un task nu este Done până când build-ul și testul creatorului trec.
198. **CONFIRMAT:** C++ pentru gameplay, networking, persistence, economie, AI și performanță. Blueprint pentru Animation Blueprint, UI layout, cinematics, configurare vizuală și excepții aprobate.
199. **PROPUS — NECESITĂ APROBARE, dar este gate de producție:** pipeline de asset-uri cu scară, pivot, nume, directoare, material slots, coliziuni, Nanite/LOD/HLOD și validare automată. Software-ul DCC exact se completează înaintea primului import mare; Source Art stă separat de repository-ul jocului și are backup 3-2-1.
200. **CONFIRMAT:** lansarea urmărită este Early Access. **PROPUS — NECESITĂ APROBARE:** primul release vandabil conține un district finit, iar Manhattan-ul complet se extinde după lansare. Cantitățile și pragul comercial se recalculează după vertical slice.

---

## Contradicții rezolvate

### Economie realistă versus progres rapid

- Cea mai ieftină mașină funcțională poate fi cumpărată în 30–60 minute.
- O mașină decentă urmărește aproximativ patru ore.
- Produsele premium și proprietățile creează progresul de zeci/sute de ore.
- Prețurile păstrează raporturi credibile, dar timpul este comprimat.

### Personaj portabil versus lume a host-ului

- Host-ul salvează numai adevărul lumii și activitățile aflate în acea sesiune.
- Jucătorul salvează recordul portabil al personajului.
- Proprietățile și vehiculele portabile sunt drepturi/recorduri, apoi sunt materializate controlat în lumea curentă.
- Poziția, urmărirea poliției și jobul activ pot fi specifice sesiunii; progresul, cazierul și reputația rămân personale.
- Fără backend, sincronizarea dintre host și fișierul local al guest-ului este best-effort: protocolul previne majoritatea duplicărilor accidentale, dar nu poate promite atomicitate perfectă după crash ori partiție de rețea.

### Reacție la crimă fără forensics

- Victima, guard-ul, polițistul ori un detector explicit de misiune poate genera Incident.
- Civilii ambientali pot fugi sau reacționa, dar nu devin sistem complet de martori.
- Poliția folosește Active Heat și o descriere temporară simplă.
- Cazierul și reputația înlocuiesc investigația criminalistică persistentă.

### Apartament privat fără a muta toată sesiunea

- Nu se folosește server travel pentru un singur jucător.
- Apartamentele sunt instanțe izolate în același world autoritativ.
- Loading screen-ul individual maschează streaming-ul și teleportul.
- Vizitatorii intră în aceeași PropertyInstanceId.

### Realism versus optimizare

- Realismul este simulat complet numai lângă jucător și numai când schimbă o decizie.
- Departe, populația și traficul folosesc reprezentări abstracte. Afacerile pot avea doar reprezentare vizuală/statistică fără venit; plata apare numai prin activitatea fizică a personajului.
- Nicio caracteristică cosmetică nu poate compromite stabilitatea celor patru bule simultane.

---

## Decizii care rămân de tuning, nu blochează începutul

- configurația exactă a PC-ului minim și VRAM-ul;
- duratele finale pentru zi, nevoi, downed, închisoare și cooldown-uri;
- numerele de damage, recoil, armor și penetrare;
- primul district artistic final și landmark-urile originale;
- catalogul și prețurile finale;
- programele DCC folosite de creator;
- limbile suplimentare și voice-over-ul;
- proximitatea voice chat și muzica personală partajată;
- host migration, cross-store, dedicated server și mai mult de patru jucători.

Aceste valori se hotărăsc la milestone-ul care le poate măsura. Nu justifică amânarea proiectului C++, a repository-ului, a TestGym-ului sau a prototipurilor de risc.
