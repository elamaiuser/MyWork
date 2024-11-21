import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { DateTime } from 'c/luxon';
import { classNames } from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import _ from 'c/lodash';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcWeekDatePicker extends LightningElement {
    @api uniqueKey;

    _firstDay;
    @api
    get firstDay() {
        return this._firstDay;
    }
    set firstDay(value) {
        this._firstDay = value;
        this.initPicker();
    }

    @api label = 'Date';

    _defaultStartDate;
    @api
    get defaultStartDate() {
        return this._defaultStartDate;
    }
    set defaultStartDate(value) {
        this._defaultStartDate = value;
        this.initPicker();
    }

    _defaultEndDate;
    @api
    get defaultEndDate() {
        return this._defaultEndDate;
    }
    set defaultEndDate(value) {
        this._defaultEndDate = value;
        this.initPicker();
    }

    @api weekLength = 1;
    @api variant;
    @api includesAdditionalDays = 0;
    @api fullWidth = false;
    @api dropdownPosition = 'right';
    
    @track weeks = [];
    @track labels = [];
    @track selectedMonth;
    @track startDate;
    @track endDate;

    todayVal;
    selectedWeekId;

    get dateUtils() {
        return slwcDateUtils.getInstance({
            timezone: TIME_ZONE
        });
    }

    get showLabel() {
        return !this.variant || this.variant != 'label-hidden';
    }

    get firstDayValue() {
       return this.dateUtils.getFirstDayValue(this.firstDay);
    }
    
    get year() {
        return this.selectedMonth ? this.selectedMonth.toFormat('yyyy') : '';
    }
    get month() {
        return this.selectedMonth ? this.selectedMonth.toFormat('MMMM') : '';
    }

    get week() {
        return this.startDate != null && this.endDate != null ? this.startDate.toFormat('MMM d') + ' - ' + this.endDate.toFormat('MMM d, yyyy') : 'Select a week';
    }

    get customClasses() {
        return {
            dropdown: classNames('slds-datepicker slds-dropdown', `slds-dropdown_${this.dropdownPosition}`)
        }
    }
    get customStyle() {
        return {
            buttonGroup: _.compact([
                this.fullWidth ? `width: 100%` : null
            ]).join(';'),
            comboboxContainer: _.compact([
                this.fullWidth ? `flex: 1` : null
            ]).join(';')
        }
    };

    connectedCallback() {
        console.log('init');
        this.initPicker();
    }

    initPicker = () => {
        this.todayVal = DateTime.local();
        if (this.defaultStartDate && this.defaultEndDate) {
            this.startDate = DateTime.fromISO(this.defaultStartDate);
            this.endDate = DateTime.fromISO(this.defaultEndDate);
            this.selectedMonth = DateTime.fromISO(this.defaultStartDate).startOf('month');
        }
        else {
            this.selectedMonth = DateTime.local().startOf('month');
        }

        this.refreshDateNodes();
    }

    closeDropdown = () => {
        let calendar = this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click');
        if (calendar) {
            calendar.classList.remove('slds-is-open');
        }
    }

    previousMonth() {
        this.selectedMonth = this.selectedMonth.minus({month: 1});
        this.refreshDateNodes();
    }

    nextMonth() {
        this.selectedMonth = this.selectedMonth.plus({month: 1});
        this.refreshDateNodes();
    }

    goToday() {
        this.selectedMonth = DateTime.local().startOf('month');
        this.refreshDateNodes();
    }

    setSelected(e) {
        const { date } = e.currentTarget.dataset;

        this.startDate = this.startOfWeek(DateTime.fromISO(date));
        this.endDate = this.startDate.plus({
            week: this.weekLength,
            day: -1
        });

        this.toggleCalendar(false);
        this.dispatchChangeEvent();
    }

    moveNext () {
        const currentDate = this.startDate;
        this.setSelected({
            currentTarget: {
                dataset: {
                    date: currentDate.plus({
                        week: this.weekLength
                    }).toISODate()
                }
            }
        })
    }

    moveBack () {
        const currentDate = this.startDate;
        this.setSelected({
            currentTarget: {
                dataset: {
                    date: currentDate.minus({
                        week: this.weekLength
                    }).toISODate()
                }
            }
        })
    }
    
    startOfWeek(date) {
        const firstDay = this.firstDayValue;
        const day = date.toJSDate().getDay();
        return date.minus({
            day: (day + 7 - firstDay) % 7
        })
    }

    generateDayLabels() {
        const defaultDayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const firstDay = Number(this.firstDayValue || 0);
        const splitLabels = defaultDayLabels.splice(0, firstDay);
        return defaultDayLabels.concat(splitLabels);
    }

    refreshDateNodes() {
        if(!this.selectedMonth) return;

        const weeks = [];
        const numWeeks = 6;
        const firstDay = this.firstDayValue; 
        const selectedMonth = this.selectedMonth;
        const firstDayOfMonth = selectedMonth.startOf('month');
        const lastDayOfMonth = selectedMonth.endOf('month').startOf('day');
        const labels = this.generateDayLabels();
        const startingDay = this.startOfWeek(firstDayOfMonth);
        let currentDateObj;
        let additionalStartDate = this.startDate;
        let additionalEndDate = this.endDate;

        if(this.includesAdditionalDays > 0) {
            if(this.startDate) {
                additionalStartDate = this.startDate.minus({
                    day: this.includesAdditionalDays
                })
            }
            
            if(this.endDate) {
                additionalEndDate = this.endDate.plus({
                    day: this.includesAdditionalDays
                })
            }
        }

        for (let i = 0; i <= numWeeks; i++) {
            let days = [];
            for (let j = firstDay; j <= 6 + firstDay; j++) {
                currentDateObj = startingDay.plus({
                    day: (i * 7 ) + (j - startingDay.toJSDate().getDay())
                });

                days.push({
                    className: classNames({
                        'slds-is-today': currentDateObj.hasSame(this.todayVal, 'day'),
                        'slds-day_adjacent-month': currentDateObj.month !== this.selectedMonth.month,
                        'slds-is-additional': currentDateObj < this.startDate || currentDateObj > this.endDate,
                        'slds-is-selected slds-is-selected-multi': additionalStartDate <= currentDateObj && additionalEndDate >= currentDateObj
                    }),
                    formatted: currentDateObj.toFormat('yyyy-MM-dd'),
                    text: currentDateObj.toFormat('dd'),
                    dateVal: currentDateObj
                })
            }

            weeks.push({
                id: 'week-' + i,
                dates: days
            });

            if (currentDateObj >= lastDayOfMonth) {
                break;
            }
        }

        this.labels = labels;
        this.weeks = weeks;
    }

    toggleCalendar (force) {
        let calendar = this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click');
        let flag = _.isBoolean(force) ? force : !calendar.className.includes('slds-is-open');
        if (flag) {
            calendar.className += ' slds-is-open';
        } else {
            calendar.classList.remove('slds-is-open');
        }
    }

    dispatchChangeEvent() {
        const weekDateChangeEvent = new CustomEvent('weekdatechange', {
            detail: { key : this.uniqueKey, startDate: this.startDate.toISODate(), endDate: this.endDate.toISODate()},
        });
        this.dispatchEvent(weekDateChangeEvent);
    }
}