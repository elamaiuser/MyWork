import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFutureDrives from '@salesforce/apex/FutureDrivesController.getFutureDrives';
import applyChangestoFutureDrives from '@salesforce/apex/FutureDrivesController.applyChangestoFutureDrives';
import futureDriveSubmissionMessage from '@salesforce/apex/FutureDrivesController.futureDriveSubmissionMessage';

export default class FilteredDriveTable extends LightningElement {

    @api isdisabled = false;
    @api recordId;
    isLoading = false;
    @track futureDrives;
    @api fields;
    @api futureDriveSubmissionMessage;

    connectedCallback() {
        this.isLoading = true;
        getFutureDrives({ recordid: this.recordId })
            .then((result) => {
                this.futureDrives = result;
                // this.futureDrives.forEach( (elem)=>{
                //     elem.url = '/lightning/r/Opportunity/' + elem.driveid ;
                // });
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                let errorMessage;
                if (error.body.message) {
                    errorMessage = error.body.message;
                }
                this.showToast('error in retrieving Future Drives', errorMessage, 'error');
            })

        futureDriveSubmissionMessage()
            .then((result) => {
                this.futureDriveSubmissionMessage = result;
                console.log('Toast==> ', this.futureDriveSubmissionMessage);
            })
            .catch((error) => {
                let errorMessage;
                if (error.body.message) {
                    errorMessage = error.body.message;
                }
                this.showToast('error in futureDriveSubmissionMessage method', errorMessage, 'error');
            })
    }
    oncancelclick(event) {
        this.closeQuickActionFunc();
    }

    closeQuickActionFunc() {
        let bookobjToDelete = {};
        this.dispatchEvent(new CustomEvent('closequickaction', { detail: bookobjToDelete }));
    }

    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }

    handleAllCheckBoxChange(event) {
        //console.log( 'target value is ' , event.target.value );
        //console.log( 'handleAllCheckBoxChange is checked ' , event.target.checked );
        this.futureDrives.forEach((elem) => {
            elem.isselected = event.target.checked;
        });
        //console.log( 'futureDrives is on All change now is ', JSON.stringify( this.futureDrives ) );

    }

    handleCheckBoxChange(event) {
        //console.log( 'target value is ' , event.target.value );
        //console.log( 'name is ' , event.target.name );
        this.futureDrives.forEach((elem) => {
            if (event.target.name === elem.driveid) {
                elem.isselected = event.target.checked;
            }
        });
        //console.log( 'futureDrives is on change now is ', JSON.stringify( this.futureDrives ) );
    }

    applynow(event) {
        // console.log( 'futureDrives is in apply now is ', JSON.stringify( this.futureDrives ) );
        // console.log( 'fields is in apply now is ', JSON.stringify( this.fields ) );

        this.isLoading = true;

        applyChangestoFutureDrives({ FutureDriveClass: JSON.stringify(this.futureDrives), recordid: this.recordId, fields: this.fields })
            .then((result) => {
                this.isLoading = false;
                this.showToast(this.futureDriveSubmissionMessage, '', 'success');
                this.closeQuickActionFunc();
            })
            .catch((error) => {
                this.isLoading = false;
                let errorMessage;
                if (error.body.message) {
                    errorMessage = error.body.message;
                }
                console.log( 'error in updating Future Drives ', errorMessage);
                this.showToast('error in updating Future Drives', errorMessage, 'error');
            })
    }

    opendetailpage(event) {
        //console.log( 'detail page url is ' ,  event.currentTarget.dataset.recordid  );
        let url = '/lightning/r/Opportunity/' + event.currentTarget.dataset.recordid + '/view';
        window.open(url, "_blank");
    }
}