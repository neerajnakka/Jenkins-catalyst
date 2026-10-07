# 🚀 Jenkins Zero → Hero

**One repo · one document · 25 blocks.** Learn Jenkins the way it's actually used at work — by building two real services (Node.js + Python) and growing their pipelines block by block, from `echo "hello"` to a signed, scanned, deployed container.

> Written for a beginner in technical language: *why* first, then *what*, then copy-paste *how*.

---

## 📖 The document

**→ [`docs/jenkins-complete-guide.html`](docs/jenkins-complete-guide.html)** — open it in a browser.

A self-contained HTML book — **~133 printed pages, ~57,000 words**. No internet needed, no build step: just open it.

- 🎨 Light/dark themes, command palette (`Ctrl/Cmd + K`), scroll-spy sidebar + on-this-page rail
- 📋 **Copy button on all 216 code blocks**, with language-aware syntax highlighting
- 🗂️ **Node | Python tabs** wherever the two stacks differ
- ✅ Checklists that **save your progress** in the browser
- 🎤 **266 interview Q&A** in click-to-expand accordions
- 🔬 **25+ hands-on labs** that break things on purpose, then fix them
- 📊 101 reference tables · ASCII architecture diagrams
- 🖨️ `Ctrl/Cmd + P` → clean PDF (nav hides, answers auto-expand)

| Block | Topic | Block | Topic |
|---|---|---|---|
| 0 | How to use this guide | 13 | Nodes, agents, labels, tools |
| 2 | Declarative pipeline anatomy | 14 | Shared Libraries |
| 3 | Snippet Generator & tooling | 15 | Multibranch Pipelines |
| 4 | Git + GitHub integration | 16 | DevSecOps · SAST (SonarQube) |
| 5 | BUILD stage — Node & Python | 17 | DevSecOps · SCA & secrets |
| 6 | TEST stage + reports & gates | 18 | DevSecOps · image scan, SBOM, DAST |
| 7 | Environment variables & parameters | 19 | Deploy stages + rollback |
| 8 | Credentials & secrets | 20 | Notifications & approvals |
| 9 | Docker build & push | 21 | Parallel, matrix, timeout, retry, lock |
| 10 | Webhooks & triggers | 22 | Backup, upgrade, maintenance |
| 11 | `post{}` mastery | 23 | Troubleshooting playbook |
| 12 | RBAC, users & permissions | 24 | Interview kit · 60-second pitch |

---

## 🗺️ Repo map

```
jenkins-zero-to-hero/
├── README.md
├── docs/
│   ├── jenkins-complete-guide.html      ← THE guide (25 blocks, 625 KB, self-contained)
│   ├── _shell.html                      ← design system (edit this for look & feel)
│   ├── blocks/block-{0..24}.html        ← content source of truth
│   └── (rebuild with: python3 ../scripts/build-doc.py)
│
├── nodejs-app/                          ← Express REST API · Node 20
│   ├── src/{app.js,server.js,routes/items.js}
│   ├── tests/app.test.js                ← Jest + Supertest · 8 tests · coverage gate 70%
│   ├── Dockerfile                       ← multi-stage · non-root · HEALTHCHECK
│   ├── Jenkinsfile                      ← FINAL v20: full DevSecOps pipeline
│   └── sonar-project.properties
│
├── python-app/                          ← Flask REST API · Python 3.12
│   ├── app.py
│   ├── tests/test_app.py                ← pytest · 8 tests · coverage gate 70%
│   ├── Dockerfile                       ← venv multi-stage · gunicorn · non-root
│   ├── Jenkinsfile                      ← FINAL v20: full DevSecOps pipeline
│   └── sonar-project.properties
│
├── jenkins/
│   ├── ec2-install.sh                   ← one-shot Jenkins + Docker install (Ubuntu 24.04)
│   ├── plugins.txt                      ← curated plugin manifest (all 24 blocks)
│   ├── jenkins.yaml                     ← JCasC: the whole controller as code
│   ├── shared-library/                  ← Block 14 (own Git repo in real life)
│   │   ├── vars/{standardPipeline,runTests,buildAndPushImage,notifyBuild}.groovy
│   │   ├── src/com/example/ci/Versions.groovy
│   │   └── resources/scripts/smoke-test.sh
│   ├── sonarqube/docker-compose.yml     ← Block 16: SAST server
│   └── deploy/docker-compose.yml        ← Block 19: deploy target
│
└── scripts/
    ├── validate-jenkinsfile.sh          ← lint a Jenkinsfile without running it
    ├── jenkins-backup.sh                ← nightly backup + master.key handling
    └── install-security-tools.sh        ← Trivy, gitleaks, syft, cosign
```

