//@ts-nocheck: We are testing hacks here!
import "./mod.js";
import { assert, assertStrictEquals } from "../dev-deps.js";

Deno.test(
  "Window is defined",
  () => assertStrictEquals(typeof window, "object"),
);

Deno.test(
  "Document is defined",
  () => assertStrictEquals(typeof document, "object"),
);

Deno.test(
  "Configurable properties pull from window",
  () => {
    Object.defineProperty(
      Object.getPrototypeOf(globalThis),
      "document",
      {
        configurable: true,
        value: false,
      },
    );
    assert(!!document);
    assertStrictEquals(document, window.document);
  },
);

Deno.test(
  "Nonconfigurable properties pull from globalThis",
  () => {
    Object.defineProperty(
      Object.getPrototypeOf(globalThis),
      "document",
      {
        configurable: false,
        value: true,
      },
    );
    assertStrictEquals(document, true);
  },
);
