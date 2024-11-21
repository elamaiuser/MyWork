import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';

const TABS = {
    DRIVE_LIST: 'driveList',
    OPTIMIZATION_RUN_LIST: 'optimizationRunList',
    SETTINGS: 'settings'
}

export default class SlwcDriveOptimizeConsole extends LightningElement {
    initialized = false;

    @wire(CurrentPageReference) pageRef;

    @track showSpinner = false;
    @track currentTab = TABS.DRIVE_LIST;

    get TABS() {
        return TABS;
    }

    get showDriveListTab() {
        return this.currentTab === TABS.DRIVE_LIST;
    }

    get showOptimizationRunListTab() {
        return this.currentTab === TABS.OPTIMIZATION_RUN_LIST;
    }

    get showSettingsTab() {
        return this.currentTab === TABS.SETTINGS;
    }
    
    get customClass() {
        return {
            driveListTab: slwcUtils.classNames('slds-tabs_default__item', {
                'slds-is-active': this.showDriveListTab
            }),
            optimizationRunListTab: slwcUtils.classNames('slds-tabs_default__item', {
                'slds-is-active': this.showOptimizationRunListTab
            }),
            settingsTab: slwcUtils.classNames('slds-tabs_default__item', {
                'slds-is-active': this.showSettingsTab
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