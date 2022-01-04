import { assert } from "./dev-deps.js";
import { waitForWindow } from "../../../lib/scripts/window.js";

// Modules which depend on the DOM must be imported *after* the window
// is set up.
await waitForWindow();
const Hyrax = await import("./hyrax.js");

Deno.test({
  name: "It works!",
  fn: () => assert(Hyrax != undefined),
});
