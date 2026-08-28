# Arhivă non-normativă — chestionarul inițial

> Acest document păstrează întrebările de cercetare. Răspunsurile consolidate și statusul lor se află exclusiv în `Docs/DECISIONS.md`. Nu folosi o întrebare de aici ca decizie și nu repeta chestionarul creatorului.

# BROKEN STREETS — Chestionarul complet de design

**Versiune:** 1.0
**Număr total:** 200 de întrebări
**Scop:** transformarea viziunii Broken Streets într-un design coerent înainte de implementarea sistemelor.

## Cum răspunzi

- `[B]` înseamnă că răspunsul poate schimba arhitectura, performanța sau ordinea implementării.
- Poți răspunde în serii: `1–25`, `26–50` etc.
- Răspunde cu numărul întrebării și alegerea sau explicația ta.
- Dacă nu știi, scrie `NU ȘTIU`. Codex îți va prezenta opțiuni, avantaje, dezavantaje și o recomandare.
- Poți scrie `DECIDE TU` pentru detalii în care vrei să alegem soluția recomandată.
- Răspunsurile deja oferite au fost folosite pentru formularea întrebărilor; nu trebuie să justifici din nou o alegere decât dacă întrebarea cere o precizare.

---

## 1. Viziunea centrală — întrebările 1–8

1. **[B]** Ordonează cele patru promisiuni ale jocului de la cea mai importantă la cea mai puțin importantă: viață aspirațională, ascensiune financiară, carieră legală/ilegală și povești trăite în co-op.

2. În ce situație începe personajul: fără bani și locuință, cu un apartament modest, cu o mașină ieftină, cu datorii sau într-o altă situație?

3. Care este fantezia de endgame: milionar cu proprietăți și mașini, antreprenor cu afaceri, lider interlop, persoană respectată legal sau posibilitatea de a combina aceste direcții?

4. **[B]** Întreaga experiență trebuie să poată fi terminată solo sau accepți activități care necesită obligatoriu minimum doi jucători?

5. **[B]** Co-op-ul trebuie să fie doar o metodă de a juca împreună sau fiecare activitate importantă trebuie proiectată cu roluri și avantaje speciale pentru echipă?

6. Vrei o campanie principală cu început și final, fire narative separate sau un sandbox în care povestea apare mai ales din sisteme?

7. Cât ar trebui să dureze o sesiune satisfăcătoare: 30–60 de minute, 1–2 ore, 3–4 ore sau fără o durată vizată?

8. După atingerea succesului maxim, jocul continuă nelimitat, pornește un New Game Plus, oferă un final sau lasă toate opțiunile deschise?

## 2. Ton, public și limite — întrebările 9–14

9. Tonul este serios și dur, realist cu umor ocazional, satiric sau diferă în funcție de activitate?

10. Ce rating de vârstă urmărești și ce permiți dintre violență grafică, droguri, alcool, jocuri de noroc, nuditate și limbaj vulgar?

11. Când realismul intră în conflict cu distracția, alegem realism strict, realism simplificat sau distracția, caz cu caz?

12. Cât umor vrei în dialoguri, reclame, radio, evenimente și reacțiile NPC-urilor?

13. **[B]** Folosim numai mărci, magazine și vehicule fictive inspirate din realitate sau vrei și mărci/licențe reale atunci când este posibil?

14. Ce teme, activități, infracțiuni sau tipuri de misiuni nu vrei sub nicio formă în Broken Streets?

## 3. Platformă, performanță și scalabilitate — întrebările 15–24

15. **[B]** Care este configurația celui mai slab PC pe care vrei să ruleze jocul: procesor, placă video, RAM, VRAM și SSD/HDD? Dacă nu o știi, accepți să alegem un PC-etalon după primul benchmark?

16. **[B]** Pe PC-ul minim accepți `1080p/30 FPS stabil`, vrei minimum `45 FPS` sau ceri `60 FPS`?

17. **[B]** Pe configurația recomandată ținta este `1080p/60`, `1440p/60`, `1440p/90` sau altceva?

18. **[B]** SSD-ul și minimum 16 GB RAM pot fi cerințe obligatorii?

19. **[B]** Accepți ca presetul Low să reducă vizibil pietonii, traficul, distanța de afișare și numărul obiectelor cosmetice, păstrând identic gameplay-ul?

