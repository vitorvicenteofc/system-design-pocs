---
name: c4-system-design
description: >-
  Create and update C4 model diagrams in this repo from user-provided architecture
  descriptions. Use when the user asks for system design diagrams, C4 context/container/
  component/dynamic/deployment diagrams, or PlantUML C4 files under designs/. Enforces
  preview-first workflow — never write repo files until the user explicitly approves.
  Also use when the user invokes /c4-system-design from any workspace.
---

# C4 System Design (PlantUML)

Personal system-design repo. Diagrams are created **ad hoc from the user's description**, not from codebase analysis.

**The user owns the architecture.** Translate their intent into correct C4-PlantUML. Do not invent elements, containers, or relationships.

## Repo root and global command

| Item | Path |
|------|------|
| **Repo root** | `/Users/vitorvicente/Documents/it-projects/system-design-pocs` |
| **Global slash command** | `/c4-system-design` (from any workspace) |
| **Command config** | `~/.cursor/c4-system-design.config.json` → `repoRoot` |

When invoked via `/c4-system-design`, read the user command at `~/.cursor/commands/c4-system-design.md` first (AskQuestion for C4 level, pipeline guide), then follow this skill. All file I/O stays under `repoRoot`; call `move_agent_to_root` before Phase 2 if needed.

## When to use

- User describes a system and wants a C4 diagram
- User asks to add or update a diagram in `designs/<slug>/`
- User mentions Context, Container, Component, Dynamic, or Deployment level
- User wants to render existing `.puml` files

## Two-phase workflow (mandatory)

**Never write files under `designs/` until the user gives explicit approval** (e.g. "looks good", "go ahead", "green light", "ship it").

### Phase 1 — Discovery and preview (no file writes)

1. **Acknowledge the C4 level** the user stated.
2. **Ask clarifying questions** only when something blocks a faithful diagram (missing names, unclear direction, ambiguous in-scope vs external). Do not invent missing pieces.
3. **Suggest improvements** when appropriate (e.g. ambiguous cache placement, unnamed external system).
4. **Show a markdown preview:**
   - **Elements** — name, C4 type, technology (if any), description
   - **Relationships** — from → to, label, protocol/technology
   - Optional: ASCII or Mermaid layout sketch
   - **Draft PlantUML** in a fenced `plantuml` code block (for review only — not saved yet)
5. **Wait for green light.** If the user requests changes, update the preview and wait again.

### Phase 2 — Commit to repo (after approval only)

1. Ensure workspace is this repo (`move_agent_to_root` if needed).
2. Create or update `designs/<slug>/` (kebab-case slug from system name).
3. Write only the **approved** `.puml` file(s) for the C4 level(s) the user specified.
4. Update `designs/<slug>/README.md` with the user's notes (problem, requirements, assumptions, tradeoffs).
5. Run `./scripts/render.sh <slug>` (Docker required).
6. Report written paths and rendered output under `designs/<slug>/diagrams/`.

Re-render on explicit request without re-approval if `.puml` content is unchanged. If diagram content changes, return to Phase 1 unless the user explicitly approves the new preview.

## Rules

| Rule | Detail |
|---|---|
| User owns architecture | Never add elements or relationships not described or approved |
| Respect C4 level | Only produce diagram type(s) the user specifies |
| Preview before write | Phase 1 always; no `designs/` writes without approval |
| Clarify, don't assume | Ask when blocked; suggest alternatives; don't fill gaps silently |
| No codebase required | Input comes from user description only |
| No extra diagrams | Don't auto-generate other C4 levels unless asked |

## C4 levels and includes

| Level | File name | C4-PlantUML include |
|---|---|---|
| Context | `context.puml` | `C4_Context.puml` |
| Container | `container.puml` | `C4_Container.puml` |
| Component | `component.puml` | `C4_Component.puml` |
| Dynamic | `dynamic.puml` | `C4_Dynamic.puml` |
| Deployment | `deployment.puml` | `C4_Deployment.puml` |

Include header (adjust file for level):

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

title System Context diagram for <System Name>

' elements and relationships

@enduml
```

## C4 element reference

**Context:** `Person`, `Person_Ext`, `System`, `System_Ext`, `SystemDb`, `SystemQueue`, `System_Boundary`, `Enterprise_Boundary`

**Container:** `Container`, `ContainerDb`, `ContainerQueue`, `Container_Ext`, `ContainerDb_Ext`, `ContainerQueue_Ext`, `Container_Boundary`

**Component:** `Component`, `ComponentDb`, `ComponentQueue`, `Component_Ext`, `ComponentDb_Ext`, `ComponentQueue_Ext`

**Relationships:** `Rel(from, to, "label", "technology")` or `BiRel(from, to, "label", "technology")`. Dynamic diagrams use numbered `Rel()`.

**Conventions:**
- `_Ext` suffix for external actors/systems/containers
- Technology tags on containers and components
- Descriptive relationship labels; add protocol where the user specifies it
- `System_Boundary` / `Container_Boundary` to group in-scope elements

## Preview template

Use this structure in Phase 1:

```markdown
## Preview: <System Name> — <C4 Level>

### Elements
| Name | Type | Technology | Description |
|------|------|------------|-------------|
| ... | Person | — | ... |

### Relationships
| From | To | Label | Technology |
|------|----|-------|------------|
| ... | ... | ... | HTTPS |

### Draft PlantUML
(fenced plantuml block)
```

## Slug naming

- kebab-case from system name: `subscription-billing`, `rate-limiter`
- One folder per design under `designs/`
- Only create `.puml` files the user requested and approved

## Rendering

Docker only — no Homebrew/Java fallback:

```bash
./scripts/render.sh              # all designs with .puml files
./scripts/render.sh <slug>       # one design
PLANTUML_FORMAT=png ./scripts/render.sh <slug>
```

Output: `designs/<slug>/diagrams/*.svg` (gitignored; regenerate anytime).

## Phase 1 example

**User:** Context diagram for subscription billing. Persons: Admin, Subscriber. External: Stripe, SendGrid. In scope: Billing Platform.

**Agent (Phase 1 — no files):**

- Confirm Context level
- Ask only if relationship labels or scope are unclear
- Show elements table, relationships table, draft PlantUML
- Wait for approval

**User:** Green light.

**Agent (Phase 2):** Write `designs/subscription-billing/context.puml`, update README, run `./scripts/render.sh subscription-billing`.
