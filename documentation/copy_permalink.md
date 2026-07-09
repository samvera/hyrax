# Copy permalink button

A "Copy permalink" button on the show pages for works and collections lets a viewer copy the record's canonical, UUID-based URL to their clipboard. The canonical URL is the form `…/concern/<work_type>/<uuid>` (for works) or `…/collections/<uuid>` (for collections) — the stable URL that always identifies the record, regardless of any aliases registered for it.

## Why

When the redirects feature is in use, the show page commonly renders at a registered alias (e.g. `/handle/12345/678`) rather than at the canonical UUID URL. The browser address bar shows the alias. A user who copies that URL is copying the alias, which could later be edited or removed. The permalink button gives one-click access to the canonical URL so the copied link will keep working as long as the record itself exists.

The button has value even without redirects enabled, because the canonical URL is the long-term stable form of the address.

## Feature flag

The button is gated by a Flipflop feature, `copy_permalink_button`, defaulting to **off**. Enable it per environment (via the YAML strategy) or per tenant (via the database strategy) like any other Flipflop feature. When the feature is off, no button is rendered.

The feature is independent of the `redirects` feature flag — the permalink button can be enabled standalone.

## What appears

On a work show page, the button appears in the citations block in the left-hand column. On a collection show page, it appears in the title header next to the collection-type and permission badges. In both cases the button is visible to all users, including anonymous visitors.

The button uses ClipboardJS (already a Hyrax dependency) and shows a brief Bootstrap tooltip on successful copy.

## Canonical URL in the page head

The work and collection show pages also include a `<link rel="canonical" href="...">` tag in the `<head>` regardless of the feature flag. This helps search engines treat the UUID-based URL as authoritative when the same record is reachable via multiple alias paths, avoiding duplicate-content penalties.

## Related

- [`documentation/redirects.md`](redirects.md) — the redirect aliases feature that motivates the canonical/alias distinction.
