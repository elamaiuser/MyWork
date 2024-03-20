import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FilterDriveContainer extends LightningElement {

    @api recordId;
    isdisabled = true;
    isdatedisabled = true;
    fieldsopted;

    oncancelclick(event){
        this.closeQuickActionFunc();
    }

    closeQuickActionFunc(){
        let bookobjToDelete = {};
        this.dispatchEvent(new CustomEvent('closequickaction', { detail : bookobjToDelete} ));
    }
    // handledateselection(event){
    //     this.isdatedisabled = event.detail.disable;
    //     //console.log( 'this.isdatedisabled value is #1 ', this.isdatedisabled );
    //     if(this.isdatedisabled === true ){
    //         //console.log( 'this.isdatedisabled value is #2 ', this.isdatedisabled );
    //         this.isdisabled = this.isdatedisabled;
    //     }
    // }
    // handledisableselection(event){
    //     this.isdisabled = event.detail.disable;
    // }

    handlefieldselection(event){
        this.fieldsopted = event.detail.selectedfields;
        //console.log( 'fieldsopted is ' , JSON.stringify( this.fieldsopted ) );

    }
}