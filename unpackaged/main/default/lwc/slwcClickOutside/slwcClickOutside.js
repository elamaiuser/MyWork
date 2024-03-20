import { LightningElement, api} from 'lwc';

export default class SlwcClickOutside extends LightningElement {
    @api func = null;
    handleClick = (event) => {
        const path = [...event.path];
        const inside = path.includes(this.template)
        if (!inside && this.func) {
            this.func();
        }
    };

    connectedCallback() {
        document.addEventListener('click', this.handleClick);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleClick);
    }
}