import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { groupBy, pick } from 'c/lodash';
import { driveQueryModel, driveService, sObjectType } from 'c/dataService';
import * as slwcUtils from "c/slwcUtils";
import * as slwcDateUtils from 'c/slwcDateUtils';

export default class SlwcDriveListMap extends LightningElement {
  @track initialized = false;
  @track showSpinner = false;
  @track driveList = [];
  @track driveSiteMap = {};
  @track mapMarkers = [];
  @track selectedDriveSiteId = null;
  @track driveSideMenuData = {
    shown: false,
    recordId: null
  }

  @track filters = {
    collectionOperationValues: {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    },
    startDate: null,
    endDate: null
  }

  @track includesAdditionalDays = 0;

  colorPalette = [
    '#2CA02C', // green
    '#17BECF', // cyan
    '#BD9E39', // mustard
    '#9467BD', // purple
    '#CEDB9C', // light green
    '#393B79', // dark blue
    '#8C6D31', // gold brown
    '#7B4173', // violet
    '#9C9EDE', // light lavender
    '#1F77B4', // blue
    '#637939', // dark olive
    '#7F7F7F', // gray
    '#BCBD22', // olive
    '#5254A3', // blue-gray
    '#8C564B', // brown
    '#E7CB94', // pale gold 
    '#9E3F3F', // dark red
    '#AEDA74', // dark yellow
    '#C4B08C', // tan
    '#FF7F0E', // orange
    '#F781BF', // pink
    ];
  
