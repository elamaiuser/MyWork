import { LightningElement, track } from 'lwc';
import * as slwcAvailator from 'c/slwcAvailator';
import { ASSET_TYPE } from 'c/slwcConstants';
import { keyBy, pick } from 'c/lodash';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as slwcUtils from 'c/slwcUtils';
import { resourceService, driveService } from 'c/dataService';
import * as autoMapper from 'c/autoMapper';

const _resourceService = new resourceService();
const _driveService = new driveService();

const EXCEPTION_CODE_MAP = {
  'UNAVAILABLE': { severity: 'error', message: 'Resource is unavailable during this period' },
  'OVERLAPPING': { severity: 'error', message: 'Resource has an overlapping allocation' },
  'OUT_OF_REGION': { severity: 'error', message: 'Resource is outside the collection operation region' },
  'RELOCATED': { severity: 'error', message: 'Resource is relocated during this period' }
};

export default class SlwcVehicleReplacementConsole extends LightningElement {
  @track filters = {
    collectionOperationValues: {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    },
    startDate: null,
    endDate: null
  };
  @track vehicleToChange = null;
  @track replacementVehicle = null;
  @track availableVehicles = [];
  @track impactedDrives = [];
  @track currentPage = 1;
  @track totalMatches = 0;
  _allDrives = [];
  @track isLoadingVehicles = false;
  @track isLoadingDrives = false;
  @track isEnriching = false;
  @track isApplying = false;
  @track selectedDriveIds = new Set();
  @track overriddenDriveIds = new Set();
  @track acknowledgedContentionIds = new Set();

  get headerTitle() {
    return this.vehicleToChange
      ? `Replace Vehicle: ${this.vehicleToChange.name}`
      : 'Replace Vehicle';
  }

  get pageName() {
    return 'schedulingConsole:vehicleReplacement';
  }

  connectedCallback() {
    this.initialize();
  }

  initialize() {
    const lastQuery = this.getLastQuery();
    if (lastQuery) {
      this.filters = { ...this.filters, ...lastQuery };
    }
    this.loadVehicles();
  }

  get collectionOperationDateRange() {
    return { startDate: this.filters.startDate, endDate: this.filters.endDate };
  }

  get isLoading() {
    return this.isLoadingVehicles || this.isLoadingDrives || this.isEnriching || this.isApplying;
  }

  get isFilterIncomplete() {
    const coIds = ((this.filters.collectionOperationValues || {}).territoryCollectionOperations || []);
    return !coIds.length || !this.filters.startDate || !this.filters.endDate || !this.vehicleToChange;
  }

  get isDriveTableVisible() {
    return !!this.vehicleToChange;
  }

  get isApplyDisabled() {
    return this.selectedDriveIds.size === 0 || this.isApplying;
  }

  get replacementVehicleExcludeId() {
    return this.vehicleToChange ? this.vehicleToChange.id : null;
  }

  get isReplacementDisabled() {
    return !this.vehicleToChange || this.isLoadingVehicles;
  }

  get selectedDriveIdsArray() {
    return Array.from(this.selectedDriveIds);
  }

  get overriddenDriveIdsArray() {
    return Array.from(this.overriddenDriveIds);
  }

  get acknowledgedContentionIdsArray() {
    return Array.from(this.acknowledgedContentionIds);
  }

  handleCollectionOperationChanged(event) {
    this.filters.collectionOperationValues = {
      divisions: event.detail.selectedDivisions,
      arcRegions: event.detail.selectedARCRegions,
      districts: event.detail.selectedDistricts,
      territoryCollectionOperations: event.detail.selectedTerritoryCollectionOperations
    };
    this.setLastQuery();
    this.vehicleToChange = null;
    this._clearPickerSelection('currentVehicle');
    this._resetDownstream();
    this.loadVehicles();
  }

  handleDateChanged(event) {
    this.filters.startDate = event.detail.startDate;
    this.filters.endDate = event.detail.endDate;
    this.setLastQuery();
    this.loadVehicles();
    if (this.vehicleToChange && this.filters.startDate && this.filters.endDate) {
      this.loadDrives();
    } else {
      this._allDrives = [];
      this.impactedDrives = [];
      this.totalMatches = 0;
      this.selectedDriveIds = new Set();
    }
  }

  handleCurrentVehicleSelected(event) {
    const vehicle = event.detail.vehicle;
    this.vehicleToChange = vehicle;
    this._resetDownstream();
    if (this.filters.startDate && this.filters.endDate) {
      this.loadDrives();
    }
  }

  handleCurrentVehicleCleared() {
    this.vehicleToChange = null;
    this._resetDownstream();
  }

  handleReplacementVehicleSelected(event) {
    this.replacementVehicle = event.detail.vehicle;
    if (this._allDrives.length) {
      this.isEnriching = true;
      this._enrichWithExceptions(this._allDrives)
        .then(enrichedDrives => {
          this._allDrives = enrichedDrives;
          this._updatePage(this.currentPage);
        })
        .finally(() => {
          this.isEnriching = false;
        });
    }
  }

