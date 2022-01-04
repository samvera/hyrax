// This file supplies a fake DOM for use in test environments (*not in
// the browser*).
//
// It should **never** be imported into actual Hyrax code.

import { DOMParser } from "https://esm.sh/linkedom@0.13.0/worker?no-check";

const window = (new DOMParser()).parseFromString(
  "<!DOCTYPE html>",
  "text/html",
).defaultView;

/**
 * A handler for generating a `Proxy` object which prioritizes pulling
 * its properties from the provided `Window` object, if available.
 *
 * This proxy behaves somewhat like :—
 *
 * ```js
 * Object.setPrototypeOf(window, Object.getPrototypeOf(O))
 * Object.setPrototypeOf(O, window)
 * ```
 *
 * —: *except* that properties of `window` take priority over
 * properties of `O` when the latter are marked as configurable.
 *
 * This is used to dynamically mixin properties from the LinkeDOM
 * window object into the prototype of `globalThis`.
 *
 * @extends {ProxyHandler<Object>}
 */
class WindowProxyHandler {
  /** @type {Window} */
  #window;

  /**
   * Make a new `WindowProxyHandler` which pulls from the provided
   * `window`.
   *
   * @param {Window} window
   */
  constructor(window) {
    this.#window = window;
  }

  /**
   * Deletes a property from both `O` and the window.
   *
   * @param {Object} O
   * @param {string | symbol} P
   * @returns {boolean}
   */
  deleteProperty(O, P) {
    const oldDesc = Object.getOwnPropertyDescriptor(O, P);
    const windowDesc = Object.getOwnPropertyDescriptor(
      this.#window,
      P,
    );
    const wasConfigurable = (oldDesc?.configurable ?? true) &&
      (windowDesc?.configurable ?? true);
    return wasConfigurable
      ? Reflect.deleteProperty(O, P) &&
        Reflect.deleteProperty(this.#window, P)
      : false;
  }

  /**
   * Gets `P` from the window, if possible and defined, or from `O`.
   *
   * @param {Object} O
   * @param {string | symbol} P
   * @param {unknown} Receiver
   * @returns {unknown}
   */
  get(O, P, Receiver) {
    checkingInvariants: {
      // Ensure proxy invariants are respected.
      const oldDesc = Object.getOwnPropertyDescriptor(O, P);
      if (oldDesc) {
        // `P` is an own property on `O`.
        if ("value" in oldDesc || "writable" in oldDesc) {
          // `P` is a data property on `O`.
          if (!oldDesc.configurable && !oldDesc.writable) {
            // `P` is readonly and nonconfigurable.
            return oldDesc.value;
          } else {
            // `P` is configurable or not readonly.
            break checkingInvariants;
          }
        } else {
          // `P` is an accessor property on `O`.
          if (!oldDesc.configurable && oldDesc.get == null) {
            // `P` is write·only and nonconfigurable.
            return undefined;
          } else {
            // `P` is configurable or not write·only.
            break checkingInvariants;
          }
        }
      } else {
        // `P` is not an own property on `O`.
        break checkingInvariants;
      }
    }
    if (P == "window") {
      // `O.window` should return the window, not `O`.
      return this.#window;
    } else if (this.has(this.#window, P)) {
      // `P` is defined on the window.
      return Reflect.get(this.#window, P, Receiver);
    } else {
      // `P` is not defined on the window; fallback to `O`.
      //
      // LinkeDOM defines the window as a proxy on `globalThis`, so
      // this shouldn’t ever be reached.
      return Reflect.get(O, P, Receiver);
    }
  }

  /**
   * Returns whether `P` is defined on `O` or on the window.
   *
   * @param {Object} O
   * @param {string | symbol} P
   * @returns {boolean}
   */
  has(O, P) {
    return Reflect.has(O, P) || /** @type {(string | symbol)[]} */ ([
      // These properties are defined by the LinkeDOM window proxy.
      "addEventListener",
      "removeEventListener",
      "dispatchEvent",
      "document",
      "navigator",
      "window",
      "customElements",
      "performance",
      "DOMParser",
      "Image",
      "MutationObserver",
    ]).includes(P);
  }

  /**
   * Sets `P` on the window, if possible and already defined, or on
   * `O`.
   *
   * @param {Object} O
   * @param {string | symbol} P
   * @param {unknown} V
   * @param {unknown} Receiver
   * @returns {boolean}
   */
  set(O, P, V, Receiver) {
    checkingInvariants: {
      // Ensure proxy invariants are respected.
      const oldDesc = Object.getOwnPropertyDescriptor(O, P);
      if (oldDesc) {
        // `P` is an own property on `O`.
        if ("value" in oldDesc || "writable" in oldDesc) {
          // `P` is a data property on `O`.
          if (!oldDesc.configurable && !oldDesc.writable) {
            // `P` is readonly and nonconfigurable.
            return oldDesc.value === V;
          } else {
            // `P` is configurable or not readonly.
            break checkingInvariants;
          }
        } else {
          // `P` is an accessor property on `O`.
          if (!oldDesc.configurable && oldDesc.set == null) {
            // `P` is readonly and nonconfigurable.
            return false;
          } else {
            // `P` is configurable or not readonly.
            break checkingInvariants;
          }
        }
      } else {
        // `P` is not an own property on `O`.
        break checkingInvariants;
      }
    }
    if (P == "window") {
      // `O.window` cannot be redefined.
      return false;
    } else if (this.has(this.#window, P)) {
      // `P` is defined on the window.
      return Reflect.set(this.#window, P, V, Receiver);
    } else {
      // `P` is not defined on the window; fallback to `O`.
      return Reflect.set(O, P, V, Receiver);
    }
  }
}

// Overwrite the prototype of `globalThis` with a proxy which will
// pull from properties defined on the JSDOM window *first*, iff so
// defined. Note that defining a property on `globalThis` does *not*
// define it on `window` (but `window` is itself a complicated proxy
// which hacks into the global object so really who can say).
Object.setPrototypeOf(
  globalThis,
  new Proxy(
    Object.create(Object.getPrototypeOf(globalThis), {
      window: {
        configurable: false,
        enumerable: true,
        value: window,
        writable: false,
      },
    }),
    new WindowProxyHandler(window),
  ),
);