  get pageName() {
    return 'schedulingConsole:driveListMap';
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  get collectionOperations() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => item.collectionOperation);
  }

  get territoryKeys() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => `${item.territoryId}:${item.collectionOperationId}`);
  }

  get collectionOperationFirstDay() {
    if (!this.collectionOperations || !this.collectionOperations.length) return;
    return this.collectionOperations[0].workWeekFirstDay;
  }

  get collectionOperationDateRange() {
    if (!this.filters || !this.filters.startDate || !this.filters.endDate) return {
      startDate: null,
      endDate: null
    };

    return {
      startDate: this.filters.startDate,
      endDate: this.filters.endDate
    }
  }

  get selectedDriveSite() {
    if(!this.selectedSiteDriveList.length) return null;
    return this.selectedSiteDriveList[0].driveSite;
  }

  get selectedSiteDriveList() {
    return this.driveSiteMap[this.selectedDriveSiteId] || [];
  }

  get showSelectedSiteDriveList() {
    return !!this.selectedDriveSite;
  }

  get hasRecords() {
    return this.driveList && this.driveList.length > 0 && this.mapMarkers.length <= 100;
  }

  get showMarkerLimitExceeded() {
    return this.mapMarkers.length > 100;
  }

  get showNoDrive() {
    return !this.driveList || this.driveList.length === 0;
  }


  @wire(CurrentPageReference) pageRef;

  connectedCallback() {
    if (!this.initialized) {
      let lastSearchQuery = this.getLastQuery();
      if (lastSearchQuery) {
        this.filters = {
          ...this.filters,
          ...lastSearchQuery
        };
      }

      if (!this.filters.collectionOperationValues.territoryCollectionOperations) {
        this.filters.collectionOperationValues.territoryCollectionOperations = [];
      }

      if (!this.filters.startDate || !this.filters.endDate) {
        const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
        this.filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), firstDay).toISODate();
        this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
          day: 1
        }).toISODate()
      }
    }
  }

  renderedCallback() {
    if (!this.initialized) {
      this.initialized = true;
    }
  }

  openDriveSideMenu(recordId) {
    const driveStaffingDetailsCmp = this.template.querySelector('c-slwc-drive-staffing-details');
    if(driveStaffingDetailsCmp && driveStaffingDetailsCmp.isLoading()) return;
    
    this.driveSideMenuData = {
      shown: true,
      recordId: recordId
    }
  }

  closeDriveSideMenu() {
    this.driveSideMenuData = {
      shown: false,
      recordId: ''
    }
  }

  saveDriveSideMenu() {
    this.closeDriveSideMenu();
  }

  getDriveList() {
    const territoryKeys = this.territoryKeys;
    if(!territoryKeys.length) {
      this.selectedDriveSiteId = null;
      this.driveList = [];
      this.driveSiteMap = {};
      this.mapMarkers = [];
      return;
    }

    let startDate = this.filters.startDate;
    let endDate = this.filters.endDate;
    if(this.includesAdditionalDays > 0) {
      startDate = DateTime.fromISO(startDate).minus({
          day: this.includesAdditionalDays
      }).toISODate();
      endDate = DateTime.fromISO(endDate).plus({
          day: this.includesAdditionalDays
      }).toISODate();
    }

    const linkDriveColorMap = new Map();
    let colorIndex = 0;
    let driveQuery = new driveQueryModel();
    let queryModel = new driveQueryModel();
    queryModel.territoryKeys = territoryKeys;
    queryModel.startDate = startDate;
    queryModel.endDate = endDate;
    queryModel.eventTypes = this.filters.driveTypes;
    queryModel.statuses = this.filters.driveStatuses;
    queryModel.stages = this.filters.stages;
    queryModel.accountTypes = this.filters.accountTypes;
    queryModel.accountIndustryCodes = this.filters.accountIndustryCodes;
    queryModel.showOnlyLinkedEvents = true;
    queryModel.accountManagerPortfolioIds = (this.filters.accountManagerPortfolios || []).map(accountManagerPortfolio => {
      return accountManagerPortfolio.id;
    });
    queryModel.districtManagerPortfolioIds = (this.filters.districtManagerPortfolios || []).map(districtManagerPortfolio => {
        return districtManagerPortfolio.id;
    })
    queryModel.markets = (this.filters.markets || []).map(market => {
      return market.id;
    });
    const driveSvc = new driveService();
    driveSvc.query(queryModel)
                .then((result) => {
                    let drives = [];
                    if (result && result.length) {
                      result.forEach((drive) => {
                        drive.recordPageUrl = '/' + drive.id;
                        drives.push(drive);
                        if (drive.linkedDriveId && !linkDriveColorMap.has(drive.linkedDriveId)) {
                          linkDriveColorMap.set(drive.linkedDriveId, this.colorPalette[colorIndex % this.colorPalette.length]);
                          colorIndex++;
                        }
                      });
                      if (!linkDriveColorMap || linkDriveColorMap.size === 0) {
                          driveQuery.isNotLinkedDrive = true;
                          driveQuery.linkedDriveIds = [...linkDriveColorMap.keys()];
                          console.log('driveQuery.linkedDriveIds ',driveQuery.linkedDriveIds);
                      }
                    }
                  })
                  .catch((error) => {
                    console.log(error);
                  });

    console.log('linkDriveColorMap ',linkDriveColorMap);

    driveQuery.territoryKeys = territoryKeys;
    driveQuery.startDate = startDate;
    driveQuery.endDate = endDate;
    driveQuery.eventTypes = this.filters.driveTypes;
    driveQuery.statuses = this.filters.driveStatuses;
    driveQuery.stages = this.filters.stages;
    driveQuery.accountTypes = this.filters.accountTypes;
    driveQuery.accountIndustryCodes = this.filters.accountIndustryCodes;
    driveQuery.accountManagerPortfolioIds = (this.filters.accountManagerPortfolios || []).map(accountManagerPortfolio => {
      return accountManagerPortfolio.id;
  });
  driveQuery.districtManagerPortfolioIds = (this.filters.districtManagerPortfolios || []).map(districtManagerPortfolio => {
      return districtManagerPortfolio.id;
  })
    // driveQuery.recruitedBys = this.filters.recruitedBys;
    driveQuery.markets = (this.filters.markets || []).map(market => {
      return market.id;
    });
    // driveQuery.daysOfWeek = this.filters.daysOfWeek;

    let service = new driveService();
    this.showSpinner = true;
    return service.getDrives_OptimizeDriveList(driveQuery)
      .then((result) => {
        let drives = [];
        if (result && result.length) {
          result.forEach((drive) => {
            drive.recordPageUrl = '/' + drive.id;
            drives.push(drive);
          });
        }
        this.selectedDriveSiteId = null;
        this.driveList = drives;
        this.buildMarkers(this.driveList,linkDriveColorMap);
      })
      .catch((error) => {
        console.log(error);
      })
      .finally(() => {
        this.showSpinner = false;
      });
  }
  
  buildMarkers(driveList,linkDriveColorMap) {
    this.mapMarkers = [];
    this.driveSiteMap = {};

    if(!driveList || !driveList.length) return;

    let driveSitesMap = groupBy(driveList, 'driveSiteId');
    this.driveSiteMap = driveSitesMap;
    console.log('test 6 ');
    this.mapMarkers = Object.keys(driveSitesMap).map(driveSiteId => {
      let drives = driveSitesMap[driveSiteId];
      let driveSite = drives[0].driveSite;
      return {
        location: {
          Latitude: driveSite.geoLocationLatitude,
          Longitude: driveSite.geoLocationLongitude
        },
        value: driveSiteId,
        icon: 'custom:custom26',
        title: `${driveSite.name}`,
        mapIcon : {
                path: 'M20 0C9 0 0 9 0 20c0 12 20 40 20 40s20-28 20-40C40 9 31 0 20 0z M27.5 14a7.5 7.5 0 1 1 -15 0a7.5 7.5 0 1 1 15 0z',
                fillColor: this.getFillColor(drives,linkDriveColorMap),
                fillOpacity: 1,
                strokeColor: '#000000',
                strokeOpacity: 0.35,
                strokeWeight: 1,
                scale: 0.6,
                anchor: { x: 20, y: 60 }
            },
        description: `
          <strong>Address: </strong><br/>
          ${driveSite.address}<br/>
          <strong>Drive List (${drives.length}): </strong><br/>
          ${drives.map(drive => {
            let driveDateString = DateTime.fromISO(drive.driveDate).toFormat('MMM dd, yyyy')
            return `${drive.name} - ${drive.typeOfDrive} - ${driveDateString}`
          }).join('<br/>')}
        `
      }
    })
  }

  getFillColor(drives, linkDriveColorMap) {
    let FILL_COLOR = '#DB4437';
    
    if (!linkDriveColorMap || linkDriveColorMap.size === 0) {
        return FILL_COLOR;
    }

    drives.forEach((drive) => {
      const linkedDriveId = drive?.linkedDriveId;
      if (linkedDriveId && linkDriveColorMap.has(linkedDriveId)) {
          console.log('linkedDriveId ',linkedDriveId);
          FILL_COLOR = linkDriveColorMap.get(linkedDriveId);
      }
    });
    console.log('FILL_COLOR ',FILL_COLOR);
    return FILL_COLOR;
  }

  handleCollectionOperationChanged(event) {
    this.filters.collectionOperationValues = {
      divisions: event.detail.selectedDivisions,
      arcRegions: event.detail.selectedARCRegions,
      districts: event.detail.selectedDistricts,
      territoryCollectionOperations: event.detail.selectedTerritoryCollectionOperations
    }

    this.handleSearch();
  }

  validateFilters() {
    if (this.filters.startDate) {
      const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
      this.filters.startDate = this.dateUtils.startOfWeek(this.filters.startDate, firstDay).toISODate();
      this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
        day: 6
      }).toISODate()
    }
  }

  handleSearch(event = {
    detail: {}
  }) {

    const { filters } = event.detail;
    this.filters = {
        ...this.filters,
        ...filters,
        territoryKeys: this.territoryKeys
    };
    this.getDriveList();
    this.setLastQuery();
  }

  handleMarkerSelect(event) {
    this.selectedDriveSiteId = event.target.selectedMarkerValue;
  }

  handleViewDetails(event) {
    const driveId = event.currentTarget.dataset['id'];
    this.openDriveSideMenu(driveId);
  }

  handleOnChange(event) {
    if (event.type === 'daterangechange') {
      this.filters = {
        ...this.filters, 
        startDate: event.detail.startDate,
        endDate: event.detail.endDate
      }
      this.handleSearch();
    }
  }

  setLastQuery() {
    slwcUtils.setLastQuery(this.pageName, this.filters);
    slwcUtils.setLastQuery('schedulingConsole', pick(this.filters, ['collectionOperationValues']));
  }

  getLastQuery() {
    let tabQuery = slwcUtils.getLastQuery(this.pageName);
    let schedulingConsoleQuery = slwcUtils.getLastQuery('schedulingConsole');
    let collectionOperationValues =  (schedulingConsoleQuery || {}).collectionOperationValues || {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    };
    if(tabQuery && tabQuery.collectionOperationValues) {
      collectionOperationValues.territoryCollectionOperations = tabQuery.collectionOperationValues.territoryCollectionOperations || [];
    }
    return {
      ...tabQuery,
      collectionOperationValues: collectionOperationValues
    };
  }
}