import "../../../lib/scripts/window.js";
export {
  assert, // true or false
  assertArrayIncludes, // array includes
  assertEquals, // deep equality
  assertMatch, // matches regex
  assertNotEquals, // not deep equality
  assertNotMatch, // does not match regex
  assertObjectMatch, // matches subset object
  assertStrictEquals, // strict equality
  assertStringIncludes, // string includes
  assertThrows, // function throws
  unimplemented, // throws if called
  unreachable, // throws if reached
} from "https://deno.land/std@0.119.0/testing/asserts.ts";
