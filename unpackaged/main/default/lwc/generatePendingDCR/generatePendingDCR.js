import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getData from '@salesforce/apex/GeneratePendingDCRController.getData';
import createRequestForDCR from '@salesforce/apex/GeneratePendingDCRController.createRequestForDCR';
import errorMessage from '@salesforce/label/c.generatePendingDCRErrorMessages';

const columns = [
    {
        label: 'Drive Name',
        fieldName: 'link',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        },
    },
    { label: 'Drive Date', fieldName: 'sked_Drive_Date__c', type: 'text', editable: false },
    { label: 'Status', fieldName: 'sked_Status__c', type: 'text', editable: false },
    { label: 'Start Time', fieldName: 'startTime', type: 'text', editable: false },
    { label: 'End Time', fieldName: 'endTime', type: 'text', editable: false },
];

export default class GeneratePendingDCR extends LightningElement {

    data = [];
    columns = columns;
    rowOffset = 0;
    options = [{ 'label': 'Draft', 'value': 'Draft' },
    { 'label': 'System Generated', 'value': 'System Generated' },
    { 'label': 'Hold', 'value': 'Hold', 'disabled': true },
    { 'label': 'Tentative', 'value': 'Tentative' },
    { 'label': 'Confirmed', 'value': 'Confirmed' },
    { 'label': 'Complete', 'value': 'Complete' },
    { 'label': 'Cancel', 'value': 'Cancel' }];
    selectedValue;
    selectedValues = [];
    label;
    minChar = 2;
    disabled = false;
    multiSelect = true;
    @track value;
    @track values = [];
    @track optionData;
    @track searchString;
    @track message;
    @track showDropdown = false;
    @track wrapper = [];
    @track loaded = false;
    @track isButtonIsVisible = true;
    @track storeTempValue;
    @track callOutParameters = {
        fromDriveDate: '',
        startTimeFrom: '',
        endTimeFrom: '',
        toDriveDate: '',
        startTimeTo: '',
        endTimeTo: ''

    };
    @track errorMessage;
    @track handleErrorMessageOnField = [
        {
            cmpName: 'fromDriveDate',
            errorMessage: ''
        },
        {
            cmpName: 'startTimeFrom',
            errorMessage: ''
        },
        {
            cmpName: 'endTimeFrom',
            errorMessage: ''
        },
        {
            cmpName: 'toDriveDate',
            errorMessage: ''
        },
        {
            cmpName: 'startTimeTo',
            errorMessage: ''
        },
        {
            cmpName: 'endTimeTo',
            errorMessage: ''
        }
    ];
    @track unfilterRecords = [];
    @api travelTimeSiteToCo;
    @api travelTimeCoToSite;
    @api isShowModal;
    @api modifiedRecordIds;
    @track elementMappings = {
        "fromDriveDate": "fromDriveDate",
        "startTimeFrom": "startTimeFrom",
        "endTimeFrom": "endTimeFrom",
        "toDriveDate": "toDriveDate",
        "startTimeTo": "startTimeTo",
        "endTimeTo": "endTimeTo",
    };
    errorMessages = {};


    
    compareTimes(time1, time2) {

        const date1 = new Date('2000-01-01 ' + time1);
        const date2 = new Date('2000-01-01 ' + time2);

        if (date1 <= date2) {
            return true;
        } else {
            return false;
        }
    }

