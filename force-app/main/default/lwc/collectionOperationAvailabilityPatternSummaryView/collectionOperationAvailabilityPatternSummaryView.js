import { LightningElement, api, track } from 'lwc';
import {
  sObjectType,
  collectionOperationService,
  collectionOperationQueryModel,
  availabilityPatternRoleService,
  availabilityPatternRoleQueryModel
} from 'c/dataService';

export default class CollectionOperationAvailabilityPatternSummaryView extends LightningElement {
    @api recordId;
    
    @track records = [];
    @track model = {};
    @track showSpinner = false;

    connectedCallback() {
        this.init();
    }

    init() {
        this.showLoading();
        let service = new collectionOperationService();
        let query = new collectionOperationQueryModel();
        console.log(this.recordId);
        query.recordIds = [this.recordId];
        query.subQueryIndicator = sObjectType.COLLECTION_OPERATION_AVAILABILITY;
        return Promise.resolve()
        .then(() => {
            return service.query(query)
        })
        .then((result) => {
            console.log(result);
            if (result.length) {
                this.model = result[0];
                const grandTotalAvailable = this.model.grandTotalAvailable ?? 0;
                const grandTotalNeeded = this.model.grandTotalNeeded ?? 0;
                const variance = grandTotalAvailable - grandTotalNeeded;

                this.model = {
                    ... this.model,
                    grandTotalAvailable: grandTotalAvailable,
                    grandTotalNeeded: grandTotalNeeded,
                    variance: variance,
                    varianceClass: this.getColorClass(variance)
                }

                service = new availabilityPatternRoleService();
                query = new availabilityPatternRoleQueryModel();
                query.colOpAvailabilityIds = this.model.collectionOperationAvailabilities.map(record => record.id);
                return service.query(query).then((queryResult) => {
                    this.model = {
                        ... this.model,
                        collectionOperationAvailabilities: this.model.collectionOperationAvailabilities.map(item => {
                            return { 
                                ...item,      
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