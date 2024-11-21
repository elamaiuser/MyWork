import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { uniqueId } from 'c/lodash';
import { DateTime } from 'c/luxon';

import * as slwcUtils from 'c/slwcUtils';
import { dataService, locationAvailabilityService, locationService, locationQueryModel } from 'c/dataService';
import _calendarMetadata from './calendarMetadata';

export default class SlwcLac extends LightningElement {
    @api recordId;

    @wire(CurrentPageReference) pageRef;

    @track queryModel;
    @track hasResult = false;
    @track showSpinner = false;
    @track calendarData = null;
    @track calendarSettings = null;
    @track calendarConfigData = null;

    location;

    get calendarDateRange() {
        let startDate = this.queryModel.startDate;
        let endDate = this.queryModel.endDate;
        if (this.calendarSettings && this.calendarSettings.viewPeriod) {
            let noOfDays = this.calendarSettings.viewPeriod * 7;
            let startDateDt = DateTime.fromISO(this.queryModel.startDate, {zone: TIME_ZONE});
            let endDateDt = startDateDt.plus( {day: noOfDays - 1} );
            startDate = startDateDt.toISODate();
            endDate = endDateDt.toISODate();
        }
        return {
            startDate: startDate,
            endDate: endDate
        }
    }

    get calendarMetadata() {
      return _calendarMetadata;
    }

    connectedCallback() {
        registerListener('onLocationAvailabilityDMLCompleted', this.handleOnLocationAvailabilityDMLCompleted, this);

        this.queryModel = {
            locationId: this.recordId,
            endDate: null,
            startDate: null
        }

        this.showSpinner = true;
        let settingKeys = ["lac"];
        let service = new dataService();
        service.getCustomSettings({settingKeys: settingKeys})
          .then(result => {
            this.calendarSettings = result.returnedData.lac;
            this.calendarSettings.timezone = TIME_ZONE;

            const templateAvailabilitySettings = result.returnedData.lac.eventTypeSettings.filter(item => {
                return item.objectType === 'locationAvailability';
            }).map(item => {
                return {...item, objectType: 'templateAvailability'};
            })

            this.calendarConfigData = {
              eventTypeSettings: result.returnedData.lac.eventTypeSettings.concat(templateAvailabilitySettings || [])
            }
          })
          .catch((error) => {
              console.log(JSON.stringify(error));
          })
          .finally(() => {
              this.showSpinner = false;
          });

        if (this.recordId) {
            let locationSvc = new locationService();
            let locationQuery = new locationQueryModel();
            locationQuery.recordIds = [this.recordId];
            locationSvc.query(locationQuery)
                .then((result) => {
                    this.location = result[0];
                })
                .catch((error) => {
                    console.log(JSON.stringify(error));
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleOnLocationAvailabilityDMLCompleted(detail) {
        this.getLocationAvailability();
    }

    handleOnChange(event) {
        if (event.type === 'weekdatechange') {
            this.queryModel.startDate = event.detail.startDate;
            this.queryModel.endDate = event.detail.endDate;
        } else {
            this.queryModel[event.target.name] = slwcUtils.getValueFromEvent(event);
        }
        this.getLocationAvailability();
    }

    get isValidQueryModel() {
        return this.recordId != null && this.recordId != undefined &&
                this.queryModel.startDate != null && this.queryModel.startDate != undefined &&
                this.queryModel.endDate != null && this.queryModel.endDate != undefined;
    }

    getLocationAvailability() {
        if (this.isValidQueryModel) {
            this.showSpinner = true;
            let service = new locationAvailabilityService();
            service.getLocationAvailability(this.queryModel)
                .then((result) => {
                    this.hasResult = true;
                    this.calendarData = {
                        locationAvailabilities: result.locationAvailabilities,
                        drives: result.drives,
                        templateAvailabilities: this.generateLocationAvailability(),
                    }
                })
                .catch((error) => {
                    console.log(JSON.stringify(error));
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }

    refresh() {
        this.getLocationAvailability();
    }

    createAvailability() {
        let eventValues = { action: "create", model: null };
        fireEvent(this.pageRef, 'showLocationAvailabilityModal', eventValues);
    }

    generateLocationAvailability() {
        let templateAvailabilities = [];
        if (this.location.daysOfWeekDeclined || this.location.daysOfWeekPreferred) {
            let daysOfWeekDeclined = this.location.daysOfWeekDeclined ? this.location.daysOfWeekDeclined : [];
            let daysOfWeekPreferred = this.location.daysOfWeekPreferred ? this.location.daysOfWeekPreferred : [];

            let noOfDays = this.calendarSettings.viewPeriod * 7;
            let startDate = DateTime.fromISO(this.queryModel.startDate, {zone: TIME_ZONE});
            let endDate = startDate.plus( {day: noOfDays - 1} );
            let tempDate = startDate;
            while (tempDate.ts <= endDate.ts) {
                let tempWeekday = tempDate.toFormat('EEEE');
                let avail = {
                    id: uniqueId('templateAvailability_'),
                    start: tempDate.toISO(),
                    finish: tempDate.plus({day: 1}).toISO(),
                    objectType: 'templateAvailability'
                }
                if (daysOfWeekDeclined.indexOf(tempWeekday) > -1) {
                    avail.isAvailable = false;
                    templateAvailabilities.push(avail);
                }
                else if (daysOfWeekPreferred.indexOf(tempWeekday) > -1) {
                    avail.isAvailable = true;
                    templateAvailabilities.push(avail);
                }
                tempDate = tempDate.plus({day: 1});
            }
        }
        return templateAvailabilities;
    }
}