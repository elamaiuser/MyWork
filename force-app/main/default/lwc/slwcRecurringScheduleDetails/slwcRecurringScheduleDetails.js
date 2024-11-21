import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import * as slwcUtils from 'c/slwcUtils';

export default class SlwcRecurringScheduleDetails extends LightningElement {
    @track patternErrorMessage;
    @track model = {
        fromDate: null,
        toDate: null,
        isRecurring: false,
        pattern: "weekly",
        weeks: [],
        week1: [],
        week2: []
    };

    get isWeekly() {
        return this.model.pattern == "weekly";
    }

    get patterns() {
        return [
            { label: 'Weekly', value: 'weekly' },
            { label: 'Every 2 Weeks', value: 'every_2_weeks' }
        ];
    }

    get weekdays() {
        return [
            { label: "Sun", value: "sun" },
            { label: "Mon", value: "mon" },
            { label: "Tue", value: "tue" },
            { label: "Wed", value: "wed" },
            { label: "Thu", value: "thu" },
            { label: "Fri", value: "fri" },
            { label: "Sat", value: "sat" }
        ];
    }

    @wire(CurrentPageReference) pageRef;

    renderedCallback() {
        this.dispatchEvent(
            new CustomEvent('loaded', { 
                bubbles: true,
                composed: true,
                detail: { 
                    callbacks: {
                        checkValidity: this.checkValidity,
                        getData: this.getData
                    }
                } 
            })
        );
    }

    checkValidity = () => {
        let errorMessages = [];
        this.patternErrorMessage = null;
        if (this.model.isRecurring) {
            if (this.model.pattern == "weekly" && this.model.week1.length == 0) {
                this.patternErrorMessage = "Complete this field.";
                errorMessages.push("Weekdays is required.");
            }
            else if (this.model.pattern == "every_2_weeks" && this.model.week1.length == 0 && this.model.week2.length == 0) {
                this.patternErrorMessage = "Complete this field.";
                errorMessages.push("Weekdays is required.");
            }
            if (this.model.fromDate == null) {
                errorMessages.push("From Date is required.");
            }
            if (this.model.toDate == null) {
                errorMessages.push("To Date is required.");
            }
            this.showUiInputError();
        }
        return errorMessages.length == 0;
    }

    showUiInputError() {
        const allValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
                .reduce((validSoFar, inputCmp) => {
                            inputCmp.reportValidity();
                            return validSoFar && inputCmp.checkValidity();
                }, true);
    }

    getData = () => {
        if (this.model.pattern == "weekly") {
            this.model.weeks = [this.model.week1];
        }
        else {
            this.model.weeks = [this.model.week1, this.model.week2];
        }
        return this.model;
    }

    handleOnChange(event) {
        this.model[event.target.name] = slwcUtils.getValueFromEvent(event);
    }
}