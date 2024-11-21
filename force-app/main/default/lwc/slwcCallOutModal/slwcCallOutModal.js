import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DateTime } from 'c/luxon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { availabilityService } from 'c/dataService';
import { classNames } from 'c/slwcUtils';

export default class SlwcCallOutModal extends LightningElement {
    @track timezoneSidId = TIME_ZONE;
    _timeOffPlansByLabel = [];
    timeOffPlans = [];
    timeOffReasonCodes = [];
    @api driveDate = null;
    @api duration = 0;
    @api isResourceMode = false;
    @api fullScreen = false;
    @api hideHeader = false;
    @api showBackButton = false;
    @api saveBtnLabel = 'Save';
    
    showSpinner = false;

    _resourceId = null;
    @api
    get resourceId() {
        return this._resourceId;
    }
    set resourceId(value) {
        this.showLoading();
        this._resourceId = value;
        if (!isNullOrEmpty(this._resourceId)) {
            let availabilitySvc = new availabilityService();
            availabilitySvc.getUnavailabilityStatistic({ resourceId: this.resourceId, selectedDate: this.driveDate, isCallOut: true })
            .then(result => {
                this._timeOffPlansByLabel = result.timeOffPlansByLabel;
                this.timeOffPlans = result.timeOffPlans.map((item) => { return { label: item.name , value: item.name}});

                if (!isNullOrEmpty(this._timeOffPlansByLabel) && !!Object.keys(this._timeOffPlansByLabel).length) {
                    this.model.hasTimeOffPlans = true;

                    // if (this.model.callOutType == 'Call Out') {
                    //     this.model.usePtoForCallOut = true;
                    // }
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Errored trying to retrieve Workday Balances for this employee.',
                        message: error,
                        variant: 'error',
                    })
                );
            })
            .finally(() => this.hideLoading());
        }
    }

    get showBalance() {
        return !this.isBereavement && !isNullOrEmpty(this.planBalance);
    }

    get planBalance() {
        let plan = this._timeOffPlansByLabel?.[this.model.timeOffPlan];
        if (!isNullOrEmpty(plan)) {
            return plan.balance;
        }
        return null;
    }

    get hasAvailableBalance() {
        return this.isBereavement || !this.model.usePtoForCallOut || this.planBalance >= this.duration;
    }

    get planBalanceClass() {
        let planBalanceClass = 'slds-text-align_center slds-plan-balance-text-';
        planBalanceClass += this.hasAvailableBalance ? 'green' : 'red';
        return planBalanceClass;
    }

    @track _isOpen = false;
    @api
    get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;
        if(this._isOpen) {
            this.init();
        }
    }

    @track model = {
        callOutReceivedDate: null,
        callOutReceivedTime: null,
        callOutType: null,
        callOutReason: null,
        callOutNotes: null,
        timeOffPlan: null,
        timeOffReasonCode: null,
        usePtoForCallOut: false,
        hasTimeOffPlans: false
    };

    @wire(CurrentPageReference) pageRef;
    
    get callOutReasonDisabled() {
        return !this.model || !this.model.callOutType
    }

    get callOutReasonControllingFieldValues() {
        return this.model && this.model.callOutType ? [this.model.callOutType] : [];
    }

    get timeOffPlanDisabled() {
        return !this.model || !this.model.callOutType || isNullOrEmpty(this._timeOffPlansByLabel);
    }

    get timeOffReasonCodeDisabled() {
        return !this.model || !this.model.callOutType || !this.model.timeOffPlan || this.isBereavement;
    }

    get isBereavement() {
        return this.model.timeOffPlan == 'Bereavement';
    }

    get customClass() {
        return {
            modal: classNames('slds-modal slds-fade-in-open', {
                'full-screen': this.fullScreen
            }),
        }
    }

    connectedCallback() {
    }

    disconnectedCallback() {
    }
    
    /** Custom functions **/
    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {}));
        this._timeOffPlansByLabel = null;
        this.timeOffPlans = null;
    }

    init() {        
        this._timeOffPlansByLabel = null;
        this.timeOffPlans = null;
        
        const today = DateTime.fromObject({
            zone: TIME_ZONE
        });

        this.model = {
            callOutReceivedDate: today.toFormat('yyyy-MM-dd'),
            callOutReceivedTime: today.toFormat('HH:mm:ss.SSS'),
            callOutType: null,
            callOutReason: null,
            callOutNotes: null,
            timeOffPlan: null,
            timeOffReasonCode: null,
            usePtoForCallOut: false,
            hasTimeOffPlans: false
        };

        this.retrieveResourceBalances();
    }

    retrieveResourceBalances() {
        if (isNullOrEmpty(this._resourceId) || this.model.hasTimeOffPlans) return; 
        
        this.showLoading();
        let availabilitySvc = new availabilityService();
        availabilitySvc.getUnavailabilityStatistic({ resourceId: this.resourceId, selectedDate: this.driveDate, isCallOut: true })
        .then(result => {
            this._timeOffPlansByLabel = result.timeOffPlansByLabel;
            this.timeOffPlans = result.timeOffPlans.map((item) => { return { label: item.name , value: item.name}});

            if (!isNullOrEmpty(this._timeOffPlansByLabel) && !!Object.keys(this._timeOffPlansByLabel).length) {
                this.model.hasTimeOffPlans = true;

                // if (this.model.callOutType == 'Call Out') {
                //     this.model.usePtoForCallOut = true;
                // }
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Errored trying to retrieve Workday Balances for this employee.',
                    message: error,
                    variant: 'error',
                })
            );
        })
        .finally(() => this.hideLoading());
    }

    get allowPtoForCallOut() {
        return this.model.hasTimeOffPlans && this.model.callOutType == 'Call Out';
    }

    handleOnCallOutTypeChange(event) {
        // let callOutType = getValueFromEvent(event);
        // if (callOutType == 'Call Out' && this.model.hasTimeOffPlans) {
        //     this.model.usePtoForCallOut = true;
        // } else {
        //     this.model.usePtoForCallOut = false;
        // }

        this.handleOnChange(event);
    }

    handleOnPlanChange(event) {
        let planName = getValueFromEvent(event);
        let reasonCodes = this._timeOffPlansByLabel[planName].timeOffReasons;
        this.timeOffReasonCodes = reasonCodes.map((item) => { return { label: item.name, value: item.reasonId }});
        this.handleOnChange(event);
    }

    handleOnChange(event) {
        let targetName = event.target.name;
        let targetValue = getValueFromEvent(event);
        this.model[targetName] = targetValue;
    }

    validate() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'), 
            ...this.template.querySelectorAll('lightning-textarea'),
            ...this.template.querySelectorAll('c-slwc-picklist'),
            ...this.template.querySelectorAll('c-slwc-dependent-picklist'),
            ...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back', {}));
        this._timeOffPlansByLabel = null;
        this.timeOffPlans = null;
    }

    handleSave() {
        if(!this.validate()) return;
        
        let callOutReceivedDateTimeObj = DateTime.fromISO(this.model.callOutReceivedDate + 'T' + this.model.callOutReceivedTime, {
            zone: this.timezoneSidId
        });

        if (this.hasAvailableBalance) {
            this.dispatchEvent(new CustomEvent('save', {
                detail: {
                    callOutReceivedDateTime: callOutReceivedDateTimeObj.toUTC().toISO(),
                    callOutType: this.model.callOutType,
                    callOutReason: this.model.callOutReason,
                    callOutNotes: this.model.callOutNotes,
                    timeOffPlan: this.model.timeOffPlan,
                    timeOffReasonCode: this.model.timeOffReasonCode,
                    usePtoForCallOut: this.model.usePtoForCallOut,
                    hasTimeOffPlans: this.model.hasTimeOffPlans
                }
            }));
            this.closeModal();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed to Save Call Out',
                    message: 'Unable to save Call Out due to insufficient Employee Balance for selected Time-Off Plan',
                    variant: 'error',
                })
            );
        }
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }
}