Both apps expose **identical endpoints** on purpose, so every concept is practised twice:

| Endpoint | Node.js (`:3000`) | Python (`:5000`) |
|---|---|---|
| `GET /health` | ✅ | ✅ |
| `GET /` | ✅ | ✅ |
| `GET /api/items` | ✅ | ✅ |
| `POST /api/items` | ✅ (400 on bad body) | ✅ |
| `GET /api/items/:id` | ✅ (404 unknown) | ✅ |
| `DELETE /api/items/:id` | ✅ | ✅ |

---

## ⚡ Quick start

### 0. Push this repo to GitHub (you need your own copy — the webhook is yours)

```bash
cd jenkins-zero-to-hero
git init -b main
git add . && git commit -m "Jenkins zero to hero: two apps, shared library, full guide"

# create an empty repo on GitHub (no README/licence), then:
git remote add origin git@github.com:<you>/jenkins-zero-to-hero.git
git push -u origin main
```

Then do these three things **before** Block 9 (Docker push) and Block 15 (Multibranch):

1. `nodejs-app/Jenkinsfile` and `python-app/Jenkinsfile` → replace `DOCKER_USER = 'REPLACE_ME'` with your Docker Hub username.
2. Block 4 → add the Jenkins server's SSH **public** key as a GitHub deploy key (read-only is enough).
3. Block 10 → Settings → Webhooks → `http://<EC2-PUBLIC-IP>:8080/github-webhook/` (or `/multibranch-webhook-trigger/invoke` for the plugin-based approach).

> 💡 The shared library in `jenkins/shared-library/` is meant to live in **its own** repo in real life — Block 14 explains why. Push it as `jenkins-shared-library` and point *Manage Jenkins → System → Global Pipeline Libraries* at it.

### 1. Bring up Jenkins (AWS EC2 · Ubuntu 24.04)

```bash
bash jenkins/ec2-install.sh
# open http://<EC2-PUBLIC-IP>:8080 and paste the unlock password it prints
```

Open port `8080` (and `22`) in the security group **for your IP only**. Use `t3.medium` + 30 GB.

### 2. Run the apps locally (optional — helps you understand what Jenkins is building)

```bash
# Node.js
cd nodejs-app && npm install && npm test && npm start     # http://localhost:3000/health

# Python
cd python-app && python3 -m venv venv && ./venv/bin/pip install -r requirements-dev.txt
./venv/bin/python -m pytest && ./venv/bin/python app.py   # http://localhost:5000/health
```

Both suites are **green** (8 tests each; 77% / 90% coverage) and both enforce a coverage gate.

### 3. Create the two pipeline jobs

For each app: `New Item` → **Pipeline** → *Pipeline* section → **Definition: Pipeline script from SCM** → SCM **Git** → repo URL → **Script Path** `nodejs-app/Jenkinsfile` or `python-app/Jenkinsfile` → **Save** → **Build Now**.

From Block 15 onward, use **Multibranch Pipeline** jobs instead — one per app, same script paths.

### 4. Credentials you must create (Block 8)

| ID | Kind | Used for |
|---|---|---|
| `github-ssh` | SSH Username with private key | cloning the repo |
| `github-pat` | Username with password | GitHub API (Multibranch) |
| `dockerhub-creds` | Username with password | pushing images (use an access token) |
| `sonar-token` | Secret text | SonarQube analysis |
| `deploy-key` | SSH Username with private key | deploying over SSH |
| `slack-bot` | Secret text | notifications |

---

## 🧭 How to study (this matters)

1. **Read one block. Then do it.** Each ends with a checklist — if you can't tick it, you're not done.
2. **Type, don't blindly paste.** Change something and see what breaks.
3. **Break things on purpose.** The error tables come from failures you should cause yourself at least once.
4. **Use Replay** (job → Replay) to iterate without committing. Commit only when green.
5. **Do everything twice** — Node way and Python way. That's what makes you useful on any repo.

---

## 🧰 Stack

| Layer | Choice |
|---|---|
| Cloud | AWS EC2 (Ubuntu 24.04 LTS, t3.medium, 30 GB) |
| CI server | Jenkins LTS on Java 21 |
| Git | GitHub + webhooks |
| Registry | Docker Hub |
| Node service | Node 20 · Express 4 · Jest · Supertest · ESLint |
| Python service | Python 3.12 · Flask 3 · Gunicorn · pytest · flake8 · Bandit · pip-audit |
| Security | SonarQube · Trivy · gitleaks · Syft (SBOM) · cosign · OWASP ZAP |
| Ops | JCasC · ThinBackup · shared libraries · RBAC · labelled agents |

---

Made for one goal: **walk into a DevOps interview with a Jenkins story you actually built.** 🚀
