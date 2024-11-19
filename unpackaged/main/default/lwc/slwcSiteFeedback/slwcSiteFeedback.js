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
import {
    findIndex,
    cloneDeep
} from 'c/lodash';
import { RTV_APPROVAL_STATUS, SITE_FEEDBACK_ACCESS_MODE } from 'c/slwcConstants';
import { classNames } from 'c/slwcUtils';

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
    @api siteId = null;
    @api accessMode = SITE_FEEDBACK_ACCESS_MODE.RESOURCE;
    @api fullScreen = false;

    @track roleTimeVarianceList = [];
    @track siteFeedbackList = [];
    @track showSpinner = false;
    @track site = null;
    
    @track siteFeedbackDetailModalData = {};
    @track confirmModalData = {};

    @wire(CurrentPageReference) pageRef;

    get customClass() {
        return {
            modal: classNames('slds-modal slds-fade-in-open', {
                'full-screen': this.fullScreen
            }),
            siteName: classNames('slds-hyphenate', {
                'slds-text-heading_small slds-text-color_weak slds-var-m-top_xx-small': !this.fullScreen,
                'slds-text-heading_medium': this.fullScreen
            })
        }
    }

    connectedCallback() {
        this.accessMode = this.accessMode || SITE_FEEDBACK_ACCESS_MODE.RESOURCE;
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    /** Confirm Modal **/
    showConfirmModal(confirmModalData) {
        this.confirmModalData = {...confirmModalData,
            isOpen: true
        }
    }

    hideConfirmModal() {
        this.confirmModalData = {};
    }

    init() {
        this.showLoading();
        return this.fetchSite()
        .then(() => {
            return Promise.all([
                this.fetchFeedback(),
                this.fetchRoleTimeVariances()
            ]);
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

    fetchSite() {
        let query = new locationQueryModel();
        query.recordIds = [this.siteId || this.job.driveSiteId];
        const service = new locationService();
        return service.query(query)
            .then(([site]) => {
                this.site = site;
            });
    }

    fetchFeedback() {
        let query = new siteFeedbackQueryModel();
        query.siteIds = [this.site.id];
        query.statuses = [
            RTV_APPROVAL_STATUS.SUBMITTED,
            RTV_APPROVAL_STATUS.WAITING_FOR_DM_APPROVAL,
            RTV_APPROVAL_STATUS.WAITING_FOR_CM_APPROVAL,
            RTV_APPROVAL_STATUS.WAITING_FOR_APS_APPROVAL,
            RTV_APPROVAL_STATUS.APPROVED
        ];
        query.excludeExpiry = true;

        const service = new siteFeedbackService();

        return service.query(query)
            .then(res => {
                this.siteFeedbackList = res.map(item => {
                    item.isReadonly = item.status !== RTV_APPROVAL_STATUS.NOT_SUBMITTED;
                    item.isDeletable = item.status !== RTV_APPROVAL_STATUS.NOT_SUBMITTED && item.status !== RTV_APPROVAL_STATUS.APPROVED;
                    item.site = item.siteId ? {
                        id: item.siteId,
                        name: item.siteName
                    } : null;
                    return item;
                })

                this.originalSiteFeedbackList = cloneDeep(this.siteFeedbackList);
            })
    }

    fetchRoleTimeVariances() {        
        if(!this.site) return;

        return Promise.resolve()
        .then(() => {
            let roleTimeVarianceSvc = new roleTimeVarianceService();
            let roleTimeVariancelQuery = new roleTimeVarianceQueryModel();
            roleTimeVariancelQuery.driveSiteIds = [this.site.id];
            roleTimeVariancelQuery.excludeExpiry = true;
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

    handleViewSiteFeedback(event) {
        const key = event.currentTarget.dataset.key;
        let siteFeedbackRecord = this.siteFeedbackList.find(item => item.key === key);
        this.handleShowSiteModal({ siteFeedbackRecord });
    }

    handleDeleteSiteFeedback(event) {
        let key = event.currentTarget.dataset.key;
        this.showConfirmModal({
            title: 'Confirm Deletion',
            message: 'Are you sure you want to delete this RTV feedback request?',
            onClose: (result) => {
                this.hideConfirmModal();
                if (result) {
                    let newList = [...this.siteFeedbackList];
                    const index = newList.findIndex((item) => item.key === key);
                    newList.splice(index, 1);
                    this.siteFeedbackList = newList;

                    this.handleSave();
                }
            },
            confirmBtnLabel: 'Yes',
            cancelBtnLabel: 'No'
        });
    }

    createSiteFeedback() {
        this.handleShowSiteModal();
    }

    handleShowSiteModal({
        siteFeedbackRecord,
        roleTimeVarianceRecord,
    } = {}) {
        this.siteFeedbackDetailModalData = {
            isOpen: true,
            siteFeedbackRecord,
            roleTimeVarianceRecord
        };
    }

    handleCreateFeedbackRTVChanges(event) {
        const key = event.currentTarget.dataset.key;
        let roleTimeVarianceRecord = this.roleTimeVarianceList.find(item => item.key === key);
        this.handleShowSiteModal({roleTimeVarianceRecord});
    }

    handleSiteFeedbackSubmitted() {
        this.handleCloseSiteModal();
        this.showLoading();
        this.fetchFeedback()
        .catch((error) => {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable'
            }));
        })
        .finally(() => this.hideLoading());
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
            const event = new ShowToastEvent({
                message: 'Role Time Variance Feedback were deleted successfully.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.fetchFeedback();
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