    connectedCallback() {
        this.errorMessages = JSON.parse(errorMessage);
        let travelTimeIndexValue = this.modifiedRecordIds;
        this.isShowModal = true;
        this.loaded = true;
        
        getData({
            travelTimeSiteToCo: travelTimeIndexValue,
            travelTimeCoToSite: travelTimeIndexValue,
        })
            .then(result => {
                if(result.drives == 0){
                    this.isButtonIsVisible = true;
                } else{
                    this.isButtonIsVisible = !result.isButtonVisible;
                }
                result.drives.forEach(element => {
                    element.startTime = element.sked_Opportunity__r.Flow_Start_Time_Label_Text__c;
                    element.endTime = element.sked_Opportunity__r.Flow_End_Time_Label_Text__c;
                    element.link = `/${element.Id}`;
                });
                this.data = result.drives;
                this.unfilterRecords = result.drives;
                this.loaded = false;
            })
            .catch(error => {
                console.log('error :: ', error);
                this.loaded = false;
            })

        this.showDropdown = false;
        let optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
        let value = this.selectedValue ? (JSON.parse(JSON.stringify(this.selectedValue))) : null;
        let values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : null;
        if (value || values) {
            let searchString;
            let count = 0;
            for (let i = 0; i < optionData.length; i++) {
                if (this.multiSelect) {
                    if (values.includes(optionData[i].value)) {
                        optionData[i].selected = true;
                        count++;
                    }
                } else {
                    if (optionData[i].value == value) {
                        searchString = optionData[i].label;
                    }
                }
            }
            if (this.multiSelect)
                this.searchString = count + ' Option(s) Selected';
            else
                this.searchString = searchString;
        }
        this.value = value;
        this.values = values;
        this.optionData = optionData;

    }

    showModalBox() {  
        this.isShowModal = true;
        const closeEvent = new CustomEvent('close', {
            detail: {
                isShowModal: false,
            }
          });
          this.dispatchEvent(closeEvent);
    }

    hideModalBox() {  
        this.isShowModal = false;
        const closeEvent = new CustomEvent('close', {
            detail: {
                isShowModal: false
            }
          });
          this.dispatchEvent(closeEvent);
    }

    validateTimeField(fieldName, compareFieldName, errorMessage) {
        // const searchCmp = this.template.querySelector(`lightning-input[data-name="${fieldName}"]`);
        // const compareValue = this.storeTempValue[compareFieldName];
        // if (compareValue !== null && compareValue !== "" && this.storeTempValue[fieldName] > compareValue) {
        //     searchCmp.setCustomValidity(errorMessage);
        //     this.handleErrorMessageOnField.find(item => item.cmpName === fieldName).errorMessage = errorMessage;
    
        //     const searchCmpToRemoveError = this.template.querySelector(`lightning-input[data-name="${compareFieldName}"]`);
        //     this.handleErrorMessageOnField.find(item => item.cmpName === compareFieldName).errorMessage = "";
        //     searchCmpToRemoveError.setCustomValidity("");
        //     searchCmpToRemoveError.reportValidity();
        // } else {
        //     searchCmp.setCustomValidity("");
        //     this.handleErrorMessageOnField.find(item => item.cmpName === fieldName).errorMessage = "";
        // }
    
        // searchCmp.reportValidity();
    }

