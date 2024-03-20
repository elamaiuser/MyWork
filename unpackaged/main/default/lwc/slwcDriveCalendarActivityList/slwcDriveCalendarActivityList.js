import { LightningElement, track, api } from 'lwc';
import {
    loadStyle
} from 'lightning/platformResourceLoader';
import { sObjectType, activityQueryModel, activityService } from 'c/dataService';
import { DateTime } from "c/luxon";
import customLWCStyle from '@salesforce/resourceUrl/skedLWCCustomStyle'
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcActivityCalendarActivityList extends LightningElement {
    @track showSpinner = false;
    @track activityList;
    @track hasResult = false;
    @track totalActivities = 0;

    _filters = {};

    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value;
        this.getActivityList();
    }

    @api includesAdditionalDays = 0;

    get columns() {
        let results = [];
        results.push({label: 'Activity Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: {label: { fieldName: 'activityTitle' }, target: '_blank' }, hideDefaultActions: true } );
        results.push({label: 'Type', fieldName: 'eventType', type: 'text', hideDefaultActions: true, wrapText: true } );
        results.push({label: 'Sub-type', fieldName: 'subtype', type: 'text', hideDefaultActions: true, wrapText: true } );
        results.push({label: 'Start', fieldName: 'start', initialWidth: 160, type: 'date', typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            timeZone: TIME_ZONE
        }, cellAttributes: { alignment: 'left', class: { fieldName: 'activityDateClass' } }, hideDefaultActions: true } );
        results.push({label: 'End', fieldName: 'finish', initialWidth: 160, type: 'date', 
        typeAttributes: {
            year: 'numeric',
            month: 'numeric',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            timeZone: TIME_ZONE
        }, cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: '# of Resources', fieldName: 'quantityText', type: 'text', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Resources/Assets', fieldName: 'resources', type: 'resources', initialWidth: 250, hideDefaultActions: true } );
        results.push({label: 'MDL Drives', fieldName: 'linkedDrivesUrl', type: 'url', initialWidth: 160, typeAttributes: {label: { fieldName: 'linkedDrivesName' }, target: '_blank' }, cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Linked Drive', fieldName: 'driveUrl', type: 'url', initialWidth: 200, typeAttributes: {label: { fieldName: 'driveName' }, target: '_blank' }, cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Notes', fieldName: 'notes', type: 'text', initialWidth: 250, wrapText: true, cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        return results;
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, customLWCStyle)
        ])
        .then(() => {

        })
    }

    getActivityList() {
        this.showSpinner = true;
        this.filteredList = [];
        const territoryKeys = this._filters.territoryKeys;

        let startDate = this.filters.startDate;
        let endDate = this.filters.endDate;

        if(this.includesAdditionalDays > 0) {
            startDate = DateTime.fromISO(startDate).minus({
                day: this.includesAdditionalDays
            }).toISODate();
            endDate = DateTime.fromISO(endDate).plus({
                day: this.includesAdditionalDays
            }).toISODate()
        }

        let activityQuery = new activityQueryModel();
        activityQuery.territoryKeys = territoryKeys;
        activityQuery.startDate = startDate;
        activityQuery.endDate = endDate;
        activityQuery.isGroupActivity = true;
        activityQuery.isShowOnCalendar = true;
        activityQuery.showOnlyLinkedEvents = this.filters.showOnlyLinkedEvents;
        activityQuery.subQueryIndicator = sObjectType.ACTIVITY_RESOURCE;

        let service = new activityService();
        service.query(activityQuery)
            .then((result) => {
                let activities = [];
                if (result && result.length) {
                    result.forEach((activity) => {
                        activity.recordPageUrl = '/' + activity.id;
                        activity.driveUrl = activity.driveId ? '/' + activity.driveId : null;
                        activity.linkedDrivesUrl = activity.linkedDrivesId ? '/' + activity.linkedDrivesId : null;
                        activity.quantityText = [(activity.activityResources || []).length, activity.quantity || ''].join('/');
                        activity.activityDate = DateTime.fromISO(activity.start).toISODate();
                        activity.activityDateClass = (activity.activityDate < this.filters.startDate || 
                            activity.activityDate > this.filters.endDate) ? 'background-green-super-light important' : 'background-blue-super-light important';
                        activity.resources = (activity.activityResources || []).map(activityResource => {
                            return activityResource.resource;
                        })
                        activities.push(activity);
                    });
                }
                this.totalActivities = activities.length;
                this.activityList = activities;
            })
            .catch((error) => {
                console.log(error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
}