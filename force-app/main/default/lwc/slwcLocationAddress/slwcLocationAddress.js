import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshLightningPage, isGeolocationValid } from 'c/slwcUtils';
import { locationService } from 'c/dataService';

export default class SlwcLocationAddress extends LightningElement {
    @api recordId;
    @api refresh;
    @api redirect = false;
    @track showSpinner = false;
    @track errors = [];
    placeDetails;

    get addressInvalid() {
        return !isGeolocationValid(this.placeDetails) || this.errors.length > 0;
    }

    validate(placeDetails) {
        this.errors = [];
        if(!placeDetails) return;

        if(!placeDetails.addressComponents || !placeDetails.addressComponents.postalCode) {
            this.errors.push(`Cannot find address zip code.`);
        }

        return this.errors.length === 0;
    }
    
    handleSelectAddress(event) {
        this.placeDetails = event.detail.placeDetails;
        console.log('this.placeDetails ',JSON.stringify(this.placeDetails));
        this.validate(this.placeDetails);
    }

    handleAddSiteAddress(event) {
        if (this.addressInvalid) {
            this.dispatchEvent(new ShowToastEvent({
                message: 'Error geocoding or locating address. Please review address and re-enter. Contact BSF Support if further assistance is needed.',
                variant: 'error',
                mode: 'dismissable',
            }));
            return;
        }

        this.showSpinner = true;
        console.log('this.placeDetails before save ',JSON.stringify(this.placeDetails));
        
        let service = new locationService();
        let model = { 
            id: this.recordId,
            address: this.placeDetails.formattedAddress,
            address1: [this.placeDetails.addressComponents.streetNumber, this.placeDetails.addressComponents.route].join(' '),
            city: this.placeDetails.addressComponents.locality,
            county: this.placeDetails.addressComponents.area2,
            state: this.placeDetails.addressComponents.area1,
            zipCode: this.placeDetails.addressComponents.postalCode,
            geoLocationLatitude: this.placeDetails.geometry.lat,
            geoLocationLongitude: this.placeDetails.geometry.lng
        };

        service.save(model)
        .then(() => {
            let message = 'Address was updated successfully.';
            const event = new ShowToastEvent({
                message: message,
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);

            if (this.refresh) {
                refreshLightningPage();
            }
            if (this.redirect) {
                window.open('/' + this.recordId, '_self');
            }
        }).catch((error) => {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }).finally(() => {
            this.showSpinner = false;
        });
    }
}