20. **[B]** Accepți ca Low să reducă sau să dezactiveze Lumen, ray tracing, umbrele avansate și reflexiile costisitoare?

21. Accepți TSR/DLSS/FSR/XeSS și rezoluție dinamică pentru menținerea FPS-ului, fără ca Frame Generation să fie necesar pentru atingerea minimului?

22. **[B]** Accepți ca PC-ul host-ului să aibă cerințe CPU/RAM mai mari decât PC-urile celor trei clienți, deoarece simulează toate cele patru zone?

23. Care este timpul maxim acceptabil pentru pornirea jocului, încărcarea campaniei și intrarea într-un interior?

24. Ordonează prioritățile când trebuie făcut un compromis: FPS, densitatea orașului, iluminarea realistă, calitatea personajelor și distanța vizuală.

## 4. NYC, geografie și dimensiunea hărții — întrebările 25–35

25. **[B]** Vrei Manhattan recognoscibil dar comprimat, o copie geografică apropiată sau un NYC fictiv construit din zone recognoscibile?

26. **[B]** La forma finală vrei doar Manhattan sau și Brooklyn, Queens, Bronx și Staten Island?

27. **[B]** Care este prima zonă pe care vrei să o construim complet?

28. **[B]** În câte minute ar trebui traversată harta finală cu o mașină obișnuită, fără trafic extrem?

29. În câte minute ar trebui traversat pe jos primul district complet?

30. Cât de fidel trebuie păstrat gridul stradal real și ce landmark-uri trebuie să fie recognoscibile obligatoriu?

31. Folosim numele reale ale străzilor și cartierelor sau nume fictive inspirate din NYC?

32. Câtă verticalitate vrei: străzi și clădiri, acoperișuri, scări de incendiu, metrou, tuneluri și canalizare?

33. Acoperișurile trebuie să formeze o rețea reală de explorare sau sunt accesibile numai în anumite clădiri și misiuni?

34. Metroul este un sistem fizic cu trenuri și stații, un fast travel mascat sau ambele?

35. Cum limităm natural harta și cum vrei să fie adăugate zonele ulterioare: poduri, tuneluri, feribot, metrou sau update-uri ale aceluiași world map?

## 5. Interioare, timp, vreme și starea lumii — întrebările 36–44

36. **[B]** Orașul și interioarele trebuie să fie continue fără ecrane de încărcare vizibile sau accepți tranziții scurte pentru interioarele foarte complexe?

37. **[B]** Aproximativ ce procent dintre clădiri trebuie să fie accesibil la lansare: 5%, 10%, 25%, majoritatea sau doar cele cu scop de gameplay?

38. Ce interioare au prioritate: apartamente, magazine, restaurante, cluburi, birouri, depozite, spitale, secții de poliție sau altele?

39. Accepți interioare modulare recombinate inteligent sau fiecare interior important trebuie să fie unic?

40. **[B]** Confirmi că cei patru jucători pot fi simultan în patru interioare sau cartiere complet diferite?

41. **[B]** Cât durează o zi completă în joc: 48, 72, 96, 120 de minute sau altă durată?

42. **[B]** Confirmi că somnul este individual, iar timpul global sare numai dacă toți jucătorii dorm sau votează pentru salt?

43. Vrei anotimpuri? Dacă da, sunt dinamice în aceeași campanie sau fiecare campanie/zonă are un anotimp fix?

44. Ce fenomene meteo dorești și care afectează gameplay-ul: ploaie, furtună, ceață, caniculă, zăpadă, gheață și inundații locale?

## 6. Populație, AI și simulare socială — întrebările 45–54

45. **[B]** Ce joc reprezintă cel mai bine densitatea de populație dorită: GTA V, Spider-Man, Cyberpunk 2077 sau alt exemplu?

46. **[B]** Confirmi că presetările slabe pot reduce mulțimea și traficul vizual, dar nu elimină martorii, poliția sau NPC-urile relevante pentru gameplay?

47. **[B]** Ce NPC-uri trebuie să aibă identitate permanentă: contacte, vecini, comercianți, angajați, martori importanți și/sau cetățeni aleatori?

48. **[B]** Fiecare cetățean trebuie să aibă casă, serviciu, bani și nevoi reale sau numai NPC-urile importante, iar restul oferă o iluzie convingătoare?

49. Cât de detaliate sunt rutinele: traseu simplu, program casă–muncă–magazin sau viață complexă cu variații?

