# Draft publication lifecycle

A **draft** is an unpublished work, visible only to its **depositor and admins**.
A draft is later **published** through a manual workflow action, at which point the
chosen active visibility (open, authenticated, restricted) cascades recursively
through the work's entire membership tree - its file sets, its child works, and
their file sets, to any depth.

The capability is **feature-flipped and off by default**.

## Design

"Draft" is a **publication-lifecycle stage**, so it is driven by Hyrax's existing
**Sipity workflow** - the same machinery as mediated deposit, but the reviewer's
"approve" screen is a "publish" screen. The workflow supplies the promotion trigger,
catalog hiding (suppression), the "who may publish" role gate, and the
audit/notification trail.

- **Deposit** puts the work into the `draft` state via `DeactivateObject`
  (`state = INACTIVE`, so it is suppressed and hidden from the catalog) and
  `GrantEditToDepositor` (so the depositor retains access). Draft access therefore
  falls out of native Hyrax: the depositor reaches the work through My Works and its
  show page (edit access + `FilterSuppressedWithRoles`), admins see everything, and
  everyone else is denied by suppression + restricted visibility. No new visibility
  value and no per-object marker are introduced.
- **Publish** (`activate`) applies the chosen visibility to the work and cascades it
  through the full membership tree.

While in draft, visibility stays `restricted` and the work is suppressed.

## Moving parts

| Concern | Location |
|---------|----------|
| Feature flag | `config/features.rb` -> `draft_permission` (default `false`) |
| Draft workflow | `lib/generators/hyrax/templates/draft_workflow.json.erb` (installed to `config/workflows/draft_workflow.json`) |
| Recursive cascade | `Hyrax::Workflow::ActivateDraftCascade` + `Hyrax::ActivateDraftCascadeJob` |
| Chosen visibility pass-through | `WorkflowActionsController` -> `Forms::WorkflowActionForm` -> `Workflow::WorkflowActionService` -> `Workflow::ActionTakenService` forward an optional `target_visibility` kwarg to the workflow methods |
| "Published" notification | `Hyrax::Workflow::PublishedNotification` + `hyrax.notifications.workflow.published.*` |
| Action gating | `Hyrax::WorkflowPresenter#actions` hides draft-workflow actions when the flag is off |
| UI + i18n | `app/views/hyrax/base/_workflow_actions.html.erb`, `hyrax.workflow.draft.*` locale keys |

## Enabling it

1. **Turn on the flag.** In the host app, enable `draft_permission` (via the Flipflop
   admin UI, `config/features.yml`, or a tenant-aware strategy). With the flag off the
   draft option and action are hidden everywhere and behavior is identical to today.

2. **Seed the draft workflow.** The install generator writes
   `config/workflows/draft_workflow.json`. Workflows are loaded by
   `Hyrax::Workflow::WorkflowImporter` (which uses `find_or_initialize_by`, so editing
   the JSON and reloading updates them), e.g. via the rake task:

   ```
   bundle exec rails hyrax:workflow:load
   ```

3. **Point a permission template at the draft workflow.** A work is governed by its
   admin set / permission template's `active_workflow`. Set that to the `draft`
   workflow for the admin sets that should deposit works as drafts, and grant the
   `approving` role to whoever may publish.

## The cascade

`Hyrax::Workflow::ActivateDraftCascade#call` runs on the `activate` action:

1. Reads the chosen `target_visibility` (default `open`).
2. Applies it to the root work (ActivateObject, also on the action, returns the root
   to the `ACTIVE` state).
3. Enqueues `Hyrax::ActivateDraftCascadeJob`, which walks the full membership tree
   (`find_child_works` + `find_child_file_sets`, recursing through child works) and
   applies the chosen visibility to every descendant, returning suppressed works to
   the `ACTIVE` state. A visited set guards against membership cycles.

The cascade is **unconditional**: publishing a draft publishes everything under it.
(An earlier iteration used a per-member "draft marker" to publish members
selectively; that was dropped in favor of this simpler tree-structural cascade.)

## Flexible metadata

The workflow, ACL, suppression, and member queries are the same Valkyrie machinery
under both `HYRAX_FLEXIBLE=false` and `HYRAX_FLEXIBLE=true`, and the feature adds no
model-level attributes, so it behaves identically in both modes. Verify in allinson
(flexible) and dassie (non-flexible).

## Downstream layers (other repos)

- **Hyku** adds a per-tenant toggle: an `AccountSettings` boolean plus a tenant-aware
  Flipflop strategy that reads it, so every Hyrax check stays tenant-agnostic via
  `Flipflop.draft_permission?`.
- **enact_knapsack** turns the setting on and applies any label/styling overrides.