    handleReset() {
        this.loaded = true;
        let getValue = this.template.querySelectorAll("lightning-input");
        getValue.forEach(element => {
            if ((element.name == "fromDriveDate") || 
                (element.name == "startTimeFrom") ||
                (element.name == "endTimeFrom") ||
                (element.name == "toDriveDate") ||
                (element.name == "startTimeTo") ||
                (element.name == "endTimeTo")) {
                element.value = '';
            }
        });
        this.optionData.forEach(element => {
            this.removePill(null, element.value);
        });
        this.data = [];
        this.data = this.unfilterRecords;
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
                datatable.selectedRows = [];
            }
        setTimeout(() => {
            this.loaded = false;
        }, 2000);
    }

    validationCheck(event) {
        try{
        let getValue = this.template.querySelectorAll("lightning-input");

        let storeTempValue = {
            fromDriveDate: '',
            startTimeFrom: '',
            endTimeFrom: '',
            toDriveDate: '',
            startTimeTo: '',
            endTimeTo: ''
        };

        getValue.forEach(element => {
            const propertyName = this.elementMappings[element.name];
            if (propertyName !== undefined && element.value !== undefined) {
                storeTempValue[propertyName] = element.value;
            }
        });
        this.storeTempValue = storeTempValue;
        if (event.target.name == "fromDriveDate") {
            this.validateTimeField("toDriveDate", "fromDriveDate", this.errorMessages.fromDriveDateError);
        }
        if (event.target.name == "startTimeFrom") {
            this.validateTimeField("startTimeFrom", "endTimeFrom", this.errorMessages.startTimeFromError);
        }
        if (event.target.name == "endTimeFrom") {
            this.validateTimeField("endTimeFrom", "startTimeFrom", this.errorMessages.endTimeFromError);
        }
        if (event.target.name == "toDriveDate") {
            this.validateTimeField("toDriveDate", "fromDriveDate", this.errorMessages.toDriveDateError);
        }
        if (event.target.name == "startTimeTo") {
            this.validateTimeField("startTimeTo", "endTimeTo", this.errorMessages.startTimeToError);
        }
        if (event.target.name == "endTimeTo") {
            this.validateTimeField("endTimeTo", "startTimeTo", this.errorMessages.endTimeToError);
        }
        } catch (error) {
            console.log('error ',error);
        }

    }

    handleFilter(event) {
        if (this.unfilterRecords.length === 0) {
            this.showToast('No records found', 'No records found', 'error');
            return;
        }
    
        this.loaded = true;

        let statusFilter = [];
            this.optionData.forEach(element => {
                if (element.selected == true) {
                    statusFilter.push(element.value);
                }
        })
        
        let hasErrors = this.handleErrorMessageOnField.some(element => element.errorMessage !== '');
    
        if (hasErrors) {
            const errorCount = this.handleErrorMessageOnField.filter(element => element.errorMessage !== '').length;
            const errorMessage = this.handleErrorMessageOnField
                .map((element, index) => `${index + 1}) ${element.errorMessage}`)
                .join('. \n');
    
            const errorTitle = `There are total ${errorCount} errors.`;
            this.showToast(errorTitle, errorMessage, 'error');
        } else {
            const getValue = this.template.querySelectorAll("lightning-input");
            getValue.forEach(element => {
                const propertyName = this.elementMappings[element.name];
                if (propertyName !== undefined) {
                    this.callOutParameters[propertyName] = element.value;
                }
            });
            const filterRecords = this.unfilterRecords.filter(element => {
                const isDriveStatusFilterIsTrue = (
                    statusFilter.length === 0 ||
                    statusFilter.some(keyword => element.sked_Status__c.includes(keyword))
                );
    
                const isDriveDateInRange = (
                    (!this.callOutParameters.fromDriveDate || element.sked_Drive_Date__c >= this.callOutParameters.fromDriveDate) &&
                    (!this.callOutParameters.toDriveDate || element.sked_Drive_Date__c <= this.callOutParameters.toDriveDate)
                );
    
                const isStartTimeInRange = (
                    (!this.callOutParameters.startTimeFrom || this.compareTimes(this.callOutParameters.startTimeFrom, element.sked_Opportunity__r.Flow_Start_Time_Label_Text__c)) &&
                    (!this.callOutParameters.startTimeTo || this.compareTimes(element.sked_Opportunity__r.Flow_Start_Time_Label_Text__c, this.callOutParameters.startTimeTo))
                );
    
                const isEndTimeInRange = (
                    (!this.callOutParameters.endTimeFrom || this.compareTimes(this.callOutParameters.endTimeFrom, element.sked_Opportunity__r.Flow_End_Time_Label_Text__c)) &&
                    (!this.callOutParameters.endTimeTo || this.compareTimes(element.sked_Opportunity__r.Flow_End_Time_Label_Text__c, this.callOutParameters.endTimeTo))
                );
    
                return isDriveDateInRange && isStartTimeInRange && isEndTimeInRange && isDriveStatusFilterIsTrue;
            });
    
            if (filterRecords.length !== 0) {
                this.data = filterRecords;
            } else {
                this.showToast('No records found', 'No records found', 'error');
            }
        }
    
        setTimeout(() => {
            this.loaded = false;
        }, 2000);
    }

    handleCancel() {
        this.isShowModal = false; // popup handler
        const closeEvent = new CustomEvent('close', {
            detail: {
                isShowModal: false,
            }
          });
          this.dispatchEvent(closeEvent);
    }

    handleGeneratePendingDCR() {
        this.loaded = true;
    
        const selectedRowsData = this.template.querySelector('lightning-datatable').getSelectedRows();
        const impactedDrivesId = selectedRowsData.map(element => element.Id);
    
        if (this.unfilterRecords.length === 0 || selectedRowsData.length === 0) {
            this.showToast('There are no records to Generate pending DCR', 'There are no records to Generate pending DCR', 'error');
            setTimeout(() => {
                this.loaded = false;
            }, 2000);
            return;
        }
    
        console.log('impactedDrivesId :: ', impactedDrivesId);
    
        createRequestForDCR({ impactedDrivesId })
            .then(result => {
                this.showToast(result, result, 'success');
                setTimeout(() => {
                    this.loaded = false;
                }, 2000);
                this.isShowModal = true;
                const closeEvent = new CustomEvent('close', {
                    detail: {
                        isShowModal: false,
                    },
                });
                this.dispatchEvent(closeEvent);
            })
            .catch(error => {
                this.showToast(error, error, 'error');
                console.log('catch error => ', error);
                setTimeout(() => {
                    this.loaded = false;
                }, 2000);
            });
    }
    
    selectItem(event) {
        let selectedVal = event.currentTarget.dataset.id;
        if (selectedVal) {
            let count = 0;
            let options = JSON.parse(JSON.stringify(this.optionData));
            for (let i = 0; i < options.length; i++) {
                if (options[i].value === selectedVal) {
                    if (this.multiSelect) {
                        if (this.values.includes(options[i].value)) {
                            this.values.splice(this.values.indexOf(options[i].value), 1);
                        } else {
                            this.values.push(options[i].value);
                        }
                        options[i].selected = options[i].selected ? false : true;
                    } else {
                        this.value = options[i].value;
                        this.searchString = options[i].label;
                    }
                }
                if (options[i].selected) {
                    count++;
                }
            }
            this.optionData = options;
            if (this.multiSelect)
                this.searchString = count + ' Option(s) Selected';
            if (this.multiSelect)
                event.preventDefault();
            else
                this.showDropdown = false;
        }
    }

    showOptions() {
        if (this.disabled == false && this.options) {
            this.message = '';
            this.searchString = '';
            let options = JSON.parse(JSON.stringify(this.optionData));
            for (let i = 0; i < options.length; i++) {
                options[i].isVisible = true;
            }
            if (options.length > 0) {
                this.showDropdown = true;
            }
            this.optionData = options;
        }
    }

    removePill(event, onCallFromReset) {
        let value;
        if (onCallFromReset) {
            value = onCallFromReset;
        } else {
            value = event.currentTarget.name;
        }
        let count = 0;
        let options = JSON.parse(JSON.stringify(this.optionData));
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === value) {
                options[i].selected = false;
                this.values.splice(this.values.indexOf(options[i].value), 1);
            }
            if (options[i].selected) {
                count++;
            }
        }
        this.optionData = options;
        if (this.multiSelect)
            this.searchString = count + ' Option(s) Selected';
    }

    blurEvent() {
        let previousLabel;
        let count = 0;
        for (let i = 0; i < this.optionData.length; i++) {
            if (this.optionData[i].value === this.value) {
                previousLabel = this.optionData[i].label;
            }
            if (this.optionData[i].selected) {
                count++;
            }
        }
        if (this.multiSelect)
            this.searchString = count + ' Option(s) Selected';
        else
            this.searchString = previousLabel;

        this.showDropdown = false;

        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                'payloadType': 'multi-select',
                'payload': {
                    'value': this.value,
                    'values': this.values
                }
            }
        }));
    }

    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }

}