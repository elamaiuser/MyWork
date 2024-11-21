import { LightningElement , api,wire,track} from 'lwc';
import checkSiteCollectionOpForNoncollectionArea from '@salesforce/apex/NewSiteController.checkSiteCollectionOpForNoncollectionArea';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import warningMsg from '@salesforce/label/c.NonCollectionArea';

export default class NonCollectionAreaSiteCollectionOpCheck extends LightningElement {

    @api recordId;
    error;
    @track nonCollectionArea;


    get bannerMsg() {
        if (!this.nonCollectionArea) return;
            
        return warningMsg;
        
    }
    
    connectedCallback()
    {
        console.log('Id ',this.recordId);
       
        checkSiteCollectionOpForNoncollectionArea({recordId:this.recordId})
        .then(result=> {  
            console.log('Result ',result);
            this.nonCollectionArea= result;
            
        }).catch(error => {
            console.log('Errors ',JSON.stringify(error));
        });
        
    }

}