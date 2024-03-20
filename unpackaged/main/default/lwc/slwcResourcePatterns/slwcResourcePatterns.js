import { LightningElement, api, track } from 'lwc';
import { resourceService } from 'c/dataService';

export default class SlwcResourcePatterns extends LightningElement {
    @api recordId;

    @track weekly_columns = [
        { label: 'Weekday', fieldName: 'weekday' },
        { label: 'Start Time', fieldName: 'startTime' },
        { label: 'End Time', fieldName: 'endTime' }
    ];

    @track custom_columns = [
        { label: 'Day', fieldName: 'day' },
        { label: 'Start Time', fieldName: 'startTime' },
        { label: 'End Time', fieldName: 'endTime' }
    ];

    @track patternResources;

    connectedCallback() {
        let service = new resourceService();
        service.getPatternResources({ resourceId: this.recordId })
            .then(skedPatternResources => {
                this.processPatternResourceData(skedPatternResources);
            })
    }

    processPatternResourceData(skedPatternResources) {
        let mapWeekdayName = {
            SUN : 'Sunday',
            MON : 'Monday',
            TUE : 'Tuesday',
            WED : 'Wednesday',
            THU : 'Thursday',
            FRI : 'Friday',
            SAT : 'Satruday'
        };
        
        let patternResources = [];
        skedPatternResources
            .forEach(skedPatternResource => {
                let patternResource = {
                    id : skedPatternResource.Id,
                    patternName : skedPatternResource.sked__Availability_Pattern__r.Name,
                    start: this.toLocaleDateString(skedPatternResource.sked__Start__c),
                    finish: this.toLocaleDateString(skedPatternResource.sked__End__c),
                    patternData: JSON.parse(skedPatternResource.sked__Availability_Pattern__r.sked__Pattern__c)
                };

                patternResource.patternData.isWeekly = patternResource.patternData.type == 'weekly';
                if (patternResource.patternData.isWeekly) {
                    var weeklyTable = [];
                    patternResource.patternData.days.forEach(day => {
                        let row = {
                            weekday : mapWeekdayName[day.weekday],
                            startTime : day.intervals[0].startTime,
                            endTime : day.intervals[0].endTime
                        };
                        weeklyTable.push(row);
                    });
                    patternResource.patternData.weeklyTable = weeklyTable;
                }

                patternResource.patternData.isCustom = patternResource.patternData.type == 'custom';
                if (patternResource.patternData.isCustom) {
                    var customTable = [];
                    patternResource.patternData.days.forEach(day => {
                        let row = {
                            day : 'Day ' + day.day,
                            startTime : day.intervals[0].startTime,
                            endTime : day.intervals[0].endTime
                        };
                        customTable.push(row);
                    });
                    patternResource.patternData.customTable = customTable;
                }

                patternResources.push(patternResource);
            });
        this.patternResources = patternResources;
    }

    toLocaleDateString(dateStr) {
        if (dateStr) {
            return new Date(dateStr).toLocaleDateString();
        }
        return 'N/A';
    }
}