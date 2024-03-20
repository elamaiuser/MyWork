import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent'
import {
    CurrentPageReference
} from 'lightning/navigation';
import {
    siteFeedbackQueryModel,
    siteFeedbackService,
    roleTimeVarianceQueryModel,
    roleTimeVarianceService,
    locationService,
    locationQueryModel
} from 'c/dataService';
import USER_ID from '@salesforce/user/Id';
import {
    findIndex,
    keyBy,
    remove,
    cloneDeep
} from 'c/lodash';
import slwcSiteFeedbackModal from './slwcSiteFeedbackModal.html';
import slwcSiteFeedbackPage from './slwcSiteFeedbackPage.html';
import { SITE_FEEDBACK_ACCESS_MODE } from 'c/slwcConstants';

const DISPLAY_MODE = {
    PAGE: 'page',
    MODAL: 'modal'
}

export default class SlwcSiteFeedback extends LightningElement {
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
    @api job = null;
    @api displayMode = DISPLAY_MODE.MODAL;
    @api accessMode = SITE_FEEDBACK_ACCESS_MODE.RESOURCE;

    @track roleTimeVarianceList = [];
    @track siteFeedbackList = [];
    @track showSpinner = false;
    
    @track siteFeedbackDetailModalData = {};

    get site() {
        if(!this.job) return null;
        return {
            id: this.job.driveSiteId,
            name: this.job.driveSiteName,
            label: this.job.driveSiteName
        };
    }
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        this.displayMode = this.displayMode || DISPLAY_MODE.MODAL;
        this.accessMode = this.accessMode || SITE_FEEDBACK_ACCESS_MODE.RESOURCE;

        if(this.displayMode === DISPLAY_MODE.PAGE) {
            this.init();
        }
    }

    render() {
        if(this.displayMode === DISPLAY_MODE.MODAL) {
            return slwcSiteFeedbackModal;
        } else {
            return slwcSiteFeedbackPage;
        }
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    init() {
        this.showLoading();
        Promise.resolve()
        .then(() => {
            if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE) {
                return Promise.all([
                    this.fetchFeedback(),
                    this.fetchRoleTimeVariances(this.job)
                ])
            } else {
                return Promise.all([
                    this.fetchFeedback()
                ])
            }
        })
        .catch((error) => {
            this.dispatchEvent(new ShowToastEvent({
              message: error.message,
              variant: 'error',
              mode: 'dismissable',
            }));
        })
        .finally(() => {
            this.hideLoading();
        });
    }

    fetchFeedback() {
        let query = new siteFeedbackQueryModel();
        query.createdByIds = [USER_ID];
        // query.createdByIds = ['0053F000007PH10QAG'];
        if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.RESOURCE) {
            query.jobIds = [this.job.id];
        } 
        if(this.accessMode === SITE_FEEDBACK_ACCESS_MODE.DRD) {
            query.queryDRDFeedback = true;
        }

        const service = new siteFeedbackService();

        return service.query(query)
            .then(res => {
                this.siteFeedbackList = res.map(item => {
                    item.isReadonly = item.status !== 'Not Submitted';
                    item.isDeleteDisabled = item.status !== 'Not Submitted' && item.status !== 'Submitted';
                    item.drive = item.driveId ? {
                        id: item.driveId,
                        name: item.driveName
                    } : null;
                    item.site = item.siteId ? {
                        id: item.siteId,
                        name: item.siteName
                    } : null;
                    if(item.drive) {
                        item.driveRecordPageUrl = '/' + item.drive.id;
                    }
                    if(item.site) {
                        item.siteRecordPageUrl = '/' + item.site.id;
                    }
                    return item;
                })

                this.originalSiteFeedbackList = cloneDeep(this.siteFeedbackList);
            })
    }

    fetchRoleTimeVariances(job) {        
        if(!job) return;

        return Promise.resolve()
        .then(() => {
            let roleTimeVarianceSvc = new roleTimeVarianceService();
            let roleTimeVariancelQuery = new roleTimeVarianceQueryModel();
            roleTimeVariancelQuery.driveSiteIds = [job.driveSiteId];
            return roleTimeVarianceSvc.query(roleTimeVariancelQuery);
        })
        .then(result => {
            this.roleTimeVarianceList = result || [];
        })
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
            }
        }));
    }

    handleDeleteSiteFeedback(event) {
        const key = event.currentTarget.dataset.key;
        let newList = [...this.siteFeedbackList];
        const index = newList.findIndex((item) => item.key === key);
        newList.splice(index, 1);
        this.siteFeedbackList = newList;
    }

    handleEditSiteFeedback(event) {
        const key = event.currentTarget.dataset.key;
        let record = this.siteFeedbackList.find(item => item.key === key);
        this.handleShowSiteModal(record);
    }

    createSiteFeedback() {
        this.handleShowSiteModal();
    }

    handleShowSiteModal(record) {
        this.siteFeedbackDetailModalData = {
            isOpen: true,
            record: record
        };
    }

    handleSaveSiteModal(event) {
        let newRecord = event.detail;
        newRecord.isReadonly = newRecord.status !== 'Not Submitted';

        if(newRecord.drive) {
            newRecord.driveRecordPageUrl = '/' + newRecord.drive.id;
        }
        if(newRecord.site) {
            newRecord.siteRecordPageUrl = '/' + newRecord.site.id;
        }

        const index = findIndex(this.siteFeedbackList, item => item.key === newRecord.key);
        if (index > -1) {
            this.siteFeedbackList[index] = newRecord;
        }
        else {
            this.siteFeedbackList.push(newRecord);
        }
        this.handleCloseSiteModal();
    }

    handleCloseSiteModal() {
        this.siteFeedbackDetailModalData = {};
    }

    handleSave() {
        const service = new siteFeedbackService()
        this.showLoading();

        const recordsToDelete = (this.originalSiteFeedbackList || []).filter(originalSiteFeedback => {
            return originalSiteFeedback.id && !this.siteFeedbackList.find(siteFeedback => siteFeedback.id === originalSiteFeedback.id);
        })

        service.deleteList(recordsToDelete)
        .then(res => {
            if(!res.success) throw res;

            return service.saveList(this.siteFeedbackList);
        })
        .then(res => {
            if(!res.success) throw res;
            const event = new ShowToastEvent({
                message: 'Role Time Variance Feedback were updated successfully.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);

            this.closeModal();
        })
        .catch((error) => {
            this.dispatchEvent(new ShowToastEvent({
              message: error.message,
              variant: 'error',
              mode: 'dismissable',
            }));
        })
        .finally(() => this.hideLoading())
    }
}