import TIME_ZONE from '@salesforce/i18n/timeZone';
import { LightningElement, track, wire, api } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { DateTime } from 'c/luxon';
import { fireEvent } from 'c/pubsub';
import { first, uniqBy } from 'c/lodash';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshLightningPage } from 'c/slwcUtils';
import * as autoMapper from 'c/autoMapper';
import { sObjectType, dataService, collectionOperationTimeBlockService, collectionOperationTimeBlockQueryModel, opportunityService, opportunityQueryModel, accountService, accountQueryModel, locationService, locationQueryModel, resourceQueryModel, resourceService } from 'c/dataService';
import { PLAN_DRIVE_ERROR_MESSAGE_MAP, DRIVE_STATUS } from 'c/slwcConstants';
import * as slwcUtils from 'c/slwcUtils';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { calendarMonthHelper, planDriveDateHelper } from 'c/slwcHelpers';

const DRIVE_ERRORS = {
  MISSING_REQUIRED_FIELDS: 'MISSING_REQUIRED_FIELDS'
}

const NO_TIME_BLOCK = 'no-timeblock';


const DEFAULT_CALENDAR_SETTINGS = {
  timezone: TIME_ZONE,
  firstDay: 0
}

export default class SlwcPlanDrive extends LightningElement {
  driveHelper = new DriveHelper();
  planDriveHelper = new planDriveDateHelper(DEFAULT_CALENDAR_SETTINGS);
  
  @api recordId;
  // @api recordId = '0062i000008JSa7AAG';

  @wire(CurrentPageReference) pageRef;
  @track initialized = false;
  @track showSpinnerCount = 0;
  @track opportunity = null;
  @track drive = null;
  @track driveDate = null;
  @track masterData = {};
  @track driveMissingFields = [];
  @track filter = {
    selectedMonth: null,
    selectedTimeBlockId: ''
  }
  @track confirmModalData = {};
  @track timeBlockOptions = [];

  get showTimeBlockSelect() {
    if(!this.driveHelper.isMobileDrive(this.opportunity)) return false;
    return this.timeBlockOptions.length > 0;
  }

  get requireSelectTimeBlock() {
    if(!this.showTimeBlockSelect) return false;

    return !this.filter.selectedTimeBlockId;
  }

  get selectedTimeBlockId() {
    if(this.filter.selectedTimeBlockId === NO_TIME_BLOCK) return '';
    return this.filter.selectedTimeBlockId;
  }

  connectedCallback() {
    //init settings
    if (!this.initialized) {
      this.init()
        .then(() => {
          try {
            subscribe('/topic/OpportunityUpdates', -1, this.messageCallback).then(response => {
              console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            });
          } catch(e) {}
          
          this.initialized = true;
        })
    }
  }

  messageCallback = (response) => {
    if (response.data.sobject.Id == this.recordId) {
      this.retrieveOpportunity(this.recordId)
        .then(() => {
          this.forceRefresh();
        });
    }
  };
  
  get showSpinner() {
    return this.showSpinnerCount > 0;
  }

  get celendarHeader() {
    if (!this.filter.selectedMonth) return null;
    const selectedMonth = DateTime.fromString(this.filter.selectedMonth, 'yyyy-MM-dd').toJSDate();
    return DateTime.fromJSDate(selectedMonth).toFormat('MMMM yyyy');
  }
  get classHeader() {
    return ( this.isDesktop || this.isTablet ) ? "slds-page-header__row slds-grid_vertical-align-center" : "";
  }
  get isMobile() {
    return slwcUtils.isMobile()
  }

  get isTablet() {
    return slwcUtils.isTablet()
  }

  get isDesktop() {
    return slwcUtils.isDesktop()
  }

  get nextMonth() {
    if (!this.filter.selectedMonth) return null;
    const nextMonth = DateTime.fromString(this.filter.selectedMonth, 'yyyy-MM-dd').plus({
      months: 1
    }).toJSDate();
    return DateTime.fromJSDate(nextMonth).toISODate()
  }

  get next2Month() {
    if (!this.filter.selectedMonth) return null;
    const next2Month = DateTime.fromString(this.filter.selectedMonth, 'yyyy-MM-dd').plus({
      months: 2
    }).toJSDate();
    return DateTime.fromJSDate(next2Month).toISODate()
  }

  exceptionHandler = (error, silentError = false) => {
    console.log(error);

    if (!silentError) {
      if (error && error.errorCode === DRIVE_ERRORS.MISSING_REQUIRED_FIELDS) {
        this.showConfirmModal({
          mode: 'error',
          title: 'Something Has Gone Wrong',
          confirmBtnLabel: 'none',
          cancelBtnLabel: 'Refresh',
          message: `There are some fields missing on the Draft Drive:
            ${this.driveMissingFields
              .map(field => '- ' + field)
              .join('\n')}
          Please help to check and fill required data. After that press Refresh button to continue.`,
          onClose: (result) => {
            this.hideConfirmModal();
            this.init();
          }
        })
      }
    }
  }

