import { LightningElement, wire, api, track } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationBackEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

// import standard toast event
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fnGetRecurrenceDate from '@salesforce/apex/DateUtility.getRecurrenceDate';
import fnGetDonorEligibilityDay from '@salesforce/apex/DateUtility.getDonorEligibilityDay';
import * as slwcDateUtils from "c/slwcDateUtils";
import TIME_ZONE from "@salesforce/i18n/timeZone";

export default class RecurringPatternScheduler extends LightningElement {

    //Public Property populated via flow
    @api availableActions = [];

    //Date Output
    @api OutputStartDate;
    @api OutputDateList = [];
    @api OutputDateValues = [];
    @api OutputDates = '';

    //Rules
    @api InputStartDateOffset;
    @api InputEndtDateOffset;
    @api InputEnableFlowButtons;
    @api InputDriveType;

    //Date Range Settings User Input Exposed as Output - Needed to Retain Input Value on Flow
    @api OutputStartDateValue;
    @api OutputEndDateValue;
    @api OutputRecurTypeValue;
    @api OutputDonorEligibilityNeededFor;
    @api OutputDonorEligibilityType; //needed for other recurrance type
    @api OutputDonorEligibilityDay;

    //Monthly Scheule Settings User Input Exposed as Output
    @api OutputMonthDayValue;
    @api OutputMonthDayOccuranceValue;
    @api OutputMonthlyFrequencyValue;

    //Weekly Scheule Settings User Input Exposed as Output
    @api OutputWeeklyFrequencyValue;
    @api
    get OutputWeeklyFreqDay() {
        let retunvalue = '';
        if (this.weeklyFreqMon) {
            retunvalue = 'MON';
        }
        if(this.weeklyFreqTue) {
            retunvalue = retunvalue + ',TUE';
        }
        if(this.weeklyFreqWed) {
            retunvalue = retunvalue + ',WED';
        }
        if(this.weeklyFreqThu) {
            retunvalue = retunvalue + ',THU';
        }
        if(this.weeklyFreqFri) {
            retunvalue = retunvalue + ',FRI';
        }
        if(this.weeklyFreqSat) {
            retunvalue = retunvalue + ',SAT';
        }
        if(this.weeklyFreqSun) {
            retunvalue = retunvalue + ',SUN';
        }
        return retunvalue;
    }

    set OutputWeeklyFreqDay(value) {

        let tempWeeklyFreqDayList = value.split(',');

        this.weeklyFreqMon = false;
        this.weeklyFreqTue = false;
        this.weeklyFreqWed = false;
        this.weeklyFreqThu = false;
        this.weeklyFreqFri = false;
        this.weeklyFreqSat = false;
        this.weeklyFreqSun = false;        

        tempWeeklyFreqDayList.forEach(val =>{
            if (val === 'MON') {
                this.weeklyFreqMon = true;                
            } else if (val === 'TUE') {
                this.weeklyFreqTue = true;                
            } else if (val === 'WED') {
                this.weeklyFreqWed = true;
            } else if (val === 'THU') {
                this.weeklyFreqThu = true;
            } else if (val === 'FRI') {
                this.weeklyFreqFri = true;
            } else if (val === 'SAT') {
                this.weeklyFreqSat = true;
            } else if (val === 'SUN'){
                this.weeklyFreqSun = true;
            } else {
                console.log('***SET OutputWeeklyFreqDay() Unknown Value in OutputWeeklyFreqDay : ' + val);
            }
        });
        
    }

    isNextAllowed(){
        if (this.availableActions.find(action => action === 'NEXT')) {
            console.log('***isNextAllowed() - TRUE');
            return true;
        } else {
            console.log('***isNextAllowed() - FALSE');
            return false;
        }
    }

    isPreviousAllowed(){
        if (this.availableActions.find(action => action === 'BACK')) {
            console.log('***isPreviousAllowed() - TRUE');
            return true;
        } else {
            console.log('***isPreviousAllowed() - FALSE');
            return false;
        }
    }

    isSubmitAllowed(){
        if (this.availableActions.find(action => action === 'SUBMIT')) {
            console.log('***isSubmitAllowed() - TRUE');
            return true;
        } else {
            console.log('***isSubmitAllowed() - TRUE');
            return false;
        }
    }

    isPreviousAllowed;
    isNextAllowed;
    isSubmitAllowed;

    hasError = false;
    errorMessage = '';
    fnGetWeeklyRecurrenceDateResponse = false;

