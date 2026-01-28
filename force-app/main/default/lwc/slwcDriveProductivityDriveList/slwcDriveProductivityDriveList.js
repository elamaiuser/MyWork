import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { driveQueryModel, driveService, sObjectType, territoryQueryModel, territoryService } from 'c/dataService';
import { groupBy } from 'c/lodash';
import { classNames, generateColors } from "c/slwcUtils";
import { LINK_DRIVE_TYPE } from 'c/slwcConstants';

export default class SlwcDriveProductivityDriveList extends LightningElement {
    @track showModal = false;
    @track showSpinner = false;
    @track driveList;
    @track filters;
    @track filteredList;
    @track hasResult = false;
    @track productivityStatusGroups = [];
    @track totalDrives = 0;
    @track linkedDriveModalData = {};

    @track btnConfirmDisabled = true;

    selectedProductivityStatus = null;
    territoriesMapById = null;
    startDate = null;
    endDate = null;

    get title() {
        if (this.startDate != this.endDate) {
            return DateTime.fromFormat(this.startDate, 'yyyy-MM-dd').toFormat('MMMM dd, yyyy') + ' - ' + DateTime.fromFormat(this.endDate, 'yyyy-MM-dd').toFormat('MMMM dd, yyyy');
        }
        else {
            return DateTime.fromFormat(this.startDate, 'yyyy-MM-dd').toFormat('MMMM dd, yyyy');
        }
    }

