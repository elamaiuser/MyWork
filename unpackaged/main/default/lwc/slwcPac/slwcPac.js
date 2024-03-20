import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { uniqueId, padStart } from 'c/lodash';
import { DateTime } from 'c/luxon';
import * as slwcDateUtils from 'c/slwcDateUtils';
import * as slwcUtils from 'c/slwcUtils';
import { PAC_LAYOUT_MODE } from 'c/slwcConstants';
import { sObjectType, dataService, clientAvailabilityService, accountService, accountQueryModel } from 'c/dataService';
import _calendarMetadata from './calendarMetadata';

export default class SlwcPac extends LightningElement {
    // @api recordId = '0013F00000a55W8QAI';
    @api recordId;

    @wire(CurrentPageReference) pageRef;

    @track queryModel;
    @track hasResult = false;
    @track calendarData = null;
    @track calendarSettings = null;
    @track calendarConfigData = null;
    @track showSpinnerCount = 0;
    account;

    get showSpinner() {
        return this.showSpinnerCount > 0;
    }

    get dateUtils() {
        return slwcDateUtils.getInstance(this.calendarSettings);
    }
    
    get calendarDateRange() {
        return {
            startDate: this.queryModel.startDate,
            endDate: this.queryModel.endDate
        }
    }

    get calendarMetadata() {
      return _calendarMetadata;
    }

    get layoutModeOptions() {
        return [
            {
                label: 'Weeks',
                value: PAC_LAYOUT_MODE.WEEKS
            },
            {

                label: 'Month',
                value: PAC_LAYOUT_MODE.MONTH
            }
        ]
    }
    
    get showCalendarWeeks() {
        return this.queryModel.layoutMode === PAC_LAYOUT_MODE.WEEKS;
    }

    get showCalendarMonth() {
        return this.queryModel.layoutMode === PAC_LAYOUT_MODE.MONTH;
    }

    get isValidQueryModel() {
        return !slwcUtils.isNullOrEmpty(this.recordId) &&
            !slwcUtils.isNullOrEmpty(this.queryModel.startDate) &&
            !slwcUtils.isNullOrEmpty(this.queryModel.endDate)
    }

