# System Design PoCs

Personal repository for system design notes, mock interview exercises, PoC evaluations, and consulting sketches.

Diagrams use the [C4 model](https://c4model.com/) rendered from [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML) source files.

## Workflow

1. Describe your architecture in Cursor chat, including the **C4 level** (Context, Container, Component, Dynamic, or Deployment).
2. The agent previews the diagram in chat (elements, relationships, draft PlantUML) and waits for your approval.
3. After you give the green light, the agent writes `.puml` files under `designs/<slug>/` and renders SVG output.

You own the architecture. The agent translates your description into C4 notation — it does not invent components or relationships.

## Repository layout

```
designs/
└── <slug>/
    ├── README.md          # Problem, requirements, assumptions, tradeoffs
    ├── context.puml       # Only the diagram levels you requested
    ├── container.puml
    └── diagrams/          # Generated SVG (gitignored; run render.sh to recreate)
scripts/
└── render.sh              # Render .puml files via Docker
```

## Render diagrams

Requires Docker.

```bash
# Render all designs that have .puml files
./scripts/render.sh

# Render one design
./scripts/render.sh subscription-billing
```

Output is written to `designs/<slug>/diagrams/`. Default format is SVG. Override with:

```bash
PLANTUML_FORMAT=png ./scripts/render.sh my-design
```

## Cursor skill

The project skill at `.cursor/skills/c4-system-design/SKILL.md` enforces the preview-first workflow. Invoke it when creating or updating C4 diagrams in this repo.

## Phase 1 preview example

When you describe a design in chat, the agent shows a preview **before writing any files**. Example for a Context diagram:

**You:** Context diagram for subscription billing. Persons: Admin, Subscriber. External: Stripe, SendGrid. In scope: Billing Platform.

**Agent preview (no files written yet):**

| Name | Type | Technology | Description |
|------|------|------------|-------------|
| Admin | Person | — | Manages billing configuration |
| Subscriber | Person | — | Uses subscription services |
| Billing Platform | System | — | In-scope billing system |
| Stripe | System_Ext | — | Payment processing |
| SendGrid | System_Ext | — | Transactional email |

| From | To | Label | Technology |
|------|----|-------|------------|
| Admin | Billing Platform | Manages | HTTPS |
| Subscriber | Billing Platform | Uses | HTTPS |
| Billing Platform | Stripe | Processes payments | HTTPS |
| Billing Platform | SendGrid | Sends email | HTTPS |

Plus a draft PlantUML block in chat for review. After you say **green light**, the agent writes `designs/subscription-billing/context.puml` and runs `./scripts/render.sh subscription-billing`.

**Note:** Rendering requires Docker to be running locally.
