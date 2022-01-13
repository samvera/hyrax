import { assert, assertStrictEquals } from "./dev-deps.js";
import "../../../lib/scripts/window/mod.js";

// Modules which depend on the DOM at runtime must be imported *after*
// the window is set up.
const { default: Hyrax } = await import("./hyrax.js");

const counts = {
  initialization: 0,
  deinitialization: 0,
};
/** @this {InstanceType<Hyrax>} */
Hyrax.initializers.test = function () {
  this.heldValues.test = counts;
  counts.initialization++;
};
/** @this {typeof counts} */
Hyrax.deinitializers.test = function () {
  this.deinitialization++;
};

Deno.test({
  name: "It works!",
  fn: () => assert(Hyrax != undefined),
});

Deno.test({
  name: "Initializers run once on DOM content loaded",
  fn: () => {
    const event = document.createEvent("Event");
    event.initEvent("DOMContentLoaded");
    counts.initialization = 0;
    assertStrictEquals(counts.initialization, 0);
    document.dispatchEvent(event);
    assertStrictEquals(counts.initialization, 1);
    document.dispatchEvent(event);
    assertStrictEquals(counts.initialization, 1);
  },
});

Deno.test({
  name:
    "Deinitializers run on finalization and are passed the appropriate held value",
  fn: () => {
    const hyrax = new Hyrax();
    counts.deinitialization = 0;
    assertStrictEquals(counts.deinitialization, 0);
    //@ts-ignore: This property is just for mocking.
    FinalizationRegistry["🥸finalize🥸"](hyrax);
    assertStrictEquals(counts.deinitialization, 1);
  },
});

Deno.test({
  name: "`Hyrax#close` can’t be made to deinitialize twice.",
  fn: () => {
    const hyrax = new Hyrax();
    counts.deinitialization = 0;
    assertStrictEquals(counts.deinitialization, 0);
    hyrax.close();
    assertStrictEquals(counts.deinitialization, 1);
    hyrax.close();
    assertStrictEquals(counts.deinitialization, 1);
  },
});