50. Ce trebuie să-și amintească NPC-urile despre jucător și pentru cât timp: ajutor, insultă, furt, violență, datorii și reputație?

51. După ce poate fi recunoscut jucătorul: față, haine, voce, mașină, număr de înmatriculare sau reputație?

52. Reputația socială este globală sau separată pe cartier, profesie, poliție, mafie și clasă socială?

53. Ce relații permiți cu NPC-urile: prietenie, rivalitate, romantism, familie, mentorat și angajare?

54. Cum preferi conversațiile: replici contextuale scurte, dialog cu opțiuni, conversații cinematice sau o combinație?

## 7. Co-op privat și sesiunea — întrebările 55–66

55. **[B]** Patru jucători reprezintă limita absolută sau arhitectura trebuie să permită o posibilă extindere după lansare?

56. **[B]** Jocul este Steam-only inițial sau trebuie să permită invitații între magazine PC diferite printr-un serviciu comun?

57. **[B]** Confirmi modelul: un jucător creează sesiunea, PC-ul lui rulează listen server-ul, iar ceilalți intră prin invitație privată?

58. **[B]** Conectarea trebuie să funcționeze fără configurarea routerului și fără port forwarding manual?

59. **[B]** Prietenii pot intra după pornirea sesiunii și în timpul unui job sau numai din lobby/între activități?

60. Când un prieten intră, apare la ultima locație salvată, acasă, lângă host sau într-un punct sigur apropiat de grup?

61. **[B]** Pentru v1 accepți ca ieșirea normală a host-ului să salveze campania și să închidă sesiunea pentru toți, fără host migration?

62. La un crash al host-ului, cât timp așteptăm reconectarea și la ce autosave valid revenim?

63. **[B]** Confirmi că nu există limită de distanță și că fiecare jucător poate rămâne permanent într-o zonă diferită?

64. **[B]** Pot exista patru joburi independente simultan sau campania are un singur job principal activ, cu activități secundare individuale?

65. În multiplayer, pauza totală există numai dacă toți votează, numai pentru host sau nu există deloc?

66. **[B]** Jucătorii sunt întotdeauna aliați sau permiți friendly fire, furt între prieteni, sabotaj ori PvP opțional configurat de host?

## 8. Save, progres și încredere — întrebările 67–75

67. **[B]** Accepți modelul recomandat: campania host-ului conține lumea și câte un record economic/persistent separat pentru fiecare prieten?

68. **[B]** Banii și bunurile rămân exclusiv în acea campanie sau trebuie să urmeze jucătorul în campaniile altor persoane?

69. **[B]** Dacă ceva poate călători între lumi, ce anume: aspectul, hainele, banii, echipamentele, vehiculele, proprietățile, reputația sau cazierul?

70. **[B]** Când campania nu rulează, timpul, nevoile, chiria, taxele, dobânzile și afacerile se opresc complet?

71. **[B]** Fiind co-op privat, accepți că proprietarul campaniei își poate modifica tehnic save-ul local, chiar dacă jocul previne erorile și duplicarea accidentală?

72. **[B]** Dacă un jucător se deconectează în timpul unui transfer, schimb sau cumpărături, operația se anulează complet și revine la starea anterioară?

73. Vrei mai multe sloturi de campanie, salvări manuale plus autosave sau numai autosave cu checkpoint-uri?

74. Vrei copii automate de siguranță și posibilitatea de a reveni la una dintre ultimele salvări valide?

75. **[B]** În Early Access promitem compatibilitatea tuturor salvărilor sau accepți resetări rare dacă o schimbare majoră nu poate fi migrată sigur?

## 9. Player, camere, input și mișcare — întrebările 76–87

76. **[B]** First-person și third-person pot fi schimbate oricând dintr-un buton, inclusiv în vehicule și combat?

77. **[B]** Cele două perspective trebuie să ofere exact aceleași acțiuni și avantaje de gameplay?

78. În first-person vezi corpul complet sau numai mâinile și obiectele ținute?

79. În third-person preferi cameră centrată, peste umăr sau comutabilă între umărul stâng și drept?

80. Ce efecte trebuie să poată fi dezactivate: head bob, motion blur, camera shake, blur la sprint și schimbarea FOV-ului?

81. **[B]** Jocul trebuie proiectat complet pentru mouse+tastatură și controller din prima versiune?

