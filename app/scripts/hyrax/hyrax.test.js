import { assert } from "./dev-deps.js";
import Hyrax from "./hyrax.js";

Deno.test({
  name: "It works!",
  fn: () => assert(Hyrax != undefined),
});
