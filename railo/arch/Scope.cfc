component {

	public void function init(Scope parent) {
		this.parent = arguments.parent ?: null
		this.elements = {}
	}

	public Boolean function has(required String ref) {
		return this.elements.keyExists(arguments.ref) || this.parent !== null && this.parent.has(arguments.ref);
	}

	public Struct function get(required String ref) {

		if (this.elements.keyExists(arguments.ref)) {
			return this.elements[arguments.ref];
		} else if (this.parent !== null) {
			return this.parent.get(arguments.ref);
		}

		Throw("Element '#arguments.ref#' not found", "NoSuchElementException");
	}

	public void function put(required String ref, required Struct element) {
		if (this.elements.keyExists(arguments.ref)) {
			Throw("Element '#arguments.ref#' already exists", "AlreadyBoundException")
		}
		this.elements[arguments.ref] = arguments.element
	}

}