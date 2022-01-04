// This file supplies a fake DOM for use in test environments (*not in
// the browser*).
//
// It should **never** be imported into actual Hyrax code.
//
// Note that JSDOM is “not fast”; please don’t import this file unless
// you actually need DOM functionality.

import { JSDOM } from "https://esm.sh/jsdom@19.0.0?no-check";

const { window } = new JSDOM(`<!DOCTYPE html>`);

/**
 * JSDOM takes a little bit to get going, which will throw an error in
 * `deno test`.
 *
 * See <https://github.com/denoland/deno/issues/7878>. Yes, this is
 * annoying.
 */
export async function waitForWindow() {
  await new Promise((resolve) => setTimeout(resolve, 10));
}

/**
 * A handler for generating a `Proxy` object which prioritizes pulling
 * its properties from the provided `Window` object, if available.
 *
 * This proxy behaves like :—
 *
 * ```js
 * Object.setPrototypeOf(window, Object.getPrototypeOf(O))
 * Object.setPrototypeOf(O, window)
 * ```
 *
 * —: *except* that properties of `window` take prioritiy over
 * properties of `O` when the latter are marked as configurable.
 *
 * This is used to dynamically mixin properties from the JSDOM window
 * object into the prototype of `globalThis`.
 *
 * @template {Object} Target
 * @extends {ProxyHandler<Target>}
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
   * @param {Target} O
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
   * @param {Target} O
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
    } else if (Reflect.has(this.#window, P)) {
      // `P` is defined on the window.
      return Reflect.get(this.#window, P, Receiver);
    } else {
      // `P` is not defined on the window; fallback to `O`.
      return Reflect.get(O, P, Receiver);
    }
  }

  /**
   * Returns whether `P` is defined on `O` or on the window.
   *
   * @param {Target} O
   * @param {string | symbol} P
   * @returns {boolean}
   */
  has(O, P) {
    return Reflect.has(O, P) || Reflect.has(this.#window, P);
  }

  /**
   * @param {Target} O
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
    } else if (Reflect.has(this.#window, P)) {
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