82. Ce opțiuni sunt obligatorii: remapping total, sensibilitate separată, hold/toggle, mers lent și aim assist pentru controller?

83. Ce viteze de deplasare există și cât de importantă este stamina: mers lent, mers, jogging, alergare și sprint?

84. **[B]** Cât parkour dorești: obstacole joase, escaladare urbană moderată sau mișcare apropiată de jocurile dedicate?

85. Personajul poate folosi scări de incendiu, țevi, cornișe și cabluri sau numai trasee special pregătite?

86. Înotul, bărcile și deplasarea în apă sunt necesare?

87. Vrei crouch, prone și cover manual, cover automat sau niciun sistem complex de cover?

## 10. Crearea personajului, hainele și statutul — întrebările 88–94

88. **[B]** Personajul este creat complet de jucător sau alegem personaje presetate personalizabile?

89. **[B]** Permiți diferențe reale de înălțime și formă corporală, acceptând costul suplimentar pentru haine, animații și coliziuni?

90. Ce poate fi modificat: față, păr, piele, ochi, tatuaje, cicatrici, voce, mers și postură?

91. Câte straturi de haine trebuie purtate simultan: lenjerie, tricou, cămașă, jachetă, pantaloni, încălțăminte și accesorii?

92. Ce sloturi de bijuterii dorești: lanțuri, ceasuri, brățări, inele, cercei și piercing-uri?

93. Vrei outfit-uri salvate și schimbare rapidă numai la garderobă, oriunde din inventar sau în anumite locații?

94. Hainele și bijuteriile influențează doar aspectul sau și statutul, accesul social, buzunarele, protecția și recunoașterea de către martori?

## 11. Nevoi, sănătate, răni și moarte — întrebările 95–106

95. **[B]** Confirmă lista exactă: foame, somn, igienă și injury. Vrei să adaugi sete, temperatură, toaletă, stres, durere, boli sau dependențe?

96. **[B]** Confirmi că nevoile avansează numai cât campania rulează și jucătorul este activ, nu după timpul real offline?

97. După cât timp de joc apare foamea și ce produce fiecare etapă: notificare, stamina redusă, recuperare lentă, slăbiciune sau leșin?

98. Ce produce lipsa somnului: reacții lente, stamina redusă, vedere afectată, micro-adormire sau efecte discrete?

99. Ce influențează igiena: aspectul, reacțiile NPC-urilor, accesul în locații, anumite joburi sau sănătatea?

100. **[B]** Sănătatea este un indicator general sau folosim răni separate pentru cap, trunchi, brațe și picioare?

101. Ce răni simulăm: sângerare, fracturi, arsuri, comoție, infecții, cicatrici și durere persistentă?

102. Rănile afectează mișcarea și acțiunile: șchiopătat, aim slab, imposibilitatea de a sprinta, ridica sau conduce?

103. Cum se tratează rănile: prim ajutor, medicamente, ambulanță, spital, operații și recuperare în timp?

104. Vrei alcoolul, drogurile, toleranța, sevrajul și dependența ca sisteme reale sau numai ca elemente narative/economice?

105. **[B]** Cum funcționează downed/revive: cât durează, cine poate stabiliza și de câte ori poți fi ridicat înainte de spital?

106. **[B]** Confirmi că la moarte păstrezi contul și bunurile depozitate, dar poți pierde cash purtat, contrabandă, obiecte abandonate, timp și costuri medicale?

## 12. Interacțiuni, obiecte, inventar și ownership — întrebările 107–118

107. **[B]** Când ridici un obiect mic, intră instant în inventar, este ținut fizic în mână sau regula diferă după categorie?

108. **[B]** Inventarul este limitat prin sloturi, greutate, volum, o combinație sau este aproape nelimitat?

109. Ce obiecte identice se pot grupa și ce categorii trebuie să rămână instanțe individuale?

110. Ce stare proprie are un obiect: calitate, uzură, murdărie, muniție, serie, proveniență și modificări?

111. Ce containere există: buzunare, rucsacuri, portbagaje, dulapuri, seifuri și depozite? Capacitatea este realistă?

112. **[B]** Obiectele lăsate în lume rămân exact unde au fost puse sau dispar după o regulă clară dacă nu sunt importante?

113. **[B]** Obiectele cumpărate/găsite rămân proprietatea personală a jucătorului în recordul campaniei?

114. **[B]** Ce permisiuni poate acorda proprietarul: folosește, mută, consumă, conduce, depozitează, modifică și vinde?

