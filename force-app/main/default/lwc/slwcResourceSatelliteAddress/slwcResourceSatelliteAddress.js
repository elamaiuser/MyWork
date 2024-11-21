import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshLightningPage, isGeolocationValid } from 'c/slwcUtils';
import { resourceService, locationService } from 'c/dataService';

export default class SlwcResourceSatelliteAddress extends LightningElement {
    @api recordId;
    @track showSpinner = false;
    placeDetails;

    exceptionHandler = (error) => {
        console.log(error);
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }

    handleSelectAddress(event) {
        this.placeDetails = event.detail.placeDetails;
    }

    handleAddSatelliteAddress(event) {
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
                
                model.satelliteAddressGeoLocationLatitude = this.placeDetails.geometry.lat;
                model.satelliteAddressGeoLocationLongitude = this.placeDetails.geometry.lng;
                model.satelliteAddress = this.placeDetails.formattedAddress;
                model.satelliteAddress1 = [this.placeDetails.addressComponents.streetNumber, this.placeDetails.addressComponents.route].join(' ');
                model.satelliteCity = this.placeDetails.addressComponents.locality;
                model.satelliteCountry = this.placeDetails.addressComponents.country;
                model.satelliteState = this.placeDetails.addressComponents.area1;
                model.satelliteZipCode = this.placeDetails.addressComponents.postalCode;

                let service = new resourceService();
                service.save(model)
                    .then(() => {
                        let message = 'Satellite Address was updated successfully.';
                        const event = new ShowToastEvent({
                            message: message,
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);

                        refreshLightningPage();
                    })
            })
            .catch((error) => {
                this.exceptionHandler(error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
}