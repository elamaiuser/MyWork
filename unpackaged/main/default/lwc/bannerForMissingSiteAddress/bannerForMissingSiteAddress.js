import { LightningElement , api} from 'lwc';
import isAddressPresentMethod from '@salesforce/apex/SiteMissingAddressBannerController.checkSiteMissingAddress';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class BannerForMissingSiteAddress extends LightningElement {

    @api recordId;
    error;
    
    connectedCallback()
    {
        console.log('Id ',this.recordId);
        isAddressPresentMethod({siteId:this.recordId})
        .then(result=> {  
            console.log('Result ',result);
            if(result != '')
            {
                const event = new ShowToastEvent({
                    message: result,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            }
            
        }).catch(error => {
            console.log('Errors ',JSON.stringify(error));
        });
        
    }

}