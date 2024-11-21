import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshLightningPage, isGeolocationValid } from 'c/slwcUtils';
import { stagingLocationService } from 'c/dataService';

export default class SlwcSetStagingLocationAddress extends LightningElement {
    @api recordId;
    @track showSpinner = false;
    placeDetails;

    handleSelectAddress(event) {
        this.placeDetails = event.detail.placeDetails;
    }

    handleAddAddress(event) {
        if (!isGeolocationValid(this.placeDetails)) {
            this.dispatchEvent(new ShowToastEvent({
                message: 'Error geocoding or locating address. Please review address and re-enter. Contact BSF Support if further assistance is needed.',
                variant: 'error',
                mode: 'dismissable',
            }));
            return;
        }

        this.showSpinner = true;
        Promise.resolve()
            .then(() => {
                let model = {
                    id: this.recordId
                };
                model.address = this.placeDetails.formattedAddress;
                model.geoLocationLatitude = this.placeDetails.geometry.lat;
                model.geoLocationLongitude = this.placeDetails.geometry.lng;
                model.zipCode = this.placeDetails.addressComponents.postalCode;

                let service = new stagingLocationService();
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
                    })
                    .catch((error) => {
                        if(error && error.message) {
                            this.dispatchEvent(new ShowToastEvent({
                                message: error.message,
                                variant: 'error',
                                mode: 'dismissable'
                            }));
                        }
                    });
            })
            .catch((error) => {
                console.log('Error', error);
                console.debug('error :: ' , error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
}