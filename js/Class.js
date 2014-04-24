/**
 * Inheritance implementation, adapted from John Resig's implementation.
 * http://ejohn.org/blog/simple-javascript-inheritance/
 */

// the root class, that all classes inherit from (directly or indirectly)
Class = function () {};

/**
 * Extends the class.
 *
 * @param	{Object}	descriptor	an object containing properties and methods to extend the class with
 * @return	{Function}	the class constructor
 */
Class.extend = function (descriptor) {

	// create a new prototype based on an instance of the current class
	Class._prototyping = true;
	var prototype = new this();
	Class._prototyping = false;

	// the 'base class' is the prototype of the current constructor
	var base = this.prototype;

	// create the constructor for the extended class
	var constructor = (descriptor.hasOwnProperty("constructor") ? descriptor.constructor : function () {});
	// override the constructor, so that the constructor of the base class is called when instantiating
	// properties created in the base constructor will then belong to the instance
	// otherwise those properties would be on the prototype and shared between instances (if the property is a reference type)
	constructor = (function (constructor, baseConstructor) {
		return function () {
			if (!Class._prototyping) {
				if (baseConstructor) {
					baseConstructor.apply(this, arguments);
				}
				constructor.apply(this, arguments);
			}
		}
	})(constructor, this);

    // copy the properties to the new prototype (except the constructor property)
    for (var name in descriptor) {
		if (descriptor.hasOwnProperty(name) && name !== "constructor") {
			if (/^\$/.test(name)) {
				// first character is $, static method or property, attach it to the constructor function
				constructor[name.substring(1)] = descriptor[name];
			} else {
				prototype[name] = Class._override(name, base[name], descriptor[name]);
			}
		}
	}

    constructor.prototype = prototype;
    // setting the prototype also overwrites the constructor property, so reset it to the new constructor
    constructor.prototype.constructor = constructor;

    return constructor;
};

/**
 * Defines a new class.
 *
 * @static
 * @param	{Object}	descriptor	the descriptor, which contains all methods and properties
 * @param	{Function}	base		the base (super) class
 */
Class.define = function (descriptor, base) {
	// if there is a base class, extend that, otherwise extend the root Class
	return Class.extend.call(base || this, descriptor);
};

/**
 * Overrides the base property with the new property, preserving access to the base property.
 *
 * @private
 * @static
 * @param	{String}	name			the name of the property
 * @param	{Object}	baseProperty	the property to be overridden
 * @param	{Object}	newProperty		the property that overrides
 */
Class._override = function (name, baseProperty, newProperty) {
	// If the new property is a function, return a closure if it is an override, but only if the base method is invoked using _base().
	if (typeof newProperty === "function" && (typeof baseProperty === "function" && /this\._base\(/.test(newProperty))) {
		return function () {
			// replace an existing base property with the base function
			// this is necessary to allow for recursive calls to the base function
			var property = this._base;
			this._base = baseProperty;

			var returnValue = newProperty.apply(this, arguments);

			// revert to the previous situation
			this._base = property;

			return returnValue;
		};
	} else {
		return newProperty;
	}
};
