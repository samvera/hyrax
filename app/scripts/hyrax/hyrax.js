/** Class and namespace for Hyrax code. */
export default class Hyrax {
  /**
  This is a brand check; see {@link Hyrax#hyrax}.

  @type {undefined}
  */
  #isHyrax;

  /**
   * Creates a new `Hyrax` instance for the provided `document`.
   *
   * @param {Document} [document]
   */
  constructor(document = globalThis.document) {
    const { initializers } = Hyrax;
    /** @type {?Window} */
    this.window = document.defaultView;
    /** @type {Document} */
    this.document = document;
    Object.defineProperties(this, {
      window: {
        configurable: false,
        writable: false,
      },
      document: {
        configurable: false,
        writable: false,
      },
    });
    for (
      const property of [
        ...Object.getOwnPropertyNames(initializers),
        ...Object.getOwnPropertySymbols(initializers),
      ]
    ) {
      initializers[property].call(this);
    }
  }

  /**
   * A brand check for `Hyrax` instances.
   *
   * Guarantees that this was properly constructed using the `Hyrax`
   * constructor. **Does not** guarantee that any particular
   * initializer was called.
   *
   * @type {Hyrax}
   * @throws {TypeError} If this was not constructed with `new Hyrax`.
   */
  get hyrax() {
    if (#isHyrax in this) {
      return this;
    } else {
      throw new TypeError(
        "This was not constructed with the Hyrax constructor.",
      );
    }
  }

  /**
   * `Hyrax` configuration.
   *
   * TODO: Do this better.
   *
   * @type {Object}
   */
  static config = {};

  /**
   * “Saved so that inline javascript can put data somewhere.”
   *
   * TODO: Make this an instance property.
   *
   * @type {Object}
   */
  static statistics = {};

  /**
   * Initializers for `Hyrax` instances.
   *
   * This object can be extended up until the `DOMContentLoaded` event
   * fires, at which point it will be frozen. The process of extending
   * Hyrax with a new initializer is thus :—
   *
   *  1. Load (and run) this script (i.e. via a Ecmascript import).
   *     It’s not a problem if multiple scripts import this one; it
   *     will only be run once.
   *
   *  2. Add a new initializer to the `Hyrax.initializers` object. It
   *     is *recommended* that you do so using an (exported) symbol
   *     rather than a string to avoid name collisions.
   *
   *  3. That’s it!
   *
   *  Note that this process will only work for scripts which are
   *  `load`‐blocking: parser‐inserted scripts and Ecmascript imports.
   *
   * @type {{[index: string | symbol]: (this: Hyrax) => void}}
   */
  static initializers = {};
}

/**
 * The `Hyrax` constructor itself.
 *
 * @type {typeof Hyrax}
 */
globalThis.Hyrax = Hyrax;

/**
 * The default `Hyrax` instance associated with the global document.
 *
 * This should remain `undefined` until DOM content load, at which
 * point it will be set to a new `Hyrax` instance automatically.
 *
 * @type {Hyrax | undefined}
 */
globalThis.hyrax = undefined;

// Do not allow simple redefinition of the global `Hyrax` / `hyrax`
// properties to prevent accidentally doing something awful.
Object.defineProperties(globalThis, {
  Hyrax: {
    configurable: true,
    writable: false,
  },
  hyrax: {
    configurable: true,
    writable: false,
  },
});

// Do not allow simple redefinition of the `Hyrax.initializers` object;
// it can still be redefined via `Object.defineProperty()`.
Object.defineProperty(Hyrax, "initializers", {
  configurable: true,
  writable: false,
});

// Set the `hyrax` property on DOM content load to be a new `Hyrax`
// instance.
//
// This is deferred to allow the `Hyrax` constructor access to the
// document tree. It also means that programs can overwrite or extend
// `Hyrax` initializers prior to DOM content load.
//
// **Note:** The `DOMContentLoaded` event is not fired until *after*
// the list of scripts that will execute when the document has
// finished parsing (technical term) is empty. This list includes all
// parser‐inserted `<script>` elements without an `async` attribute,
// including modules and those with a `defer` attribute. See
// <https://html.spec.whatwg.org/multipage/parsing.html#the-end>,
// steps 5 and 6.
//
// Assuming the Blacklight script has already been run, its onLoad
// callbacks will fire first.
{
  const onLoad = () => {
    Object.freeze(Hyrax.initializers);
    Object.defineProperty(Hyrax, "initializers", {
      configurable: false,
      writable: false,
    });
    Object.defineProperty(globalThis, "hyrax", {
      value: new Hyrax(),
    });
    /** @type {any} */ (globalThis)?.Blacklight?.onLoad?.(() => {
      // Re‐initialize for Turbolinks.
      Object.defineProperty(globalThis, "hyrax", {
        value: new Hyrax(),
      });
    });
    document.removeEventListener("DOMContentLoaded", onLoad);
  };
  document.addEventListener("DOMContentLoaded", onLoad);
}
