import { LightningElement, track, api } from 'lwc';
import { skedService } from 'c/dataService';

export default class SlwcAddressInput extends LightningElement {
    @api label;
    @api placeholder = '';
    @api value = null;
    @api errors = [];
    @api scrollAfterNItems;
    @api customKey;
    @api isReadonly = false;
    @api isRequired = false;
    
    @api reportValidity() {
        [
            ...this.template.querySelectorAll('c-slwc-lookup')
        ].forEach((inputField) => {
            inputField.reportValidity();
        });
    }

    @api checkValidity() {
        return [
            ...this.template.querySelectorAll('c-slwc-lookup'),
        ].reduce((validSoFar, inputField) => {
            return validSoFar && inputField.checkValidity();
        }, true);
    }

    sessionId;

    handleSearch(searchData) {
        let service = new skedService();
        return service.getAddressPredictions({queryText: searchData.searchTerm})
            .then((result) => {
                let apiResult = JSON.parse(result);
                this.sessionId = apiResult.sessionId;

                let predictions = JSON.parse(apiResult.response);
                return predictions.result.predictions.map((input) => {
                    return {
                        id: input.placeId,
                        description: input.description
                    }
                });
            });
    }

    handleSelectAddress(event) {
        if (!event.detail.selection || !event.detail.selection.description) {
            const selectionChangeEvent = new CustomEvent('selectionchange', {
                detail: {
                    placeDetails: null
                }
            });
            this.dispatchEvent(selectionChangeEvent);
            return;
        };

        let service = new skedService();
        service.getPlaceDetails({placeId: event.detail.selection.id, sessionId: this.sessionId})
            .then((result) => {
                let apiResult = JSON.parse(result);
                const selectionChangeEvent = new CustomEvent('selectionchange', {
                    detail: {
                        placeDetails: apiResult.result
                    }
                });
                this.dispatchEvent(selectionChangeEvent);
            });
    }
}