    get columns() {
        let results = [];
        results.push({label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true } );
        results.push({label: 'Drive Name', fieldName: 'driveNameData', type: 'driveName', hideDefaultActions: false, wrapText: true, hideDefaultActions: true } );
        // results.push({fieldName: 'linkedDrive', type: 'linkedDrive', initialWidth: 155, hideDefaultActions: true, wrapText: true, typeAttributes: {
        //     iconClicked: (event) => {
        //         this.handleLinkedDriveIconClicked(event.currentTarget.dataset['value'])
        //     }
        // }});
        results.push({label: 'Min Shift Start', fieldName: 'minShiftStart', type: 'date', typeAttributes: { hour: "numeric", minute: "2-digit", timeZone: TIME_ZONE }, hideDefaultActions: true } );
        results.push({label: 'Max Shift End', fieldName: 'maxShiftEnd', type: 'date', typeAttributes: { hour: "numeric", minute: "2-digit", timeZone: TIME_ZONE }, hideDefaultActions: true } );
        results.push({label: 'Products Projected', fieldName: 'totalProductsProjected', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Staff Requested', fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Staff Scheduled', fieldName: 'staffAllocated', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Planned Productivity', fieldName: 'driveProductivityPlanned', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Scheduled Productivity', fieldName: 'driveProductivityScheduled', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Recruited By', fieldName: 'recruitedBy', type: 'text', hideDefaultActions: true } );
        return results;
    }

    get territoryKeys() {
        if (!this.filters || !this.filters.collectionOperationValues) return [];
        return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => `${item.territoryId}:${item.collectionOperationId}`);
    }

    get collectionOperations() {
        if (!this.filters || !this.filters.collectionOperationValues) return [];
        return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => item.collectionOperation);
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        this.initialize();
        registerListener('productivityCalendar:showDriveList', this.handleShowDriveList, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    initialize() {
        let driveProductivityStatuses = ["High", "Mid", "Low"];
        driveProductivityStatuses.forEach((productivityStatus) => {
            let productivityStatusGroup = {
                class: "slds-grid slds-grid_vertical-align-center scheduling-status__filter-item",
                productivityStatus: productivityStatus,
                totalDrives: 0
            };
            productivityStatusGroup.countClass = classNames('drives-count', {
                'productivity__high': productivityStatus == "High",
                'productivity__mid': productivityStatus == "Mid",
                'productivity__low': productivityStatus == "Low"
            });
            this.productivityStatusGroups.push(productivityStatusGroup);
        });
    }

    handleShowDriveList(detail) {
        this.filters = detail.filters;
        this.startDate = detail.startDate;
        this.endDate = detail.endDate;
        this.showModal = true;
        this.getDriveList();
    }

    handleCloseModal() {
        this.showModal = false;
    }

    getDriveList() {
        this.showSpinner = true;
        this.filteredList = [];

        const territoryKeys = this.territoryKeys;
        const territoryIds = territoryKeys.map(key => key.split(':')[0]);

        return Promise.resolve()
            .then(() => {
                let driveQuery = new driveQueryModel();
                driveQuery.territoryKeys = this.territoryKeys;
                driveQuery.startDate = this.startDate;
                driveQuery.endDate = this.endDate;
                driveQuery.eventTypes = this.filters.driveTypes;
                driveQuery.statuses = this.filters.driveStatuses;
                driveQuery.stages = this.filters.stages;
                driveQuery.accountTypes = this.filters.accountTypes;
                driveQuery.accountIndustryCodes = this.filters.accountIndustryCodes;
                // driveQuery.recruitedBys = this.filters.recruitedBys;
                driveQuery.markets = (this.filters.markets || []).map(market => {
                    return market.id;
                });
                driveQuery.subQueryIndicator = sObjectType.JOB;
                
                let territoryQuery = new territoryQueryModel();
                territoryQuery.recordIds = territoryIds;

                let driveSvc = new driveService();
                let territorySvc = new territoryService();

                return Promise.all([
                    driveSvc.query(driveQuery),
                    territorySvc.query(territoryQuery)
                ])
            })
            .then(([driveResult, territoryResult]) => {
                this.territoriesMapById = territoryResult.reduce((map, territory) => {
                    map[territory.id] = territory;
                    return map;
                }, {});

                if (driveResult && driveResult.length) {
                    driveResult.forEach((drive) => {
                        let territoryCollectionOperation = ((this.filters.collectionOperationValues || {}).territoryCollectionOperations || []).find(item => item.territoryId == drive.territoryId);

                        const territory = this.territoriesMapById[territoryCollectionOperation.territoryId];

                        drive.recordPageUrl = '/' + drive.id;
                        drive.driveNameData = {
                            id: drive.id,
                            name: drive.name,
                            totalStaffRequested: drive.totalStaffRequested,
                            staffAllocated: drive.staffAllocated
                        };

                        drive.linkedDrive = drive.linkedDriveId ? {
                            id: drive.linkedDriveId,
                            driveId: drive.id,
                            name: drive.linkedDriveName,
                            linkedDriveType: drive.linkedDriveType,
                            url: '/' + drive.linkedDriveId
                        } : null;

                        drive.productivityStatus = "";
                        if (territory) {
                            if (drive.driveProductivityPlanned < territory.midDriveProductivityThreshold) {
                                drive.productivityStatus = "Low";
                            }
                            else if (drive.driveProductivityPlanned < territory.highDriveProductivityThreshold) {
                                drive.productivityStatus = "Mid";
                            }
                            else {
                                drive.productivityStatus = "High";
                            }
                        }
                    });
                }
                this.totalDrives = driveResult.length;
                this.driveList = driveResult;
                this.countDriveByProductivityStatus();
                this.updateLinkedDrivesStyle();
                this.filterDriveList("High");
            })
            .catch((error) => {
                console.log(error);
            })
            .finally(() => {
                this.showSpinner = false
            });
    }

    countDriveByProductivityStatus() {
        let drivesGroupByStatus = groupBy(this.driveList, "productivityStatus");
        this.productivityStatusGroups.forEach((group) => {
            group.totalDrives = 0;
            if (drivesGroupByStatus[group.productivityStatus]) {
                group.totalDrives = drivesGroupByStatus[group.productivityStatus].length;
            }
        });
    }

    updateLinkedDrivesStyle() {
        let drivesGroupByLinkedDrive = groupBy(this.driveList.filter(drive => !!drive.linkedDriveId), (drive) => {
            return drive.linkedDriveId;
        });
        const colors = generateColors(Object.keys(drivesGroupByLinkedDrive).length);

        Object.keys(drivesGroupByLinkedDrive).forEach((linkedDriveId, linkedDriveIndex) => {
            const drives = drivesGroupByLinkedDrive[linkedDriveId];
            let color = colors.shift();

            drives.forEach(drive => {
                drive.linkedDrive = {
                    ...drive.linkedDrive,
                    linkedDriveIndex: linkedDriveIndex + 1,
                    isMultiDayLink: drive.linkedDrive.linkedDriveType === LINK_DRIVE_TYPE.MULTI_DAY,
                    customStyle: {
                        iconContainer: `background-color: ${color}`
                    }
                }
            })
        })
    }

    handleFilterDrives(event) {
        this.selectedProductivityStatus = event.currentTarget.dataset['value'];
        this.filterDriveList(this.selectedProductivityStatus);
    }

    filterDriveList(productivityStatus) {
        this.filteredList = this.driveList.filter((drive) => drive.productivityStatus == productivityStatus);
        this.productivityStatusGroups.forEach((group) => {
            group.class = classNames('slds-grid slds-grid_vertical-align-center scheduling-status__filter-item', {
                'is-selected': group.productivityStatus == productivityStatus
            });
        })
    }

    showLinkedDriveModal = (drive) => {
        this.linkedDriveModalData = {
            shown: true,
            drive: drive
        }
    }

    closeLinkedDriveModal = (event) => {
        this.linkedDriveModalData = {};
        const result = !!event.detail.result;
        if(result) {
            this.handleRefresh();
        }
    }

    handleLinkedDriveIconClicked = (driveId) => {
        const drive = this.driveList.find(item => item.id === driveId);
        if(!drive) return;

        this.showLinkedDriveModal(drive); 
    }
}