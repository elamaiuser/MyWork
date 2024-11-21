import { LightningElement, api } from 'lwc';
import { siteCollectionOpService } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { isNullOrEmpty } from 'c/slwcUtils';


export default class SlwcRefreshTravelTimeBanner extends LightningElement {
    @api recordId;
    isManualRefreshInProgress = false;
    hasInvalidTravelTimeData = false;
    travelTimeSettings = {};

    get bannerClass() {
        let bannerCls = 'slds-card slds-notify slds-notify_alert ';
        if (this.isManualRefreshInProgress || this.hasInvalidTravelTimeData) {
            bannerCls += 'slds-alert_warning';
        }
        return bannerCls;
    }

    get iconName() {
        return (this.isManualRefreshInProgress || this.hasInvalidTravelTimeData) ? 'utility:warning' : 'utility:info';
    }

    get bannerContent() {
        let content = 'No detected discrepancies in Travel Time/Distances for this Site Collection Operation.';
        if (this.isManualRefreshInProgress) {
            content = 'A manual process recalculating travel time/distance for this Site Collection Operation is currently underway.'
            content += ' Please refresh periodically to get an update on progress.';
        } else if (this.hasInvalidTravelTimeData) {
            content = 'One or more Travel Time Index relating to this Site Collection Operation is missing Travel Time/Distance Information.';
        }

        return content;
    }

    get showLink() {        
        return !this.isManualRefreshInProgress;
    }

    get linkContent() {
        return 'Click here to initiate manual refresh';
    }

    get showTravelTimeBanner() {
        return !isNullOrEmpty(this.travelTimeSettings) && this.travelTimeSettings.enableManualRefreshBanner;
    }

    connectedCallback() {
        let _scoSvc = new siteCollectionOpService();
        Promise.all([
            _scoSvc.isManualRefreshInProgress({ siteCollectionOperationId: this.recordId }),
            _scoSvc.hasInvalidTravelTimeData({ siteCollectionOperationId: this.recordId }),
            _scoSvc.getCustomSettings({ settingKeys: ['travelTimeManager']})
        ])
        .then(([isManualRefreshInProgress, hasInvalidTravelTimeData, travelTimeSettings]) => {
            this.isManualRefreshInProgress = isManualRefreshInProgress;
            this.hasInvalidTravelTimeData = hasInvalidTravelTimeData;
            this.travelTimeSettings = travelTimeSettings.returnedData.travelTimeManager;
        })
        .catch(e => console.debug(e))
        .finally()
    }

    initiateManualRefresh() {
        let _scoSvc = new siteCollectionOpService();
        _scoSvc.manualRefreshTravelTimeIndexes({
            siteCollectionOperationId: this.recordId
        }).then(res => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success!',
                message: 'Successfully initiated manual refresh for Travel Time Indexes related to this Site Collection Operation.',
                variant: 'success',
                mode: 'dismissable',
            }));
            this.isManualRefreshInProgress = true;            
        });
    }
}