    connectedCallback() {
        registerListener('onClientAvailabilityDMLCompleted', this.handleOnClientAvailabilityDMLCompleted, this);

        if(!this.recordId) {
            //TODO: handle error
            return;
        }

        this.setDefaultQueryModel();

        let settingKeys = ["pac"];
        let accountSvc = new accountService();
        let accountQuery = new accountQueryModel();
        accountQuery.recordIds = [this.recordId];
        accountQuery.subQueryIndicator = sObjectType.ACCOUNT_AVAILABILITY_PREFERENCE;
        
        this.showLoading();
        return Promise.all([
            accountSvc.getCustomSettings({settingKeys: settingKeys}),
            accountSvc.query(accountQuery)
        ])
        .then(([customSettingsKeyResult, accountResult]) => {
            this.calendarSettings = customSettingsKeyResult.returnedData.pac;
            this.calendarSettings.timezone = TIME_ZONE;
            const templateAvailabilitySettings = customSettingsKeyResult.returnedData.pac.eventTypeSettings.filter(item => {
                return item.objectType === 'clientAvailability';
            }).map(item => {
                return {...item, objectType: 'templateAvailability'};
            })

            this.calendarConfigData = {
              eventTypeSettings: customSettingsKeyResult.returnedData.pac.eventTypeSettings.concat(templateAvailabilitySettings || [])
            }

            this.account = accountResult[0];

            //trigger change to refresh the calendar
            this.handleOnChange({
                type: 'weekdatechange',
                detail: {
                    startDate: this.queryModel.startDate,
                    endDate: this.queryModel.endDate
                }
            })
        })
        .catch((error) => {
            console.log(error);
        })
        .finally(() => {
            this.hideLoading();
        });
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleOnClientAvailabilityDMLCompleted(detail) {
        this.getClientAvailability();
    }

    showLoading = () => {
        this.showSpinnerCount++;
      }
    
    hideLoading = () => {
        this.showSpinnerCount--;
        if(this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        } 
    }

    setDefaultQueryModel() {
        this.queryModel = {
            accountId: this.recordId,
            layoutMode: PAC_LAYOUT_MODE.WEEKS,
            startDate: this.dateUtils.startOf(new Date(), 'week'),
            endDate: this.dateUtils.endOf(new Date(), 'week')
        }
    }

    handleOnChange(event) {
        if (event.type === 'weekdatechange') {
            this.queryModel.startDate = event.detail.startDate;
            this.queryModel.endDate = event.detail.endDate;
            this.queryModel.selectedMonth = this.queryModel.startDate;
        } else if (event.type === 'monthchange') {
            this.queryModel.selectedMonth = event.detail.selectedDate;
            this.queryModel.startDate = event.detail.selectedDate;
        } else {
            this.queryModel[event.target.name] = slwcUtils.getValueFromEvent(event);
        }

        if(this.queryModel.layoutMode === PAC_LAYOUT_MODE.WEEKS) {
            if (this.calendarSettings && this.calendarSettings.viewPeriod) {
                let noOfDays = this.calendarSettings.viewPeriod * 7;
                let startDateDt = DateTime.fromISO(this.queryModel.startDate, {zone: this.calendarSettings.timezone});
                let endDateDt = startDateDt.plus( {day: noOfDays - 1} );
                this.queryModel.startDate = startDateDt.toISODate();
                this.queryModel.endDate = endDateDt.toISODate();
            }
        }

        if(this.queryModel.layoutMode === PAC_LAYOUT_MODE.MONTH) {
            this.queryModel.startDate = this.dateUtils.startOf(this.dateUtils.startOf(this.queryModel.selectedMonth, 'month'), 'week');
            this.queryModel.endDate = this.dateUtils.endOf(this.dateUtils.endOf(this.queryModel.selectedMonth, 'month'), 'week');
        }

        this.getClientAvailability();
    }

    getClientAvailability() {
        if (this.isValidQueryModel) {
            this.showLoading();
            let service = new clientAvailabilityService();
            return service.getClientAvailability(this.queryModel)
                .then((result) => {
                    this.hasResult = true;
                    this.calendarData = {
                        clientAvailabilities: result.clientAvailabilities,
                        drives: result.drives,
                        templateAvailabilities: this.generateClientAvailability(),
                    }
                })
                .catch((error) => {
                    console.log(JSON.stringify(error));
                })
                .finally(() => {
                    slwcUtils.setLastQuery("Drive Optimizer", this.queryModel);
                    this.hideLoading();
                });
        }
    }

    refresh() {
        this.getClientAvailability();
    }

    createAvailability() {
        let eventValues = { action: "create", model: null };
        fireEvent(this.pageRef, 'showClientAvailabilityModal', eventValues);
    }

    generateClientAvailability() {
        let daysOfWeekDeclined = this.account.daysOfWeekDeclined || [];
        let daysOfWeekPreferred = this.account.daysOfWeekPreferred || [];

        let templateAvailabilities = [];
        let startDate = DateTime.fromISO(this.queryModel.startDate, {zone: this.calendarSettings.timezone});
        let endDate = DateTime.fromISO(this.queryModel.endDate, {zone: this.calendarSettings.timezone});
        let tempDate = startDate;
        while (tempDate.ts <= endDate.ts) {
            let avail = {
                id: uniqueId('templateAvailability_'),
                start: tempDate.toUTC().toISO(),
                finish: tempDate.plus({day: 1}).toUTC().toISO(),
                objectType: 'templateAvailability'
            }

            let preference = (this.account.accountAvailabilityPreferences || []).find(item => item.monthName == tempDate.monthLong);
            if (preference) {
                let isPreferredWeekday = preference.preferredWeekdays && preference.preferredWeekdays.indexOf(tempDate.weekdayLong) > -1;
                let isRestrictedWeekday = preference.restrictedWeekdays && preference.restrictedWeekdays.indexOf(tempDate.weekdayLong) > -1;

                let startOfMonth = tempDate.startOf('month');
                let startOfMonthWeekIndex = tempDate.startOf('month').weekday;
                if (startOfMonthWeekIndex == 7) {
                    startOfMonthWeekIndex = 1;
                }
                else {
                    startOfMonthWeekIndex = startOfMonthWeekIndex + 1;
                }
                
                let dayDiff = tempDate.diff(startOfMonth, ['days']).values.days;
                let weekNo = Math.ceil((startOfMonthWeekIndex + dayDiff) / 7);
                let weekName = "Week " + weekNo;
                
                let idPreferredWeek = preference.preferredWeeks && preference.preferredWeeks.indexOf(weekName) > -1;
                let idRestrictedWeek = preference.restrictedWeeks && preference.restrictedWeeks.indexOf(weekName) > -1;
                
                if (isPreferredWeekday || isRestrictedWeekday || idPreferredWeek || idRestrictedWeek) {
                    avail.isAvailable = !(isRestrictedWeekday || idRestrictedWeek);
                    templateAvailabilities.push(avail);
                }
            }
            else {
                if (daysOfWeekDeclined.indexOf(tempDate.weekdayLong) > -1) {
                    avail.isAvailable = false;
                    templateAvailabilities.push(avail);
                }
                else if (daysOfWeekPreferred.indexOf(tempDate.weekdayLong) > -1) {
                    avail.isAvailable = true;
                    templateAvailabilities.push(avail);
                }
            }
            tempDate = tempDate.plus({day: 1});
        }
            
        return templateAvailabilities;
    }

    addEvent(event) {
        let eventValues = { action: "create", model: event };
        fireEvent(this.pageRef, 'showClientAvailabilityModal', eventValues);
    }

    handleSelectTimes(event) {
        let detail = event.detail;
        this.addEvent({
            start: detail.start ? this.dateUtils.parseDateTimeInfo(detail.start.date, detail.start.time) : null,
            finish: detail.finish ? this.dateUtils.parseDateTimeInfo(detail.finish.date, detail.finish.time) : null
        });
    }
}