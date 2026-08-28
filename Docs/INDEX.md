# Indexul documentației

Acesta este routerul de lectură al proiectului. Nu conține design nou.

| Document | Adevărul pe care îl deține | Când se citește |
|---|---|---|
| `AGENTS.md` | contractul permanent al agenților | înainte de orice lucru |
| `Docs/STATUS.md` | ce există efectiv, task activ și următorul pas | la începutul fiecărui task |
| `Docs/VISION.md` | promisiunea produsului și pilonii experienței | design, scope, prioritizare |
| `Docs/DECISIONS.md` | deciziile de produs confirmate și statutul celor deschise | înainte de designul unui sistem |
| `Docs/PENDING_DECISIONS.md` | întrebările materiale rămase, grupate după gate | când milestone-ul le poate măsura |
| `Docs/NON_GOALS.md` | ceea ce nu construim acum | estimare și protecția scope-ului |
| `Docs/ARCHITECTURE.md` | granițe tehnice și fluxuri cross-system | înainte de cod ori config arhitectural |
| `Docs/SYSTEM_OWNERSHIP.md` | cine poate modifica fiecare adevăr runtime | orice task ce atinge mai multe domenii |
| `Docs/ROADMAP.md` | ordinea viitoare, dependențe și gates | planificare și alegerea task-ului următor |
| `Docs/REFERENCE_POLICY.md` | clean-room, copyright și licențe | research, conținut ori dependențe externe |
| `Docs/Build/TOOLCHAIN.md` | versiuni și proceduri de build | setup, build, regenerare, upgrade |
| `Docs/Build/PLUGIN_AND_LICENSE_MANIFEST.md` | pluginuri/dependințe și licențele lor | înainte de orice integrare externă |
| `Docs/Systems/README.md` | catalogul documentelor de sistem existente | înainte de a crea/modifica un sistem |
| `Docs/Systems/SYSTEM_TEMPLATE.md` | structura obligatorie a unui system design | când sistemul intră în `Ready` |
| `Docs/Decisions/README.md` | regula ADR și indexul deciziilor arhitecturale | decizii cross-system greu de inversat |
| `Docs/Tasks/README.md` | stările și regulile task packets | alegerea și urmărirea unui task |
| `Docs/Tasks/TASK_TEMPLATE.md` | contractul unui task `BS-###` | înainte de implementare |
| task packet-ul activ `Docs/Tasks/BS-###-*.md` | rezultatul, scope-ul autorizat și dovada task-ului curent | pe toată durata task-ului |
| `Docs/Workflows/CODEX_TASK_WORKFLOW.md` | procesul complet de execuție | orice schimbare de cod ori asset |
| `Docs/Workflows/DEFINITION_OF_DONE.md` | gate universal și verificări condiționale | înainte de handoff/merge |
| `Docs/Workflows/USER_COMPILE_GUIDE.md` | pașii exacți pentru compilarea de către creator | după schimbări C++ |
| `Docs/Workflows/EDITOR_INSTRUCTION_STANDARD.md` | formatul pașilor manuali | orice handoff cu Unreal Editor |
| `Docs/Workflows/GIT_WORKFLOW.md` | branch, commit, merge și rollback | orice task versionat |
| `Docs/Workflows/RECOVERY_AND_ROLLBACK.md` | clean clone, backup și restaurare | recovery drill ori incident |
| `Docs/Testing/TEST_STRATEGY.md` | nivelurile de test și matricea multiplayer | designul acceptării și verificare |
| `Docs/Performance/BUDGETS.md` | ținte și bugete măsurate/provizorii | orice hot path sau benchmark |
| `Docs/Performance/BENCHMARK_SCENARIOS.md` | scenariile standard comparabile | profiling și gates de scalare |

## Reguli de navigare

- Separă autoritatea pe trei axe: cererea + task packet-ul spun ce este autorizat; repository-ul + dovezile + STATUS spun ce există; DECISIONS/ADR/system/architecture spun ce trebuie construit.
- Nu citi întregul roadmap pentru un typo sau o modificare izolată de documentație.
- Pentru design de produs citește numai secțiunea relevantă din `DECISIONS.md`, plus `VISION.md` și `NON_GOALS.md`.
- Pentru cod citește arhitectura, ownership-ul, documentul sistemului și ADR-urile relevante.
- Documentele din `Docs/Archive/` sunt non-normative. Dacă diferă de documentele canonice, cele canonice câștigă.
- Un document planificat nu dovedește că implementarea există. Commitul verificat, codul/configul/contentul și dovezile reproductibile decid realitatea; `STATUS.md` trebuie să le rezume și se corectează când diferă.
