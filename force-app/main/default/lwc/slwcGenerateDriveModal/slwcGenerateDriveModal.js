import { LightningElement, api,wire, track } from 'lwc';
import {
  ShowToastEvent
} from 'lightning/platformShowToastEvent'
import { sObjectType, debugLogService, driveService, driveChangeRequestQueryModel, driveChangeRequestService, opportunityQueryModel, opportunityService, locationService, locationQueryModel, driveQueryModel, approvalService } from 'c/dataService';
import { isNullOrEmpty, getValueFromEvent, waitUntil} from 'c/slwcUtils';
import { isArray, isString, isEmpty } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { PENDING_ACTION, DRIVE_REQUEST_CHANGE_STATUS, DRIVE_STATUS, DRIVE_CHANGE_REQUEST_ITEM_TYPE, DRIVE_APPROVAL_STATUS, DRIVE_TYPE } from 'c/slwcConstants';
import { slwcDriveGeneratorHelper, DriveHelper, DriveFetch } from 'c/slwcDriveGenerator';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import fetchOpportunityFromDriveChangeRequest from '@salesforce/apex/OpportunityControllerHelper.fetchOpportunityFromDriveChangeRequest';
import getWarningMessage from '@salesforce/apex/OpportunityControllerHelper.getWarningMessage';

const OPP_ARD_VALIDATION_FLAG = ['Opportunity.Pending_ARD_Confirmation__c'];
const DCR_FIELDS = [
  'sked_Drive_Change_Request__c.sked_Opportunity__c',
  'sked_Drive_Change_Request__c.sked_Drive__c'
];

const DRIVE_FIELDS = ['sked_Drive__c.sked_Opportunity__c'];

let driveGeneratorInstance = {
  drive: null,
  masterData: {
      driveTags: {
      accountTags: [],
      locationTags: []
      },
      isReadonly: false,
      lunchBreakSettings: [],
      resourceRoleGroups: null,
      roleTimeData: null,
      roleTimeDetailMap: null,
      roleTimeVarianceMap: {},
      sameDateActivities: [],
      sameDateDrives: [],
      staffingDecisionMatrix: null,
      timezoneSidId: null,
      vehicles: [],
      backupDriveShiftMap: {}
  },
  errorMessages: []
};

