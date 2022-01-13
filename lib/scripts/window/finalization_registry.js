/** @type {(heldValue: unknown) => void} */
const defaultHandler = (_) => {};
/** @type {Set<FinalizationRegistry<unknown>>} */
const registries = new Set();

/**
 * Mocks `FinalizationRegistry`.
 *
 * Call `FinalizationRegistry["🥸finalize🥸"](token)` to test the
 * finalization of a given `token`.
 *
 * @template T
 */
export default class FinalizationRegistry {
  /** @type {function} */
  #handler = defaultHandler;
  /** @type {Map<object, {object: object, heldValue: T}>} */
  #registry = new Map();

  /**
   * @param {(heldValue: T) => void} handler
   */
  constructor(handler) {
    this.#handler = handler;
    registries.add(this);
  }

  /**
   * @param {object} object
   * @param {T} heldValue
   * @param {object | undefined} token
   */
  register(object, heldValue, token) {
    this.#registry.set(token ?? object, { object, heldValue });
  }

  /**
   * @param {object} token
   */
  unregister(token) {
    this.#registry.delete(token);
  }

  /**
   * @param {object} token
   */
  "🥸finalize🥸"(token) {
    if (this.#registry.has(token)) {
      this.#handler(this.#registry.get(token)?.heldValue);
    }
  }

  /**
   * @type {"FinalizationRegistry"}
   */
  get [Symbol.toStringTag]() {
    return "FinalizationRegistry";
  }

  /**
   * @param {object} token
   */
  static "🥸finalize🥸"(token) {
    for (const registry of registries) {
      registry["🥸finalize🥸"](token);
    }
  }
}
