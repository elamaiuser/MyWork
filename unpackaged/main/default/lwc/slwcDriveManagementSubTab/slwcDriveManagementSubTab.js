import { LightningElement, api, track } from 'lwc';
import schedulingProgressTab from './schedulingProgressTab.html';
import fixedSiteTab from './fixedSiteTab.html';
import wbFixedSiteTab from './wbFixedSiteTab.html';
import mobileTab from './mobileTab.html';
import productivityTab from './productivityTab.html';
import accountInformationTab from './accountInformationTab.html';
import systemInformationTab from './systemInformationTab.html';
import { DriveHelper } from 'c/slwcDriveGenerator';
import TIME_ZONE from '@salesforce/i18n/timeZone';

const SUB_TAB_TYPE = {
  SCHEDULING_PROGRESS: 'schedulingProgress',
  FIXED_SITE: 'fixedSite',
  WB_FIXED_SITE: 'wbFixedSite',
  MOBILE: 'mobile',
  PRODUCTIVITY: 'productivity',
  ACCOUNT_INFORMATION: 'accountInformation',
  SYSTEM_INFORMATION: 'systemInformation'
}

const SUB_TAB_TYPE_TEMPLATE_MAPPING = {
  [SUB_TAB_TYPE.SCHEDULING_PROGRESS]: schedulingProgressTab,
  [SUB_TAB_TYPE.FIXED_SITE]: fixedSiteTab,
  [SUB_TAB_TYPE.WB_FIXED_SITE]: wbFixedSiteTab,
  [SUB_TAB_TYPE.MOBILE]: mobileTab,
  [SUB_TAB_TYPE.PRODUCTIVITY]: productivityTab,
  [SUB_TAB_TYPE.ACCOUNT_INFORMATION]: accountInformationTab,
  [SUB_TAB_TYPE.SYSTEM_INFORMATION]: systemInformationTab
}

export default class SlwcSchedulingProgressTab extends LightningElement {
  driveHelper = new DriveHelper();

  @track timezoneSidId = TIME_ZONE;

  @api name = null;
  @api drive = null;
  @api masterData = null;

  get drivePlateletRounds() {
    if(!this.drive || !this.drive.driveShiftsMetadata) return null;

    return (this.drive.driveShiftsMetadata.driveShifts || []).reduce((result, item) => {
      return result + (item.numberOfRounds || 0)
    }, 0);
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

  render() {
    return SUB_TAB_TYPE_TEMPLATE_MAPPING[this.name];
  }
}