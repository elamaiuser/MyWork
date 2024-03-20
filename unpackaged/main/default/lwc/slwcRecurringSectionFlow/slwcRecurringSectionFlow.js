import { LightningElement, track, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { calendarMonthHelper, planDriveDateHelper } from 'c/slwcHelpers';
import { classNames, getValueFromEvent } from 'c/slwcUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DateTime } from 'c/luxon';
import { cloneDeep, uniqueId, extend, remove, first, last, find, findLast, union, max, isEmpty, isEqual, pick} from 'c/lodash';
import { PLAN_DRIVE_SLOT_COLOR_SETTING, PLAN_DRIVE_SLOT_BACKGROUND_COLOR_SETTING } from 'c/slwcConstants';
import { sObjectType, accountQueryModel, accountService } from 'c/dataService';

const DEFAULT_CALENDAR_SETTINGS = {
    timezone: TIME_ZONE,
    firstDay: 0
}

export default class SlwcRecurringSectionFlow extends LightningElement {
    @track _drive = null;
    @track _lastDrive = null;
    @api isNotFlow = false;
    @api driveDate;
    @api driveDays;
    _driveDate;
    @api
    get drive() {
        return this._drive;
    }
    set drive(value) {
        this._lastDrive = cloneDeep(this._drive);
        this._drive = value;
        this.handleDriveChanged(this._drive, this._lastDrive);
    }

    @track _dayStatusMapping = {};
    @api
    get dayStatusMapping() {
        return this._dayStatusMapping || {}
    }
    set dayStatusMapping(value) {
        this._dayStatusMapping = value;
        this.updateCalendarsStatus();
    }

    @track opportunity = null;
    @track showSpinner = false;
    @track disabledDays = [];
    @track selectedDays = [];
    @track calendars = [];
    @track isSchedulePatternModalShow = false;
    @track recurringModel = {
        isRecurring: false
    }

    get patternOptions() {
        return [{
            label: 'Weekly',
            value: 'weekly'
        }, {
            label: 'Monthly on Nth',
            value: 'monthlyNth'
        }]
    }

    get recurringOnNthOptions() {
        let options = [];
        for(var i = 1; i <= 31; i++) {
            options.push({
                label: 'Day ' + i,
                value: i
            });
        }
        return options;
    }

    get recurringWeekDayOptions() {
        const weekDays = this.weekDays;
        return weekDays.map(weekDay => {
            return {
                key: 'week-day-' + weekDay,
                label: weekDay,
                value: weekDay,
                selected: (this.recurringModel.weekDays || []).includes(weekDay)
            }
        })
    }

    get recurringMonthOptions() {
        const calendars = this.calendars;
        return calendars.map(calendar => {
            return {
                key: 'month-' + calendar.dateIso,
                label: calendar.header,
                value: calendar.dateIso,
                selected: (this.recurringModel.months || []).includes(calendar.dateIso)
            }
        })
    }

    get customClass() {
        return {
            modalClass: classNames('slds-modal', `slds-modal_small`, {
                'slds-fade-in-open': this.isSchedulePatternModalShow
            }),
            headerClass: classNames('slds-modal__header', {
            }),
            footerClass: classNames('slds-modal__footer slds-grid slds-grid_vertical-align-center slds-grid_align-end', {
            }),
            backdropClass: classNames('slds-backdrop', {
                'slds-backdrop_open': this.isSchedulePatternModalShow
            })
        }
    }

    get customStyle() {
        return {
            modalStyle: [
            ].join(';'),
            backdropStyle: [
            ].join(';')
        }
    };

    _calendarHelper = null;
    get calendarHelper() {
        if (!this._calendarHelper) {
            this._calendarHelper = new calendarMonthHelper(DEFAULT_CALENDAR_SETTINGS);
        }
        return this._calendarHelper;
    }

    _planDriveHelper = null;
    get planDriveHelper() {
        if (!this._planDriveHelper) {
            this._planDriveHelper = new planDriveDateHelper(DEFAULT_CALENDAR_SETTINGS);
        }
        return this._planDriveHelper;
    }

    get weekDays() {
        return this.calendarHelper.buildWeekDays(true);
    }

    get today() {
        return DateTime.local().toJSDate();
    }

    get showWeeklyPattern() {
        return this.recurringModel.pattern === 'weekly';
    }

    get showMonthlyPattern() {
        return this.recurringModel.pattern === 'monthlyNth';
    }

    get invalidSelectedDays() {
        const selectedDays = this.selectedDays || [];
        const dayStatusMapping = this.dayStatusMapping || {};
        return selectedDays.filter(dateIso => {
            const dayStatus = dayStatusMapping[dateIso];
            return dayStatus && !dayStatus.isAvailable;
        })
    }

    get showBtnRemoveInvalidDays() {
        return this.invalidSelectedDays.length;
    }

    connectedCallback() {
        if(!this.isNotFlow){
            this.recurringModel.isRecurring = true;
        }
        if(!this.drive) {
            return;
        }



        return Promise.resolve()
            .then(() => {
                this.opportunity = cloneDeep(this.drive.opportunity);
                this.disabledDays = [];
                if(this.opportunity && this.opportunity.drives) {
                    this.disabledDays = this.opportunity.drives.map(item => item.driveDate);
                }

                return Promise.all([
                    this.retrieveAccount(this.opportunity ? this.opportunity.accountId : null)
                ])
            })
            .then(() => {
                this.planDriveHelper.initData_deprecated({
                    opportunity: this.opportunity,
                    accountAvailabilityPreferences: (this.opportunity && this.opportunity.account) ? this.opportunity.account.accountAvailabilityPreferences : []
                });

                const startMonth = DateTime.fromString(this.drive.driveDate, 'yyyy-MM-dd').startOf('month').toISODate();
                const endMonth = DateTime.fromString(startMonth, 'yyyy-MM-dd').plus({month: 11}).endOf('month').toISODate();
                this.dayAccountAvailabilityMapping = (this.opportunity && this.opportunity.account) ? this.planDriveHelper.generateDayAccountAvailabilityMapping(startMonth, endMonth) : [];
                this.generateCalendars(startMonth, endMonth);
            })
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    retrieveAccount = (accId) => {
        let accountQuery = new accountQueryModel();
        accountQuery.recordIds = [accId];
        accountQuery.subQueryIndicator = sObjectType.ACCOUNT_AVAILABILITY_PREFERENCE;

        let accountSvc = new accountService();

        this.showLoading();
        return accountSvc.query(accountQuery)
            .then((result) => {
                this.opportunity.account = first(result);
                return this.opportunity.account;
            })
            .catch(console.log)
            .finally(() => this.hideLoading());
    }

    toggleRecurring = () => {
        this.recurringModel.isRecurring = !this.recurringModel.isRecurring;
        if(!this.recurringModel.isRecurring) {
            this.updateSelectedDays([]);
        }
    }

    handleResetSeletedDays = (event) => {
        const selectedMonth = event.currentTarget.dataset['value'];
        if(selectedMonth) {
            const selectedDays = this.selectedDays.filter(dateIso => {
                const month1 = dateIso.split('-')[1];
                const month2 = selectedMonth.split('-')[1];
                return month1 !== month2;
            });
            this.updateSelectedDays(selectedDays);
        } else {
            this.updateSelectedDays([]);
        }
    }

    handleSelectDay = (event) => {
        const dateIso = event.currentTarget.dataset['value'];
        const selectedDays = this.selectedDays || [];
        let existed = selectedDays.includes(dateIso);
        if(existed) {
            remove(selectedDays, day => day === dateIso );
        } else {
            selectedDays.push(dateIso);
        }
        this.updateSelectedDays(selectedDays);
    }

    handleRemoveInvalidDays = (event) => {
        const invalidDays = this.invalidSelectedDays;
        const selectedDays = this.selectedDays.filter(dateIso => {
            return !invalidDays.includes(dateIso);
        })
        this.updateSelectedDays(selectedDays);
    }

    handleDriveChanged = (newDrive, lastDrive) => {
        let trackingFields = ['driveDate'];
        this.opportunity = cloneDeep(this.drive.opportunity);

        if(!isEqual(pick(newDrive, trackingFields), pick(lastDrive, trackingFields))) {
            //TODO: re-generate calendars
        }
    }

    updateSelectedDays = (selectedDays = []) => {
        this.selectedDays = selectedDays;
        this.updateCalendarsStatus();
        const onchangeEvent = new CustomEvent('change', {
            detail: {
                selectedDays: this.selectedDays || []
            }
        });
        this.dispatchEvent(onchangeEvent);
        console.log(JSON.stringify(this.selectedDays));
    }

    /* Schedule Pattern Modal */
    generateCalendar = (selectedMonth = DateTime.local().toISODate()) => {
        if(!selectedMonth) return [];

        let calendarHeader = DateTime.fromString(selectedMonth, 'yyyy-MM-dd').toFormat('MMMM yyyy');
        let calendarWeeks = this.calendarHelper.buildCalendarWeeks(selectedMonth, this.today);
        calendarWeeks.forEach(week => {
            week.days.forEach(day => {
                this.buildSlot(day, this.dayAccountAvailabilityMapping, this.dayStatusMapping);
                this.buildDots(day, this.dayStatusMapping);
            })
        })

        return {
            key: uniqueId('calendar_'),
            header: calendarHeader,
            dateIso: selectedMonth,
            weeks: calendarWeeks
        };
    }

    generateCalendars = (startMonth, endMonth) => {
        this.calendars = [];
        let currentMonth = startMonth;
        for(currentMonth; currentMonth <= endMonth; ) {
            this.calendars.push(this.generateCalendar(currentMonth));
            currentMonth = DateTime.fromString(currentMonth, 'yyyy-MM-dd').plus({month: 1}).toISODate();
        }
    }

    updateCalendarsStatus = () => {
        const calendars = this.calendars || [];

        calendars.forEach(calendar => {
            calendar.weeks.forEach(week => {
                week.days.forEach(day => {
                    this.buildSlot(day, this.dayAccountAvailabilityMapping, this.dayStatusMapping);
                    this.buildDots(day, this.dayStatusMapping);
                })
            })
        })
    }

    buildSlot = (day, dayAccountAvailabilityMapping = {}, dayStatusMapping = {}) => {
        //reset
        day.class = day.class.replace('selected', '').trim();
        day.class = day.class.replace('validated', '').trim();
        day.class = day.class.replace('disabled', '').trim();

        if (day.isOutOfMonth) return;

        const dayAccountAvailability = dayAccountAvailabilityMapping[day.dateIso] || {};
        const dayStatus = dayStatusMapping[day.dateIso];

        day = extend(day, {
            class: classNames(day.class, {
                'selected': this.selectedDays.includes(day.dateIso),
                'validated': !!dayStatus,
                'disabled': this.disabledDays.includes(day.dateIso)
            }),
            slotStyle: [
                `background-color: ${PLAN_DRIVE_SLOT_BACKGROUND_COLOR_SETTING[dayAccountAvailability.status]}`
            ].join(';')
        })

        return day;
    }

    buildDots = (day, dayStatusMapping = {}) => {
        day.dots = [];
        day.showPopover = false;

        const isSelected = this.selectedDays.includes(day.dateIso);
        if(day.isOutOfMonth || !dayStatusMapping[day.dateIso] || !isSelected) return;

        const dayStatus = dayStatusMapping[day.dateIso] || {};
        const isAvailable = dayStatus.isAvailable;

        day.dots.push({
            key: uniqueId('dot_'),
            style: [
                `background-color: ${PLAN_DRIVE_SLOT_COLOR_SETTING[isAvailable]}`
            ].join(';'),
        })

        day = extend(day, {
            showPopover: !!dayStatus,
            popoverData: {
                ...dayStatus,
                colorStyle: [
                    `color: ${PLAN_DRIVE_SLOT_COLOR_SETTING[isAvailable]}`
                ].join(';'),
                barStyle: [
                    `background-color: ${PLAN_DRIVE_SLOT_COLOR_SETTING[isAvailable]}`
                ].join(';'),
                driveLimitIconStyle: [
                    `background-color: ${PLAN_DRIVE_SLOT_COLOR_SETTING[dayStatus.isDriveLimitValid]}`
                ].join(';'),
                resourceIconStyle: [
                    `background-color: ${PLAN_DRIVE_SLOT_COLOR_SETTING[dayStatus.isEnoughResources]}`
                ].join(';'),
                vehicleIconStyle: [
                    `background-color: ${PLAN_DRIVE_SLOT_COLOR_SETTING[dayStatus.isEnoughVehicles]}`
                ].join(';')
            }
        })


        return day;
    }

    showSchedulePatternModal = () => {
        this.isSchedulePatternModalShow = true;
        this.initSchedulePatternModal();
    }

    saveSchedulePatternModal = () => {
        const selectedDays = this.generateSelectedDaysFromRecurringModel(this.recurringModel);
        if(this.recurringModel.resetBeforeApply) {
            this.updateSelectedDays(selectedDays);
        } else {
            this.updateSelectedDays(union(this.selectedDays, selectedDays));
        }
        this.driveDate = this.recurringModel.startDate;
        this.closeSchedulePatternModal();
    }

    closeSchedulePatternModal = () => {
        this.isSchedulePatternModalShow = false;
    }

    initSchedulePatternModal = () => {
        this.recurringModel = extend(this.recurringModel, {
            pattern: 'weekly',
            nthDay: 1,
            weekDays: [],
            months: this.recurringMonthOptions.map(item => item.value),
            startDate: DateTime.local().toISODate(),
            resetBeforeApply: false,
            allMonthSelected: true
        });
        this.recurringModel.startDate = this.driveDate;
    }

    generateSelectedDaysFromRecurringModel = (recurringModel) => {
        if(!recurringModel || !this.calendars || !this.calendars.length) return [];
        if(!recurringModel.months || !recurringModel.months.length) return [];

        const isWeekDayValid = (dateObj) => {
            const selectedWeekDays = recurringModel.weekDays || [];
            const weekDay = dateObj.toFormat('ccc');
            return selectedWeekDays.includes(weekDay);
        }

        const isMonthValid = (dateObj) => {
            const selectedMonths = recurringModel.months || [];
            const month = dateObj.startOf('month').toISODate();
            return selectedMonths.includes(month);
        }

        const isNthDayValid = (dateObj) => {
            const selectedNthDay = recurringModel.nthDay;
            const nthDay = Number(dateObj.toFormat('d'));
            return selectedNthDay === nthDay;
        }

        const isDayDisabled = (dateObj) => {
            const dateIso = dateObj.toISODate();
            const disabledDays = this.disabledDays || [];
            return disabledDays.includes(dateIso);
        }

        const calendars = this.calendars;
        const maxSelectedMonth = max(recurringModel.months);
        const minStartDate = find(first(first(calendars).weeks).days, day => {
            return !day.isOutOfMonth;
        }).dateIso;
        const maxEndDate = findLast(last(find(calendars, calendar => {
            return calendar.dateIso >= maxSelectedMonth;
        }).weeks).days, day => {
            return !day.isOutOfMonth;
        }).dateIso;
        let startDate = recurringModel.startDate;
        if(!startDate) {
            startDate = minStartDate;
        }
        let endDate = maxEndDate;
        if(startDate > endDate) return [];

        let currentDate = startDate;
        let result = [];
        while(currentDate <= endDate) {
            const currentDateObj = DateTime.fromFormat(currentDate, 'yyyy-MM-dd');
            const disabledDay = isDayDisabled(currentDateObj);
            const monthValid = isMonthValid(currentDateObj);
            if(!disabledDay && monthValid) {
                if(recurringModel.pattern === 'weekly') {
                    if(isWeekDayValid(currentDateObj)) {
                        result.push(currentDate);
                    }
                } else if (recurringModel.pattern === 'monthlyNth') {
                    if(isNthDayValid(currentDateObj)) {
                        result.push(currentDate);
                    }
                }
            }

            currentDate = currentDateObj.plus({
                day: 1
            }).toISODate();
        }

        return result;
    }

    handleRecurringModelChanged = (event) => {
        let value = getValueFromEvent(event);
        this.recurringModel[event.target.name] = value;
        if(event.target.name === 'startDate'){
            this._driveDate = value;
            const attributeChangeEvent = new FlowAttributeChangeEvent('driveDate', this._driveDate);
            this.dispatchEvent(attributeChangeEvent);
        }
        if (event.target.name === 'nthDay') {
            this.recurringModel[event.target.name] = Number(value);
        }

        if (event.target.name === 'isRecurring' && !this.recurringModel.isRecurring) {
            this.updateSelectedDays([]);
        }

        if (event.target.name.includes('week-day-')) {
            const value = event.currentTarget.dataset['value'];
            const existed = this.recurringModel.weekDays.includes(value);
            if(existed) {
                remove(this.recurringModel.weekDays, weekDay => weekDay === value);
            } else {
                this.recurringModel.weekDays.push(value);
            }
        }

        if (event.target.name.includes('month-')) {
            const value = event.currentTarget.dataset['value'];
            const existed = this.recurringModel.months.includes(value);
            if(existed) {
                remove(this.recurringModel.months, month => month === value);
            } else {
                this.recurringModel.months.push(value);
            }
        }

        if (event.target.name === 'allMonthSelected') {
            const value = this.recurringModel.allMonthSelected;
            if(value) {
                this.recurringModel.months = this.recurringMonthOptions.map(item => item.value);
            } else {
                this.recurringModel.months = [];
            }
        }
    }
}