import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshLightningPage } from 'c/slwcUtils';
import { collectionOperationService, locationService } from 'c/dataService';

export default class SlwcCollectionOperationStagingAddress extends LightningElement {
    @api recordId;
    @track showSpinner = false;
    placeDetails;

    handleSelectAddress(event) {
        this.placeDetails = event.detail.placeDetails;
    }

    handleAddAddress(event) {
        if (!this.placeDetails) return;

        this.showSpinner = true;
        Promise.resolve()
            .then(() => {
                let model = {
                    id: this.recordId
                };
                model.stagingLocationAddress = this.placeDetails.formattedAddress;
                model.stagingLocationGeolocationLatitude = this.placeDetails.geometry.lat;
                model.stagingLocationGeolocationLongitude = this.placeDetails.geometry.lng;

                let service = new collectionOperationService();
                service.save(model)
                    .then(() => {
                        let message = 'Staging Location Address was updated successfully.';
                        const event = new ShowToastEvent({
                            message: message,
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);

                        refreshLightningPage();
                    });
            })
            .catch((error) => {
                console.log('Error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
}