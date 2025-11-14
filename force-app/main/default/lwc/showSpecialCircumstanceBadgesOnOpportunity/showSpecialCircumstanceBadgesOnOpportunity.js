import { LightningElement, api, track } from 'lwc';
import { opportunityService, opportunityQueryModel } from 'c/dataService';
import { isNullOrEmpty } from 'c/slwcUtils';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import SPECIAL_CIRCUMSTANCES_BADGES_LOGO_ZIP from "@salesforce/resourceUrl/Special_Circumstances_Badge_Logo";
import SPECIAL_AFFILIATIONS_BADGES_LOGO_ZIP from "@salesforce/resourceUrl/Special_Affiliations_Badge_Logo";
export default class ShowSpecialCircumstanceBadgesOnOpportunity extends LightningElement {

    channelName = '/data/OpportunityChangeEvent';
    subscription = {};

    @api recordId;

    @track drive;
    @track specialCircumstanceBaseUrl = SPECIAL_CIRCUMSTANCES_BADGES_LOGO_ZIP;
    @track specialAffiliationBaseUrl = SPECIAL_AFFILIATIONS_BADGES_LOGO_ZIP;
    @track showSpinner = false;

    get showBadgeLogo() {
        if (!this.drive) return false;

        return !isNullOrEmpty(this.drive.specialCircumstances) || !isNullOrEmpty(this.drive.specialAffiliations);
    }

    get specialBadges() {
       if(!this.showBadgeLogo) return [];

        return [
            ...(this.drive.specialCircumstances?.split(';').map(
                val => this.getBadgeObj(val, this.specialCircumstanceBaseUrl)
            ) || []),

            ...(this.drive.specialAffiliations?.split(';').map(
                val => this.getBadgeObj(val, this.specialAffiliationBaseUrl)
            ) || [])
        ];
       
    }

    connectedCallback() {
        this.init();
        this.handleSubscribe();
    }

    init() {
        if (!this.recordId) return;

        const oppService = new opportunityService();
        const oppQueryModel = new opportunityQueryModel();
        oppQueryModel.recordIds = [this.recordId];

        return oppService.query(oppQueryModel)
            .then(([drive]) => {
                this.drive = drive;
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideloading)
    }

    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }
    
    getBadgeObj(label, baseUrl) {
        const safeValue = label.replace(/[^a-zA-Z0-9]/g, '_').replace(/_+/g, '_');
        return {
            label: label,
            value: safeValue,
            badgeLogo: `${baseUrl}/Badges/${safeValue}.png`
        }
    }

    handleRefreshComponent() {
        this.showLoading = true;
        this.init();
    }

    handleSubscribe() {
        const messageCallback = response => {
            const changedFields = response.data.payload.ChangeEventHeader.changedFields;
            if(changedFields.includes('Special_Circumstances__c') || changedFields.includes('Special_Affiliations__c')) {
                this.handleRefreshComponent();
            }
        };
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, onError);
        this.subscription = {};
    }

    /*global ShowToastEvent*/
    /*eslint no-undef: "error"*/

    exceptionHandler = (error) => {
        console.log(error);
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }

}