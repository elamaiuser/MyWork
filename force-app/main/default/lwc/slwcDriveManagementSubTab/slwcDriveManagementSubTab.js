import { LightningElement, api, track } from 'lwc';
import schedulingProgressTab from './schedulingProgressTab.html';
import fixedSiteTab from './fixedSiteTab.html';
import wbFixedSiteTab from './wbFixedSiteTab.html';
import mobileTab from './mobileTab.html';
import productivityTab from './productivityTab.html';
import accountInformationTab from './accountInformationTab.html';
import systemInformationTab from './systemInformationTab.html';
import resultsTab from './resultsTab.html';
import { DriveHelper } from 'c/slwcDriveGenerator';
import TIME_ZONE from '@salesforce/i18n/timeZone';

const SUB_TAB_TYPE = {
  SCHEDULING_PROGRESS: 'schedulingProgress',
  FIXED_SITE: 'fixedSite',
  WB_FIXED_SITE: 'wbFixedSite',
  MOBILE: 'mobile',
  PRODUCTIVITY: 'productivity',
  ACCOUNT_INFORMATION: 'accountInformation',
  SYSTEM_INFORMATION: 'systemInformation',
  RESULTS: 'results'
}

const SUB_TAB_TYPE_TEMPLATE_MAPPING = {
  [SUB_TAB_TYPE.SCHEDULING_PROGRESS]: schedulingProgressTab,
  [SUB_TAB_TYPE.FIXED_SITE]: fixedSiteTab,
  [SUB_TAB_TYPE.WB_FIXED_SITE]: wbFixedSiteTab,
  [SUB_TAB_TYPE.MOBILE]: mobileTab,
  [SUB_TAB_TYPE.PRODUCTIVITY]: productivityTab,
  [SUB_TAB_TYPE.ACCOUNT_INFORMATION]: accountInformationTab,
  [SUB_TAB_TYPE.SYSTEM_INFORMATION]: systemInformationTab,
  [SUB_TAB_TYPE.RESULTS]: resultsTab
}

export default class SlwcSchedulingProgressTab extends LightningElement {
  driveHelper = new DriveHelper();

  @track timezoneSidId = TIME_ZONE;

  @api name = null;
  @api drive = null;
  @api masterData = null;

  get drivePlateletRounds() {
    return this.driveHelper.getDrivePlateletRounds(this.drive);
  }

  get accountName() {
    if (this.drive && this.drive.account) {
        return this.drive.account.name;
    }
    return "";
  }

  get isMobileDrive() {
    return this.driveHelper.isMobileDrive(this.drive);
  }

  get operationalEfficiencyValue() {
    const collected = this.drive && this.drive.actualTotalUnitsCollected;
    const projected = this.drive && this.drive.totalProductsProjected;
    if (!projected || projected === 0) return null;
    return (collected / projected) * 100;
  }

  get operationalEfficiencyPercent() {
    const val = this.operationalEfficiencyValue;
    if (val === null) return 'N/A';
    return Math.round(val) + '%';
  }

  get operationalEfficiencyLabel() {
    const val = this.operationalEfficiencyValue;
    if (val === null) return '';
    if (val > 97) return 'Exceeded Expectations';
    if (val >= 95) return 'Achieved Expectations';
    if (val >= 93) return 'Partially Met Expectations';
    return 'Did Not Meet Expectations';
  }

  get operationalEfficiencyIconStyle() {
    const val = this.operationalEfficiencyValue;
    let color;
    if (val === null) color = '#9e9e9e';
    else if (val >= 95) color = '#2e844a';
    else if (val >= 93) color = '#dd7a01';
    else color = '#ba0517';
    return `display:inline-block;width:14px;height:14px;border-radius:50%;background-color:${color};vertical-align:middle;margin-right:6px;`;
  }

  render() {
    return SUB_TAB_TYPE_TEMPLATE_MAPPING[this.name];
  }
}