import { LightningElement } from 'lwc';
export default class RecurringDrive extends LightningElement {
    value = 'Daily';

    get options() {
        return [
            { label: 'Daily', value: 'Daily' },
            { label: 'Weekly', value: 'Weekly' },
            { label: 'Monthly', value: 'Monthly' },
            { label: 'Yearly', value: 'Yearly' },
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    get checkboxoptions() {
        return [
            { label: 'Monday', value: 'Monday' },
            { label: 'Tuesday', value: 'Tuesday' },
             { label: 'Wednesday', value: 'Wednesday' },
              { label: 'Thursday', value: 'Thursday' },
               { label: 'Friday', value: 'Friday' },
        ];
    }

    get checkboxselectedValues() {
        return this.value.join(',');
    }

    handlecheckboxChange(e) {
        this.value = e.detail.value;
    }
}