115. Schimbul între jucători folosește o fereastră sigură confirmată de ambii, transfer direct din mână sau ambele?

116. Pot jucătorii să-și fure obiectele între ei și poate host-ul dezactiva această regulă?

117. Interacțiunea principală folosește un singur buton contextual, meniu radial pentru acțiuni multiple sau combinație?

118. Ce acțiuni necesită timp și animație și pot fi întrerupte: forțat uși, căutat, reparat, realimentat, tratat și mutat obiecte?

## 13. Economie, bancă, taxe, chirie și datorii — întrebările 119–130

119. **[B]** Confirmi că timpul economic se oprește complet când campania host-ului nu rulează?

120. **[B]** Vrei numerar, cont bancar și bani ilegali/murdari ca trei forme distincte sau numai cash și bancă?

121. **[B]** Dacă există bani murdari, trebuie spălați înaintea cumpărăturilor mari și ce risc dorești pentru această operație?

122. Ce se întâmplă exact cu numerarul purtat la moarte, spital și arest: pierdere totală, procent, confiscare sau posibilitate de recuperare?

123. Contul bancar este accesibil integral din telefon oriunde sau anumite operațiuni necesită ATM/sucursală?

124. Transferurile între prieteni sunt gratuite și nelimitate sau au limite, comisioane și posibilitatea de a atrage atenție?

125. Pe lângă conturile personale, vrei un fond comun voluntar pentru echipă, afaceri ori bunuri comune?

126. Folosim dolari și cenți exacți sau rotunjim majoritatea prețurilor și veniturilor pentru claritate?

127. Prețurile urmează aproximativ NYC-ul real sau comprimăm economia pentru ca progresul să fie satisfăcător într-un număr rezonabil de ore?

128. Vrei prețuri fixe sau variații pe cartier, cerere, raritate, reputație, anotimp și evenimente?

129. După câte ore de joc ar trebui obținute prima mașină, primul apartament bun și primul obiect de lux?

130. **[B]** Precizează regulile pentru taxe, datorii și chirie: ce plăți sunt manuale/automate, ce perioadă de grație există și când apar penalizări, evacuare sau recuperarea bunului?

## 14. Cumpărături, lux, proprietăți și afaceri — întrebările 131–142

131. **[B]** Cumpărăturile se fac în magazine fizice, prin aplicații cu livrare sau prin ambele? Ce categorii trebuie cumpărate fizic?

132. Magazinele au stoc real care se epuizează și se reface sau catalog permanent cu raritate controlată prin preț și acces?

133. Mașinile se cumpără de la dealeri, second-hand, licitații, persoane private și piață ilegală? Ce canale intră în prima versiune?

134. Pentru mașini și proprietăți vrei plată integrală, finanțare, leasing, închiriere și ipotecă?

135. Hainele influențează temperatura, buzunarele, protecția, statutul, recunoașterea și accesul social sau doar o parte dintre acestea?

136. Bijuteriile sunt simboluri de statut, investiții, obiecte ușor de furat, garanții pentru împrumuturi și/sau bunuri care atrag atenție?

137. **[B]** Apartamentele există fizic în clădire cu vedere reală sau pot fi spații separate încărcate când intri?

138. Un jucător poate închiria/deține mai multe locuințe și aceeași proprietate poate fi cumpărată separat de mai mulți jucători?

139. Cât de profundă este personalizarea locuinței: preseturi, mobilier plasat liber, finisaje și modificări structurale?

140. Bunurile se mută între proprietăți instant sau trebuie transportate fizic de jucător, vehicul ori serviciu de mutări?

141. Ce categorii de echipament trebuie să existe primele și ce le diferențiază: eficiență, zgomot, capacitate, fiabilitate, uzură și statut?

142. **[B]** Afacerile sunt gestionate activ, produc venit pasiv numai când campania rulează sau evoluează și între sesiuni?

## 15. Joburi, misiuni și evenimente — întrebările 143–152

143. **[B]** Joburile sunt predominant scrise manual, generate sistemic sau hibride: povești manuale plus activități repetabile?

144. Ce fantezie alegi pentru primul job legal: livrări, taxi, mecanic, construcții, curățenie, securitate, depozit sau altceva?

145. Ce fantezie alegi pentru prima activitate ilegală: furt, spargere, furt auto, contrabandă, jaf, fraudă, recuperare pentru mafie sau altceva?

