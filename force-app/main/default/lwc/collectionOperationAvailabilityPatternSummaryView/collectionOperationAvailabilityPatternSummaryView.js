import { LightningElement, api, track } from 'lwc';
import {
  sObjectType,
  collectionOperationService,
  collectionOperationQueryModel,
  availabilityPatternRoleService,
  availabilityPatternRoleQueryModel
} from 'c/dataService';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import { DateTime } from 'c/luxon';
import { isNullOrEmpty } from 'c/slwcUtils';
export default class CollectionOperationAvailabilityPatternSummaryView extends LightningElement {
    @api recordId;
    
    @track model = {};
    @track showSpinner = false;

    get todayIso() {
        return DateTime.fromJSDate(new Date()).toISODate();
    }

    connectedCallback() {
        this.init();
    }

    init() {
        this.showLoading();
        let service = new collectionOperationService();
        let query = new collectionOperationQueryModel();
        query.recordIds = [this.recordId];
        query.subQueryIndicator = sObjectType.COLLECTION_OPERATION_AVAILABILITY;
        return Promise.resolve()
        .then(() => {
            return service.query(query)
        })
        .then((result) => {
            if (result.length) {
                this.model = result[0];
                const grandTotalAvailable = (this.model.grandTotalAvailableFixedSite ?? 0) + (this.model.grandTotalAvailableMobile ?? 0);
                const grandTotalNeeded = (this.model.grandTotalNeededFixedSite ?? 0) + (this.model.grandTotalNeededMobile ?? 0);
                const variance = grandTotalAvailable - grandTotalNeeded;
                const colOpGrandTotalModels = [
                    {
                        typeOfStaff: 'Total Staff',
                        grandTotalAvailable: grandTotalAvailable,
                        grandTotalNeeded: grandTotalNeeded,
                        variance: grandTotalAvailable - grandTotalNeeded,
                        varianceClass: this.getColorClass(variance)
                    },
                    {
                        typeOfStaff: 'Fixed Site Staff',
                        grandTotalAvailable: this.model.grandTotalAvailableFixedSite ?? 0,
                        grandTotalNeeded: this.model.grandTotalNeededFixedSite ?? 0,
                        variance: (this.model.grandTotalAvailableFixedSite ?? 0) - (this.model.grandTotalNeededFixedSite ?? 0),
                        varianceClass: this.getColorClass((this.model.grandTotalAvailableFixedSite ?? 0) - (this.model.grandTotalNeededFixedSite ?? 0))
                    },
                    {
                        typeOfStaff: 'Mobile Staff',
                        grandTotalAvailable: this.model.grandTotalAvailableMobile ?? 0,
                        grandTotalNeeded: this.model.grandTotalNeededMobile ?? 0,
                        variance: (this.model.grandTotalAvailableMobile ?? 0) - (this.model.grandTotalNeededMobile ?? 0),
                        varianceClass: this.getColorClass((this.model.grandTotalAvailableMobile ?? 0) - (this.model.grandTotalNeededMobile ?? 0))
                    }
                ];

                this.model = {
                    ... this.model,
                    collectionOperationAvailabilities: (this.model.collectionOperationAvailabilities?.filter(coAp => isNullOrEmpty(coAp.endDate) || coAp.endDate >= this.todayIso) ?? []),
                    colOpGrandTotalModels: colOpGrandTotalModels
                };

                service = new availabilityPatternRoleService();
                query = new availabilityPatternRoleQueryModel();
                query.colOpAvailabilityIds = this.model.collectionOperationAvailabilities.map(record => record.id);
                return service.query(query).then((queryResult) => {
                    this.model = {
                        ... this.model,
                        collectionOperationAvailabilities: this.model.collectionOperationAvailabilities.map(item => {
                            return { 
                                ...item,
                                showApTotals: (queryResult?.some(apRole => apRole.colOpAvailabilityId === item.id)) ?? false,
                                totalApModels: [
                                    {
                                        typeOfStaff: 'Total',
                                        totalActualResources: (item.totalActualResourcesFixedSite ?? 0) + (item.totalActualResourcesMobile ?? 0),
                                        totalTargetResources: (item.totalTargetFixedSite ?? 0) + (item.totalTargetMobile ?? 0),
                                        totalVariance: ((item.totalActualResourcesFixedSite ?? 0) + (item.totalActualResourcesMobile ?? 0)) 
                                                        - ((item.totalTargetFixedSite ?? 0) + (item.totalTargetMobile ?? 0)),
                                        totalVarianceClass: this.getColorClass(
                                            ((item.totalActualResourcesFixedSite ?? 0) + (item.totalActualResourcesMobile ?? 0)) - ((item.totalTargetFixedSite ?? 0) + (item.totalTargetMobile ?? 0))),
                                    },
                                    {
                                        typeOfStaff: 'Fixed Site',
                                        totalActualResources: item.totalActualResourcesFixedSite ?? 0,
                                        totalTargetResources: item.totalTargetFixedSite ?? 0,
                                        totalVariance: (item.totalActualResourcesFixedSite ?? 0) - (item.totalTargetFixedSite ?? 0),
                                        totalVarianceClass: this.getColorClass((item.totalActualResourcesFixedSite ?? 0) - (item.totalTargetFixedSite ?? 0)),
                                    },
                                    {
                                        typeOfStaff: 'Mobile',
                                        totalActualResources: item.totalActualResourcesMobile ?? 0,
                                        totalTargetResources: item.totalTargetMobile ?? 0,
                                        totalVariance: (item.totalActualResourcesMobile ?? 0) - (item.totalTargetMobile ?? 0),
                                        totalVarianceClass: this.getColorClass((item.totalActualResourcesMobile ?? 0) - (item.totalTargetMobile ?? 0)),
                                    }
                                ],
                                availabilityPatternRoles: (queryResult?.filter(apRole => apRole.colOpAvailabilityId === item.id) ?? []).map(apRoleItem => {
                                    return {
                                        ...apRoleItem,
                                        variance: apRoleItem.actualCountOfRoles - apRoleItem.minNumberOfRoles,
                                        varianceClass: this.getColorClass(apRoleItem.actualCountOfRoles - apRoleItem.minNumberOfRoles),
                                    }
                                })
                            };
                        })
                    }
                })
            }
        })
        .catch(error => this.exceptionHandler(error))
        .finally(() => this.hideLoading());
    }

    getColorClass(value) {
        if (value < 0) {
            return 'negative-variance';
        }
        return 'positive-variance';
    }

    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }

    exceptionHandler = (error) => {
        if (error && error.message) {
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
        }
    }
}