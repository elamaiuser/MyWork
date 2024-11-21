import { LightningElement, track, api } from 'lwc';
import { getValueFromEvent } from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import _ from 'c/lodash';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcDateRangePicker extends LightningElement {
    @api uniqueKey;

    @api label = 'Date';
    @api variant;
    @api defaultStartDate;
    @api defaultEndDate;

    @track tempDateRange = {
        startDate: null,
        endDate: null
    };

    get dateUtils() {
        return slwcDateUtils.getInstance({
            timezone: TIME_ZONE
        });
    }

    get showLabel() {
        return !this.variant || this.variant != 'label-hidden';
    }

    get dateRangeLabel() {
        if(!this.defaultStartDate || !this.defaultEndDate) return '';

        return DateTime.fromFormat(this.defaultStartDate, 'yyyy-MM-dd').toFormat('MMM d') + ' - ' + DateTime.fromFormat(this.defaultEndDate, 'yyyy-MM-dd').toFormat('MMM d, yyyy');
    }

    get disableApply() {
        if(!this.tempDateRange.startDate || !this.tempDateRange.endDate) return true;
        if(this.tempDateRange.startDate > this.tempDateRange.endDate) return true;
        return false;
    }

    connectedCallback() {
    }

    initPicker = () => {
        this.tempDateRange = {
            startDate: this.defaultStartDate,
            endDate: this.defaultEndDate
        }
    }

    handletempDateRangeChange = (event) => {
        event.stopPropagation();

        let value = getValueFromEvent(event);
        this.tempDateRange[event.currentTarget.name] = value;

        setTimeout(() => {
            [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        })
    }

    applyDateRange = () => {
        const changeEvent = new CustomEvent('daterangechange', {
            detail: { 
                startDate: this.tempDateRange.startDate, 
                endDate: this.tempDateRange.endDate
            },
        });
        this.dispatchEvent(changeEvent);

        this.closeDropdown();
    }

    closeDropdown = () => {
        let calendar = this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click');
        if (calendar) {
            calendar.classList.remove('slds-is-open');
        }
    }

    togglePicker (force) {
        let calendar = this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click');
        let flag = _.isBoolean(force) ? force : !calendar.className.includes('slds-is-open');
        if (flag) {
            calendar.className += ' slds-is-open';
        } else {
            calendar.classList.remove('slds-is-open');
        }

        this.initPicker();
    }
}