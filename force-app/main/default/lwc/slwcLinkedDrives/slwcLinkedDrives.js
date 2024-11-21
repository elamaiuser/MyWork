import { LightningElement, track, api } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import { debugLogService, linkedDrivesService, linkedDrivesQueryModel, driveService, driveQueryModel, activityService } from 'c/dataService';
import { keyBy, orderBy, uniqBy, remove, cloneDeep, maxBy, groupBy } from 'c/lodash';
import { DateTime } from 'c/luxon';
import * as slwcDateUtils from 'c/slwcDateUtils';
import * as slwcUtils from 'c/slwcUtils';
import { DRIVE_STATUS, ASSET_TYPE, LINK_DRIVE_TYPE } from 'c/slwcConstants';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcLinkedDrivesAvailator from 'c/slwcLinkedDrivesAvailator';
import { DriveHelper, drivesGeneratorInstance } from 'c/slwcDriveGenerator';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const MODE = {
  DEFAULT: 'default',
  UPDATE_LINK: 'updateLink'
}

const MAXIMUM_MULTI_DAY_LINKED_DRIVES = 7;
const MAXIMUM_SINGLE_DAY_LINKED_DRIVES = 2;

const TABS = {
  DRIVE: 'drives',
  ACTIVITY: 'activity'
};

export default class SlwcLinkedDrives extends LightningElement {
  @api drive = null;
  @api canDelete = false;
  @api readOnly = false;

  @track TABS = TABS;
  @track DRIVE_TABLE_COLUMNS = [
    {label: 'Drive Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' }, hideDefaultActions: true },
    {label: 'Drive Type', fieldName: 'typeOfDrive', type: 'text', hideDefaultActions: true, wrapText: true },
    {label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true, wrapText: true },
    {label: 'Start Time', fieldName: 'startTime', type: 'time', hideDefaultActions: true, wrapText: true },
    {label: 'End Time', fieldName: 'endTime', type: 'time', hideDefaultActions: true, wrapText: true },
    {label: '# of Staff Requested', fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    {label: '# of Machines Requested', fieldName: 'totalEquipmentRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    {label: 'Proj Reg Donors', fieldName: 'projectedRegisteredDonors', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    {
      label: '', type: 'linkDriveButton', fieldName: 'id', hideDefaultActions: true, initialWidth: 180, typeAttributes: {
        isLinked: {
          fieldName: 'isLinked'
        },
        clickAction: (event) => {
          this.handleLinkDriveBtn(event.currentTarget.dataset['value'], event.currentTarget.dataset['action']);
        }
      }
    }
  ];

