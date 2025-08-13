import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { DateTime } from 'c/luxon';
import { driveQueryModel, driveService, sObjectType } from 'c/dataService';
import { DRIVE_TYPE, DRIVE_OPERATION_TYPE } from 'c/slwcConstants';

export default class SlwcDriveCalendarDayModal extends LightningElement {
    @track showModal = false;
    @track filters;
    @track showNonIntegratedDrivesTab = false;

    get title() {
        if (this.filters.startDate != this.filters.endDate) {
            return DateTime.fromFormat(this.filters.startDate, 'yyyy-MM-dd').toFormat('MMMM dd, yyyy') + ' - ' + DateTime.fromFormat(this.filters.endDate, 'yyyy-MM-dd').toFormat('MMMM dd, yyyy');
        }
        else {
            return DateTime.fromFormat(this.filters.startDate, 'yyyy-MM-dd').toFormat('MMMM dd, yyyy');
        }
    }

    get territoryKeys() {
        if (!this.filters || !this.filters.collectionOperationValues) return [];
        return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => `${item.territoryId}:${item.collectionOperationId}`);
    }

    get driveCalendarDriveListFilters() {
        return {
            ...this.filters,
            territoryKeys: this.territoryKeys
        }
    }

    get nonIntegratedDrivesTabFilters() {
        return {
            ...this.filters,
            territoryKeys: this.territoryKeys,
            driveOperationTypes: [DRIVE_OPERATION_TYPE.NIFS]
        }
    }

    @api isReadonly = false;

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('driveCalendar:showDayModal', this.handleShowDayModal, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleShowDayModal(detail) {
        this.filters = detail.filters;
        this.filters.startDate = detail.startDate;
        this.filters.endDate = detail.endDate;
        this.showModal = true;

        this.checkNonIntegratedDrives();
    }

    handleCloseModal() {
        this.showModal = false;
    }

    checkNonIntegratedDrives() {
        let driveQuery = new driveQueryModel();
        driveQuery.territoryKeys = this.nonIntegratedDrivesTabFilters.territoryKeys;
        driveQuery.startDate = this.nonIntegratedDrivesTabFilters.startDate;
        driveQuery.endDate = this.nonIntegratedDrivesTabFilters.endDate;
        driveQuery.eventTypes = this.nonIntegratedDrivesTabFilters.driveTypes;
        driveQuery.statuses = ["Tentative", "Confirmed", "Complete", "Hold", "Cancel"];
        driveQuery.stages = this.nonIntegratedDrivesTabFilters.stages;
        driveQuery.accountTypes = this.nonIntegratedDrivesTabFilters.accountTypes;
        driveQuery.accountIndustryCodes = this.filters.accountIndustryCodes;
        // driveQuery.recruitedBys = this.nonIntegratedDrivesTabFilters.recruitedBys;
        driveQuery.markets = (this.nonIntegratedDrivesTabFilters.markets || []).map(market => {
            return market.id;
        });
        driveQuery.subQueryIndicator = sObjectType.JOB;
        driveQuery.operationTypes = this.nonIntegratedDrivesTabFilters.operationTypes;
        
        let service = new driveService();
        service.query(driveQuery)
        .then((result) => {
            this.showNonIntegratedDrivesTab = result && result.length;
        })
    }
}