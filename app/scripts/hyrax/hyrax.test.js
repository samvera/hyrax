import { assert } from "./dev-deps.js";
import "../../../lib/scripts/window.js";

// Modules which depend on the DOM at runtime must be imported *after*
// the window is set up.
const Hyrax = await import("./hyrax.js");

Deno.test({
  name: "It works!",
  fn: () => assert(Hyrax != undefined),
});