  showLoading = () => {
    this.showSpinnerCount++;
  }

  hideLoading = () => {
      this.showSpinnerCount--;
      if(this.showSpinnerCount < 0) {
          this.showSpinnerCount = 0;
      } 
  }

  checkDriveMissingFields = (opp) => {
    var missingFields = [];
    if(!opp) {
      missingFields.push('Draft Drive');
    }

    if(!opp.anticipatedRegisteredDonors) {
      missingFields.push('Anticipated Registered Donors');
    }

    if(!opp.driveSite) {
      missingFields.push('Drive Site');
    }

    return missingFields;
  }

  collectCollectionOperations = (opportunity) => {
    if(!opportunity?.driveSite || !this.filter?.selectedMonth || !this.next2Month) return [];

    const { startDate: startDateOfFirstMonth } = this.planDriveHelper.getDateRange(this.filter.selectedMonth);
    const { endDate: endDateOfLastMonth } = this.planDriveHelper.getDateRange(this.next2Month);
    return this.planDriveHelper.getCollectionOperations(
      this.opportunity.driveSite, 
      startDateOfFirstMonth,
      endDateOfLastMonth
    );
  }

  retrieveOpportunity = (oppId) => {
    let opportunityQuery = new opportunityQueryModel();
    opportunityQuery.recordIds = [oppId];
    opportunityQuery.subQueryIndicator = sObjectType.DRIVE | sObjectType.OPPORTUNITY_CONTACT_ROLE;

    let opportunitySvc = new opportunityService();

    this.showLoading();
    return opportunitySvc.query(opportunityQuery)
    .then(([opportunity]) => {
      return Promise.all([
        opportunity,
        this.retrieveAccount(opportunity.accountId),
        this.retrieveDriveSite(opportunity.driveSiteId)
      ]);
    })
    .then(([opportunity, account, driveSite]) => {
      opportunity.account = account;
      opportunity.driveSite = driveSite;
      this.opportunity = opportunity;
      this.drive = (opportunity.drives && opportunity.drives.length > 0) ? opportunity.drives[0] : null;
      return this.opportunity;
    })
    .catch(error => this.exceptionHandler(error, true))
    .finally(this.hideLoading);
  }

  retrieveTimeBlocks = (opportunity) => {
    const collectionOperations = this.collectCollectionOperations(opportunity);
    if (!collectionOperations.length) {
      this.timeBlockOptions = [];
      return;
    };

    let service = new collectionOperationTimeBlockService();
    let queryModel = new collectionOperationTimeBlockQueryModel();
    queryModel.collectionOperationIds = collectionOperations.map(item => item.id);
    this.showLoading();
    return service.query(queryModel)
      .then((result = []) => {
        this.timeBlockOptions = [{
          label: 'No Time Block',
          value: NO_TIME_BLOCK
          }, ...uniqBy(result.map(COTimeBlock => {
            return {
              label: `${COTimeBlock.timeBlock.name} (${this.formatTime(COTimeBlock.timeBlock.startTime)} - ${this.formatTime(COTimeBlock.timeBlock.endTime)})`,
              value: COTimeBlock.timeBlock.id
            };
          }), item => item.value)
        ];

        if (this.filter.selectedTimeBlockId) {
          const noLongerValid = !this.timeBlockOptions.find(option => option.value === this.filter.selectedTimeBlockId);
          if(noLongerValid) {
            this.filter.selectedTimeBlockId = null;
          }
        }
          
      })
      .catch(error => this.exceptionHandler(error, true))
      .finally(this.hideLoading);
  }

  retrieveCustomSettings() {
    let settingKeys = ["resourceRoleGroups", "lunchBreakSettings"];
    this.showLoading();
    let service = new dataService();
    return service.getCustomSettings({ settingKeys: settingKeys })
      .then((result) => {
        this.masterData.resourceRoleGroups = result.returnedData.resourceRoleGroups;
        this.masterData.lunchBreakSettings = autoMapper.autoMapperInstance.mapToArray('sked_Lunch_Break_Setting__c', result.returnedData.lunchBreakSettings);
      })
      .catch(error => this.exceptionHandler(error, true))
      .finally(this.hideLoading);
  }

  retrieveAccount = (accId) => {
    let accountQuery = new accountQueryModel();
    accountQuery.recordIds = [accId];
    accountQuery.subQueryIndicator = sObjectType.ACCOUNT_AVAILABILITY_PREFERENCE;

    let accountSvc = new accountService();

    this.showLoading();
    return accountSvc.query(accountQuery)
    .then((result) => {
      return first(result);
    })
    .catch(error => this.exceptionHandler(error, true))
    .finally(this.hideLoading);
  }