const STEP = {
  CHECKING_DCR: {
    value: 1,
    label: 'Checking Drive Change Request',
    action: function(scope) {
      let queryModel = new driveChangeRequestQueryModel();
      queryModel.recordIds = [scope.recordId];
      queryModel.subQueryIndicator = sObjectType.DRIVE_CHANGE_REQUEST_ITEM;

      let service = new driveChangeRequestService();
      return service.query(queryModel)
      .then(result => {
        if(!result || !result.length) {
          scope.resultMessage = 'Cannot find Drive Change Request';
          scope.hookAfterFinishedHandler(false, scope.resultMessage);
          return false;
        }
        
        const dcrRecord = result[0];
        const driveChanges = (dcrRecord.driveChangeRequestItems || []).filter(dcrItem => dcrItem.type === DRIVE_CHANGE_REQUEST_ITEM_TYPE.CHANGE);
        const needToRegenerateDrive = driveChanges.length > 0;
        if(!needToRegenerateDrive) {
          scope.resultMessage = 'The Drive Change Request does not require to regenerate the drive.';
          scope.hookAfterFinishedHandler(false, scope.resultMessage);
          return false;
        }

        scope.recordId = dcrRecord.driveId;
        scope.driveChangeRequest = dcrRecord;

        return true;
      })
    }
  },
  GENERATE_PAST_DRIVE: {
    value: 2,
    label: 'Generating Past Drive',
    action: function(scope) {
      const { recordId } = scope;
      return scope.generatePastDrive(recordId);
    }
  },
  GENERATE_DRIVE: {
    value: 2,
    label: 'Generating Drive',
    action: function(scope) {
      const { recordId } = scope;
      return slwcDriveGeneratorHelper.initialize(recordId)
      .then((result) => {
        driveGeneratorInstance = result.driveGeneratorInstance;
        scope.drive = result.drive;
        scope.errorMessages = driveGeneratorInstance.errorMessages || [];
        if(scope.drive && scope.drive.id) {
          scope.resultMessage = 'Drive had already been generated.';
          scope.hookAfterFinishedHandler(false, scope.resultMessage);
          return false;
        }
        return !scope.driveGeneratorHasError;
      })
    }
  },
  SAVE_DRIVE: {
    value: 4,
    label: 'Saving Drive',
    action: function(scope) {
      return scope.saveDrive(scope.drive, scope)
        .then(() => {
          if (scope.mode === MODE.GENERATE_DRIVE) {
            scope.resultMessage = 'Drive was generated successfully.';
            scope.needToRefreshPage = true;
          } 
          else if (scope.mode === MODE.GENERATE_PAST_DRIVE) {
            scope.resultMessage = 'Past Drive was generated successfully.';
            scope.needToRefreshPage = true;
          } 
          else if (scope.mode === MODE.LISTEN_OPPORTUNITY_CHANGED) {
            scope.resultMessage = 'Your changes have been approved and updates have been made by system.';
            scope.needToRefreshPage = true;
          }
          else if (scope.mode === MODE.APPROVE_DCR) {
            scope.resultMessage = 'Drive was updated successfully.';
          }
          scope.hookAfterFinishedHandler(true, scope.resultMessage);
        })
        .catch(error => {
          scope.resultMessage = error.message;
          scope.hookAfterFinishedHandler(false, scope.resultMessage);
        })
        .finally(() => {
          return false;
        })
    }
  },
  APPLY_CHANGES_TO_DRIVE: {
    value: 6,
    label: 'Applying changes...',
    action: function(scope) {
        return slwcDriveGeneratorHelper.initialize(scope.recordId)
        .then((result) => {
          driveGeneratorInstance = result.driveGeneratorInstance;
          scope.drive = driveGeneratorInstance.drive;
        })
        .then(() => {
          let driveChanges = scope.generateDriveChangesFromDCR(scope.drive, scope.driveChangeRequest);
          return driveGeneratorInstance.onDriveDataChanged(driveChanges, { isCalledFromDCRProcessingModal : true })
        })
        .then(() => {
          scope.drive = driveGeneratorInstance.drive;
          return true;
        });
    }
  },
  CAPTURE_DRIVE_CHANGES: {
    value: 7,
    label: 'Capturing drive changes...',
    action: function(scope) {
      return Promise.resolve()
      .then(() => {
        const service = new approvalService();
        return service.isPendingApproval({
          recordId: scope.drive.id
        })
      })
      .then((result) => {
        const isDrivePendingApproval = result.returnedData;
        scope.needConfirmToSubmitDriveForApproval = false;

        const driveHelper = new DriveHelper();
        const autoApprove = driveHelper.isFixedSiteDrive(scope.drive) || (scope.drive.status === DRIVE_STATUS.DRAFT && !isDrivePendingApproval);
        let driveContentions = scope.getDriveContentions(scope.drive);
        console.log('driveContentions ',driveContentions);
       // driveContentions = !isNullOrEmpty(driveContentions) ? driveContentions.split(';') : [];
        
        if(!scope.noAction && !autoApprove && driveContentions.length > 0) {
          scope.needConfirmToSubmitDriveForApproval = true;

          scope.resultMessage = `Drive requires approval due to contentions:
              ${driveContentions.map(contention => {
                return `- ${contention}`
              }).join('\n')}
              Do you want to submit this Drive for approval (${scope.drive.routeApprovalRequestTo})?
              <strong>Note:</strong> In order to discard the changes and revert the Opportunity, click "No".
          `;

          scope.hookAfterFinishedHandler(false, scope.resultMessage);
          return false;
        }
        return scope.submitDCR();
      });
    }
  },
  VALIDATE_ASSETS: {
    value: 8,
    label: 'Validating Drive',
    action: function (scope) {
      if(scope.drive.status === DRIVE_STATUS.DRAFT) {
        const service = new approvalService();
        return service.isPendingApproval({
          recordId: scope.drive.id
        })
        .then((result) => {
          const isDrivePendingApproval = result.returnedData;
          if (isDrivePendingApproval) {
            return driveGeneratorInstance.submitDrive()
            .then(() => {
              return driveGeneratorInstance.validateDrive();
            })
            .then(() => {
              let pendingActionReasonCodes = driveGeneratorInstance.drive.pendingActionReasonCode || [];
              if (pendingActionReasonCodes.length === 0) {
                driveGeneratorInstance.drive.status = [DRIVE_STATUS.DRAFT].includes(driveGeneratorInstance.drive.status) ? DRIVE_STATUS.TENTATIVE : driveGeneratorInstance.drive.status;
              }
            })
          }
        })
        .then(() => {
          scope.drive = driveGeneratorInstance.drive;
          return true;
        })
      }

      return driveGeneratorInstance.validateCurrentAssignedAssets()
        .then(({ allAssignedEquipmentsValid, newEquipmentJobsMap, lockedEquipments = [], allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
          //equipments
          return Promise.resolve()
            .then(() => {
              if (!allAssignedEquipmentsValid) {
                return driveGeneratorInstance.onDriveDataChanged([{
                  targetName: 'totalEquipmentRequestedChanged',
                  targetValue: {
                    equipmentJobsMap: newEquipmentJobsMap,
                    lockedEquipments: lockedEquipments
                  }
                }])
              }
            })
            .then(() => {
              return {
                allAssignedVehiclesValid,
                newVehicles,
                lockedVehicles,
                canHandleDriveProjectedRegisteredDonors
              }
            })
        })
        .then(({ allAssignedVehiclesValid, newVehicles, lockedVehicles = [], canHandleDriveProjectedRegisteredDonors }) => {
          //vehicles
          if (!canHandleDriveProjectedRegisteredDonors) {
            return driveGeneratorInstance.onDriveDataChanged([{
              targetName: 'totalVehicleRequestedChanged',
              targetValue: {
                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                vehicles: newVehicles,
                lockedVehicles: lockedVehicles
              }
            }])
          }

          if (!allAssignedVehiclesValid && canHandleDriveProjectedRegisteredDonors) {
            return driveGeneratorInstance.onDriveDataChanged([{
              targetName: 'totalVehicleRequestedChanged',
              targetValue: {
                totalVehicleRequested: newVehicles.length + lockedVehicles.length,
                vehicles: newVehicles,
                lockedVehicles: lockedVehicles
              }
            }])
          }
        })
        .then(() => {
          return driveGeneratorInstance.validateDrive()
        })
        .then(() => {
          scope.drive = driveGeneratorInstance.drive;
          return true;
        })
    }
  },
  VALIDATE_OPPORTUNITY: {
    value: 9,
    label: 'Validating Opportunity',
    action: function (scope) {
      return scope.validateOpportunity(scope.recordId)
      .then((errorMessages = []) => {
        if(errorMessages.length > 0) {
          scope.resultMessage = `Opportunity is missing below data:
              ${errorMessages.map(erorrMessage => {
                return `- ${erorrMessage}`
              }).join('\n')}
          `;

          scope.hookAfterFinishedHandler(false, scope.resultMessage);
        }

        return errorMessages.length <= 0;
      })
    }
  },
  VALIDATE_DRIVE_PRODUCTIVITY: {
    value: 10,
    label: 'Validating Planned Drive Productivity',
    action: function (scope) {
      return Promise.resolve()
      .then(() => {
        if(scope.noAction) return true;
        
        const isLowDriveProductivity = scope.drive.driveProductivityPlanned < 0.8;
        if(isLowDriveProductivity) {
          scope.needConfirmToContinue = true;
          scope.resultMessage = 'Low Productivity Drive';
          scope.hookAfterFinishedHandler(false, scope.resultMessage);
          return false;  
        }

        return true;
      })
    }
  },
  VALIDATE_DRIVE: {
    value: 11,
    label: 'Validating Drive',
    action: function (scope) {
      if(scope.drive.status === DRIVE_STATUS.DRAFT) {
        return Promise.resolve(true);
      }

      return driveGeneratorInstance.validateDrive()
        .then(() => {
          scope.drive = driveGeneratorInstance.drive;
          return true;
        })
    }
  },
  VALIDATE_DRAFT_DRIVE: {
    value: 12,
    label: 'Validating Draft Drive',
    action: function (scope) {
      if(scope.drive.status !== DRIVE_STATUS.DRAFT) {
        return Promise.resolve(true);
      }

      const service = new driveService();
      return service.validateDraftDrive({
          request: {
              driveId: scope.drive.id
          }
      })
      .then((result) => {
        return true;
      })
      .catch(error => {
        scope.resultMessage = error.message;
        scope.hookAfterFinishedHandler(false, scope.resultMessage);
        return false;
      });
    }
  },
  PRE_GENERATE_DRIVE_CHECKING: {
    value: 13,
    label: 'Pre-generate Drive Checking',
    action: function(scope) {
      return scope.validatePreGenerateDrive(scope.recordId)
      .then((errorMessages = []) => {
        if(errorMessages.length > 0) {
          scope.resultMessage = `Cannot generate drive due to below errors:
              ${errorMessages.map(erorrMessage => {
                return `- ${erorrMessage}`
              }).join('\n')}
          `;

          scope.hookAfterFinishedHandler(false, scope.resultMessage);
        }

        return errorMessages.length <= 0;
      });
    }
  }
}

const MODE = {
  GENERATE_DRIVE: 'generateDrive',
  GENERATE_PAST_DRIVE: 'generatePastDrive',
  LISTEN_OPPORTUNITY_CHANGED: 'listenOpportunityChanged',
  APPROVE_DCR: 'approveDCR'
}

const MODE_STEPS = {
  [MODE.GENERATE_PAST_DRIVE]: [
    STEP.VALIDATE_OPPORTUNITY,
    STEP.GENERATE_PAST_DRIVE,
    STEP.SAVE_DRIVE
  ],
  [MODE.GENERATE_DRIVE]: [
    STEP.VALIDATE_OPPORTUNITY,
    STEP.PRE_GENERATE_DRIVE_CHECKING,
    STEP.GENERATE_DRIVE,
    STEP.VALIDATE_DRIVE_PRODUCTIVITY,
    STEP.SAVE_DRIVE
  ],
  [MODE.LISTEN_OPPORTUNITY_CHANGED]: [
    STEP.CHECKING_DCR,
    STEP.VALIDATE_OPPORTUNITY,
    STEP.APPLY_CHANGES_TO_DRIVE,
    STEP.VALIDATE_ASSETS,
    STEP.VALIDATE_DRAFT_DRIVE,
    STEP.VALIDATE_DRIVE_PRODUCTIVITY,
    STEP.CAPTURE_DRIVE_CHANGES,
    STEP.SAVE_DRIVE
  ],
  [MODE.APPROVE_DCR]: [
    STEP.CHECKING_DCR,
    STEP.APPLY_CHANGES_TO_DRIVE,
    STEP.SAVE_DRIVE
  ]
}

export default class SlwcGenerateDriveModal extends NavigationMixin(LightningElement) {
  // @api recordId = '0063F00000PAVtOQAX';
  @api recordId = null;
  @api mode = MODE.GENERATE_DRIVE;
  @api noAction = false;
  @api embededMode = false;
  @api hookAfterFinished;

  @track resultMessage = null;
  @track showSpinner = false;
  @track spinnerText = null;
  @track drive = null;
  @track driveChangeRequest = null;
  @track errorMessages = [];
  @track steps = [];
  @track currentStep = null;
  @track needToRefreshPage = false;
  @track needConfirmToContinue = false;
  @track needConfirmToSubmitDriveForApproval = false;
  opportunity = null;
  @api opportunityRecordId;
  @track oppArdValidationFlag;
  @track showARDValidationMessage=false;
  @track declineByUser=false;
  @track ardWarningMessage;

  get submissionNotesRequired() {
    return this.drive && this.drive.routeApprovalRequestTo === 'Request DM evaluation';
  }

  get driveGeneratorHasError() {
    return this.errorMessages.length > 0;
  }

  get errorHeaderMessage() {
    return 'Cannot generate drive due to the below error(s):';
  }

  connectedCallback() {
    // this.recordId = '0062i000008JSa7AAG';
    // this.isOpen = true;
    // this.mode = MODE.GENERATE_PAST_DRIVE;
    console.log('connectedCallback recordId :',this.recordId,' opportunityRecordId:',this.opportunityRecordId);
      
    if (!this.opportunityRecordId || this.opportunityRecordId.trim() === '') {
        console.log('opportunityRecordId not found');
        this.getOpportunity();
    }
    
    this.init();
  }

  @wire(getRecord, { recordId: '$opportunityRecordId', fields: OPP_ARD_VALIDATION_FLAG })
    wiredOpportunity({ error, data }) {
      console.log('data --->',data);
        if (data) {
            this.oppArdValidationFlag = data.fields.Pending_ARD_Confirmation__c.value;
        } else if (error) {
            console.error('Error fetching Opportunity record:', error);
        }
    }

  getOpportunity() {
    console.log('getOpportunity called.');
    fetchOpportunityFromDriveChangeRequest({ dcrId: this.recordId })
      .then(result => {
          if (result) {
              console.log('Opportunity Record:', JSON.stringify(result));
              this.oppArdValidationFlag = result.Pending_ARD_Confirmation__c;
              //this.opportunity = result;
          } else {
              console.log('No Opportunity found.');
          }
      })
      .catch(error => {
          console.error('Error fetching Opportunity:', error);
      });
  }

  showLoading(customSpinnerText) {
    this.showSpinner = true;
    this.spinnerText = customSpinnerText;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  init() {
    if(!this.recordId) return;

    this.mode = this.mode || MODE.GENERATE_DRIVE;
    this.steps = MODE_STEPS[this.mode];
    this.needConfirmToContinue = false;
    this.needToRefreshPage = false;
    if(!this.steps.length) return;

    this.showLoading();
    this.nextStep()
    .catch((error) => {
      new debugLogService().captureDebugLog(error, this.drive?.id);
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
      
      this.hookAfterFinishedHandler(false, error.message);
    })
    .finally(() => this.hideLoading())
  }

  nextStep(event, forceStep) {
    this.needConfirmToContinue = false;

    if(forceStep) {
      this.currentStep = forceStep;
    } else {
      if(!this.currentStep) {
        this.currentStep = this.steps[0];
      } else {
        const currentStepIdnex = this.steps.findIndex(step => step.value === this.currentStep.value);
        const nextStepIndex = (currentStepIdnex + 1) % this.steps.length;
        this.currentStep = this.steps[nextStepIndex];
      }
    }
   
    return this.currentStep.action(this)
    .then((result) => {
      if(result) {
        return this.nextStep();
      }
    })
  }
  
  refreshPage() {
    let recordId = this.recordId;
    if(this.mode === MODE.LISTEN_OPPORTUNITY_CHANGED || this.mode === MODE.APPROVE_DCR) {
      recordId = this.drive.opportunityId;
    }

    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
          recordId: recordId,
          actionName: 'view'
      }
    });
  }

  handleOnChange(event) {
    event.stopPropagation();

    let model = this.drive;
    if(this.mode === MODE.LISTEN_OPPORTUNITY_CHANGED) {
      model = this.driveChangeRequest;
    }

    if(event.detail && event.detail.selection) {
      model[event.currentTarget.name] = event.detail.selection.id;
    } else {
      let value = getValueFromEvent(event);
      model[event.currentTarget.name] = value;
    }
  }
  
  generateDriveChangesFromDCR(drive, driveChangeRequest) {
    let driveHelper = new DriveHelper();
    return driveHelper.generateDriveChangesFromDCR(drive, driveChangeRequest);
  } 

  validateOpportunity(oppOrDriveId) {
    const validatingPastDrive = this.mode === MODE.GENERATE_PAST_DRIVE;
    
    const ERROR_1 = 'Cannot find any collection operation associates with this Opportunity.';
    const ERROR_2 = 'There is no vehicle associate with the collection operation yet.'
    const ERROR_3 = 'Missing Drive Site.';
    const ERROR_4 = 'Missing Drive Date.';
    const ERROR_5 = 'Missing Drive Type.';
    const ERROR_6 = 'Missing Account.';

    let errorMessages = [];
    let fetch = null;
    return Promise.resolve()
    .then(() => {
      return this.retrieveOpportunity(oppOrDriveId);
    })
    .then(([opportunity]) => {
      if(!opportunity.driveSiteId) {
        errorMessages.push(ERROR_3);
        throw 'stop';
      }

      if(!opportunity.accountId) {
        errorMessages.push(ERROR_6);
        throw 'stop';
      }

      if(!opportunity.driveDate) {
        errorMessages.push(ERROR_4);
        throw 'stop';
      }

      if(!opportunity.typeOfDrive) {
        errorMessages.push(ERROR_5);
        throw 'stop';
      }

      if(validatingPastDrive) {
        throw 'stop';
      }

      fetch = new DriveFetch({
        driveType: opportunity.typeOfDrive
      })
   
      return Promise.all([
        opportunity,
        fetch.retrieveDriveSite(opportunity)
      ]);
    })
    .then(([opportunity, driveSite]) => {
      const validSiteCollectionOperation = (driveSite.siteCollectionOperations || []).find(item => {
        return item.startDate <= opportunity.driveDate && opportunity.driveDate <= item.endDate;
      })

      if(!validSiteCollectionOperation || !validSiteCollectionOperation.collectionOperationId) {
        errorMessages.push(ERROR_1);
        throw 'stop';
      }
      
      return Promise.all([
        opportunity,
        fetch.retrieveVehicles({
          collectionOperationId: validSiteCollectionOperation.collectionOperationId,
          driveDate: opportunity.driveDate,
          driveSite: driveSite
        })
      ])
    })
    .then(([opportunity, vehicles]) => {
      if(!vehicles || !vehicles.length) {
        errorMessages.push(ERROR_2);
        throw 'stop';
      }

      return errorMessages;
    })
    .catch((error) => {
      if(error !== 'stop') {
        errorMessages.push('Invalid data.')
      }

      return errorMessages;
    })
  }

  validatePreGenerateDrive(oppOrDriveId) {
    const validateTravelTimeData = ({ driveSite, driveDate, typeOfDrive, travelTimeIndexItemMap, loginUser }) => {
      let errorMessages = [];
      const helper = new DriveHelper();
      if (typeOfDrive === DRIVE_TYPE.MOBILE && !helper.isAdminUser(loginUser) && !helper.isAPSAdmin(loginUser)) {
        const validSiteCollectionOperation = (driveSite.siteCollectionOperations || []).find(item => {
          return item.startDate <= driveDate && driveDate <= item.endDate;
        });

        const { travelTimeBreakdownsCoToSite, travelTimeBreakdownsSiteToCo} = helper.getTravelTimeBreakdownData({
          driveDate,
          driveSite,
          collectionOperation: validSiteCollectionOperation?.collectionOperation || {}
        }, { travelTimeIndexItemMap });

        if (!travelTimeBreakdownsCoToSite?.length || !travelTimeBreakdownsSiteToCo?.length) {
          errorMessages.push('Travel Time Data is missing.');
        }
      }

      return errorMessages;
    }

    return Promise.resolve()
      .then(() => {
        return this.retrieveOpportunity(oppOrDriveId);
      })
      .then(([opportunity]) => {
        const fetch = new DriveFetch({
          driveType: opportunity.typeOfDrive
        });
        return fetch.retrieveDriveSite(opportunity)
        .then(driveSite => {
          return Promise.all([
            opportunity,
            driveSite,
            fetch.retrieveTravelTimeIndexItemMap({ driveSite }),
            fetch.retrieveLoginUser()
          ]);
        });
      })
      .then(([opportunity, driveSite, travelTimeIndexItemMap, loginUser]) => {
        return Promise.all([
          validateTravelTimeData({ 
            driveSite,
            driveDate: opportunity.driveDate,
            typeOfDrive: opportunity.typeOfDrive,
            travelTimeIndexItemMap,
            loginUser
          })
        ]);
      })
      .then(errorLists => {
        return errorLists.reduce((mergedList, currentErrorList) => {
          return [...mergedList, ...currentErrorList];
        }, []);
      });
  }

  retrieveOpportunity(oppOrDriveId) {
    return Promise.resolve()
    .then(() => {
      if (this.opportunity) {
        return [this.opportunity];
      } else {
        if(oppOrDriveId.startsWith('006')) {
          let service = new opportunityService();
          let queryModel = new opportunityQueryModel();
          queryModel.recordIds = [oppOrDriveId];
          return service.query(queryModel)
          .then(([opportunity]) => {
            this.opportunity = opportunity;
            return [opportunity];
          })
        } else {
          let service = new driveService();
          let queryModel = new driveQueryModel();
          queryModel.recordIds = [oppOrDriveId];
          return service.query(queryModel)
          .then(([drive]) => {
            this.opportunity = drive.opportunity;
            return [drive.opportunity];
          });
        } 
      }
    });
  }

  saveDrive(drive, scope) {
    return Promise.resolve()
      .then(()=> {
          let drivesToSave = [];
          let model = { ...drive };
          drivesToSave.push(model);
          let service = new driveService();
          return service.saveList(drivesToSave);
      })
      .then((result) => {
        if(!result.success) throw result;

        if (scope.mode === MODE.LISTEN_OPPORTUNITY_CHANGED && scope.driveChangeRequest) {
          let dcrService = new driveChangeRequestService();
          let dcr = {
            id: scope.driveChangeRequest.id,
            status: DRIVE_REQUEST_CHANGE_STATUS.APPROVED_BY_SYSTEM
          }
          return dcrService.save(dcr);
        }
      })
      .catch(error => {
        return Promise.resolve()
          .then(() => {
            if (this.mode === MODE.LISTEN_OPPORTUNITY_CHANGED && this.driveChangeRequest) {
              let dcrService = new driveChangeRequestService();
              let dcr = {
                id: this.driveChangeRequest.id,
                status: DRIVE_REQUEST_CHANGE_STATUS.CANCELLED
              }
              return dcrService.save(dcr);
            }
          })
          .then(() => {
            throw error;
          })
      })
  }

  validate() {
    let allInputsCorrect = [
      ...this.template.querySelectorAll("lightning-textarea")
    ];
    return allInputsCorrect.reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
    }, true);
  }

  declineContinue() {
    if(this.driveChangeRequest) {
      this.declineByUser=true;
      this.needConfirmToContinue = false;
      this.rejectDCR();
      this.rollbackChanges();
    } else {
      this.closeModal();
    }
  }
  
  confirmContinue(event) {
    this.showLoading();
    this.nextStep()
    .catch((error) => {
      new debugLogService().captureDebugLog(error, this.drive?.id);
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
      this.hookAfterFinishedHandler(false, error.message);
    })
    .finally(() => this.hideLoading())
  }

  getDriveContentions(drive) {
    if(!drive) return [];
    let driveContentions = drive.pendingActionReasonCode || [];
    driveContentions = isString(driveContentions) && !isNullOrEmpty(driveContentions) ? driveContentions.split(';') : driveContentions;
    return driveContentions;
  }

  submitDCR() {
    this.needConfirmToSubmitDriveForApproval = false;

    this.showLoading();
    let driveContentions = this.getDriveContentions(this.drive);
    console.log('driveContentions ',driveContentions);
    //driveContentions = !isNullOrEmpty(driveContentions) ? driveContentions.split(';') : [];
    let driveChangeRequestItems = driveGeneratorInstance.compareAndGetDriveChanges();
    let service = new driveService();
    return service.captureDriveImpact({
      request: {
        id: this.driveChangeRequest.id,
        driveId: this.drive.id,
        driveChangeRequestItems: driveChangeRequestItems
      }
    })
      .then(() => {
        const service = new approvalService();
        return service.isPendingApproval({
          recordId: this.drive.id
        })
      })
      .then((result) => {
        const isDrivePendingApproval = result.returnedData;
        return Promise.resolve()
          .then(() => {
            if (isDrivePendingApproval) {
              const approvalSvc = new approvalService();
              return approvalSvc.withdraw({
                request: {
                  recordId: this.drive.id
                }
              })
                .then(() => {
                  //wait until isDrivePendingApproval returned false
                  return waitUntil(() => {
                    return approvalSvc.isPendingApproval({
                      recordId: this.drive.id
                    })
                      .then(result => {
                        return !result.returnedData;
                      });
                  }, 3000, 100);
                })
            }
          })
          .then(() => {
            return isDrivePendingApproval;
          })
      })
      .then((isDrivePendingApproval) => {
        const driveHelper = new DriveHelper();
        const autoApprove = driveHelper.isFixedSiteDrive(this.drive) || (this.drive.status === DRIVE_STATUS.DRAFT && !isDrivePendingApproval);
        if (!autoApprove && driveContentions.length > 0) {
          if (this.drive.status === DRIVE_STATUS.DRAFT) {
            this.showLoading('Re-submitting Drive Approval Request...');
            let dcrService = new driveChangeRequestService();
            let dcr = {
              id: this.driveChangeRequest.id,
              status: 'Approved by System'
            }
            return dcrService.save(dcr)
              .then(() => {
                return this.nextStep(null, STEP.SAVE_DRIVE);
              });
          } else {
            let dcrService = new driveChangeRequestService();
            let dcr = {
              id: this.driveChangeRequest.id,
              driveContention: [...driveContentions],
              notes: this.driveChangeRequest.notes,
              status: 'Submitted',
              routeApprovalRequestTo: this.drive.routeApprovalRequestTo
            }
            console.log('dcr to save ',dcr);
            return dcrService.save(dcr)
              .then(() => {
                this.resultMessage = 'Drive has been submitted for approval.';
                this.hookAfterFinishedHandler(true, this.resultMessage);
                return false;
              })
              .catch(error => {
                this.resultMessage = error.message || 'Cannot submit drive for approval.';
                this.hookAfterFinishedHandler(false, this.resultMessage);
                return false;
              });
          }
        }
        else {
          return this.nextStep(null, STEP.SAVE_DRIVE);
        }
      })
      .finally(() => this.hideLoading())
}

  rejectDCR() {
    let dcrService = new driveChangeRequestService();
    let dcr = {
      id: this.driveChangeRequest.id,
      status: 'Cancelled'
    }
    this.showLoading('Rejecting the Drive Change Request...');
    return dcrService.save(dcr)
    .then(() => {
      this.needConfirmToSubmitDriveForApproval = false;

      this.resultMessage = `Drive Change Request has been cancelled.
        The process to revert the Opportunity will take time.
        Please wait a moment then refreshing the page.`;

      this.hookAfterFinishedHandler(false, this.resultMessage);
      return false;
    })
    .finally(() => this.hideLoading())
  }

  generatePastDrive(optyId) {
    let service = new opportunityService();
    let queryModel = new opportunityQueryModel();
    queryModel.recordIds = [optyId];
    queryModel.subQueryIndicator = sObjectType.DRIVE;

    this.showLoading();
    return service.query(queryModel)
    .then(([opty]) => {
      if(opty.drives?.length >= 0) {
        this.resultMessage = 'Drive had already been generated.';
        this.hookAfterFinishedHandler(false, this.resultMessage);
        return false;
      }

      const driveHelper = new DriveHelper();
      let pastDrive = {
        name: driveHelper.truncateDriveName(opty.name),
        accountId: opty.accountId,
        driveDate: opty.driveDate,
        minShiftStart: null,
        maxShiftEnd: null,
        startTime: opty.startTime,
        endTime: opty.endTime,
        driveSiteId: opty.driveSiteId,
        opportunityId: opty.id,
        surrogateDriveForId: null,
        status: DRIVE_STATUS.CONFIRMED
      }

      this.drive = pastDrive;
      return true;
    })
    .finally(() => this.hideLoading);
  }

  closeModal() { 
    console.log('closeModal B showARDValidationMessage :',this.showARDValidationMessage,' declineByUser:',this.declineByUser);
    if(!this.declineByUser){
      //this.checkTimeDifference();
      if(this.oppArdValidationFlag){
        this.showARDValidationMessage=true;
      }
    }
    console.log('closeModal A showARDValidationMessage :',this.showARDValidationMessage);
    if(!this.showARDValidationMessage){
      this.conditionalCloseModal();
    }
  }
  conditionalCloseModal(){
    console.log('conditionalCloseModal ');
    const closeModalEvent = new CustomEvent('closemodal', {
      detail: {
        needToRefreshPage: this.needToRefreshPage
      }
    });
    this.dispatchEvent(closeModalEvent);

    if(this.needToRefreshPage) {
      this.refreshPage();
    }
  }
  handleWarningOk(){
    console.log('handleWarningOk !');
    this.showARDValidationMessage=false;
    this.conditionalCloseModal();
  }
  async rollbackChanges() {
    console.log('HRP-6051 Rolling back changes...');
    const fields = { 
        Id: this.opportunityRecordId, 
        Pending_ARD_Confirmation__c: false
    };
    const recordInput = { fields };
    console.log('HRP-6051 recordInput ->',JSON.stringify(recordInput));
    try {
        await updateRecord(recordInput);
        console.log('HRP-6051 Rollback successful');
    } catch (error) {
        console.error('Rollback failed:', error.body ? error.body.message : error.message);
        console.error('HRP-6051 Rollback failed:', JSON.stringify(error));
    } finally {
        console.error('HRP-6051 Rollback Finally block:');
    }
}
  

  /* hooks */
  hookAfterFinishedHandler = (result = false, resultMessage) => {
    if(!this.hookAfterFinished) return;
    this.hookAfterFinished({
      detail: {
        result: result,
        resultMessage: resultMessage,
        recordId: this.recordId
      }
    });
  }
    @wire(getWarningMessage)
    wiredMessage({ error, data }) {
        if (data) {
            this.ardWarningMessage = data;
        } else if (error) {
            this.message = 'Error fetching message';
            console.error('Error:', JSON.stringify(error));
        }
    }
}