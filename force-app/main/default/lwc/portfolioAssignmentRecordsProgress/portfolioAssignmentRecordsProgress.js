import { LightningElement } from 'lwc';
import getBatchList from '@salesforce/apex/PortfolioAssignmentRecordsController.getBatchList';

export default class PortfolioAssignmentRecordsProgress extends LightningElement {
    showBanner = false;
    connectedCallback(){
        getBatchList()
        .then(result =>{
            if(result){
                this.showBanner = true;
            }
        })
    }
}