146. Cum sunt descoperite joburile: telefon, aplicații, firme fizice, NPC-uri, contacte și reputație?

147. Povestea principală blochează sisteme/zone sau doar oferă context, personaje și recompense?

148. Ce evenimente spontane apar în oraș și cât de des: accidente, jafuri, controale, cereri urgente, oportunități rare și conflicte?

149. **[B]** Joburile co-op oferă roluri distincte precum șofer, observator, negociator și executant sau fiecare poate face orice?

150. **[B]** Cum se adaptează jobul la 1–4 jucători: obiective simultane, timp, dificultate, adversari și recompense?

151. **[B]** Ce se întâmplă când cineva intră, se deconectează sau revine în mijlocul jobului?

152. **[B]** Cum se împart recompensele și ce se întâmplă la eșec: egal, după contribuție, negociat, checkpoint, consecințe persistente sau continuare cu plată redusă?

## 16. Crimă, martori, poliție, mafie și închisoare — întrebările 153–166

153. **[B]** Wanted-ul, cazierul și consecințele sunt strict individuale sau anumite infracțiuni compromit întreaga echipă?

154. Ce trebuie să știe un martor pentru un raport util: fapta, fața, hainele, vocea, arma, vehiculul și numărul lui?

155. Raportarea este instant sau martorul trebuie să scoată telefonul, să fugă ori să ajungă la poliție?

156. Poți convinge, mitui, amenința sau imobiliza un martor și ce consecințe suplimentare are fiecare metodă?

157. Camerele de securitate sunt vizibile, evitabile, dezactivabile și pot avea înregistrări șterse/recuperate?

158. Identificarea folosește fața, vocea, hainele, amprentele, ADN-ul, arma și numărul mașinii? Ce ascund masca și mănușile?

159. **[B]** Ce dovezi fizice intră în prima versiune și care rămân persistente după descărcarea zonei?

160. **[B]** Care sunt treptele răspunsului poliției: verificare, oprire, urmărire, blocaje, unități armate, elicopter și investigație ulterioară?

161. **[B]** Poliția vine numai din unități existente care se deplasează fizic sau poate apărea controlat în afara privirii?

162. Cum scapi și cum te predai: ruperea contactului, schimbarea hainelor/mașinii, ascundere, rezolvarea dovezilor, surrender voluntar?

163. Când devii complice pentru un prieten urmărit: simpla prezență, conducerea mașinii, o acțiune concretă sau ignorarea unui ordin?

164. Mafia este o singură organizație sau mai multe familii? Reputația este individuală, comună grupului sau ambele?

165. Vrei polițiști corupți, informatori, mită, protecție și conflicte poliție–mafie independente de jucător?

166. **[B]** Închisoarea este gameplay complet, zonă cu activități limitate, secvență scurtă sau salt de timp? Pot prietenii ajuta legal ori ilegal?

## 17. Combat, arme și damage — întrebările 167–175

167. Confirmi că o carieră legală poate evita aproape complet combat-ul, iar o carieră violentă îl poate face frecvent fără a schimba letalitatea de bază?

168. **[B]** Definește letalitatea: câte lovituri obișnuite de pistol în trunchi suportă un om neprotejat și cât de des o lovitură la cap este fatală?

169. **[B]** Gloanțele folosesc proiectile cu viteză/cădere, calcul instant la distanțe mici sau un sistem hibrid?

170. Ce arme intră în nucleul inițial: pumni, arme improvizate, cuțite, pistoale, shotgun, SMG și puști?

171. Cum sunt obținute armele și cât de rare sunt: licență, magazin legal, piață ilegală, furt, crafting sau recompense?

172. Armele sunt vizibile pe corp, ascunse sub haine sau transportate în geantă/vehicul? Ce observă civilii și poliția?

173. Cât de detaliată este manipularea: recoil, încărcătoare păstrate, glonț pe țeavă, blocaje, curățare și uzură?

174. Vrei damage pe zone, armură cu acoperire reală, penetrare prin materiale și ricoșeu?

175. Cât de profund este melee-ul: lovituri simple, blocaj/esquivă, grappling, imobilizare și folosirea mediului?

## 18. Vehicule și trafic — întrebările 176–185

176. **[B]** Ce senzație de condus urmărești: arcade realist, simulare accesibilă, realism dur sau comportament diferit pe categorii?