    driveTypeValue = '';
    recurTypeValue = '';
    donorEligibilityDay = '';
    donorEligibilityMsg = '';
    startDateValue;
    endDateValue;
    showTabWeekly = false;
    showTabMonthly = false;
    showTabOther = false;
    
    monthDayValue = '';
    monthDayOccuranceValue = '';
    monthlyFrequencyValue;    

    weeklyFrequencyValue;
    weeklyFreqMon = true;
    weeklyFreqTue = true;
    weeklyFreqWed = true;
    weeklyFreqThu = true;
    weeklyFreqFri = true;
    weeklyFreqSat = false;
    weeklyFreqSun = false;

    selectedDonorEligibilityFor;
    
    /*
    get driveTypeOptions() {
        return [
            { label: 'Fixed', value: 'fixed' },
            { label: 'Mobile', value: 'mobile' },
        ];
    }*/

    get recurTypeOptions() {
        let options = [
            { label: 'Weekly', value: 'weekly' },
            { label: 'Monthly', value: 'monthly' }
        ];
        if(this.InputDriveType === 'Mobile') {
            options.push({ label: 'Other', value: 'other' });
        }
        return options;
    }

    get cbMonthDayOccuranceOption() {
        return [
            { label: 'First', value: '1' },
            { label: 'Second', value: '2' },
            { label: 'Third', value: '3' },
            { label: 'Forth', value: '4' },
            { label: 'Last', value: '-1' },
        ];
    }

    get cbMonthDayOption() {
        return [
            { label: 'Day', value: 'day' },
            { label: 'Week Day', value: 'weekday' },
            { label: 'Weekend Day', value: 'weekend' },
            { label: 'Monday', value: 'monday' },
            { label: 'Tuesday', value: 'tuesday' },
            { label: 'Wednesday', value: 'wednesday' },
            { label: 'Thursday', value: 'thursday' },
            { label: 'Friday', value: 'friday' },
            { label: 'Saturday', value: 'saturday' },
            { label: 'Sunday', value: 'sunday' },
        ];
    }

