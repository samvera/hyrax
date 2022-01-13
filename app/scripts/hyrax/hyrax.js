/**
 * Call Hyrax deinitializers with the provided `heldValues`.
 *
 * @param {{[index: string | symbol]: unknown}} heldValues
 * @returns {void}
 */
const deinitialize = (heldValues) => {
  const { deinitializers } = Hyrax;
  for (const property of Reflect.ownKeys(deinitializers)) {
    // Call the appropriate deinitializer with the appropriate held
    // value.
    deinitializers[property].call(heldValues[property]);
    if (
      Object.getOwnPropertyDescriptor(heldValues, property)
        ?.configurable
    ) {
      // Delete the corresponding held value so that it can be freed.
      delete heldValues[property];
    }
  }
};

/**
 * The finalization registry for `Hyrax` objects.
 */
const hyraxFinalizationRegistry = new FinalizationRegistry(
  deinitialize,
);

/**
 * The `Hyrax` instance associated with a given `Document`.
 *
 * This is stored in an external `WeakMap` and accessed through the
 * `Document` prototype rather than stored on individual `document`
 * instances for broad consistency and to ensure a single source of
 * truth about whether a `Hyrax` instance for a given document is
 * defined.
 *
 * @type {WeakMap<Document, Hyrax>}
 */
const hyraxesForDocuments = new WeakMap();

/**
 * Class and namespace for Hyrax code.
 */
export default class Hyrax {
  /**
   * Whether this instance has been deinitialized yet.
   *
   * @type {boolean}
   */
  #deinitialized = false;

  /**
   * This is a brand check; see {@link Hyrax#hyrax}.
   *
   * @type {undefined}
   */
  #isHyrax;

  /**
   * Creates a new `Hyrax` instance for the provided `document`.
   *
   * @param {Document} [document]
   */
  constructor(document = globalThis.document) {
    const { initializers } = Hyrax;

    // Set up instance properties.
    /** @type {Document} */
    this.document = document;
    /** @type {{[index: string | symbol]: unknown}} */
    this.heldValues = Object.create(null);

    // Prevent overwriting of `document` or `heldValue`.
    Object.defineProperties(this, {
      document: {
        configurable: false,
        writable: false,
      },
      heldValues: {
        configurable: false,
        writable: false,
      },
    });

    // Initialize and set up deinitialization.
    for (const property of Reflect.ownKeys(initializers)) {
      initializers[property].call(this);
    }
    hyraxFinalizationRegistry.register(this, this.heldValues, this);
  }

  /**
   * Deinitializes this `Hyrax` instance if it is not already `closed`.
   *
   * @returns {void}
   */
  close() {
    if (!this.#deinitialized) {
      // This has not yet been deinitialized.
      hyraxFinalizationRegistry.unregister(this);
      deinitialize(this.heldValues);
      this.#deinitialized = true;
    } else {
      // This has already been deinitialized.
      /* do nothing */
    }
    if (hyraxesForDocuments.get(this.document) === this) {
      // This is assigned to its own `document`.
      hyraxesForDocuments.delete(this.document);
    } else {
      // This is not assigned to its own `document`.
      /* do nothing */
    }
  }

  /**
   * Returns whether {@link Hyrax#close} has been called on this Hyrax
   * instance.
   *
   * @type {boolean}
   */
  get closed() {
    return this.#deinitialized;
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
   * The window associated with the `document` of this `Hyrax`
   * instance.
   *
   * @returns {?Window}
   */
  get window() {
    return this.document.defaultView;
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
   * Deinitializers for `Hyrax` instances.
   *
   * As with {@link Hyrax.initializers}, this object can be extended up
   * until the `DOMContentLoaded` event fires, at which point it will
   * be frozen.
   *
   * Deinitializers will be called with the their `this` set to the
   * value of the corresponding property in the instance’s `heldValue`,
   * which **should not** contain any strong references to the Hyrax
   * instance in question.
   *
   * Deinitializers exist to allow for the removal of event listeners
   * and DOM observers once a `Hyrax` object is no longer in use. If
   * your initializer doesn’t establish any such callbacks, you don’t
   * need to assign a deinitializer for it.
   *
   * @type {{[index: string | symbol]: (this: unknown) => void}}
   */
  static deinitializers = {};

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

  /**
   * “Saved so that inline javascript can put data somewhere.”
   *
   * TODO: Make this an instance property.
   *
   * @type {Object}
   */
  static statistics = {};

  /**
   * The Hyrax symbol.
   */
  static symbol = Symbol("Hyrax");
}

// Do not allow simple redefinition of the global `Hyrax` property to
// prevent accidentally doing something awful.
Object.defineProperty(globalThis, "Hyrax", {
  configurable: true,
  enumerable: true,
  value: Hyrax,
  writable: false,
});

// Do not allow simple redefinition of important static properties of
// the `Hyrax` constructor; some of these can still be redefined via
// via `Object.defineProperty()`.
Object.defineProperties(Hyrax, {
  deinitializers: { writable: false },
  initializers: { writable: false },
  symbol: {
    configurable: false,
    writable: false,
  },
});

// Define `Hyrax.symbol` on the `Document` prototype to get the `Hyrax`
// instance associated with a given document, if one has been created.
Object.defineProperty(
  Object.getPrototypeOf(document),
  Hyrax.symbol,
  {
    configurable: true,

    /**
     * Gets the current `Hyrax` instance associated with this `Document`.
     *
     * @this {Document}
     * @returns {Hyrax | undefined}
     */
    get() {
      return hyraxesForDocuments.get(this);
    },

    /**
     * Sets the `Hyrax` instance associated with this `Document` to the
     * provided `value`.
     *
     * Note that this setter *does not* close out any existing `Hyrax`
     * instance.
     *
     * @this {Document}
     * @param {Hyrax | undefined} value
     * @returns {void}
     */
    set(value) {
      if (value === undefined) {
        // Remove the `Hyrax` property.
        hyraxesForDocuments.delete(this);
      } else {
        // Will throw a `TypeError` if `value` was not constructed using
        // the `Hyrax` constructor.
        Reflect.get(Hyrax.prototype, "hyrax", value);
        hyraxesForDocuments.set(this, value);
      }
    },
  },
);

// Set the `hyrax` property on DOM content load to be a new `Hyrax`
// instance.
//
// This is deferred to allow `Hyrax` initializers full access to the
// document tree. It also means that programs can overwrite or extend
// `Hyrax` properties prior to DOM content load.
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
  const reload = () => {
    //@ts-ignore: TypeScript isn’t aware of this property.
    document[Hyrax.symbol]?.close();
    //@ts-ignore: TypeScript isn’t aware of this property.
    document[Hyrax.symbol] = new Hyrax(document);
  };
  const onLoad = () => {
    const { deinitializers, initializers } = Hyrax;
    Object.defineProperties(Hyrax, {
      deinitializers: {
        configurable: false,
        value: Object.freeze(deinitializers),
        writable: false,
      },
      initializers: {
        configurable: false,
        value: Object.freeze(initializers),
        writable: false,
      },
    });
    reload();
    //@ts-ignore: TypeScript doesn’t know about Blacklight.
    globalThis?.Blacklight?.onLoad?.(reload);
    document.removeEventListener("DOMContentLoaded", onLoad);
  };
  document.addEventListener("DOMContentLoaded", onLoad);
}
