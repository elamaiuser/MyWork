import { LightningElement, api } from 'lwc';
//import getBaseURLExternalform from '@salesforce/apex/AccountBasedPortfolioClass.getBaseURLExternalform';

export default class OpenAccountDetailcmp extends LightningElement {

    @api accobject;

    redirecttoaccount(event){
        // getBaseURLExternalform()
        // .then((result)=>{
        //     console.log("result url is ", result );
        //     let url = result+ ".lightning.force.com/lightning/r/Account/"+ this.accrecord.Id + "/view" ;
        //     window.open(url, "_blank");
        // })
        // .catch((error)=>{

        // })
        
        let recordurl = this.accobject.domainurl + ".lightning.force.com/lightning/r/Account/"+ this.accobject.account_id + "/view" ;
        window.open(recordurl, "_blank");
    }
}