    get otherRecTypes() {
        return [
            { label: 'Power Red', value: 'powerRed', checked: false },
            { label: 'Whole Blood', value: 'wholeBlood', checked: false }
        ];
    }

    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        });
    }

    connectedCallback() {
        console.log('***connectedCallback() this.OutputStartDateValue: ' + this.OutputStartDateValue);
        console.log('***connectedCallback() this.OutputEndDateValue: ' + this.OutputEndDateValue);
        console.log('***connectedCallback() this.OutputRecurTypeValue: ' + this.OutputRecurTypeValue);
        console.log('***connectedCallback() this.OutputWeeklyFrequencyValue: ' + this.OutputWeeklyFrequencyValue);
        console.log('***connectedCallback() this.OutputMonthlyFrequencyValue: ' + this.OutputMonthlyFrequencyValue);
        console.log('***connectedCallback() this.OutputMonthDayOccuranceValue: ' + this.OutputMonthDayOccuranceValue);
        console.log('***connectedCallback() this.OutputMonthDayValue: ' + this.OutputMonthDayValue);

        console.log('***connectedCallback() this.InputStartDateOffset: ' + this.InputStartDateOffset);
        console.log('***connectedCallback() this.InputEndtDateOffset: ' + this.InputEndtDateOffset);
        console.log('***connectedCallback() this.InputEnableFlowButtons: ' + this.InputEnableFlowButtons);

        if (this.availableActions.find(action => action === 'BACK')) {
            this.isPreviousAllowed = true;
        } else {
            this.isPreviousAllowed = false;
        }

        if (this.availableActions.find(action => action === 'NEXT')) {
            this.isNextAllowed = true;
        } else {
            this.isNextAllowed = false;
        }

        if (this.availableActions.find(action => action === 'SUBMIT')) {
            this.isSubmitAllowed = true;
        } else {
            this.isSubmitAllowed = false;
        }

        console.log('***connectedCallback - isPreviousAllowed : '+ this.isPreviousAllowed);
        console.log('***connectedCallback - isNextAllowed : '+ this.isNextAllowed);
        console.log('***connectedCallback - isSubmitAllowed : '+ this.isSubmitAllowed);

        
        if(this.StartDateOffset !== '' && this.StartDateOffset !== null && this.StartDateOffset !== undefined){
            console.log('***connectedCallback() Setting this.startDateValue from Previous value: ' + this.OutputStartDateValue);
            this.startDateValue = this.OutputStartDateValue;
        }
        
        if(this.OutputStartDateValue !== '' && this.OutputStartDateValue !== null && this.OutputStartDateValue !== undefined){
            console.log('***connectedCallback() Setting this.startDateValue from Previous value: ' + this.OutputStartDateValue);
            this.startDateValue = this.OutputStartDateValue;
        }
        if(this.OutputEndDateValue !== '' && this.OutputEndDateValue !== null && this.OutputEndDateValue !== undefined){
            console.log('***connectedCallback() Setting this.endDateValue from Previous value: ' + this.OutputEndDateValue);
            this.endDateValue = this.OutputEndDateValue;
        }
        if(this.OutputRecurTypeValue !== '' && this.OutputRecurTypeValue !== null && this.OutputRecurTypeValue !== undefined){
            this.recurTypeValue = this.OutputRecurTypeValue;
            console.log('***connectedCallback() Setting this.recurTypeValue from Previous value: ' + this.OutputRecurTypeValue);
            if(this.recurTypeValue === 'weekly') {
                this.showTabWeekly = true;
                this.showTabMonthly = false;
            } else if (this.recurTypeValue === 'monthly') {
                this.showTabMonthly = true;
                this.showTabWeekly = false;
            } else {
                this.showTabMonthly = false;
                this.showTabWeekly = false;
                this.showTabOther = true;
            }
        }

        if(this.OutputWeeklyFrequencyValue !== '' && this.OutputWeeklyFrequencyValue !== null && this.OutputWeeklyFrequencyValue !== undefined){
            this.weeklyFrequencyValue = this.OutputWeeklyFrequencyValue;
            console.log('***connectedCallback() Setting this.weeklyFrequencyValue from Previous value: ' + this.OutputWeeklyFrequencyValue);
        } else {
            this.weeklyFrequencyValue = 1;
        }

        if(this.OutputMonthlyFrequencyValue !== '' && this.OutputMonthlyFrequencyValue !== null && this.OutputMonthlyFrequencyValue !== undefined){
            this.monthlyFrequencyValue = this.OutputMonthlyFrequencyValue;
            console.log('***connectedCallback() Setting this.monthlyFrequencyValue from Previous value: ' + this.OutputMonthlyFrequencyValue);
        } else {
            this.monthlyFrequencyValue = 1;
        }

        if(this.OutputMonthDayOccuranceValue !== '' && this.OutputMonthDayOccuranceValue !== null && this.OutputMonthDayOccuranceValue !== undefined){
            this.monthDayOccuranceValue = this.OutputMonthDayOccuranceValue;
            console.log('***connectedCallback() Setting this.monthDayOccuranceValue from Previous value: ' + this.OutputMonthDayOccuranceValue);
        }

        if(this.OutputMonthDayValue !== '' && this.OutputMonthDayValue !== null && this.OutputMonthDayValue !== undefined){
            this.monthDayValue = this.OutputMonthDayValue;
            console.log('***connectedCallback() Setting this.monthDayValue from Previous value: ' + this.OutputMonthDayValue);
        }

        if(this.InputStartDateOffset === '' || this.InputStartDateOffset === null || this.InputStartDateOffset === undefined){
            this.InputStartDateOffset = -1
            console.log('***connectedCallback() Defaulting this.InputStartDateOffset: ' + this.InputStartDateOffset);
        }

        if(this.InputEndtDateOffset=== '' || this.InputEndtDateOffset === null || this.InputEndtDateOffset === undefined){
            this.InputEndtDateOffset = -1;
            console.log('***connectedCallback() Defaulting InputEndtDateOffset: ' + this.InputEndtDateOffset);
        }

        if(this.InputEnableFlowButtons=== '' || this.InputEnableFlowButtons === null || this.InputEnableFlowButtons === undefined){
            this.InputEnableFlowButtons = true;
            console.log('***connectedCallback() Defaulting this.InputEnableFlowButtons: ' + this.InputEnableFlowButtons);
        }

        if(this.OutputDonorEligibilityType !== null && this.OutputDonorEligibilityType !== undefined) {
            this.selectedDonorEligibilityFor = this.OutputDonorEligibilityType;
            this.donorEligibilityDay = this.OutputDonorEligibilityDay;
        }
    }

    handleCheckBoxChange(event) {

        console.log('***handleCheckBoxChange() event.target.name: ' + event.target.name);
        console.log('***handleCheckBoxChange() event.detail.checked: ' + event.detail.checked);

        if(event.target.name === 'chkMon') {
            this.weeklyFreqMon = event.detail.checked;
            console.log('***handleCheckBoxChange() weeklyFreqMon: ' + this.weeklyFreqMon);
        } else if (event.target.name === 'chkTue') {
            this.weeklyFreqTue = event.detail.checked;
            console.log('***handleCheckBoxChange() weeklyFreqTue: ' + this.weeklyFreqTue);
        } else if (event.target.name === 'chkWed') {
            this.weeklyFreqWed = event.detail.checked;
            console.log('***handleCheckBoxChange() weeklyFreqWed: ' + this.weeklyFreqWed);
        }else if (event.target.name === 'chkThu') {
            this.weeklyFreqThu = event.detail.checked;
            console.log('***handleCheckBoxChange() weeklyFreqThu: ' + this.weeklyFreqThu);
        }else if (event.target.name === 'chkFri') {
            this.weeklyFreqFri = event.detail.checked;
            console.log('***handleCheckBoxChange() weeklyFreqTFri: ' + this.weeklyFreqFri);
        }else if (event.target.name === 'chkSat') {
            this.weeklyFreqSat = event.detail.checked;
            console.log('***handleCheckBoxChange() weeklyFreqSat: ' + this.weeklyFreqSat);
        }else if (event.target.name === 'chkSun') {
            this.weeklyFreqSun = event.detail.checked;
            console.log('***handleCheckBoxChange() weeklyFreqSun: ' + this.weeklyFreqSun);
        } else if(event.target.name === 'otherRecTypes') {
            this.selectedDonorEligibilityFor = event.detail.value;
            return new Promise(async (resolve, reject) =>{
                var result = await fnGetDonorEligibilityDay({ 
                    donorEligibilityNeededFor: this.otherRecTypes.find(item => item.value === (this.selectedDonorEligibilityFor || ''))?.label  
                });
                this.donorEligibilityDay = result.donorEligibilityDay;
                this.donorEligibilityMsg = result.donorEligibilityMsg;
                resolve(result);
            });
        }

    /*
    handleDriveTypeChange(event) {
        this.driveTypeValue = event.detail.value;
    }*/
    }

    handleMonthDayOccuranceChange(event) {
        this.monthDayOccuranceValue = event.detail.value;
    }

    handleMonthDayChange(event) {
        this.monthDayValue = event.detail.value;
    }

    handleRecurTypeChange(event) {
        this.recurTypeValue = event.detail.value;
        if(this.recurTypeValue === 'weekly') {
            this.showTabWeekly = true;
            this.showTabMonthly = false;
            this.showTabOther = false;
        } else if (this.recurTypeValue === 'monthly') {
            this.showTabWeekly = false;
            this.showTabOther = false;
            this.showTabMonthly = true;
        } else {
            this.showTabWeekly = false;
            this.showTabMonthly = false;
            this.showTabOther = true;
        }
    }

    handlePreviousClick(event) {
        console.log('****RecurringPatternScheduler.handlePreviousClick() : ' + JSON.stringify(this.availableActions));
        if (this.availableActions.find(action => action === 'BACK')) {
            this.captureUserInput();
            const navigateBackEvent = new FlowNavigationBackEvent ();
            this.dispatchEvent(navigateBackEvent);
        }
    }

    //Method called from Next Button in Component
    async handleProceedClick(event) {
        let buttonName = event.target.dataset.name;
        console.log('****RecurringPatternScheduler.handleProceedClick() Called from : ' + buttonName);

        if(this.validateUserInput()){
            //calling function defined as Async to get data from Server / Apex. Only returns data. No promice object is returned
            let finalResults = await this.calculateDates();
            let finalResultsObj = JSON.parse(JSON.stringify(finalResults));
            
            console.log('****RecurringPatternScheduler.handleProceedClick() finalResultsObj.operationStatus: ' + finalResultsObj.operationStatus);
            if(finalResultsObj.operationStatus) {
                console.log('****RecurringPatternScheduler.handleProceedClick() finalResultsObj.returnValue: ' + finalResultsObj.returnValue);
                //setting output to public exposed params via Design file, so that flow can get the same.
                this.OutputDateList = JSON.parse(JSON.stringify(finalResultsObj.returnValue));
                this.OutputDates = JSON.stringify(finalResultsObj.returnValue);
                this.OutputDateValues = this.convertToDateArray(this.OutputDateList);
                console.log('****RecurringPatternScheduler.handleProceedClick() this.OutputDateList: ' + this.OutputDateList);
                console.log('****RecurringPatternScheduler.handleProceedClick() this.OutputDateValues: ' + this.OutputDateValues);
                console.log('****RecurringPatternScheduler.handleProceedClick() this.OutputDates: ' + this.OutputDates);

                if(this.OutputDateValues.length === 0) {
                    this.errorMessage = 'No dates found for the given range. Please adjust the date range and try again!';
                    this.showNotification(); 
                    return;
                }
                //dispatching flow event for Navigation based on button clicked.
                if (buttonName === 'btnNext' && this.availableActions.find(action => action === 'NEXT')) {
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }
                if (buttonName === 'btnFinish' && this.availableActions.find(action => action === 'SUBMIT')) {
                    const navigateFinishEvent = new FlowNavigationFinishEvent();
                    this.dispatchEvent(navigateFinishEvent);
                }
            } else {
                this.errorMessage = finalResultsObj.errorMessage;
                console.log('****RecurringPatternScheduler.handleProceedClick() finalResultsObj.errorMessage: ' + finalResultsObj.errorMessage);
                this.showNotification(); 
            }
        
        } else {
            console.log('****RecurringPatternScheduler.handleProceedClick() this.errorMessage: ' + this.errorMessage);
            this.showNotification(); 
        }        

    }
    
    //method called automatically by Flow Runtime based on Name and @api decoration. This does not support 'async'
    @api
    validate() {
        
        console.log('****RecurringPatternScheduler.validate() Called from Flow');

        if(this.validateUserInput()){
            //calling function NOT defined as Async to get data from Server / Apex. Server data fetch is done async in this method. Returns Promice Object
            this.calculateDatesAsync()
            .then(result => {
                let finalResultsObj = JSON.parse(JSON.stringify(result));
                console.log('****RecurringPatternScheduler.validate() fnGetWeeklyRecurrenceDate.result: ' + JSON.stringify(result));
                if(finalResultsObj.operationStatus){
                    console.log('****RecurringPatternScheduler.validate() finalResultsObj.returnValue: ' + finalResultsObj.returnValue);
                    //setting output to public exposed params via Design file, so that flow can get the same.
                    this.OutputDateList = JSON.parse(JSON.stringify(finalResultsObj.returnValue));
                    this.OutputDates = JSON.stringify(finalResultsObj.returnValue);
                    this.OutputDateValues = this.convertToDateArray(this.OutputDateList);
                    console.log('****RecurringPatternScheduler.handleProceedClick() this.OutputDateList: ' + this.OutputDateList);
                    console.log('****RecurringPatternScheduler.handleProceedClick() this.OutputDateValues: ' + this.OutputDateValues);
                    console.log('****RecurringPatternScheduler.handleProceedClick() this.OutputDates: ' + this.OutputDates);
                    //inform flow runtime of attribute value change when 
                    const attributeChangeEvent = new FlowAttributeChangeEvent('OutputDateList', this.OutputDateList);
                    this.dispatchEvent(attributeChangeEvent);
                    return { isValid: true };
                }
            })
            .catch(error => {
                console.log('****RecurringPatternScheduler.validate() fnGetWeeklyRecurrenceDate.error: ' + JSON.stringify(error));
                this.errorMessage = JSON.stringify(error);
                this.hasError = true;
                this.fnGetWeeklyRecurrenceDateResponse = true;
                return { 
                    isValid: false, 
                    errorMessage: this.errorMessage
                };
            });
        } else {
            console.log('****RecurringPatternScheduler.validate() this.errorMessage: ' + this.errorMessage);
            return { 
                isValid: false, 
                errorMessage: this.errorMessage
            };
        }
    }

    //function colates user input in UI fields
    captureUserInput() {

        let userInputElements = this.template.querySelectorAll("lightning-input");
        
        userInputElements.forEach((element)=>{

            if(element.name=="rgDriveType")
                this.driveTypeValue = this.driveTypeValue;

            else if(element.name=="dtStartDate")
                this.startDateValue = element.value;
            
            else if(element.name=="dtEndDate")
                this.endDateValue = element.value;
            
            else if(element.name=="cbMonthDayOccurance")
                this.monthDayOccuranceValue = element.value;
            
            else if(element.name=="cbMonthDay")
                this.monthDayValue = element.value;
            
            else if(element.name=="numMonthlyFrequency")
                this.monthlyFrequencyValue = element.value;

            else if(element.name=="numWeeklyFrequency")
                this.weeklyFrequencyValue = element.value;
            
        },this);

        
        if(!this.showTabWeekly && !this.showTabMonthly){
            console.log('****RecurringPatternScheduler.captureUserInput() Setting Default Values for Weekly Frequency and Days of Week');
            this.weeklyFrequencyValue = 1;
            this.weeklyFreqMon = true;
            this.weeklyFreqTue = true;
            this.weeklyFreqWed = true;
            this.weeklyFreqThu = true;
            this.weeklyFreqFri = true;
            this.weeklyFreqSat = true;
            this.weeklyFreqSun = true;

        }

        this.OutputStartDateValue = this.startDateValue;
        this.OutputEndDateValue = this.endDateValue;
        this.OutputRecurTypeValue = this.recurTypeValue;
        this.OutputDonorEligibilityType = this.selectedDonorEligibilityFor;
        this.OutputDonorEligibilityDay = this.donorEligibilityDay;
        this.OutputWeeklyFrequencyValue = this.weeklyFrequencyValue;
        this.OutputStartDate = this.getDateValuefromString(this.startDateValue);

        this.OutputMonthDayOccuranceValue = this.monthDayOccuranceValue;
        this.OutputMonthDayValue = this.monthDayValue;
        this.OutputMonthlyFrequencyValue = this.monthlyFrequencyValue;
        
        //console.log('****RecurringPatternScheduler.captureUserInput() driveTypeValue: ' + this.driveTypeValue);
        console.log('****RecurringPatternScheduler.captureUserInput() recurTypeValue: ' + this.recurTypeValue);
        console.log('****RecurringPatternScheduler.captureUserInput() startDateValue: ' + this.startDateValue);
        console.log('****RecurringPatternScheduler.captureUserInput() OutputStartDate: ' + this.OutputStartDate);
        console.log('****RecurringPatternScheduler.captureUserInput() endDateValue: ' + this.endDateValue);
        console.log('****RecurringPatternScheduler.captureUserInput() weeklyFrequencyValue: ' + this.weeklyFrequencyValue);
        console.log('****RecurringPatternScheduler.captureUserInput() weeklyFreqDay: ' + this.OutputWeeklyFreqDay);
        console.log('****RecurringPatternScheduler.captureUserInput() monthDayValue: ' + this.monthDayValue);
        console.log('****RecurringPatternScheduler.captureUserInput() monthDayOccuranceValue: ' + this.monthDayOccuranceValue);
        console.log('****RecurringPatternScheduler.captureUserInput() monthlyFrequencyValue: ' + this.monthlyFrequencyValue);

    }

    //Converts String Value in [YYYY-MM-DD] Format to JS Date Obj
    getDateValuefromString(strDate) {
        console.log('****RecurringPatternScheduler.getDateValuefromString() Input Date String: ' + strDate);
        /*let result = strDate.split('-');
        let month = parseInt(result[1]) - 1;
        let newDate = new Date(result[0], month, result[2], 0, 0, 0);*/
        return this.dateUtils.date2dateIso(strDate);
    }

    //Converts String Array with Date Value in [YYYY-MM-DD] Format to JS Date [] Obj
    convertToDateArray(strDateList){
        let returnVal = [];
        console.log('****RecurringPatternScheduler.convertToDateArray() - Input Str [] Lenght : ' + strDateList.length);
        for(let i=0; i< strDateList.length; i++){
            console.log('****RecurringPatternScheduler.convertToDateArray() - Input Date Str : ' + strDateList[i]);
            returnVal.push(this.getDateValuefromString(strDateList[i]));
        }
        console.log('****RecurringPatternScheduler.convertToDateArray() - returnVal : ' + returnVal);
        return returnVal;
    }

    //function to validate user input.
    validateUserInput() {

        this.captureUserInput();
        let tempStartDate;
        let tempEndDate;

        let currentDate = new Date();
        //getting current date with time factor as 0.
        let offsetStartDate = new Date(currentDate.getFullYear(),currentDate.getMonth(), currentDate.getDate(),0,0,0);
        let offsetEndDate = new Date(currentDate.getFullYear(),currentDate.getMonth(), currentDate.getDate(),0,0,0);
        

        console.log('****RecurringPatternScheduler.validateUserInput() recurTypeValue: ' + this.recurTypeValue);
        console.log('****RecurringPatternScheduler.validateUserInput() startDateValue: ' + this.getDateValuefromString(this.startDateValue));
        console.log('****RecurringPatternScheduler.validateUserInput() endDateValue: ' + this.getDateValuefromString(this.endDateValue));
        console.log('****RecurringPatternScheduler.validateUserInput() weeklyFrequencyValue: ' + this.weeklyFrequencyValue);
        console.log('****RecurringPatternScheduler.validateUserInput() InputStartDateOffset: ' + this.InputStartDateOffset);
        console.log('****RecurringPatternScheduler.validateUserInput() InputEndtDateOffset: ' + this.InputEndtDateOffset);
        //console.log('****RecurringPatternScheduler.validateUserInput() Initial offsetStartDate: ' + offsetStartDate);
        //console.log('****RecurringPatternScheduler.validateUserInput() Initial offsetEndDate: ' + offsetEndDate);

        if(this.startDateValue !== '' && this.startDateValue !== null && this.startDateValue !== undefined){
            tempStartDate = this.getDateValuefromString(this.startDateValue);
        }
        if(this.InputStartDateOffset !== '' && this.InputStartDateOffset !== null && this.InputStartDateOffset !== undefined && this.InputStartDateOffset !== -1){
            offsetStartDate.setDate(offsetStartDate.getDate() + this.InputStartDateOffset);
            offsetStartDate.setHours(0,0,0,0);
        }
        console.log('****RecurringPatternScheduler.validateUserInput() offsetStartDate: ' + offsetStartDate);
        if(this.endDateValue !== '' && this.endDateValue !== null && this.endDateValue !== undefined){
            tempEndDate = this.getDateValuefromString(this.endDateValue);
        }
        if(this.InputEndtDateOffset !== '' && this.InputEndtDateOffset !== null && this.InputEndtDateOffset !== undefined && this.InputEndtDateOffset !== -1){
            offsetEndDate.setDate(offsetEndDate.getDate() + this.InputEndtDateOffset);
            offsetEndDate.setHours(0,0,0,0);
        }
        console.log('****RecurringPatternScheduler.validateUserInput() offsetEndDate: ' + offsetEndDate);

        offsetStartDate = this.getDateValuefromString(offsetStartDate);
        offsetEndDate = this.getDateValuefromString(offsetEndDate);

        if(this.startDateValue === '' || this.startDateValue === null){
            this.hasError = true;
            this.errorMessage = 'Please enter Start Date';
            
        } else if (this.endDateValue === '' || this.endDateValue === null) {
            this.hasError = true;
            this.errorMessage = 'Please enter End Date';
            
        } else if (tempEndDate <= tempStartDate) {
            this.hasError = true;
            this.errorMessage = 'End Date Must be After Start Date';
            
        } else if (this.recurTypeValue === '' || this.recurTypeValue === null) {
            this.hasError = true;
            this.errorMessage = 'Please select Recurrence Type';
            
        } else if ((this.InputStartDateOffset !== undefined && this.InputStartDateOffset !== -1) && offsetStartDate !== undefined && offsetStartDate > tempStartDate && this.recurTypeValue !== 'other') {
            this.hasError = true;
            this.errorMessage = 'Start Date must be ' + this.InputStartDateOffset + ' Day(s) in future from Today';
            
        } else if ((this.InputEndtDateOffset !== undefined && this.InputEndtDateOffset !== -1) && offsetEndDate !== undefined && offsetEndDate > tempEndDate) {
            this.hasError = true;
            this.errorMessage = 'End Date must be ' + this.InputEndtDateOffset+ ' Day(s) in future from Today';
            
        }  else if (this.recurTypeValue === 'weekly' && this.weeklyFrequencyValue === '') {
            this.hasError = true;
            this.errorMessage = 'Please enter Week Frequency';
            
        } else if (this.recurTypeValue === 'weekly' && this.OutputWeeklyFreqDay === '') {
            this.hasError = true;
            this.errorMessage = 'Please select Day(s) of Week';
            
        } else if (this.recurTypeValue === 'weekly' && isNaN(this.weeklyFrequencyValue)) {
            this.hasError = true;
            this.errorMessage = 'Please enter numeric value in Week Frequency';
            
        } else if (this.recurTypeValue === 'monthly' && this.monthDayOccuranceValue === '') {
            this.hasError = true;
            this.errorMessage = 'Please enter Occurance in Month';
            
        } else if (this.recurTypeValue === 'monthly' && this.monthDayValue === '') {
            this.hasError = true;
            this.errorMessage = 'Please enter Day of Month';
            
        } else if (this.recurTypeValue === 'monthly' && (this.monthlyFrequencyValue === '' || this.monthlyFrequencyValue === null)) {
            this.hasError = true;
            this.errorMessage = 'Please enter Monthly Frequency';
            
        } else if (this.recurTypeValue === 'monthly' && isNaN(this.monthlyFrequencyValue)) {
            this.hasError = true;
            this.errorMessage = 'Please enter numeric value in Monthly Frequency';
            
        } else if(this.recurTypeValue === 'other' && !this.selectedDonorEligibilityFor) {
            this.hasError = true;
            this.errorMessage = 'Please select one of the options to calculate donor eligibility for other recurrence type';
        } else {
            this.hasError = false;
            this.errorMessage = '';
        }

        return !this.hasError;

    }

    

    async calculateDates(){

        //console.log('****RecurringPatternScheduler.calculateDates() driveTypeValue: ' + this.driveTypeValue);
        console.log('****RecurringPatternScheduler.calculateDates() recurTypeValue: ' + this.recurTypeValue);
        console.log('****RecurringPatternScheduler.calculateDates() monthDayValue: ' + this.monthDayValue);
        console.log('****RecurringPatternScheduler.calculateDates() monthDayOccuranceValue: ' + this.monthDayOccuranceValue);
        console.log('****RecurringPatternScheduler.calculateDates() monthlyFrequencyValue: ' + this.monthlyFrequencyValue);
        console.log('****RecurringPatternScheduler.calculateDates() startDateValue: ' + this.startDateValue);
        console.log('****RecurringPatternScheduler.calculateDates() endDateValue: ' + this.endDateValue);
        console.log('****RecurringPatternScheduler.calculateDates() weeklyFrequencyValue: ' + this.weeklyFrequencyValue);
        console.log('****RecurringPatternScheduler.calculateDates() weeklyFreqDay: ' + this.OutputWeeklyFreqDay);

        //this.OutputDateList = ["2021-06-01","2021-06-02","2021-06-03","2021-06-04","2021-06-05","2021-06-06","2021-06-07","2021-06-08","2021-06-09","2021-06-10","2021-06-11"];

        var result = await fnGetRecurrenceDate({ 
            startDate : this.startDateValue, 
            endDate : this.endDateValue, 
            recurrenceType: this.recurTypeValue,
            weeklyRecurrence : this.weeklyFrequencyValue,
            daysOfWeek: this.OutputWeeklyFreqDay,
            occurance: this.OutputMonthDayOccuranceValue,
            monthlyRecurrence: this.monthlyFrequencyValue,
            dayOfMonth: this.OutputMonthDayValue, 
            donorEligibilityFor: this.otherRecTypes.find(item => item.value === (this.OutputDonorEligibilityType || ''))?.label              
        });
        
        console.log('****RecurringPatternScheduler.calculateDates() Completed result: ' + JSON.stringify(result));

        return result;

    }

    calculateDatesAsync(){

        //console.log('****RecurringPatternScheduler.calculateDatesAsync() driveTypeValue: ' + this.driveTypeValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() recurTypeValue: ' + this.recurTypeValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() monthDayValue: ' + this.monthDayValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() monthDayOccuranceValue: ' + this.monthDayOccuranceValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() monthlyFrequencyValue: ' + this.monthlyFrequencyValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() startDateValue: ' + this.startDateValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() endDateValue: ' + this.endDateValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() weeklyFrequencyValue: ' + this.weeklyFrequencyValue);
        console.log('****RecurringPatternScheduler.calculateDatesAsync() weeklyFreqDay: ' + this.OutputWeeklyFreqDay);

        //this.OutputDateList = ["2021-06-01","2021-06-02","2021-06-03","2021-06-04","2021-06-05","2021-06-06","2021-06-07","2021-06-08","2021-06-09","2021-06-10","2021-06-11"];

        return new Promise(async (resolve, reject) =>{
                console.log('****RecurringPatternScheduler.calculateDatesAsync() Calling Server');
                var result = await fnGetRecurrenceDate({ 
                    startDate : this.startDateValue, 
                    endDate : this.endDateValue, 
                    recurrenceType: this.recurTypeValue,
                    weeklyRecurrence : this.weeklyFrequencyValue,
                    daysOfWeek: this.OutputWeeklyFreqDay,
                    occurance: this.OutputMonthDayOccuranceValue,
                    monthlyRecurrence: this.monthlyFrequencyValue,
                    dayOfMonth: this.OutputMonthDayValue, 
                    donorEligibilityFor: this.otherRecTypes.find(item => item.value === (this.OutputDonorEligibilityType || ''))?.label       
                });
                console.log('****RecurringPatternScheduler.calculateDatesAsync() Calling Server Complete');
                resolve(result);
        });
        

    }

    showNotification() {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: this.errorMessage,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }


}