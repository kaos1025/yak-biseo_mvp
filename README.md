<p align="center">
  <img src="assets/icon/icon.png" alt="SuppleCut Logo" width="120" />
</p>

<h1 align="center">SuppleCut — AI Supplement Stack Analyzer</h1>

<p align="center">
  <strong>Scan your supplements. Find overlaps. Cut waste. Save money.</strong>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.supplecut.app">
    <img src="https://img.shields.io/badge/Google_Play-Closed_Beta-green?logo=google-play" alt="Google Play" />
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Gemini_Flash-Vision%2FOCR-4285F4?logo=google" alt="Gemini" />
  <img src="https://img.shields.io/badge/Claude_Sonnet-Reasoning-CC785C?logo=anthropic" alt="Claude" />
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License" />
</p>

---

## The Problem

The average American takes **4+ supplements daily**, spending **$56/month**. Most don't realize their stack contains redundant ingredients — sometimes exceeding safe Upper Limits (UL) without knowing it.

Even pharmacists can miss hidden overlaps buried in excipient-level ingredients like **Dicalcium Phosphate** (a common tablet binder that quietly adds calcium to your daily intake).

## The Solution

**SuppleCut** takes a photo of your supplement bottles, identifies every product using AI vision, and analyzes the entire stack for:

- 🔴 **Ingredient Overlaps** — Same nutrient from multiple products exceeding UL
- 🟡 **Mechanism Conflicts** — GABAergic, androgenic, blood-thinning pathway overlaps  
- ⚡ **UL Exceedance** — Single-product or cross-product Upper Limit violations
- ⚕️ **Drug Interactions** — Statin equivalents (Red Yeast Rice), thyroid conflicts, etc.
- 💰 **Cost Optimization** — Which supplement to cut, with monthly/annual savings

<p align="center">
  <img src="screenshots/playstore_v4_01.jpg" alt="Scan" width="180" />
  <img src="screenshots/playstore_v4_02.jpg" alt="Analysis" width="180" />
  <img src="screenshots/playstore_v4_03.jpg" alt="Overlap" width="180" />
  <img src="screenshots/playstore_v4_04.jpg" alt="Report" width="180" />
</p>

## Architecture

```
📸 Photo Input
    │
    ▼
┌─────────────────────────────────┐
│  Gemini Flash (Free Tier)       │
│  ─────────────────────────────  │
│  • Vision OCR → Product ID     │
│  • Ingredient Parsing           │
│  • Overlap Detection            │
│  • Mechanism Analysis           │
│  • UL Calculation               │
│  • Exclusion Recommendation     │
│  • Cost Savings Calculation     │
│  → overall_status (🟢🟡🔴)     │
└──────────────┬──────────────────┘
               │
    ┌──────────┴──────────┐
    ▼                     ▼
┌────────────┐    ┌────────────────────┐
│  App UI    │    │  Claude Sonnet     │
│  (Free)    │    │  ($1.99 IAP)       │
│            │    │  ────────────────  │
│  Traffic   │    │  5-Section Report  │
│  Light UX  │    │  • Stack Overview  │
│  🟢🟡🔴    │    │  • Overlap & UL    │
│            │    │  • Safety Alerts   │
│            │    │  • What to Cut     │
│            │    │  • How to Take     │
└────────────┘    └────────────────────┘
```

**Core Principle: "Decisions by Engine, Explanations by AI"**

- **Gemini** handles all deterministic decisions (OCR, overlap detection, UL calculation, exclusion logic)
- **Claude** handles narrative explanation only (never overrides Gemini's numbers)
- Prices always sourced from Play Billing API `formattedPrice` — never hardcoded

## Key Features

### 🔬 Excipient-Level Detection (Killer Feature)
Most analyzers only check active ingredients. SuppleCut detects hidden nutrients in inactive ingredients — like calcium from Dicalcium Phosphate tablet binders — that even pharmacists can miss.

### 🚦 4-Tier Exclusion System
| Tier | Color | Action |
|------|-------|--------|
| `critical_stop` | 🔴 Red | ⛔ Discontinue Immediately (Research chemicals) |
| `medical_supervision` | 🟣 Purple | ⚕️ Consult your doctor (Therapeutic doses) |
| `recommend_remove` | 🟠 Orange | Remove to reduce risk |
| `conditional_remove` | 🟡 Yellow | Remove only if condition applies |

### 📊 Validated Across 20 Test Cases
Pharmacist-reviewed analysis covering 3–12 products per case, including edge cases like:
- 7-product GABAergic pathway overlap detection
- Monacolin K = Lovastatin (prescription statin) identification in Red Yeast Rice
- Therapeutic dose medications (Palafer iron) — flagged for medical supervision, not removal
- Blood-thinning mechanism overlap (4+ products)

**Results:** 70% PASS+, 15% PASS, 0 launch blockers.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter/Dart (cross-platform) |
| **AI — Vision/OCR** | Google Gemini Flash |
| **AI — Reasoning** | Anthropic Claude Sonnet |
| **Payments** | Google Play Billing (IAP) |
| **Hosting** | Cloudflare Pages |
| **Development** | Claude Code (AI-assisted coding) |

## Business Model

| Tier | Content | Price |
|------|---------|-------|
| **Free** | Overlap detection + safety alerts (Gemini) | $0 |
| **Standard** | 5-section detailed report (Claude) | $1.99 |
| **Premium** | Full 13-page report (planned) | $4.99 |

**Target Market:** US health-conscious consumers (40-50 age group)  
**Distribution:** Google Play → iOS (planned) → Japan localization (H2 2027)

## Project Status

- ✅ 20/20 pharmacist-verified test cases passed
- ✅ Google Play closed beta (14-day testing in progress)
- ✅ In-app purchase integration tested on real device
- ✅ FDA disclaimer, Privacy Policy, Terms of Service
- 🔜 Production launch (April 2026)
- 🔜 iOS version
- 🔜 Korean Government Startup Grant (예비창업패키지) — application submitted

## Platform Vision

SuppleCut is the first product in an **AI ingredient analysis platform**:

| Product | Domain | Status |
|---------|--------|--------|
| **SuppleCut** | Supplement overlap analysis | 🟢 Beta |
| **PetCut** | Pet food ingredient analysis | 💡 Planned |
| **Trouble Detective** | Skincare conflict analysis | 💡 Planned |

## Links

- 🌐 [supplecut.com](https://supplecut.com)
- 📧 [support@supplecut.com](mailto:support@supplecut.com)
- 📱 [Google Play (Beta)](https://play.google.com/store/apps/details?id=com.supplecut.app)

---

<p align="center">
  <sub>Built by a solo developer with 18 years of backend experience, AI-assisted coding, and a lot of supplements.</sub>
</p>
