import { LightningElement, track, api } from 'lwc';
import { DateTime } from 'c/luxon';
import _ from 'c/lodash';

export default class SlwcMonthPicker extends LightningElement {
    _isoDateFormat = 'yyyy-MM-dd';
    @track _defaultValue;
    @track months = [];
    @track quarters = [];
    @track selectedDate;
    @track pickerDate;
    
    @api hideNavigateButtons = false;
    @api name;
    @api uniqueKey;
    @api variant;
    @api label;
    @api 
    set defaultValue(input) {
        if (input) {
            this._defaultValue = input;
            this.selectedDate = _.isString(this._defaultValue) ? DateTime.fromISO(this._defaultValue).startOf('month') : DateTime.fromJSDate(this._defaultValue).startOf('month');
            this.pickerDate = _.isString(this._defaultValue) ? DateTime.fromISO(this._defaultValue).startOf('month') : DateTime.fromJSDate(this._defaultValue).startOf('month');
        } else {
            this.pickerDate = DateTime.local().startOf('month');
        }
        this.renderCalendar();
    }
    get defaultValue() {
        return this._defaultValue;
    }

    get showLabel() {
        return this.variant !== 'label-hidden'
    }
    
    connectedCallback () {
        if (!this.pickerDate) {
            this.pickerDate = DateTime.local().startOf('month');
        }
        this.renderCalendar();
    }

    get year() {
        return this.pickerDate ? this.pickerDate.toFormat('y') : '';
    }

    get month() {
        return this.selectedDate ? this.selectedDate.toFormat('MMMM yyyy') : '';
    }

    previousYear() {
        this.pickerDate = this.pickerDate.plus({ year: -1 });
        this.renderCalendar();
    }

    nextYear() {
        this.pickerDate = this.pickerDate.plus({ year: 1 });
        this.renderCalendar();
    }

    renderCalendar() {
        this.months = [];
        this.quarters = [];
        const currentMoment = this.pickerDate.toFormat(this._isoDateFormat);
        for (let i = 0; i < 12; i++) {
            const day = DateTime.fromFormat(currentMoment, this._isoDateFormat).startOf('year').plus({ month: i });
            let className = '';
            if (this.selectedDate && (day.toISODate() == this.selectedDate.toISODate())) {
                className += 'slds-is-selected ';
            }
            this.months.push({
                className: className,
                formatted: day.toFormat(this._isoDateFormat),
                text: day.toFormat('MMM'),
                dateVal: day
            });
        }
        let quarter = null;
        this.months.forEach((month, index) => {
            if (index % 3 == 0) {
                quarter = {
                    id: 'quarter-' + index,
                    months: []
                }
                this.quarters.push(quarter);
            }
            quarter.months.push(month);
        });
    }

    setSelected(e) {
        const { date } = e.currentTarget.dataset;
        this.pickerDate = DateTime.fromFormat(date, this._isoDateFormat);

        this.toggleCalendar(false);

        this.dispatchEvent(new CustomEvent('monthchange', {
            detail: { key : this.uniqueKey, selectedDate: this.pickerDate.toFormat(this._isoDateFormat)},
        }));
    }

    closeDropdown = () => {
        this.toggleCalendar(false);
    }

    moveNext () {
        const currentDate = this.pickerDate;
        this.setSelected({
            currentTarget: {
                dataset: {
                    date: currentDate.plus({
                        month: 1
                    }).toISODate()
                }
            }
        })
    }

    moveBack () {
        const currentDate = this.pickerDate;
        this.setSelected({
            currentTarget: {
                dataset: {
                    date: currentDate.minus({
                        month: 1
                    }).toISODate()
                }
            }
        })
    }

    toggleCalendar (force) {
        let calendar = this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click');
        let flag = _.isBoolean(force) ? force : !calendar.className.includes('slds-is-open');
        if (flag) {
            if (this.selectedDate) {
                this.pickerDate = DateTime.fromJSDate(this.selectedDate.toJSDate()).startOf('month');
            }
            calendar.className += ' slds-is-open';
        } else {
            calendar.classList.remove('slds-is-open');
        }
    }

}