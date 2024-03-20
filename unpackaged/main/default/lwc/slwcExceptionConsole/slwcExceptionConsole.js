import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';

const TABS = {
    DRIVE_EXCEPTION: 'driveException',
    RESOURCE_EXCEPTION: 'resourceException'
}

export default class SlwcExceptionConsole extends LightningElement {
    initialized = false;

    @wire(CurrentPageReference) pageRef;

    @track showSpinner = false;
    @track currentTab = TABS.DRIVE_EXCEPTION;

    get TABS() {
        return TABS;
    }

    get showDriveExceptionTab() {
        return this.currentTab === TABS.DRIVE_EXCEPTION;
    }

    get showResourceExceptionTab() {
        return this.currentTab === TABS.RESOURCE_EXCEPTION;
    }

    get customClass() {
        return {
            driveExceptionTab: slwcUtils.classNames('slds-tabs_default__item', {
                'slds-is-active': this.showDriveExceptionTab
            }),
            resourceExceptionTab: slwcUtils.classNames('slds-tabs_default__item', {
                'slds-is-active': this.showResourceExceptionTab
            })
        }
    }

    connectedCallback() {
    }

    renderedCallback() {
    }

    handleTabChange(event) {
        const newTab = event.currentTarget.dataset['value'];
        this.currentTab = newTab;
    }
}