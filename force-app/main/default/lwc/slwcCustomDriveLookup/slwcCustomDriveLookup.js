import { LightningElement, track, api } from 'lwc';
import { getValueFromEvent } from "c/slwcUtils";
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { driveService, driveQueryModel } from 'c/dataService';
import { debounce } from "c/lodash";

export default class SlwcCustomDriveLookup extends LightningElement {
    DRIVE_TABLE_COLUMNS = [
        {label: 'Drive Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' }, hideDefaultActions: true },
        {label: 'UFID', fieldName: 'ufid', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true },
        {label: 'Drive Type', fieldName: 'typeOfDrive', type: 'text', hideDefaultActions: true, wrapText: true },
        {label: 'Drive Status', fieldName: 'status', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true },
        {label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true, wrapText: true },
        {label: 'Start Time', fieldName: 'startTime', type: 'time', hideDefaultActions: true, wrapText: true },
        {label: 'End Time', fieldName: 'endTime', type: 'time', hideDefaultActions: true, wrapText: true },
        {label: '# of Staff Requested', fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
        {label: '# of Machines Requested', fieldName: 'totalEquipmentRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
        {label: 'Proj Reg Donors', fieldName: 'projectedRegisteredDonors', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    ];

    @api label = '';
    @api defaultFilters = null;

    @track filters = {};
    @track drives = [];

    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        });
    }

    connectedCallback() {
        this.filters = {
            ufid: '',
            startDate: this.dateUtils.startOfWeek(DateTime.local(), 0).toISODate(),
            endDate: DateTime.fromISO(this.dateUtils.startOfWeek(DateTime.local(), 0).toISODate()).plus({
                day: 6
            }).toISODate(),
            driveStatuses: ['System Generated', 'Hold', 'Tentative', 'Confirmed', 'Complete'],
            driveTypes: ['Fixed Site', 'Mobile']
        };

        this.fetchResult();
    }

    handleFilterChanged(event) {
        if(event.currentTarget.name === 'ufid') {
            this.debounceFunc && this.debounceFunc.cancel();
            this.debounceFunc = debounce(() => {
                let value = getValueFromEvent(event);
                this.filters.ufid = value;
                this.fetchResult();
            }, 700);
            this.debounceFunc();
            return;
        }

        if (event.type === 'weekdatechange') {
            this.filters = {
                ...this.filters, 
                startDate: event.detail.startDate,
                endDate: event.detail.endDate
            }
        } else {
            let value = getValueFromEvent(event);
            this.filters[event.currentTarget.name] = value;
        }

        this.fetchResult();
    }

    /* Search Drive Modal */
    fetchResult() {
        this.showLoading();
        const transformDrive = (item) => {
            return {
              ...item,
              recordPageUrl: '/' + item.id,
            }
        }

        let queryModel = new driveQueryModel();
        let service = new driveService();

        queryModel.startDate = this.filters.startDate;
        queryModel.endDate = this.filters.endDate;
        queryModel.statuses = this.filters.driveStatuses;
        queryModel.eventTypes = this.filters.driveTypes;
        queryModel.ufid = this.filters.ufid;

        if(this.defaultFilters) {
            queryModel.excludedIds = this.defaultFilters.excludedIds;
        }

        return service.query(queryModel)
        .then((result) => {
          this.drives = (result || []).map(transformDrive);
        })
        .catch((e) => this.exceptionHandler(e))
        .finally(() => { this.hideLoading(); });
    }

    @api selectedDrive;
    handleRowSelection(event) {
        this.selectedDrive = (event.detail.selectedRows && event.detail.selectedRows.length) ? event.detail.selectedRows[0] : null;
        
        this.dispatchEvent(new CustomEvent('driveselected', {
            detail: {
                drive: this.selectedDrive
            }
        }));
    }

    showLoading() {
        this.dispatchEvent(new CustomEvent('showloading'));
    }

    hideLoading() {
        this.dispatchEvent(new CustomEvent('hideloading'));
    }
}