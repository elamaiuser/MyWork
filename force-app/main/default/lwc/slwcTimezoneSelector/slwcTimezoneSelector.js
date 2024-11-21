import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import { sObjectType, collectionOperationService, collectionOperationQueryModel } from 'c/dataService';

export default class SlwcTimezoneSelector extends LightningElement {
    @track value;
    @track options = [
        { label: TIME_ZONE, value: TIME_ZONE }
    ];

    @api name;
    @api label = "Timezone";
    @api variant;
    @api 
    get selectedValue() {
        return this.value;
    }
    set selectedValue(val) {
        if (val === '' || val === undefined || val === null) {
            this.value = TIME_ZONE;
        }
        else {
            this.value = val;
        }
    }
    
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        let query = new collectionOperationQueryModel();
        query.subQueryIndicator = sObjectType.REGION;
        let service = new collectionOperationService();
        service.query(query)
            .then((collectionOps) => {
                let tempOptions = [];
                let allTimezones = [TIME_ZONE];
                if (collectionOps && collectionOps.length > 0) {
                    collectionOps.forEach((collectionOp) => {
                        if (collectionOp.regions && collectionOp.regions.length > 0) {
                            collectionOp.regions.forEach((region) => {
                                if (allTimezones.indexOf(region.timezoneSidId) == -1) {
                                    allTimezones.push(region.timezoneSidId);
                                }
                            });
                        }
                    });
                    allTimezones.forEach((timezone) => {
                        tempOptions.push({ label: timezone, value: timezone })
                    });
                    this.options = tempOptions;
                }
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
            });
    }

    handleChange(event) {
        let tempValue = event.target.value;
        let selectedValue = tempValue;
        let key = this.uniqueKey;

        const pickValueChangeEvent = new CustomEvent('timezonechange', {
            detail: { selectedValue, key },
        });
        this.dispatchEvent(pickValueChangeEvent);
    }
}