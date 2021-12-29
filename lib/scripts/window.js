// This file stubs expected DOM properties for use in test
// environments (not in the browser).
//
// It should never be imported into actual Hyrax code.

import {
  DOMParser,
  XMLSerializer,
} from "https://esm.sh/@xmldom/xmldom@0.8.0";

const xhtmlNamespace = "http://www.w3.org/1999/xhtml";

//@ts-ignore: any necessary missing parts should be polyfilled below
globalThis.window ??= globalThis;
window.DOMParser ??= DOMParser;
window.XMLSerializer ??= XMLSerializer;
window.document ??=
  //  A blank XHTML page.
  (new DOMParser()).parseFromString(
    `<html xmlns="${xhtmlNamespace}"><head/><body/></html>`,
    "application/xhtml+xml",
  );

const DocumentPrototype = Object.getPrototypeOf(window.document);
const NodePrototype = Object.getPrototypeOf(DocumentPrototype);

// TODO: Polyfill event listeners if needed.
NodePrototype.addEventListener ??=
  /** @this {Node} */
  function addEventListener() {
    if (this.nodeType != 1 && this.nodeType != 9) {
      throw new TypeError("This is not an event target.");
    }
  };
NodePrototype.removeEventListener ??=
  /** @this {Node} */
  function removeEventListener() {
    if (this.nodeType != 1 && this.nodeType != 9) {
      throw new TypeError("This is not an event target.");
    }
  };
