import { LightningElement, api, track } from 'lwc';
import { getValueFromEvent } from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFilteredOpportunities from '@salesforce/apex/MassUpdateOpportunity.getFilteredOpportunities';
import getActivePicklistValues from '@salesforce/apex/BSF_Utilities.getActivePicklistValues';

const DEFAULT_RECORD_LIMIT = 20;
const DEFAULT_ROW_OFFSET = 0;

export default class BsfMassUpdateOpportunityFilteringModal extends LightningElement {
    @api recordId;
    @api varSelectedOpportunityIdList = [];
    @api opportunityRecordsInTable = [];
    @api tempDriveName;
    @api tempDriveStatus;
    @api tempDayOfDrive;
    @api tempDriveDateStart;
    @api tempDriveDateEnd;
    @api tempSiteOperationType;
    @api tempDayOfDriveList;
    @api tempDriveStatusList;
    @api tempSiteOperationList;

    @track filterWrapper = {};
    @track opportunityRecords = [];
    @track enableInfiniteLoading = true;
    @track showSpinner = false;
    @track errorMessage = '';
    @track dayOfDriveList = [];
    @track driveStatusList = [];
    @track siteOperationTypeList = [];

    get opportunityColumns() {
        return [
            { label: 'Drive Name', fieldName: 'driveNameUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, initialWidth: 200, wrapText : true, cellAttributes: { alignment: 'left' } },
            { label: 'Drive Date', fieldName: 'Drive_Date__c', type: 'date-local', typeAttributes: { 
                day: "numeric", 
                month: "numeric", 
                year: "numeric" 
                },
                cellAttributes: { alignment: 'left' } 
            },
            { label: 'Drive Date Day', fieldName: 'Drive_Date_Day__c', type: 'text', initialWidth: 150, cellAttributes: { alignment: 'left' } },
            { label: 'Start Time', fieldName: 'driveStartTime', initialWidth: 110, cellAttributes: { alignment: 'left' } },
            { label: 'End Time', fieldName: 'driveEndTime', initialWidth: 100, cellAttributes: { alignment: 'left' } },
            { label: 'Drive Status', fieldName: 'DriveStatus__c', type: 'text', cellAttributes: { alignment: 'left' } },
            { label: 'WB Procedures', fieldName: 'WB_Projected_Procedures__c', type: 'number', initialWidth: 90, cellAttributes: { alignment: 'left' } },
            { label: '2RBC Procedures', fieldName: 'X2RBC_Projected_Procedures__c', type: 'number', cellAttributes: { alignment: 'left' } },
            { label: 'Plasma Procedures', fieldName: 'Plasma_Pheresis_Projected_Procedures__c', type: 'number', cellAttributes: { alignment: 'left' } },
            { label: 'Platelet Procedures', fieldName: 'Platelet_Projected_Procedures__c', type: 'number', cellAttributes: { alignment: 'left' } }
        ]
    }

    get showDataTable() {
        return this.opportunityRecords.length > 0 || this.varSelectedOpportunityIdList.length > 0;
    }

    connectedCallback() {
        this.opportunityRecords = this.opportunityRecordsInTable;
        this.initializeWrapper();
        this.getDriveStatusList();
        this.getDayOfDriveList();
        this.getSiteOperationTypeList();
    }

    initializeWrapper() {
        return {
            accountId: this.recordId,
            driveName: null,
            driveDateStart: null,
            driveDateEnd: null,
            driveStatus: [],
            dayOfDrive: [],
            siteOperationType: [],
            recordLimit: DEFAULT_RECORD_LIMIT,
            rowOffset: DEFAULT_ROW_OFFSET
        }
    }

    getDriveStatusList() {
        getActivePicklistValues({objectApiName: 'sked_Drive__c', fieldApiName: 'sked_Status__c'})
        .then(picklistValues => {
            let picklistValueList = [];
            if(picklistValues) {
                picklistValueList = picklistValues.map(picklistValue => ({
                    label: picklistValue,
                    value: picklistValue,
                    selected: false
                }));
            }
            this.driveStatusList = Array.from(picklistValueList);
            this.tempDriveStatusList = [...this.driveStatusList];
            this.tempDriveStatusList
                .filter((item) => (this.tempDriveStatus || []).find(x => x === item.value))
                .forEach((item) => (item.selected = true));
            let selectedDriveStatus = this.tempDriveStatusList.filter((item) => item.selected === true);
            if(selectedDriveStatus.length) {
                this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
                    if (element.name === 'driveStatus') {
                        element.selectedItems = this.getPlaceholder(selectedDriveStatus);
                    }
                });
            }
        })
        .catch(error => this.exceptionHandler(error))
    }
    
    getDayOfDriveList() {
        getActivePicklistValues({objectApiName: 'Opportunity', fieldApiName: 'Drive_Date_Day__c'})
        .then(picklistValues => {
                let picklistValueList = [];
                if(picklistValues) {
                    picklistValueList = picklistValues.map(picklistValue => ({
                        label: picklistValue,
                        value: picklistValue,
                        selected: false
                    }));
                }
            this.dayOfDriveList = Array.from(picklistValueList);
            this.tempDayOfDriveList = [...this.dayOfDriveList];
            this.tempDayOfDriveList
                .filter((item) => (this.tempDayOfDrive || []).find(x => x === item.value))
                .forEach((item) => (item.selected = true));
            let selectedDayOfDrive = this.tempDayOfDriveList.filter((item) => item.selected === true);
            if(selectedDayOfDrive.length) {
                this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
                    if (element.name === 'dayOfDrive') {
                        element.selectedItems = this.getPlaceholder(selectedDayOfDrive);
                    }
                });
            }
        })
        .catch(error => this.exceptionHandler(error))
    }

    getSiteOperationTypeList() {
        getActivePicklistValues({objectApiName: 'sked__Location__c', fieldApiName: 'Operation_Type__c'})
        .then(picklistValues => {
            let picklistValueList = [];
            if(picklistValues) {
                picklistValueList = picklistValues.map(picklistValue => ({
                    label: picklistValue,
                    value: picklistValue,
                    selected: false
                }));
            }
            this.siteOperationTypeList = Array.from(picklistValueList);   
            this.tempSiteOperationList = this.siteOperationTypeList;
            this.tempSiteOperationList
                .filter((item) => (this.tempSiteOperationType || []).find(x => x === item.value))
                .forEach((item) => (item.selected = true));
            let selectedSiteOperationType = this.tempSiteOperationList.filter((item) => item.selected === true);
            if(selectedSiteOperationType.length) {
                this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
                    if (element.name === 'siteOperationType') {
                        element.selectedItems = this.getPlaceholder(selectedSiteOperationType);
                    }
                });
            }
        })
        .catch(error => this.exceptionHandler(error))
    }

    getPlaceholder = (selectedItems) => {
        let selection = '';
        if (selectedItems.length > 2) {
            selection = `${selectedItems.length} Options Selected`;
        } else {
            selection = selectedItems.map((selected) => selected.label).join(', ');
        }
        return selection;
    }

    handleChange(event) {
        const fieldName = event.currentTarget.name;
        const value = getValueFromEvent(event);

        if(fieldName === 'driveName') {
            this.tempDriveName = value;
        } else if(fieldName === 'driveDateStart') {
            this.tempDriveDateStart = value;
        } else if(fieldName === 'driveDateEnd') {
            this.tempDriveDateEnd = value;
        } else if(fieldName === 'dayOfDrive') {
            this.tempDayOfDrive = this.getValuesForMultiSelectPicklist(event.detail);
            this.dayOfDriveList
                .filter((item) => this.tempDayOfDrive.find(x => x === item.value))
                .forEach((item) => (item.selected = true));
        } else if(fieldName === 'driveStatus') {
            this.tempDriveStatus = this.getValuesForMultiSelectPicklist(event.detail);
            console.log('this.tempDriveStatus ',this.tempDriveStatus);
            this.driveStatusList
                .filter((item) => this.tempDriveStatus.find(x => x === item.value))
                .forEach((item) => (item.selected = true));
        } else {
            this.tempSiteOperationType = this.getValuesForMultiSelectPicklist(event.detail);
            this.siteOperationTypeList
                .filter((item) => this.tempSiteOperationType.find(x => x === item.value))
                .forEach((item) => (item.selected = true));
        }
        
    }

    getValuesForMultiSelectPicklist(event) {
        let selectedOptionList =[];
        for(let key in event) {
            if (event[key] !== null || event[key].value !== '') {
                event[key].selected = true;
                selectedOptionList.push(event[key].value);
            }
        }
        return selectedOptionList;
    }

    handleSearch() {
        this.opportunityRecords = [];
        this.showSpinner = true;
        this.enableInfiniteLoading = false;
        this.captureUserInput();
        this.fetchData();
    }

    validateUserInput() {
        let isError = false;
        if(this.tempDriveDateStart && this.tempDriveDateEnd) {
            if(this.tempDriveDateStart > this.tempDriveDateEnd) {
                isError = true;
                this.errorMessage = 'Drive Start Date must be earlier than Drive End Date';
            } else if (this.tempDriveDateStart === this.tempDriveDateEnd) {
                isError = true;
                this.errorMessage = 'Drive Start Date and Drive End Date cannot be equal';
            }
        }
        return isError;
    }

    captureUserInput() {
        this.filterWrapper = {
            accountId: this.recordId,
            recordLimit: DEFAULT_RECORD_LIMIT,
            rowOffset: DEFAULT_ROW_OFFSET,
            siteOperationType: this.tempSiteOperationType,
            driveName: this.tempDriveName,
            driveStatus: this.tempDriveStatus,
            dayOfDrive: this.tempDayOfDrive,
            driveDateStart: this.tempDriveDateStart,
            driveDateEnd: this.tempDriveDateEnd,
        };
        console.log('this.filterWrapper ',this.filterWrapper);
    }

    fetchData() {
        this.filterWrapper.rowOffset = (this.opportunityRecords || []).length;
        return Promise.resolve()
            .then(() => {
                return getFilteredOpportunities({ filterWrapper: this.filterWrapper});
            })
            .then((result) => {
                this.showSpinner = false;
                const oppData = result.map((item) => Object.assign({}, item, {
                    driveNameUrl: '/' + item.Id,
                    driveStartTime: this.convertTimePerTimeZone(item.Start_Time__c, item.Drive_Date__c, item.Drive_Site__r.sked_Timezone__c),
                    driveEndTime: this.convertTimePerTimeZone(item.End_Time__c, item.Drive_Date__c, item.Drive_Site__r.sked_Timezone__c)
                }))
                const currentData = this.opportunityRecords || [];
                this.opportunityRecords = [...currentData, ...oppData];
                this.opportunityRecordsInTable = this.opportunityRecords;
                this.enableInfiniteLoading = oppData.length < DEFAULT_RECORD_LIMIT ? false : true;
                return this.opportunityRecords;
            })
            .catch((error) => {
                throw error;
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    convertTimePerTimeZone(timeString, date, timezoneSidId) {
        let dateTimeNew = this.newDateTime(date, this.formatMilliseconds(timeString), timezoneSidId);
        let dateObj = new Date(dateTimeNew);
        return this.dateJSToTimeIso(dateObj, timezoneSidId);
    }

    formatMilliseconds(ms) {
        const totalSeconds = Math.floor(ms / 1000);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;
    
        // Pad with leading zeros if necessary
        const pad = (num) => String(num).padStart(2, '0');
    
        return `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
    }

    dateJSToTimeIso(
        dateJS,
        timezoneSidId
      ) {
        if (!dateJS || !timezoneSidId) return null;
        return DateTime.fromJSDate(dateJS, {
          zone: timezoneSidId
        }).toFormat('hh:mm a');
      }

    newDateTime(dateIso, timeIso, timezoneSidId) {
        if (!dateIso || !timeIso || !timezoneSidId) return null;
    
        let dateTimeIso = dateIso + 'T' + timeIso;
        let dateTimeObj = DateTime.fromISO(dateTimeIso, {
          zone: timezoneSidId
        });
    
        return dateTimeObj.toJSDate();
      }
        

    handleRowSelection(event) {
        let ids = (event.detail.selectedRows || []).map((item) => item.Id);
        this.varSelectedOpportunityIdList = [... ids];
    }

    handleLoadMoreData(event) {
        event.target.isLoading = true;
        let target = event.target;
        this.fetchData()
            .then((result) => {
                if (result.length == 0) {
                    this.enableInfiniteLoading = false;
                }
                else {
                    this.enableInfiniteLoading = true;
                    this.opportunityRecords = result;
                }
            })
            .finally(() => {
                target.isLoading = false;
            });
    }

    exceptionHandler = (error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
    }

}