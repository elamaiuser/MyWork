import { LightningElement, api } from 'lwc';

export default class BsfTaskChecklistChild extends LightningElement {
    @api uiElements;
    @api disableEditAccess = false;

    handleInputChange(event) {
        const inputType = event.target.type;
        const id = event.target.dataset.recordId;
        const name = event.target.name;
        let fieldValue;
        if (inputType === 'checkbox') {
            fieldValue = event.target.checked;
        } else {
            fieldValue = event.target.value;
        }

        // console.log('id: ', id);
        // console.log('name: ', name);
        // console.log('fieldValue: ', fieldValue);

        this.dispatchEvent(new CustomEvent('inputchange', {
            detail: {
                data: { id: id, name: name, value: fieldValue }
            }
        }));
    }
}