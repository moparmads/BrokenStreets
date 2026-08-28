# Git workflow și rollback

## Repository

- root: `F:/BrokenStreets`;
- remote: `https://github.com/moparmads/BrokenStreets.git`;
- default branch: `main`;
- repository: privat;
- Git LFS: obligatoriu pentru `.uasset` și `.umap`.

## Flux per task

1. Verifică branch, `git status` și base commit.
2. Dacă există modificări necunoscute ori overlapping, oprește-te și explică.
3. Actualizează task packet-ul la `Ready`.
4. Creează branch:
   - `feature/BS-###-short-name`;
   - `fix/BS-###-short-name`;
   - `docs/BS-###-short-name`.
5. Pentru orice asset binar, obține lock-ul LFS înainte de deschiderea/editarea lui.
6. Fă modificări mici și în scope.
7. Inspectează separat working tree-ul și indexul: `git status --short --branch`, `git diff HEAD`, `git diff --cached --name-status`, `git diff --cached --check`, generated files și `git lfs status`.
8. Creează un commit candidat atomic pe branch. Nu îl considera acceptat doar pentru că există.
9. Rulează verificările proporționale pe commitul candidat/tree-ul exact. Madalin compilează/playtestează când este necesar. Orice fix produce un candidat nou și invalidează dovada veche pentru fișierele runtime afectate.
10. Actualizează task/status/evidence. Un commit ulterior numai cu documentația dovezii poate referi candidatul verificat; nu trebuie să schimbe C++, Config, Content, `.uproject`, pluginuri ori build scripts.
11. Push branch, review/merge în `main`, apoi push `main`.
12. Confirmă că `main` local și remote au același commit, obiectele LFS sunt pe remote și working tree-ul este curat. Eliberează lock-urile binare numai după această confirmare.

## Commit messages

Format recomandat:

```text
docs: establish BS-008 project memory
feat: add BS-014 stable identifiers
fix: prevent duplicate BS-043 transactions
test: cover BS-024 profile recovery
chore: pin BS-009 build toolchain
```

Descrie rezultatul, nu activitatea vagă „updates”. Include ID-ul task-ului când ajută trasabilitatea.

## Asset-uri binare

- `.uasset/.umap` trebuie să fie LFS pointers.
- Un asset binar nu este editat în două branch-uri în paralel.
- Editorul este închis înainte de rollback/revert al unui asset încărcat.
- Înainte de editare: `git lfs locks`, apoi `git lfs lock "Content/path/Asset.uasset"`. Dacă lock-ul lipsește, eșuează ori aparține altcuiva, nu edita asset-ul.
- După staging: `git check-attr filter diff merge lockable -- "Content/path/Asset.uasset"`, `git lfs status` și `git lfs ls-files`. Pentru fiecare blob staged verifică pointerul din index, nu fișierul smudged din working tree: `git show ':Content/path/Asset.uasset' | git lfs pointer --check --stdin`; orice cod de ieșire nenul oprește commitul. După commitul candidat rulează și `git lfs fsck --pointers HEAD` pentru pointere canonice.
- Înainte de push: `git lfs push --dry-run origin HEAD` arată obiectele pending; după push verifică remote-ul și lock ownerul.
- După merge/push confirmat: `git lfs unlock "Content/path/Asset.uasset"`. Nu folosi `--force` fără aprobarea explicită și cauza documentată.
- Nu muta/renumi asset-uri în File Explorer; folosește Unreal Editor și fix redirectors în task explicit.

Primele lock/pointer/push/unlock sunt exercitate controlat în BS-007B. Până atunci nu presupunem că simpla prezență a `.gitattributes` dovedește workflow-ul complet.

## Dovada legată de candidat

Task packet-ul notează cel puțin:

- candidate commit hash și, când merge-ul adaugă numai metadata, runtime/content tree verificat;
- lista exactă a comenzilor/testelor, targetul și build configuration;
- cine a executat verificarea și pe ce engine/hardware/topologie;
- orice fișier runtime schimbat după test, caz în care dovada este `INVALIDATED` până la rerulare.

`git diff` fără argumente vede numai modificările unstaged. Pentru auditul livrării folosește `git diff HEAD` și verifică explicit indexul; altfel un task complet staged poate părea fals gol.

## Interdicții

- fără `git reset --hard`;
- fără force push pe `main`;
- fără checkout/restore destructiv peste munca utilizatorului;
- fără stash automat ce ascunde modificări necunoscute;
- fără rescrierea istoricului LFS în grabă;
- fără commit de secrets, Saved/Intermediate/Binaries/cache ori Source Art.

## Rollback

Pentru o schimbare deja acceptată/pushed:

1. identifică commitul exact;
2. verifică impactul save/assets/migrations;
3. creează branch `fix/BS-###-rollback-*` dacă rollback-ul nu este trivial;
4. folosește `git revert` pentru istoric public;
5. rebuild/test/restore după revert;
6. actualizează STATUS și ADR/system docs dacă decizia se schimbă.

Un revert de cod nu garantează compatibilitatea unui save ori asset salvat cu versiunea nouă. Planul de rollback se scrie înaintea schimbării de schemă.

## Tag-uri

Tag numai pentru:

- baseline recuperabil important;
- vertical slice gate;
- release candidate/release;
- save migration checkpoint major.

Nu tag-ui fiecare task.