  handleReplacementVehicleCleared() {
    this.replacementVehicle = null;
    this._allDrives.forEach(drive => {
      drive.exceptions = [];
      drive.contentions = [];
      drive.hasException = false;
    });
    this.selectedDriveIds = new Set();
    this.acknowledgedContentionIds = new Set();
    this._updatePage(this.currentPage);
  }

  handleRowSelection(event) {
    const { driveId, isSelected } = event.detail;
    const newSet = new Set(this.selectedDriveIds);
    if (isSelected) {
      newSet.add(driveId);
    } else {
      newSet.delete(driveId);
    }
    this.selectedDriveIds = newSet;
  }

  handleOverrideChanged(event) {
    const { overrideKey, isOverridden } = event.detail;
    const newSet = new Set(this.overriddenDriveIds);
    if (isOverridden) {
      newSet.add(overrideKey);
    } else {
      newSet.delete(overrideKey);
    }
    this.overriddenDriveIds = newSet;
  }

  handleContentionAcknowledgeChanged(event) {
    const { conKey, isAcknowledged } = event.detail;
    const newAcknowledged = new Set(this.acknowledgedContentionIds);
    if (isAcknowledged) {
      newAcknowledged.add(conKey);
    } else {
      newAcknowledged.delete(conKey);
      const driveId = conKey.split('_con_')[0];
      const newSelected = new Set(this.selectedDriveIds);
      newSelected.delete(driveId);
      this.selectedDriveIds = newSelected;
    }
    this.acknowledgedContentionIds = newAcknowledged;
  }

  handlePageChange(event) {
    const { direction } = event.detail;
    if (direction === 'prev' && this.currentPage > 1) {
      this.currentPage -= 1;
    } else if (direction === 'next') {
      this.currentPage += 1;
    }
    this._updatePage(this.currentPage);
  }

