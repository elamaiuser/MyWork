import { LightningElement, api, track } from 'lwc';
import { resourceService } from 'c/dataService';

export default class SlwcResourceTemplates extends LightningElement {
    @api recordId;

    @track template_entry_columns = [
        { label: 'Weekday', fieldName: 'weekday' },
        { label: 'Start Time', fieldName: 'startTime' },
        { label: 'Finish Time', fieldName: 'finishTime' }
    ];

    @track availabilityTemplates;

    connectedCallback() {
        resourceService.getResourceTemplates({ resourceId: this.recordId })
            .then(skedTemplates => {
                this.processTemplateData(skedTemplates);
            })
    }

    processTemplateData(skedTemplates) {
        let mapWeekday = {
            SUN : 0,
            MON : 1,
            TUE : 2,
            WED : 3,
            THU : 4,
            FRI : 5,
            SAT : 6
        };

        let mapWeekdayName = {
            SUN : 'Sunday',
            MON : 'Monday',
            TUE : 'Tuesday',
            WED : 'Wednesday',
            THU : 'Thursday',
            FRI : 'Friday',
            SAT : 'Satruday'
        };

        let templates = [];
        skedTemplates
            .forEach(skedTemplate => {
                let template = {
                    id : skedTemplate.Id,
                    name : skedTemplate.Name,
                    start: this.toLocaleDateString(skedTemplate.sked__Start__c),
                    finish: this.toLocaleDateString(skedTemplate.sked__Finish__c)
                };
                templates.push(template);

                template.entries = [];
                skedTemplate.sked__Availability_Template_Entries__r
                    .forEach(skedEntry => {
                        let entry = {
                            id : skedEntry.Id,
                            startTime : this.convertTimeIntToString(skedEntry.sked__Start_Time__c),
                            finishTime : this.convertTimeIntToString(skedEntry.sked__Finish_Time__c),
                            weekday : mapWeekdayName[skedEntry.sked__Weekday__c],
                            weekdayIndex : mapWeekday[skedEntry.sked__Weekday__c]
                        };
                        template.entries.push(entry);
                    });
                    template.entries.sort(function (entryA, entryB) {
                        if (entryA.weekdayIndex > entryB.weekdayIndex) {
                            return 1;
                        }
                        if (entryB.weekdayIndex > entryA.weekdayIndex) {
                            return -1;
                        }
                        return 0;
                    });
            });
        this.availabilityTemplates = templates;
    }

    convertTimeIntToString(timeInt) {
        let hour = timeInt / 100;
        let minute = timeInt % 100;
        let period = 'AM';
        if (hour === 0 || hour === 24) {
            hour = 12;
        }
        else if (hour > 12) {
            hour -= 12;
            period = 'PM';
        }
        return hour + ':' + this.padZeroLeft(minute, 2) + ' ' + period;
    }

    padZeroLeft(str, max) {
        str = str.toString();
        return str.length < max ? this.padZeroLeft("0" + str, max) : str;
    }

    toLocaleDateString(dateStr) {
        if (dateStr) {
            return new Date(dateStr).toLocaleDateString();
        }
        return 'N/A';
    }
}