  get ACTIVITY_TABLE_COLUMNS() {
    const actions = [
      { label: 'Activity Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: { label: { fieldName: 'activityTitle' }, target: '_blank' }, hideDefaultActions: true },
      { label: 'Type', fieldName: 'eventType', type: 'text', hideDefaultActions: true, wrapText: true },
      { label: 'Sub-type', fieldName: 'subtype', type: 'text', hideDefaultActions: true, wrapText: true },
      {
        label: 'Start', fieldName: 'start', initialWidth: 160, type: 'date', typeAttributes: {
          year: 'numeric',
          month: 'numeric',
          day: 'numeric',
          hour: 'numeric',
          minute: '2-digit',
          timeZone: TIME_ZONE
        }, cellAttributes: { alignment: 'left', class: { fieldName: 'activityDateClass' } }, hideDefaultActions: true
      },
      {
        label: 'End', fieldName: 'finish', initialWidth: 160, type: 'date', typeAttributes: {
          year: 'numeric',
          month: 'numeric',
          day: 'numeric',
          hour: 'numeric',
          minute: '2-digit',
          timeZone: TIME_ZONE
        }, cellAttributes: { alignment: 'left' }, hideDefaultActions: true
      },
      { label: 'Notes', fieldName: 'notes', type: 'text', initialWidth: 250, wrapText: true, cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    ];
    
    if(!this.readOnly) {
      actions.push({
        label: '', type: 'actionButton', fieldName: 'id', hideDefaultActions: true, initialWidth: 180, typeAttributes: {
          rowActions: [
            {
              name: 'delete',
              label: 'Delete',
              variant: 'destructive-text',
              clickAction: (event) => {
                this.handleLinkedActivityAction('delete', event.currentTarget.dataset['value']);
              }
            },
            {
              name: 'edit',
              label: 'Edit',
              variant: 'base',
              clickAction: (event) => {
                this.handleLinkedActivityAction('edit', event.currentTarget.dataset['value']);
              }
            },
          ]
        }
      })
    }

    return actions;
  }

  @track showSpinner = false;
  @track confirmModalData = {};
  @track activityModalData = {};
  @track linkedDriveStaffingDetailsModalData = {};

  @track currentTab = TABS.DRIVE;
  @track mode = MODE.DEFAULT;
  @track selectedLinkDriveNode = null;
  @track linkedDrive = {};
  @track linkedDriveNodes = [];
  @track linkedDrives = [];
  @track linkedActivities = [];
  @track originalLinkedDrives = [];
  @track possibleDrives = [];

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    })
  }
  
  get pageHeader() {
    if(!this.drive) return;
    if(!this.drive.linkedDriveId) return 'New';
    return this.drive.linkedDriveName;
  }

  get pageSubHeader() {
    if(!this.linkedDrive) return null;

    return this.linkedDrive.linkedDriveType;
  }

  get classHeader() {
    return ( this.isDesktop || this.isTablet ) ? "slds-page-header__row slds-grid_vertical-align-center" : "";
  }

  get isEditMode() {
    return this.linkedDrive && this.linkedDrive.id;
  }

  get isLinkedDriveValid() {
    return this.linkedDrive && this.linkedDrive.linkedDriveType;
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

  get isMultiDayLink() {
    return this.linkedDrive && this.linkedDrive.linkedDriveType === LINK_DRIVE_TYPE.MULTI_DAY;
  }

  get showLinkedDrivesTab() {
    return this.currentTab === TABS.DRIVE;
  }

  get showLinkedActivitiesTab() {
    return this.currentTab === TABS.ACTIVITY;
  }

  get showCreateActivityButton() {
    if(!this.drive) return false;
    return this.drive.linkedDriveId;
  }

  get showStaffingDetailsButton() {
    if(!this.drive) return false;
    return this.drive.linkedDriveId;
  }

  get showDriveNotLinkedWarning() {
    if(!this.drive) return false;

    return !this.drive.linkedDriveId;
  }
  
  get showDeleteLinkButton() {
    if(!this.drive) return false;

    return this.drive.linkedDriveId && this.canDelete;
  }

  get possibleDrivesDates() {
    if(!this.linkedDrives.length) return [];
    if(!this.isMultiDayLink) return [this.drive.driveDate];

    let linkedDriveDateIsoList = this.linkedDrives.map(linkedDrive => linkedDrive.driveDate);
    linkedDriveDateIsoList = orderBy(linkedDriveDateIsoList, [dateIso => dateIso], ['asc']);
    let firstDateIso = linkedDriveDateIsoList[0];
    let lastDateIso = linkedDriveDateIsoList[linkedDriveDateIsoList.length - 1];

    let dateIsos = [];

    //date before
    dateIsos.push(DateTime.fromFormat(firstDateIso, 'yyyy-MM-dd').minus({
      day: 1
    }).toISODate());

    //date after
    dateIsos.push(DateTime.fromFormat(lastDateIso, 'yyyy-MM-dd').plus({
      day: 1
    }).toISODate());

    //date between that not fullfilled yet
    const diff = this.dateUtils.diffDays(firstDateIso, lastDateIso);
    for(let i = 0; i < diff; i++) {
      const currentDateIso = DateTime.fromFormat(firstDateIso, 'yyyy-MM-dd').plus({
        day: i
      }).toISODate();

      if(!linkedDriveDateIsoList.includes(currentDateIso)) {
        dateIsos.push(currentDateIso);
      }
    }

    return orderBy(dateIsos, item => item, ['asc']);
  }

  get maximumLinkedDrives() {
    if(this.isMultiDayLink) return MAXIMUM_MULTI_DAY_LINKED_DRIVES;
    return MAXIMUM_SINGLE_DAY_LINKED_DRIVES;
  }

  get possibleDrivesTableHeader() {
    if(this.mode === MODE.DEFAULT) {
      if(this.linkedDrives.length >= this.maximumLinkedDrives) {
        return 'Maximum number of Linked Drives has been reached.';
      }

      let possibleDrivesDates = this.possibleDrivesDates || [];
      let possibleDrivesDatesText = possibleDrivesDates.map(dateIso => {
        return DateTime.fromFormat(dateIso, 'yyyy-MM-dd').toFormat('MMM dd, yyyy');
      }).join(' and ');
      if(possibleDrivesDatesText) {
        return 'Available Drives to Link on ' + possibleDrivesDatesText;
      } else {
        return 'Available Drives to Link';
      }
    } else if (this.mode === MODE.UPDATE_LINK) {
      return 'Update Linked Drive in ' + DateTime.fromFormat(this.selectedLinkDriveNode.drive.driveDate, 'yyyy-MM-dd').toFormat('MMM dd, yyyy');
    }
  }

  connectedCallback() {
    this.init();
  }

  exceptionHandler = (error) => {
    new debugLogService().captureDebugLog(error, this.drive?.id);
    this.dispatchEvent(new ShowToastEvent({
      message: error.message,
      variant: 'error',
      mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinner = true;
  }

  hideLoading = () => {
    this.showSpinner = false;
  }

  init = () => {
    if(!this.drive) return;

    this.currentTab = TABS.DRIVE;
    this.linkedDrive = {
      linkedDriveType: this.linkedDrive.linkedDriveType || LINK_DRIVE_TYPE.MULTI_DAY
    }
 
    this.cancelEditLinkedDriveNode(null, true);
    return this.fetchData()
  }

  handleChangeTab(event) {
    this.currentTab = event.target.value;
  }

  fetchData = () => {
    this.showLoading();
    return this.getDriveData()
    .then(() => {
      return this.getLinkedDriveData();
    })
    .then(() => {
      this.generateLinkedDriveNodes();
      this.updateLinkedDriveNodes();
      return this.getPossibleDrives();
    })
    .catch((e) => this.exceptionHandler(e))
    .finally(() => this.hideLoading());
  }

  getDriveData = () => {
    let queryModel = new driveQueryModel();
    let service = new driveService();

    queryModel.recordIds = [this.drive.id];
    return service.query(queryModel)
    .then(([result]) => {
      this.drive = {
        ...this.drive,
        linkedDriveId: result.linkedDriveId,
        linkedDriveName: result.linkedDriveName,
        linkedDrive: result.linkedDrive
      }
    })
  }

  transformActivity = (record) => {
    return {
      ...record,
      recordPageUrl: '/' + record.id
    }
  }

  getLinkedDriveData = () => {
    let queryModel = new linkedDrivesQueryModel();
    let service = new linkedDrivesService();

    return Promise.resolve()
    .then(() => {
      if(!this.drive.linkedDriveId) {
        this.linkedDrives = [];
        this.linkedActivities = [];
        this.originalLinkedDrives = [];
        return;
      }

      queryModel.recordIds = [this.drive.linkedDriveId];
      return service.query(queryModel)
      .then(([result]) => {
        this.linkedDrive = result;
        this.linkedDrives = result.drives || [];
        this.linkedActivities = (result.activities || []).map(this.transformActivity);
        this.originalLinkedDrives = cloneDeep(this.linkedDrives);
      })
    })
    .then(() => {
      if(!this.linkedDrives.length) {
        this.linkedDrives.push(this.drive);
      }
    })
  }

  getPossibleDrives = () => {
    const postProcess = (drives = []) => {
      let result = drives.map(item => transformDrive(item));
      result = orderBy(result, ['driveDate', 'startTime'], ['asc', 'asc']);

      if(!this.isMultiDayLink) {
        const drivesCannotBeOverlapped = this.linkedDrives.filter(drive => {
          if(this.mode !== MODE.UPDATE_LINK) return true;

          return this.selectedLinkDriveNode.drive.id !== drive.id;
        });
        
        result = result.filter(drive => {
          return !drivesCannotBeOverlapped.find(drive2 => {
            const isLinked = drive2.id === drive.id;
            if(isLinked) return false;

            const overlapped = drive.startTime < drive2.endTime && drive.endTime > drive2.startTime;
            return overlapped;
          });
        });
      }

      return result;
    }

    const transformDrive = (item) => {
      return {
        ...item,
        recordPageUrl: '/' + item.id,
        isLinked: !!this.linkedDrives.find(linkedDrive => linkedDrive.id === item.id)
      }
    }

    this.showLoading();
    let service = new driveService();
    return service.getTerritoryKeys({
      request: {
        collectionOperationId: this.drive.collectionOperationId,
        startDate: this.drive.driveDate,
        endDate: this.drive.driveDate
      }
    })
    .then((territoryKeysResult) => {
      if(this.mode === MODE.DEFAULT && (
        (this.linkedDrives.length >= this.maximumLinkedDrives) || 
        !this.linkedDrive.linkedDriveType
      )) {
        this.possibleDrives = [];
        return;
      }
  
      let queryModel = new driveQueryModel();
      let service = new driveService();

      queryModel.territoryKeys = territoryKeysResult.returnedData || [];
      queryModel.eventTypes = [this.drive.typeOfDrive];
      queryModel.statuses = [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED];
      queryModel.isNotLinkedDrive = true;
      queryModel.linkedDriveIds = this.drive.linkedDriveId ? [this.drive.linkedDriveId] : [];
    
      if(this.mode === MODE.DEFAULT) {
        queryModel.selectedDates = this.possibleDrivesDates || [];
      } else if(this.mode === MODE.UPDATE_LINK) {
        queryModel.selectedDates = [this.selectedLinkDriveNode.drive.driveDate];
      }
      
      queryModel.orderBy = 'driveDate';
      queryModel.orderAscending = 'asc';

      return service.query(queryModel)
      .then(result => {
        this.possibleDrives = postProcess(result);
      })
    })
    .catch((e) => this.exceptionHandler(e))
    .finally(() => this.hideLoading());
  }

  generateLinkedDriveNodes() {
    let nodes = [];
    for(let i = 0; i < this.maximumLinkedDrives; i++) {
      let newNode = {
        key: i,
        index: i + 1,
        drive: null
      };

      newNode = this.buildLinkedDriveNodeInformation(newNode, i);
      nodes.push(newNode);
    }
    
    this.linkedDriveNodes = nodes;
  }
  
  updateLinkedDriveNodes() {
    const sortedLinkedDrives = orderBy(this.linkedDrives, ['driveDate', 'startTime'], ['asc', 'asc']);

    if(this.isMultiDayLink) {
      const firstLinkedDrive = sortedLinkedDrives[0];
      const lastLinkedDrive = sortedLinkedDrives[sortedLinkedDrives.length - 1];

      //date between that not fullfilled yet
      const diff = this.dateUtils.diffDays(firstLinkedDrive.driveDate, lastLinkedDrive.driveDate);
      for(let i = 0; i <= diff; i++) {
        const currentDateIso = DateTime.fromFormat(firstLinkedDrive.driveDate, 'yyyy-MM-dd').plus({
          day: i
        }).toISODate();

        const temp = sortedLinkedDrives.find(item => item.driveDate === currentDateIso);
        if(temp) {
          this.linkedDriveNodes[i] = this.buildLinkedDriveNodeInformation({
            ...this.linkedDriveNodes[i],
            drive: temp
          }, i);
        }
      }
      
    } else {
      this.linkedDriveNodes = this.linkedDriveNodes.map((linkedDriveNode, linkedDriveNodeIndex) => {
        linkedDriveNode.drive = sortedLinkedDrives[linkedDriveNodeIndex] || null;
        linkedDriveNode = this.buildLinkedDriveNodeInformation(linkedDriveNode, linkedDriveNodeIndex);
  
        return linkedDriveNode;
      })
    }
  
    let linkedDriveNodes = this.linkedDriveNodes.filter(linkedDriveNode => {
      return !!linkedDriveNode.drive;
    })
    
    linkedDriveNodes.forEach((linkedDriveNode, linkedDriveNodeIndex) => {
      const isFirstNode = linkedDriveNodeIndex === 0;
      const isLastNode = linkedDriveNodeIndex === linkedDriveNodes.length - 1;
      linkedDriveNode.disableUnlink = linkedDriveNode.isCurrentDrive || !(isFirstNode || isLastNode);
      linkedDriveNode.disableUpdateLink = linkedDriveNode.isCurrentDrive;
    })
  }

  buildLinkedDriveNodeInformation(item, currentIndex) {
    const isCurrentDrive = item.drive && item.drive.id === this.drive.id;
    const isLinked = !!item.drive; 
    const isSelected = this.mode === MODE.UPDATE_LINK && this.selectedLinkDriveNode.key === item.key;
    let isNextOrPreviousToALinkedDriveNode = false;
    const previousNode = this.linkedDriveNodes[currentIndex - 1];
    const nextNode = this.linkedDriveNodes[currentIndex + 1];
    if(previousNode && previousNode.drive) {
      isNextOrPreviousToALinkedDriveNode = true;
    }
    if(nextNode && nextNode.drive) {
      isNextOrPreviousToALinkedDriveNode = true;
    }

    return {
      ...item,
      isCurrentDrive: isCurrentDrive,
      isLinked: isLinked,
      isReadonly: this.readOnly,
      class: classNames('slds-path__item', {
        'slds-is-disabled': !isNextOrPreviousToALinkedDriveNode && !item.drive,
        'slds-is-complete': !isSelected && !isCurrentDrive && isLinked,
        'slds-is-active': !isSelected && isCurrentDrive,
        'slds-is-current': isSelected,
        'slds-is-incomplete': !isLinked,
      })
    }
  }

  handleLinkDriveBtn = (id, action) => {
    const item = this.possibleDrives.find(item => item.id === id);
    if(!item) return;

    if(action === 'link') {
      //don't need to check when update linked drive
      if(this.mode === MODE.DEFAULT) {
        let currentLinkedDrivesCount = this.linkedDrives.length;
        if(currentLinkedDrivesCount >= this.maximumLinkedDrives) {
          this.dispatchEvent(new ShowToastEvent({
            message: `Cannot link more than ${this.maximumLinkedDrives} Drives.`,
            variant: 'error',
            mode: 'dismissable'
          }));
          return;
        }
      }

      this.handleLinkDrives([
        item
      ])
      
      if(this.mode === MODE.UPDATE_LINK) {
        this.selectedLinkDriveNode = {
          ...this.selectedLinkDriveNode,
          drive: item
        };
      }

      this.updateLinkedDriveNodes();
      this.getPossibleDrives();
    }
  }

  calculateAssetsForLinkedDrives = (linkedDrives) => {
    const driveHelper = new DriveHelper();

    const calculateVehicles = (drives, allResources = [], mapResourcePossibleAllocations = {}, mapLockedResourceOnDriveByResourceId = {}, mapLockedResourceOnDriveByDriveId = {}) => {
      //vehicles has most available jobs on top
      let sortedVehicles = orderBy(allResources.filter(resource => {
        return resource.assetType === ASSET_TYPE.VEHICLE;
      }), [(resource) => {
        const numberOfDrivesResourceLocked = mapLockedResourceOnDriveByResourceId?.[resource.id] || [];
        return numberOfDrivesResourceLocked.length;
      }, (resource => {
        const availableJobsCount = (mapResourcePossibleAllocations[resource.id] || []).filter(posAl => {
          return (posAl.exceptionLog || []).length === 0;
        }).length;
        return availableJobsCount;
      }), 'presDonorCapacity'], ['desc', 'desc', 'desc']);

      //calculate vehicles 
      const linkedDriveNeedMostVehicle = maxBy(drives, linkedDrive => {
        const lockedVehicles = mapLockedResourceOnDriveByDriveId[linkedDrive.id]?.lockedVehicles || [];
        const lockedVehiclesPresDonorCapacity = lockedVehicles.reduce((result, item) => {
          return result + (item.presDonorCapacity || 0);
        }, 0);
        const vehicleJob = (linkedDrive.jobs || []).find(job => job.assetType === ASSET_TYPE.VEHICLE);
        if(!vehicleJob) return -1;
        return Math.max(driveHelper.getMaxDonorsScheduledOfDriveShifts(linkedDrive) - lockedVehiclesPresDonorCapacity, 0);
      })

      //simple allocation
      let driveWithVehicles = null;
      if(linkedDriveNeedMostVehicle) {
        [driveWithVehicles] = driveHelper.suggestVehicles([linkedDriveNeedMostVehicle], sortedVehicles);
      }

      return driveWithVehicles ? driveWithVehicles.vehicles : [];
    }

    const calculateEquipments = (drives, allResources = [], mapResourcePossibleAllocations = {}, mapLockedResourceOnDriveByResourceId = {}, mapLockedResourceOnDriveByDriveId = {}) => {
      //equipments has most available jobs on top
      let sortedEquipments = orderBy(allResources.filter(resource => {
        return resource.assetType === ASSET_TYPE.EQUIPMENT;
      }), [(resource) => {
        const numberOfDrivesResourceLocked = mapLockedResourceOnDriveByResourceId?.[resource.id] || [];
        return numberOfDrivesResourceLocked.length;
      }, (resource => {
        const availableJobsCount = (mapResourcePossibleAllocations[resource.id] || []).filter(posAl => {
          return (posAl.exceptionLog || []).length === 0;
        }).length;
        return availableJobsCount;
      })], ['desc', 'desc']);

      //calculate equipments
      const linkedDriveNeedMostEquipment = maxBy(drives, linkedDrive => {
        const lockedEquipments = mapLockedResourceOnDriveByDriveId[linkedDrive.id]?.lockedEquipments || [];
        const equipmentJob = (linkedDrive.jobs || []).find(job => job.assetType === ASSET_TYPE.EQUIPMENT);
        if(!equipmentJob) return -1;
        return Math.max(equipmentJob.quantity - (lockedEquipments?.length ?? 0), 0);
      })

      //simple allocation
      let driveWithEquipments = null;
      if(linkedDriveNeedMostEquipment) {
        [driveWithEquipments] = driveHelper.suggestEquipments([linkedDriveNeedMostEquipment], sortedEquipments);
      }

      return driveWithEquipments ? driveWithEquipments.equipmentJobsMap : {};
    }

    let availator = slwcLinkedDrivesAvailator.getInstance({
      linkedDrives: linkedDrives,
      mapApis: window.google ? window.google.maps : null
    });

    return Promise.all([
      availator.fetchData(true)
    ])
    .then(() => {
      return availator.buildScheduledAllocations();
    })
    .then((result) => {
      const mapResourcePossibleAllocations = groupBy(result.possibleAllocations, 'resourceId');
      const mapLockedResourceOnDriveByResourceId = {};
      const mapLockedResourceOnDriveByDriveId = {};
      result.linkedDrives.forEach((drive) => {
        const { lockedEquipments = [] } = driveHelper.getCurrentAssignedEquipments(drive);
        const { lockedVehicles = [] } = driveHelper.getCurrentAssignedVehicles(drive);

        mapLockedResourceOnDriveByDriveId[drive.id] = {
          lockedEquipments,
          lockedVehicles
        }

        lockedEquipments.concat(lockedVehicles).forEach(equipment => {
          if(!mapLockedResourceOnDriveByResourceId[equipment.id]) {
            mapLockedResourceOnDriveByResourceId[equipment.id] = [];
          }

          if(!mapLockedResourceOnDriveByResourceId[equipment.id].includes(drive.id)) {
            mapLockedResourceOnDriveByResourceId[equipment.id].push(drive.id);
          }
        })
      });
      let vehicles = calculateVehicles(result.linkedDrives, result.resources, mapResourcePossibleAllocations, mapLockedResourceOnDriveByResourceId, mapLockedResourceOnDriveByDriveId);
      let equipmentJobsMap = calculateEquipments(result.linkedDrives, result.resources, mapResourcePossibleAllocations, mapLockedResourceOnDriveByResourceId, mapLockedResourceOnDriveByDriveId);

      return {
        vehicles: vehicles,
        equipmentJobsMap: equipmentJobsMap 
      }
    });
  }

  handleLinkDrives = (drives) => {
    drives.forEach(drive => {
      if(this.isMultiDayLink) {
        remove(this.linkedDrives, linkedDrive => linkedDrive.driveDate === drive.driveDate);
      } else {
        remove(this.linkedDrives, linkedDrive => {
          if(this.mode === MODE.UPDATE_LINK) {
            return linkedDrive.id === this.selectedLinkDriveNode.drive.id;
          };
          return drives.find(item => item.id === linkedDrive.id) 
        });
      }
      this.linkedDrives.push({
        ...drive,
        isLinked: true
      });
    })
  }

  handleUnlinkDrives = (drives) => {
    const driveIds = drives.map(drive => drive.id);
    remove(this.linkedDrives, drive => driveIds.includes(drive.id));
  }

  handleLinkedDrivePopoverAction = (event) => {
    const action = event.detail.action;

    if(action === 'unlink') {
      let message = `Are you sure you want to de-link the selected Drive?`;
      if(event.detail.record.isCurrentDrive) {
        message += `\n<strong>Note:</strong> De-linking the current drive will be performed immediately and cannot be undone.`
      }
      this.showConfirmModal({
        title: 'Confirmation',
        message: message,
        onClose: (result) => {
          this.hideConfirmModal();
          if (result) {
            if(event.detail.record.isCurrentDrive) {
              this.handleDelinkCurrentDrive();
            } else {
              this.handleUnlinkDrives([
                event.detail.record.drive
              ])
        
              this.cancelEditLinkedDriveNode();
              this.getPossibleDrives();
            }
          }
        },
        confirmBtnLabel: 'Yes',
        cancelBtnLabel: 'No'
      });
    } else  if(action === 'updateLink') {
      this.enableEditLinkedDriveNode(event.detail.record);
    }
  }

  enableEditLinkedDriveNode = (item) => {
    this.mode = MODE.UPDATE_LINK;
    this.selectedLinkDriveNode = item;

    this.updateLinkedDriveNodes();
    this.getPossibleDrives();
  }

  cancelEditLinkedDriveNode = (event, firstLoad = false) => {
    this.mode = MODE.DEFAULT;
    this.selectedLinkDriveNode = null;

    if(!firstLoad) {
      this.generateLinkedDriveNodes();
      this.updateLinkedDriveNodes();
      this.getPossibleDrives();
    }
  }

  handleRefresh = () => {
    return this.init();
  }

  handleRefreshActivities = () => {
    let queryModel = new linkedDrivesQueryModel();
    let service = new linkedDrivesService();
    
    this.showLoading();
    return Promise.resolve()
    .then(() => {
      if(!this.drive.linkedDriveId) {
        this.linkedActivities = [];
        return;
      }

      queryModel.recordIds = [this.drive.linkedDriveId];
      return service.query(queryModel)
      .then(([result]) => {
        this.linkedActivities = (result.activities || []).map(this.transformActivity);
      })
    })
    .catch((e) => this.exceptionHandler(e))
    .finally(() => this.hideLoading());
  }

  handleCreateLinkedDrives = () => {
    //validate
    if(!this.linkedDrive.linkedDriveType) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'Please select Linked Drive Type.',
        variant: 'error',
        mode: 'dismissable',
      }));

      return;
    }

    const linkedDrives = this.linkedDrives || [];
    if(linkedDrives.length <= 1) {
      this.dispatchEvent(new ShowToastEvent({
        message: 'Please link at least 2 Drive together.',
        variant: 'error',
        mode: 'dismissable',
      }));

      return;
    }

    //create linkedDrives
    let service = new linkedDrivesService();
    let newLinkedDrives = {
      ...this.linkedDrive
    };

    this.showLoading();
    let vehicles = [];
    let equipmentJobsMap = {};
    return service.save(newLinkedDrives)
    .then((result) => {
      if(!result || !result.success) {
        throw result;
      }

      newLinkedDrives.id = result.returnedData[0].Id;
      return this.calculateAssetsForLinkedDrives(linkedDrives)
    })
    .then((result) => {
      vehicles = result.vehicles || [];
      equipmentJobsMap = result.equipmentJobsMap || {};
      return drivesGeneratorInstance.initialize(linkedDrives.map(linkedDrive => linkedDrive.id), true);
    })
    .then(() => {
      const driveHelper = new DriveHelper();
      let promises = [];
      promises = drivesGeneratorInstance.drives.map(drive => {
        let driveGeneratorInstance = drivesGeneratorInstance.driveGeneratorInstanceMap[drive.id];
        let { lockedEquipments } = driveHelper.getCurrentAssignedEquipments(drive);
        let { lockedVehicles } = driveHelper.getCurrentAssignedVehicles(drive);

        return driveGeneratorInstance.onDriveDataChanged([{
          targetName: 'totalVehicleRequestedChanged',
          targetValue: {
            totalVehicleRequested: vehicles.length,
            vehicles: vehicles,
            lockedVehicles
          }
        }, {
          targetName: 'totalEquipmentRequestedChanged',
          targetValue: {
            equipmentJobsMap: equipmentJobsMap,
            lockedEquipments
          }
        }], true)
        .then(() => {
          return driveGeneratorInstance.drive;
        })
      })
      return Promise.all(promises);
    })
    .then((allocatedDrives) => {
      const _driveService = new driveService();
      return Promise.all([
        allocatedDrives, 
        _driveService.saveList(allocatedDrives)
      ]);
    })
    .then(([allocatedDrives, result]) => {
      if(!result || !result.success) {
        throw result;
      }
      const drivesToUpdate = allocatedDrives.map(allocatedDrive => {
        return {
          id: allocatedDrive.id,
          linkedDriveId: newLinkedDrives.id
        }
      })
      const _driveService = new driveService();
      return _driveService.saveList(drivesToUpdate);
    })
    .then((result) => {
      if(!result || !result.success) {
        throw result;
      }

      this.dispatchEvent(new ShowToastEvent({
        message: 'Link Drives successfully.',
        variant: 'success',
        mode: 'dismissable',
      }));

      return this.handleRefresh();
    })
    .catch((e) => this.exceptionHandler(e))
    .finally(() => this.hideLoading());
  }

  handleUpdateLinkedDrives = () => {
    //validate
    const driveHelper = new DriveHelper();
    const linkedDrives = this.linkedDrives || [];
    if(linkedDrives.length <= 1) {
       this.dispatchEvent(new ShowToastEvent({
         message: 'Please link at least 2 Drive together.',
         variant: 'error',
         mode: 'dismissable',
       }));
 
       return;
    }

    this.showConfirmModal({
      title: 'Confirmation',
      message: 'Are you sure you want to update the linked drives?',
      onClose: (result) => {
        this.hideConfirmModal();
        if (result) {
          this.showLoading();
          let vehicles = [];
          let equipmentJobsMap = {};
          this.calculateAssetsForLinkedDrives(linkedDrives)
          .then((result) => {
            vehicles = result.vehicles || [];
            equipmentJobsMap = result.equipmentJobsMap || {};
            return drivesGeneratorInstance.initialize(linkedDrives.map(linkedDrive => linkedDrive.id));
          })
          .then(() => {
            let promises = [];
            promises = drivesGeneratorInstance.drives.map(drive => {
              let driveGeneratorInstance = drivesGeneratorInstance.driveGeneratorInstanceMap[drive.id];
              let { lockedEquipments } = driveHelper.getCurrentAssignedEquipments(drive);
              let { lockedVehicles } = driveHelper.getCurrentAssignedVehicles(drive);
      
              return driveGeneratorInstance.onDriveDataChanged([{
                targetName: 'totalVehicleRequestedChanged',
                targetValue: {
                  totalVehicleRequested: vehicles.length,
                  vehicles: vehicles,
                  lockedVehicles
                }
              }, {
                targetName: 'totalEquipmentRequestedChanged',
                targetValue: {
                  equipmentJobsMap: equipmentJobsMap,
                  lockedEquipments
                }
              }], true)
              .then(() => {
                return driveGeneratorInstance.drive;
              })
            })
            return Promise.all(promises);
          })
          .then((allocatedDrives) => {
            const _driveService = new driveService();
            return Promise.all([
              allocatedDrives,
              _driveService.saveList(allocatedDrives)
            ]);
          })
          .then(([allocatedDrives, result]) => {
            if(!result || !result.success) {
              throw result;
            }
            const drivesToLink = allocatedDrives.map(allocatedDrive => {
              return {
                id: allocatedDrive.id,
                linkedDriveId: this.drive.linkedDriveId
              }
            });
            const originalLinkedDrives = this.originalLinkedDrives || [];
            const drivesToLinkIds = drivesToLink.map(drive => drive.id);
            const drivesToUnlink = originalLinkedDrives.filter(originalLinkedDrive => {
              return !drivesToLinkIds.includes(originalLinkedDrive.id);
            }).map(linkedDrive => {
              return {
                id: linkedDrive.id,
                linkedDriveId: ''
              }
            })
            const _driveService = new driveService();
            return _driveService.saveList(drivesToUnlink.concat(drivesToLink))
            .then((result) => {
              if(!result || !result.success) {
                throw result;
              }
              this.dispatchEvent(new ShowToastEvent({
                message: 'Update Linked Drives successfully.',
                variant: 'success',
                mode: 'dismissable',
              }));
              return this.handleRefresh();
            })
          })
          .catch((e) => this.exceptionHandler(e))
          .finally(() => this.hideLoading());
        }
      },
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No'
    });
  }

  handleDelinkCurrentDrive = () => {
    this.showLoading();
    const drivesToUpdate = [{
      id: this.drive.id,
      linkedDriveId: ''
    }];

    const _driveService = new driveService();
    return _driveService.saveList(drivesToUpdate)
    .then((result) => {
      if(!result || !result.success) {
        throw result;
      }

      this.dispatchEvent(new ShowToastEvent({
        message: 'De-link the current Drive successfully.',
        variant: 'success',
        mode: 'dismissable',
      }));

      return this.handleRefresh();
    })
    .catch((e) => this.exceptionHandler(e))
    .finally(() => this.hideLoading());
  }
  
  handleDeleteLinkedDrives = () => {
    this.showConfirmModal({
      title: 'Confirmation',
      message: 'Are you sure you want to delete the Link?\n<strong>Note:</strong> All linked drives will be de-linked.',
      onClose: (result) => {
        this.hideConfirmModal();
        if (result) {
          this.showLoading();
          const _linkedDrivesService = new linkedDrivesService();
          let _linkedDrivesQueryModel = new linkedDrivesQueryModel();
          _linkedDrivesQueryModel.recordIds = [this.drive.linkedDriveId];
          _linkedDrivesService.query(_linkedDrivesQueryModel)
          .then(([result]) => {
            const drives = result.drives || [];
            const driveToDelink = drives.map(drive => {
              return {
                id: drive.id,
                linkedDriveId: ''
              }
            })
            const _driveService = new driveService();
            return _driveService.saveList(driveToDelink)
          })
          .then((result) => {
            if(!result || !result.success) {
              throw result;
            }

            return _linkedDrivesService.delete({
              id: this.drive.linkedDriveId
            })
          })
          .then((result) => {
            if(!result || !result.success) {
              throw result;
            }
      
            this.dispatchEvent(new ShowToastEvent({
              message: 'Delete Link successfully.',
              variant: 'success',
              mode: 'dismissable',
            }));
      
            return this.handleRefresh();
          })
          .catch((e) => this.exceptionHandler(e))
          .finally(() => this.hideLoading());
        }
      },
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No'
    });
  }

  handleLinkedActivityAction = (actionName, recordId) => {
    let record = this.linkedActivities.find(item => item.id === recordId);
    if(actionName === 'edit') {
      this.handleEditActivity(record); 
    } else if (actionName === 'delete') {
      this.handleDeleteActivity(record);
    }
  }

  handleCreateActivity = () => {
    this.showActivityModal({
      drive: this.linkedDrives[0]
    })
  }

  handleEditActivity = (record) => {
    this.showActivityModal({
      drive: this.linkedDrives[0],
      activity: record
    })
  }

  handleDeleteActivity = (record) => {
    this.showConfirmModal({
      title: 'Confirmation',
      message: 'Are you sure you want to delete this linked activity?',
      onClose: (result) => {
        this.hideConfirmModal();
        if (result) {
          this.showLoading();
          const service = new activityService();
          return service.delete({
            id: record.id
          })
          .then((result) => {
            if(!result || !result.success) {
              throw result;
            }
      
            this.dispatchEvent(new ShowToastEvent({
              message: 'Delete Linked Activity successfully.',
              variant: 'success',
              mode: 'dismissable',
            }));
      
            return this.handleRefreshActivities();
          })
          .catch((e) => this.exceptionHandler(e))
          .finally(() => this.hideLoading());
        }
      },
      confirmBtnLabel: 'Yes',
      cancelBtnLabel: 'No'
    });
  }
  
  handleShowStaffingDetailsModal = () => {
    this.showLinkedDriveStaffingDetailsModal({
      recordId: this.drive.linkedDriveId
    });
  }

  handleOnChange(event) {
    let targetName = event.target.name;
    let targetValue = getValueFromEvent(event);
   
    this.linkedDrive[targetName] = targetValue;

    if(targetName === 'linkedDriveType' && this.linkedDrive.linkedDriveType) {
      this.cancelEditLinkedDriveNode(null, true);
      return this.fetchData();
    }
  }

  /** Confirm Modal **/
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {...confirmModalData,
      isOpen: true
    }
  }

  hideConfirmModal() {
    this.confirmModalData = {};
  }

  /** Activity Modal **/
  showActivityModal(activityModalData) {
    this.activityModalData = {...activityModalData,
      isOpen: true
    }
  }

  closeActivityModal(event) {
    this.activityModalData = {};

    if(event.detail.result) {
      this.handleRefreshActivities();
    }
  }

  /** Linked Drive Staffing Details Modal */
  showLinkedDriveStaffingDetailsModal(modalData) {
    this.linkedDriveStaffingDetailsModalData = {...modalData,
      isOpen: true
    }
  }

  closeLinkedDriveStaffingDetailsModal(event) {
    this.linkedDriveStaffingDetailsModalData = {};
  }

  saveLinkedDriveStaffingDetailsModal(event) {
    this.closeLinkedDriveStaffingDetailsModal();
  }
  
}