import { getValueFromEvent } from "c/slwcUtils";
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { driveService, driveQueryModel } from 'c/dataService';
import { debounce } from "c/lodash";

export default class skedDriveController {
    constructor() {}

    getTableColumns() {
        return [
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
    }

    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        });
    }

    init() { }

    getDefaultFilters() {
        return {
            ufid: '',
            startDate: this.dateUtils.startOfWeek(DateTime.local(), 0).toISODate(),
            endDate: DateTime.fromISO(this.dateUtils.startOfWeek(DateTime.local(), 0).toISODate()).plus({
                day: 6
            }).toISODate(),
            driveStatuses: ['System Generated', 'Hold', 'Tentative', 'Confirmed', 'Complete'],
            driveTypes: ['Fixed Site', 'Mobile']
        }
    }

    getService() {
        return new driveService();
    }

    getPopulatedQuery(filters, defaultFilters) {
        let driveQuery = new driveQueryModel();
        driveQuery.startDate = filters.startDate;
        driveQuery.endDate = filters.endDate;
        driveQuery.statuses = filters.driveStatuses;
        driveQuery.eventTypes = filters.driveTypes;
        driveQuery.ufid = filters.ufid;

        if(defaultFilters) {
            driveQuery.excludedIds = defaultFilters.excludedIds;
        }

        return driveQuery;
    }

    transformResults(items) {
        return items.map(item => {
            return {
                ...item,
                recordPageUrl: '/' + item.id
            }
        });
    }

    fetchResults(filters, defaultFilters) {
        let service = this.getService();
        let queryModel = this.getPopulatedQuery(filters, defaultFilters);

        return service.query(queryModel)
        .then((results) => {
            return this.transformResults(results);
        });
    }

    handleFilterChanged(event, filters) {
        if (event.type === 'weekdatechange') {
            filters = {
                ...filters, 
                startDate: event.detail.startDate,
                endDate: event.detail.endDate
            }
        } else {
            let value = getValueFromEvent(event);
            filters[event.currentTarget.name] = value;
        }

        return filters;
    }

}