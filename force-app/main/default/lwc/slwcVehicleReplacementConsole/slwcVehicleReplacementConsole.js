import { LightningElement, track } from 'lwc';
import * as slwcAvailator from 'c/slwcAvailator';
import { ASSET_TYPE, DRIVE_CONTENTION_RESOLUTION } from 'c/slwcConstants';
import { keyBy, pick } from 'c/lodash';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as slwcUtils from 'c/slwcUtils';
import { resourceService, driveService } from 'c/dataService';
import * as autoMapper from 'c/autoMapper';
import SlwcVehicleReplacementConfirmModal from 'c/slwcVehicleReplacementConfirmModal';

const _resourceService = new resourceService();
const _driveService = new driveService();


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
  @track selectedContentionResolutions = {};

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

  get activeVehicles() {
    const { startDate, endDate } = this.filters;
    if (!startDate || !endDate) return this.availableVehicles;
    return this.availableVehicles.filter(v => {
      if (!v.effectiveDate && !v.futureInactiveDate) return v.isActive;
      const effectiveOk = !v.effectiveDate || v.effectiveDate <= endDate;
      const inactiveOk = !v.futureInactiveDate || v.futureInactiveDate >= startDate;
      return effectiveOk && inactiveOk;
    });
  }

  get isReplacementDisabled() {
    return !this.vehicleToChange || this.isLoadingVehicles;
  }

  get selectedDriveIdsArray() {
    return Array.from(this.selectedDriveIds);
  }


  get selectedContentionResolutionsData() {
    return { ...this.selectedContentionResolutions };
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
    this.selectedContentionResolutions = {};
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


  handleContentionResolutionChanged(event) {
    const { conKey, resolution } = event.detail;
    const updated = { ...this.selectedContentionResolutions };
    if (resolution) {
      updated[conKey] = resolution;
    } else {
      delete updated[conKey];
      const driveId = conKey.split('_con_')[0];
      const hasOtherResolved = Object.keys(updated).some(k => k.startsWith(driveId + '_con_'));
      if (!hasOtherResolved) {
        const newSelected = new Set(this.selectedDriveIds);
        newSelected.delete(driveId);
        this.selectedDriveIds = newSelected;
      }
    }
    this.selectedContentionResolutions = updated;
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
    const resolutionMap = this.selectedContentionResolutions;
    const selectedDrives = this._allDrives
      .filter(d => this.selectedDriveIds.has(d.id))
      .map(d => {
        const resolution = (d.contentions || [])
          .map((_, idx) => resolutionMap[`${d.id}_con_${idx}`])
          .find(Boolean);
        return { ...d, selectedResolution: resolution || null };
      });
    SlwcVehicleReplacementConfirmModal.open({
      size: 'medium',
      currentVehicle: this.vehicleToChange,
      replacementVehicle: this.replacementVehicle,
      drives: selectedDrives
    }).then(result => {
      if (result === 'confirm') {
        this._executeApply();
      }
    });
  }

  _executeApply() {
    this.isApplying = true;
    const driveIds = Array.from(this.selectedDriveIds);
    const resolutionMap = this.selectedContentionResolutions;
    const contentionResolutions = {};
    this._allDrives
      .filter(d => this.selectedDriveIds.has(d.id))
      .forEach(d => {
        const resolutions = (d.contentions || [])
          .map((_, idx) => resolutionMap[`${d.id}_con_${idx}`])
          .filter(Boolean);
        if (resolutions.length) {
          contentionResolutions[d.id] = resolutions.join(';');
        }
      });
    _driveService.applyVehicleReplacement({ request: {
      vehicleToChangeId: this.vehicleToChange.id,
      replacementVehicleId: this.replacementVehicle.id,
      driveIds,
      contentionResolutions
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

    this.selectedContentionResolutions = {};
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
        const data = (result && result.returnedData) || {};
        const jobsByDriveId = {};
        (data.jobs || []).forEach(rawJob => {
          const job = autoMapper.autoMapperInstance.mapTo('sked__Job__c', rawJob);
          if (!jobsByDriveId[job.driveId]) jobsByDriveId[job.driveId] = [];
          jobsByDriveId[job.driveId].push(job);
        });
        const mappedDrives = (data.drives || []).map(r => {
          const drive = autoMapper.autoMapperInstance.mapTo('sked_Drive__c', r);
          drive.jobs = jobsByDriveId[drive.id] || [];
          return drive;
        });
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
    const jobs = drives.map(d => {
      const [vehicleJob] = d.jobs || [];
      return {
        id: d.id,
        assetType: ASSET_TYPE.VEHICLE,
        start: vehicleJob ? vehicleJob.start : null,
        finish: vehicleJob ? vehicleJob.finish : null,
        jobTags: vehicleJob ? vehicleJob.jobTags : [],
        driveDate: d.driveDate,
        collectionOperationIds: d.collectionOperationId ? [d.collectionOperationId] : []
      };
    });

    const collectionOperationIds = [...new Set(drives.map(d => d.collectionOperationId).filter(Boolean))];

    return availator.fetchAssetsDataDriveCalendar(jobs, {
      timezoneSidId: this.vehicleToChange.timezoneId,
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
          drive.exceptions = pa ? (pa.exceptionLog || []).map(e => ({ severity: 'error', message: e.exception })) : [];

          const remainingCapacity = (drive.vehicleCapacity || 0) - (this.vehicleToChange.presDonorCapacity || 0);
          const minRequiredCapacity = (drive.projectedRegisteredDonors || 0) - remainingCapacity;
          drive.contentions = this.replacementVehicle.presDonorCapacity < minRequiredCapacity
            ? [{
              message: `Capacity gap: replacement vehicle capacity of ${this.replacementVehicle.presDonorCapacity} is less than the required ${minRequiredCapacity}`,
              resolutionOptions: [
                { value: DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_USE_RENTAL },
                { value: DRIVE_CONTENTION_RESOLUTION.ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY }
              ]
            }]
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

    this.selectedContentionResolutions = {};
  }

  _clearPickerSelection(dataId) {
    const picker = this.template.querySelector(`c-slwc-vehicle-picker[data-id="${dataId}"]`);
    if (picker) {
      picker.clearSelection();
    }
  }
}