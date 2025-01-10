import { LightningElement, track, api } from "lwc";
import { getValueFromEvent } from "c/slwcUtils";
import { isString } from "c/lodash";
import { SITE_FEEDBACK_ACCESS_MODE } from 'c/slwcConstants';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { siteFeedbackService, userService } from "c/dataService";
import { DriveHelper } from "c/slwcDriveGenerator";

export default class SlwcSiteFeedbackDetail extends LightningElement {
    @track _isOpen = false;
    @api
    get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;
        if(this._isOpen) {
            setTimeout(() => {
                this.init();
              });
        }
    }
    @api record;
    @api roleTimeVarianceRecord;
    @api job;
    @api site;
    @api accessMode = SITE_FEEDBACK_ACCESS_MODE.RESOURCE; 

    @track model = {};
    @track showSpinner = false;
    @track errorMessages = [];

    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        });
    }

    get isCreate() {
        return !this.record;
    }

    get isCreatedForRTVChangesFeedback() {
        return !!this.roleTimeVarianceRecord || !!this.record?.roleTimeVarianceId;
    }

    get isReadonly() {
        return this.record && this.record.status !== 'Not Submitted';
    }

    get disableVarianceType() {
        return this.isCreatedForRTVChangesFeedback || this.isReadonly;
    }

    get showVarianceTypeOther() {
        return this.model && this.model.varianceType === 'Other';
    }

    connectedCallback() {
    }

    exceptionHandler = (error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    init() {
        this.showLoading();
        let service = new userService();
        service.getLoginUser()
        .then((result) => {
            const helper = new DriveHelper();
            const loginUser = result.returnedData;
            this.accessMode = this.accessMode || SITE_FEEDBACK_ACCESS_MODE.RESOURCE;

            if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE && (!this.job || !this.site)) return;
    
            if (this.isCreate) {
                this.model = {};
                if (this.isCreatedForRTVChangesFeedback) {
                    this.model = this.initFeedbackFromRTV(this.roleTimeVarianceRecord);
                }
                if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE) {
                    this.model = {
                        ...this.model,
                        jobId: this.job.id,
                        site: this.site,
                        siteId: this.site.id,
                        status: 'Submitted',
                        routeApprovalRequestTo: 'Request CM evaluation'
                    }
                } else {
                    this.model = {
                        ...this.model,
                        site: this.site,
                        siteId: this.site.id,
                        status: 'Submitted',
                        routeApprovalRequestTo: helper.isCollectionManagentUser(loginUser) ? 'Request CM evaluation' : 'Request DM evaluation'
                    }
                }
            } else {
                this.model = {
                  ...this.record
                }
            }
            
            this.model.resourceRoleGroup = this.model.resourceRoleGroup || [];
            this.model.varianceAppliesTo = this.model.varianceAppliesTo || [];
            this.model.daysOfWeek = this.model.daysOfWeek || [];
            this.model.varianceTypeControllingFieldValues = this.model.varianceType ? [this.model.varianceType] : [];
        })
        .catch(err => this.exceptionHandler(err))
        .finally(() => this.hideLoading());
    }

    initFeedbackFromRTV(roleTimeVariance) {
        return {
            ...roleTimeVariance,
            id: null,
            name: null,
            roleTimeVarianceId: roleTimeVariance.id,
            roleTimeVariance
        }
    }

    handleOnChange(event) {
        const value = getValueFromEvent(event);
        this.model[event.currentTarget.name] = value;
        if (event.currentTarget.name === 'varianceType') {
            this.model.varianceTypeControllingFieldValues = value ? [value] : [];
            if (this.model.varianceType !== 'Other') {
                this.model.varianceTypeOther = null;
            }
        }
    }

    handleSubmit() {
        if (this.validate()) {
            this.showLoading();
            const service = new siteFeedbackService();
            service.save(this.model)
            .then(res => {
                if(!res.success) throw res;
                this.dispatchEvent(new ShowToastEvent({
                    message: 'Role Time Variance Feedback were updated successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
                this.dispatchEvent(new CustomEvent("submitted"));
            })
            .catch((error) => {
                this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
                }));
            })
            .finally(() => this.hideLoading());
        }
    }

    validate() {
        this.errorMessages = [];

        let allInputsCorrect = [
            ...this.template.querySelectorAll("lightning-input"),
            ...this.template.querySelectorAll("c-slwc-picklist"),
            ...this.template.querySelectorAll("c-slwc-multi-picklist"),
            ...this.template.querySelectorAll("lightning-combobox"),
            ...this.template.querySelectorAll("c-slwc-lookup"),
            ...this.template.querySelectorAll("c-slwc-select"),
        ];

        if (this.model.effectiveStartDate && this.model.effectiveEndDate) {
            if (this.model.effectiveStartDate >= this.model.effectiveEndDate) {
                this.errorMessages.push({
                    message: 'Effective Start Date must before Effective End Date.'
                })
            }
        }

        return !this.errorMessages.length && allInputsCorrect.reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
    }

    closeModal() {
        const eventModal = new CustomEvent("close");
        this.dispatchEvent(eventModal);
    }
}