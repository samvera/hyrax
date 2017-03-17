export default class {
    // takes a jquery selector for a select field
    // create a custom change event with the data when it changes
    constructor(element) {
        this.changeHandlers = []
        this.element = element
        element.on('change', (e) => {
            this.change(this.data())
        })
    }

    data() {
        return this.element.find(":selected").data()
    }

    isEmpty() {
        return this.element.children().length === 0
    }

    /**
     * returns undefined or true
     */
    isSharing() {
        return this.data()["sharing"]
    }

    on(eventName, handler) {
        switch (eventName) {
            case "change":
                return this.changeHandlers.push(handler)
        }
    }

    change(data) {
        for (let fn of this.changeHandlers) {
          setTimeout(function() { fn(data) }, 0)
        }
    }
}
