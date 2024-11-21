import { LightningElement, track } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { remove } from 'c/lodash';

import {
  collectionOperationService,
  collectionOperationQueryModel,
  userService
} from 'c/dataService';

const TABS = {
  DRIVE_LIST: 'driveList',
  DRIVE_LIST_MAP: 'driveListMap',
  DRIVE_CALENDAR: 'driveCalendar',
  DRIVE_PRODUCTIVITY: 'driveProductivity',
  DRIVE_OPTIMIZER: 'driveOptimizer',
  EXCEPTION_CONSOLE: 'exceptionConsole',
  APPROVAL_CONSOLE: 'approvalConsole',
  CALL_OUTS: 'callOuts'
}
export default class SlwcSchedulingConsole extends LightningElement {
  @track currentUser = {};
  @track currentTab = null;
  @track tabList = [];
  @track initialized = false;
  @track filters = {}

  get TABS() {
    return TABS;
  }

  get driveCalendarTabEnabled() {
    return (this.tabList || []).indexOf(TABS.DRIVE_CALENDAR) > -1;
  }
  get driveListTabEnabled() {
    return (this.tabList || []).indexOf(TABS.DRIVE_LIST) > -1;
  }
  get driveListMapTabEnabled() {
    return (this.tabList || []).indexOf(TABS.DRIVE_LIST_MAP) > -1;
  }
  get driveProductivityTabEnabled() {
    return (this.tabList || []).indexOf(TABS.DRIVE_PRODUCTIVITY) > -1;
  }
  get driveOptimizerTabEnabled() {
    return (this.tabList || []).indexOf(TABS.DRIVE_OPTIMIZER) > -1;
  }
  get exceptionConsoleTabEnabled() {
    return (this.tabList || []).indexOf(TABS.EXCEPTION_CONSOLE) > -1;
  }
  get approvalConsoleTabEnabled() {
    return (this.tabList || []).indexOf(TABS.APPROVAL_CONSOLE) > -1;
  }
  get callOutsTabEnabled() {
    return (this.tabList || []).indexOf(TABS.CALL_OUTS) > -1;
  }
  get showDriveCalendarTab() {
    return this.currentTab === TABS.DRIVE_CALENDAR;
  }
  get showDriveListTab() {
    return this.currentTab === TABS.DRIVE_LIST;
  }
  get showDriveListMapTab() {
    return this.currentTab === TABS.DRIVE_LIST_MAP;
  }
  get showDriveProductivityTab() {
    return this.currentTab === TABS.DRIVE_PRODUCTIVITY;
  }
  get showDriveOptimizerTab() {
    return this.currentTab === TABS.DRIVE_OPTIMIZER;
  }
  get showExceptionConsoleTab() {
    return this.currentTab === TABS.EXCEPTION_CONSOLE;
  }
  get showApprovalConsoleTab() {
    return this.currentTab === TABS.APPROVAL_CONSOLE;
  }
  get showCallOutsTab() {
    return this.currentTab === TABS.CALL_OUTS;
  }
  get driveCalendarReadonly() {
    const driveHelper = new DriveHelper();
    return driveHelper.isDRDUser(this.currentUser);
  }

  connectedCallback() {
    //init settings
    if (!this.initialized) {
      this.initialize();

      let lastSearchQuery = this.getLastQuery();
      if (lastSearchQuery) {
        Promise.resolve()
        .then(() => {
          const collectionOperations = ((lastSearchQuery.collectionOperationValues || {}).collectionOperations || []);
          if(collectionOperations.length) {
            const service = new collectionOperationService();
            let queryModel = new collectionOperationQueryModel();
            queryModel.recordIds = collectionOperations.map(item => item.id);
            return service.query(queryModel)
            .then(result => {
              collectionOperations.forEach(collectionOperation => {
                const newData = result.find(item => item.id === collectionOperation.id);
                if(newData) {
                  collectionOperation.workWeekFirstDay = newData.workWeekFirstDay;
                }
              })
            });
          }
        })
        .then(() => {
          this.filters = {
            ...this.filters, 
            ...lastSearchQuery
          };
        })
      }
    }
  }
  
  initialize() {
    this.retrieveCurrentUser();
    this.initialized = true;
  }

  retrieveCurrentUser() {
    let userSvc = new userService();
    return userSvc.getLoginUser()
      .then((result) => {
        this.currentUser = result.returnedData;
        this.getVisibleTabs();
      })
  }

  getVisibleTabs() {
    this.tabList = [
      TABS.DRIVE_LIST,
      TABS.DRIVE_LIST_MAP,
      TABS.DRIVE_CALENDAR,
      TABS.DRIVE_PRODUCTIVITY,
      TABS.DRIVE_OPTIMIZER,
      TABS.EXCEPTION_CONSOLE,
      TABS.APPROVAL_CONSOLE,
      TABS.CALL_OUTS
    ];

    let limitedProfile = ['DRD Profile', 'DRD Manager', 'Biomed Read Only', 'Recruitment Admin'];
    let limitedProfileTabs1 = [
      TABS.DRIVE_LIST,
      TABS.DRIVE_LIST_MAP,
      TABS.DRIVE_CALENDAR,
      TABS.DRIVE_PRODUCTIVITY,
      TABS.APPROVAL_CONSOLE
    ];
    let mapProfileToTabs = limitedProfile.reduce((result, profileName) => {
      result[profileName] = limitedProfileTabs1;
      return result;
    }, {});
    mapProfileToTabs['Collection Management'] = [
      TABS.APPROVAL_CONSOLE
    ];

    if (this.currentUser) {
      if (this.currentUser.profileName in mapProfileToTabs) {
        this.tabList = mapProfileToTabs[this.currentUser.profileName];
      }

      if (this.currentUser.approvalPermission && (
        !this.currentUser.approvalPermission.driveChangeRequest && 
        !this.currentUser.approvalPermission.driveShiftTradeRequest && 
        !this.currentUser.approvalPermission.pendingActionDrive &&
        !this.currentUser.approvalPermission.roleTimeVariance
      )) {
        remove(this.tabList, tab => tab === TABS.APPROVAL_CONSOLE)
      }
    }

    this.currentTab = this.tabList[0];
  }

  handleChangeTab(event) {
    this.currentTab = event.target.value;
  }

  setLastQuery() {
    slwcUtils.setLastQuery('schedulingConsole', this.filters);
  }

  getLastQuery() {
    let pageQuery = slwcUtils.getLastQuery('schedulingConsole');
    return pageQuery;
  }
}