  retrieveDriveSite(driveSiteId) {
    let locationSvc = new locationService();
    let locationQuery = new locationQueryModel();
    locationQuery.recordIds = [driveSiteId];
    this.showLoading();
    return locationSvc.query(locationQuery)
    .then((result) => {
      return first(result);
    })
    .catch(error => this.exceptionHandler(error, true))
    .finally(this.hideLoading);
  }

  init() {
    this.showLoading();
    return Promise.resolve()
      .then(() => {
        return Promise.all([
          this.retrieveOpportunity(this.recordId),
          this.retrieveCustomSettings()
        ]);
      })
      .then(() => {
        this.driveMissingFields = this.checkDriveMissingFields(this.opportunity);
        if(this.driveMissingFields.length > 0) {
          throw {
            errorCode: DRIVE_ERRORS.MISSING_REQUIRED_FIELDS          
          };
        }
      })
      .then(() => {
        let opportunity = this.opportunity;

        this.driveDate = opportunity.driveDate;

        this.filter.selectedMonth = DateTime.local().toISODate();
        if(this.driveDate) {
          this.filter.selectedMonth = this.driveDate;
        }
        return this.retrieveTimeBlocks(this.opportunity);
      })  
      .catch((error) => this.exceptionHandler(error, false))
      .finally(this.hideLoading)
  }

  handleOnMonthChanged(event) {
    this.filter.selectedMonth = event.detail.selectedDate;

    this.retrieveTimeBlocks(this.opportunity);
  }

  handleTimeBlockChanged = (event) => {
    const value = slwcUtils.getValueFromEvent(event);
    this.filter.selectedTimeBlockId = value ?? '';
  }

  forceRefresh() {
    this.showLoading();
    return Promise.resolve()
      .then(() => {
        return Promise.all([
          this.retrieveOpportunity(this.recordId)
        ]);
      })
      .then(() => {
        let opportunity = this.opportunity;

        this.driveDate = opportunity.driveDate;
        if(this.driveDate) {
          this.filter.selectedMonth = this.driveDate;
        }

        return this.retrieveTimeBlocks(this.opportunity);
      })
      .then(() => {    
        fireEvent(this.pageRef, 'planDrive:forceRefresh');
      })  
      .catch((error) => this.exceptionHandler(error, false))
      .finally(this.hideLoading)
  }

  buildConfirmMessage(dateDetails) {
    const selectedDateString = DateTime.fromFormat(dateDetails.dateIso, 'yyyy-MM-dd').toFormat('MMMM dd, yyyy');
    let confirmMessage = `Confirm ${selectedDateString} as the Drive Date`;

    if(dateDetails.errorMessages && dateDetails.errorMessages.length) {
      confirmMessage = `${confirmMessage}

        The proposed drive will be put into queue due to the below reasons:
        ${dateDetails.errorMessages.map(errorCode => {
          return ' - ' + PLAN_DRIVE_ERROR_MESSAGE_MAP[errorCode];
        }).join('\n')}
        The Drive will require an Approval to be placed on the Calendar.
      `
    }

    return confirmMessage;
  }
  
  handleSelectDate(event) {
    const selectedDate = event.detail.selectedDate;
    const data = event.detail.data;
    
    if(this.drive && [DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.COMPLETE].includes(this.drive.status)) {
      this.showConfirmModal({
        title: 'Error',
        message: 'This drive is in Confirmed Drive Status, a date change is no longer permitted. You must cancel and add a new opportunity.',
        mode: 'error',
        confirmBtnLabel: 'none',
        cancelBtnLabel: 'Close',
        onClose: (result) => {
          this.hideConfirmModal();
        }
      })
    } else {
      this.showConfirmModal({
        title: 'Drive Date Confirmation',
        message: this.buildConfirmMessage(data),
        onClose: (result) => {
          this.hideConfirmModal();
  
          if(result) {
            this.showLoading();
            return Promise.resolve()
              .then(() => {
                let oppService = new opportunityService();
                return oppService.save({ id: this.recordId, driveDate: selectedDate , driveDateChangeReason : `Changed from Plan a Drive at ${DateTime.fromObject({
                  zone: this.opportunity.driveSite.timezoneSidId
                  }).toFormat('yyyy-MM-dd hh:mm:ss z')}`})
              })
              .then((result) => {
                this.driveDate = selectedDate;
        
                this.dispatchEvent(new ShowToastEvent({
                  message: 'Draft Drive Date was updated successfully.',
                  variant: 'success',
                  mode: 'dismissable'
                }));
        
                refreshLightningPage();
              })
              .catch((error) => this.exceptionHandler(error, true))
              .finally(this.hideLoading)
          }
        }
      })
    }
  }

  showConfirmModal(confirmModalData) {
    this.confirmModalData = {...confirmModalData,
      isOpen: true
    }
  }

  hideConfirmModal() {
    this.confirmModalData = {};
  }

  formatTime(time) {
    return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
  }
}