177. **[B]** Damage-ul vehiculului este vizual, afectează motorul/roțile/direcția sau include deformare fizică avansată?

178. Vrei transmisie automată implicită și manuală opțională? Ce asistențe pot fi dezactivate: ABS, tracțiune și stabilitate?

179. **[B]** Mașinile personale rămân exact unde au fost parcate, cu damage și combustibil, sau sunt recuperate automat în garaj?

180. Cum funcționează cheile, permisiunile, încuierea, spargerea, hotwire-ul și furtul cheilor?

181. Combustibilul diferă după vehicul și stilul de condus? Alimentarea durează, poate fi întreruptă și permite canistre/ajutor?

182. Cât de detaliate sunt întreținerea, defecțiunile, reparațiile, asigurarea, tractarea și recuperarea unei mașini distruse?

183. Ce upgrade-uri persistente permiți: motor, suspensie, frâne, anvelope, blindaj, vopsea, sunet și interior?

184. **[B]** Confirmi că traficul îndepărtat este simulat simplificat și devine fizic complet numai lângă jucători?

185. Ce reguli rutiere sunt aplicate: viteza, semafoarele, camerele, parcarea, numărul de înmatriculare, opririle și confiscarea?

## 19. UI, audio, voice chat și accesibilitate — întrebările 186–195

186. **[B]** UI-ul este minimalist și integrat în lume, bazat pe telefon, HUD clasic sau combinație?

187. HUD-ul este permanent, apare contextual sau poate fi configurat complet?

188. Nevoile și starea folosesc procente exacte sau termeni naturali precum „flămând”, „obosit” și „rănit”?

189. Vrei minimap permanent, hartă mare, GPS cu traseu, indicatoare în lume sau combinație?

190. Telefonul este interfața principală pentru joburi, bancă, hartă, contacte, cumpărături și mesaje?

191. Cum îi vezi pe prieteni: contur prin pereți, marker, hartă, ping contextual sau fără ajutor supranatural?

192. **[B]** Vrei voice chat integrat și cum funcționează: canal de grup, proximitate, telefon în joc sau combinație?

193. Cât de realist este sunetul: ocluzie prin pereți, ecou în interioare, distanțe reale și identitate sonoră pe cartiere?

194. Muzica folosește ambient, radio în mașini și locații, piese originale și/sau muzică licențiată?

195. **[B]** Ce limbi și opțiuni de accesibilitate sunt obligatorii la lansare: subtitrări, speaker labels, text mărit, daltonism, indicatoare sonore și reducerea mișcării camerei?

## 20. Producție, asset-uri, Codex și lansare — întrebările 196–200

196. **[B]** Proiectul Unreal există deja? Care este calea, ce funcționează acum și sunt instalate Visual Studio, SDK-urile și toolchain-ul pentru UE 5.8.1?

197. **[B]** Confirmi că Codex poate modifica direct proiectul, compila și rula testele, iar tu intervii pentru decizii, asset-uri și pașii vizuali explicați exact în Unreal Editor?

198. **[B]** Confirmi regula: C++ pentru gameplay, networking, save, economie, AI și performanță; Blueprint pentru animații, UI, cinematics, configurarea asset-urilor și excepții aprobate?

199. **[B]** Ce programe folosești pentru asset-uri și accepți un pipeline obligatoriu pentru scară, pivot, nume, foldere, materiale, coliziuni, Nanite/LOD/HLOD, plus Source Art separat de repo-ul jocului?

200. **[B]** Lansarea dorită este Early Access sau versiune completă și care este pragul minim înainte de a cere bani: suprafață, joburi, vehicule, proprietăți, ore de conținut și nivel de stabilitate?

---

## Ordinea recomandată pentru răspunsuri

- Mai întâi toate întrebările `[B]` din 1–75 — fixează arhitectura și infrastructura.
- Apoi 76–142 — fixează player-ul, viața și economia.
- Apoi 143–185 — fixează joburile, criminalitatea, combat-ul și vehiculele.
- La final 186–200 — fixează prezentarea și procesul de producție.

După fiecare lot de răspunsuri, Codex va:

- rezuma deciziile fără a le reinterpreta greșit;
- identifica contradicțiile și compromisurile;
- propune o recomandare pentru răspunsurile `NU ȘTIU`;
- actualiza roadmap-ul și documentele sistemelor;
- separa ce este stabilit pentru v1 de ce este amânat.
