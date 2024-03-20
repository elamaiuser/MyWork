import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';

const TABS = {
  SITE_FEEDBACK: 'siteFeedback',
  DRIVE_SHIFT_TRADE: 'driveShiftTrade',
  DRIVE_CHANGE_REQUEST: 'driveChangeRequest',
  PENDING_ACTION_DRIVE: 'pendingActionDrive',
  PENDING_DRIVE_CHANGE_REQUEST: 'pendingDriveChangeRequest',
}

export default class SlwcApprovalConsole extends LightningElement {
  initialized = false;

  @api loginUser = null;

  @wire(CurrentPageReference) pageRef;

  @track showSpinner = false;
  @track currentTab = TABS.SITE_FEEDBACK;
  @track tabVisibilityMap = {};

  get TABS() {
    return TABS;
  }

  get showSiteFeedbackTab() {
    return this.currentTab === TABS.SITE_FEEDBACK;
  }

  get showDriveShiftTradeTab() {
    return this.currentTab === TABS.DRIVE_SHIFT_TRADE;
  }

  get showDriveChangeRequestTab() {
    return this.currentTab === TABS.DRIVE_CHANGE_REQUEST;
  }

  get showPendingDriveChangeRequestTab() {
    return this.currentTab === TABS.PENDING_DRIVE_CHANGE_REQUEST;
  }

  get showPendingActionDriveTab() {
    return this.currentTab === TABS.PENDING_ACTION_DRIVE;
  }

  get customClass() {
    return {
      siteFeedbackTab: slwcUtils.classNames('slds-tabs_default__item', {
        'slds-is-active': this.showSiteFeedbackTab
      }),
      driveShiftTradeTab: slwcUtils.classNames('slds-tabs_default__item', {
        'slds-is-active': this.showDriveShiftTradeTab
      }),
      driveChangeRequestTab: slwcUtils.classNames('slds-tabs_default__item', {
        'slds-is-active': this.showDriveChangeRequestTab
      }),
      pendingDriveChangeRequestTab: slwcUtils.classNames('slds-tabs_default__item', {
        'slds-is-active': this.showPendingDriveChangeRequestTab
      }),
      pendingActionDriveTab: slwcUtils.classNames('slds-tabs_default__item', {
        'slds-is-active': this.showPendingActionDriveTab
      })
    }
  }

  connectedCallback() {
    this.tabVisibilityMap = this.buildTabVisibilityMap(this.loginUser);
    this.populateDefaultTab();
  }

  renderedCallback() {
  }

  populateDefaultTab() {
    let validTabs = Object.keys(this.tabVisibilityMap).filter(tab => {
      return this.tabVisibilityMap[tab];
    })
    this.currentTab = validTabs[0];
  }

  buildTabVisibilityMap(loginUser) {
    let tabVisibilityMap = {
      [TABS.SITE_FEEDBACK]: true,
      [TABS.DRIVE_SHIFT_TRADE]: true,
      [TABS.DRIVE_CHANGE_REQUEST]: true,
      [TABS.PENDING_DRIVE_CHANGE_REQUEST]: true,
      [TABS.PENDING_ACTION_DRIVE]: true
    }
    
    if (loginUser && loginUser.approvalPermission) {
      tabVisibilityMap[TABS.SITE_FEEDBACK] = loginUser.approvalPermission.roleTimeVariance;
      tabVisibilityMap[TABS.DRIVE_SHIFT_TRADE] = loginUser.approvalPermission.driveShiftTradeRequest;
      tabVisibilityMap[TABS.DRIVE_CHANGE_REQUEST] = loginUser.approvalPermission.driveChangeRequest;
      tabVisibilityMap[TABS.PENDING_DRIVE_CHANGE_REQUEST] = loginUser.approvalPermission.driveChangeRequest;
      tabVisibilityMap[TABS.PENDING_ACTION_DRIVE] = loginUser.approvalPermission.pendingActionDrive;
    }

    return tabVisibilityMap;
  }
  
  handleTabChange(event) {
    const newTab = event.currentTarget.dataset['value'];
    this.currentTab = newTab;
  }
}