  handleApply() {
    if (this.isApplyDisabled) return;
    this.isApplying = true;
    const driveIds = Array.from(this.selectedDriveIds);
    _driveService.applyVehicleReplacement({ request: {
      vehicleToChangeId: this.vehicleToChange.id,
      replacementVehicleId: this.replacementVehicle.id,
      driveIds
    } })
      .then(() => {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Success',
          message: 'Vehicle replacement applied successfully.',
          variant: 'success'
        }));
        this.selectedDriveIds = new Set();
        this.loadDrives();
      })
      .catch(err => {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Error',
          message: (err && err.message) || 'An error occurred applying the vehicle replacement.',
          variant: 'error'
        }));
      })
      .finally(() => {
        this.isApplying = false;
      });
  }

  handleCancel() {
    this.filters = {
      collectionOperationValues: { divisions: [], arcRegions: [], districts: [], territoryCollectionOperations: [] },
      startDate: null,
      endDate: null
    };
    this.vehicleToChange = null;
    this.replacementVehicle = null;
    this.availableVehicles = [];
    this._allDrives = [];
    this.impactedDrives = [];
    this.totalMatches = 0;
    this.selectedDriveIds = new Set();
    this.overriddenDriveIds = new Set();
    this.acknowledgedContentionIds = new Set();
    this.currentPage = 1;
  }

  loadVehicles() {
    const coIds = ((this.filters.collectionOperationValues || {}).territoryCollectionOperations || [])
      .map(item => item.collectionOperationId);
    if (!coIds.length || !this.filters.startDate || !this.filters.endDate) {
      this.availableVehicles = [];
      return;
    }
    this.isLoadingVehicles = true;
    _resourceService.getVehiclesForCOs({ request: {
      collectionOperationIds: coIds,
      startDate: this.filters.startDate,
      endDate: this.filters.endDate
    } })
      .then(result => {
        const data = result && result.returnedData || {};
        const relocatedIds = new Set(data.relocatedIds || []);
        this.availableVehicles = (data.vehicles || []).map(r => {
          const v = autoMapper.autoMapperInstance.mapTo('sked__Resource__c', r);
          return {
            ...v,
            status: v.isActive ? 'Active' : 'Inactive',
            isRelocated: relocatedIds.has(v.id)
          };
        });
      })
      .catch(() => {
        this.availableVehicles = [];
      })
      .finally(() => {
        this.isLoadingVehicles = false;
      });
  }

  loadDrives() {
    this.isLoadingDrives = true;
    const coIds = ((this.filters.collectionOperationValues || {}).territoryCollectionOperations || [])
      .map(item => item.collectionOperationId);
    _driveService.getImpactedDrives({ request: {
      vehicleToChangeId: this.vehicleToChange.id,
      startDate: this.filters.startDate,
      endDate: this.filters.endDate,
      collectionOperationIds: coIds
    } })
      .then(result => {
        const drives = (result && result.returnedData && result.returnedData.drives) || [];
        const mappedDrives = drives.map(r => autoMapper.autoMapperInstance.mapTo('sked_Drive__c', r));
        return this._enrichWithExceptions(mappedDrives);
      })
      .then(enrichedDrives => {
        this._allDrives = enrichedDrives;
        this.totalMatches = enrichedDrives.length;
        this._updatePage(1);
      })
      .catch(() => {
        this._allDrives = [];
        this.impactedDrives = [];
        this.totalMatches = 0;
      })
      .finally(() => {
        this.isLoadingDrives = false;
      });
  }

  _updatePage(page) {
    const pageSize = 10;
    this.currentPage = page;
    const start = (page - 1) * pageSize;
    this.impactedDrives = this._allDrives.slice(start, start + pageSize);
  }

  _enrichWithExceptions(drives) {
    if (!drives.length || !this.replacementVehicle) return Promise.resolve(drives);

    const availator = slwcAvailator.getInstance({ mapApis: null, considerDateOnly: true });
    const jobs = drives.map(d => ({
      id: d.id,
      assetType: ASSET_TYPE.VEHICLE,
      start: d.jobs && d.jobs[0] ? d.jobs[0].start : null,
      finish: d.jobs && d.jobs[0] ? d.jobs[0].finish : null,
      driveDate: d.driveDate,
      collectionOperationIds: d.collectionOperationId ? [d.collectionOperationId] : []
    }));

    const collectionOperationIds = [...new Set(drives.map(d => d.collectionOperationId).filter(Boolean))];

    return availator.fetchAssetsDataDriveCalendar(jobs, {
      timezoneSidId: null,
      collectionOperationIds,
      excludedDriveIds: [],
      resourceIds: [this.replacementVehicle.id]
    })
      .then(() => availator.buildScheduledAllocations({ ignoreDedicatedSiteRule: true }))
      .then(result => {
        const paByJobId = keyBy(
          (result.possibleAllocations || []).filter(pa => pa.resourceId === this.replacementVehicle.id),
          'jobId'
        );

        drives.forEach(drive => {
          const pa = paByJobId[drive.id];
          drive.exceptions = pa ? this._mapExceptionLog(pa.exceptionLog) : [];

          const remainingCapacity = (drive.vehicleCapacity || 0) - (this.vehicleToChange.presDonorCapacity || 0);
          const minRequiredCapacity = (drive.projectedRegisteredDonors || 0) - remainingCapacity;
          drive.contentions = this.replacementVehicle.presDonorCapacity < minRequiredCapacity
            ? [{ message: `Capacity gap: replacement vehicle capacity of ${this.replacementVehicle.presDonorCapacity} is less than the required ${minRequiredCapacity}` }]
            : [];

          drive.hasException = drive.exceptions.length > 0 || drive.contentions.length > 0;
        });

        return drives;
      })
      .catch(() => {
        drives.forEach(drive => {
          drive.exceptions = [];
          drive.contentions = [];
          drive.hasException = false;
        });
        return drives;
      });
  }

  _mapExceptionLog(exceptionLog) {
    if (!exceptionLog || !exceptionLog.length) return [];
    return exceptionLog.map(entry => {
      const mapped = EXCEPTION_CODE_MAP[entry.exception];
      return mapped
        ? { severity: mapped.severity, message: mapped.message }
        : { severity: 'error', message: entry.exception };
    });
  }

  setLastQuery() {
    slwcUtils.setLastQuery(this.pageName, this.filters);
    slwcUtils.setLastQuery('schedulingConsole', pick(this.filters, ['collectionOperationValues']));
  }

  getLastQuery() {
    const tabQuery = slwcUtils.getLastQuery(this.pageName);
    const schedulingConsoleQuery = slwcUtils.getLastQuery('schedulingConsole');
    const collectionOperationValues = (schedulingConsoleQuery || {}).collectionOperationValues || {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    };
    if (tabQuery && tabQuery.collectionOperationValues) {
      collectionOperationValues.territoryCollectionOperations = tabQuery.collectionOperationValues.territoryCollectionOperations || [];
    }
    return {
      ...tabQuery,
      collectionOperationValues
    };
  }

  _resetDownstream() {
    this.replacementVehicle = null;
    this._clearPickerSelection('replacementVehicle');
    this._allDrives = [];
    this.impactedDrives = [];
    this.totalMatches = 0;
    this.currentPage = 1;
    this.selectedDriveIds = new Set();
    this.overriddenDriveIds = new Set();
    this.acknowledgedContentionIds = new Set();
  }

  _clearPickerSelection(dataId) {
    const picker = this.template.querySelector(`c-slwc-vehicle-picker[data-id="${dataId}"]`);
    if (picker) {
      picker.clearSelection();
    }
  }
}