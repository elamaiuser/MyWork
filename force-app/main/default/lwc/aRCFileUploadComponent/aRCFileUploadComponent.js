import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableFileTypes from '@salesforce/apex/ARCFileUploadController.getAvailableFileTypes';
import getAvailableFileFormats from '@salesforce/apex/ARCFileUploadController.getAvailableFileFormats';
import getFileTypeAndInsert from '@salesforce/apex/ARCFileUploadController.getFileTypeAndInsert';
import getFilesAndDelete from '@salesforce/apex/ARCFileUploadController.getFilesAndDelete';

export default class ARCFileUploadComponent extends LightningElement {
    @api recordId;
    acceptedFormats;
    acceptedTypes;
    @track errorMsg;
    @track expiryDate;

    fileName ;
    typeoptions;
    uploadedFileIds = [];
    disableUploadFile = true;
    disableTypeselection = false;
    componentDocumentId;
    showFileNames = [];


    @api displayAddIcon = false;
    @api displayDeleteIcon = false;
    @api defaultRow = false;
    @api cmpInstanceId=null;

    connectedCallback(event) {
        console.log( "connectedCallback called here",this.recordId);
        //this.displayAddIcon = true;
    }

    @wire(getAvailableFileTypes, { recordid: '$recordId' })
    availabledata(value) {
        const {data, error}  = value ;
        //console.log( "#wire called 1" , data);
        if(data) {
            this.acceptedTypes = [...data];
            //console.log( "#acceptedTypes is" , this.acceptedTypes);
            this.typeoptions = [];
            this.acceptedTypes.sort().forEach((elem)=> {
                //console.log( "element is " , elem);
                this.typeoptions.push( { label: elem, value: elem } );
            });
        }
    }

    @wire(getAvailableFileFormats)
    availabledataformat(value) {
        const {data, error}  = value ;
        //console.log( "#wire called 2" , data);
        if(data) {
            this.acceptedFormats = [...data];
            //console.log( "#acceptedFormats is" , this.acceptedFormats);
        }
    }

    handleChange(event) {
        this.fileName = event.detail.value;
        console.log('File Name:',this.fileName);
        this.enableFileUpload(); // Call a function to check both conditions
    }

    handleExpiryDateChange(event) {
        this.expiryDate = event.target.value;
        console.log('Expiry Date:', this.expiryDate);
        this.enableFileUpload(); // Call a function to check both conditions
    }

    handleUploadFinished(event) {
        console.log("handleUploadFinished expiryDate:=> ",this.expiryDate,' recordId:',this.recordId);
        if (!this.expiryDate) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select an expiry date',
                    variant: 'error',
                }),
            );
            return;
        }
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;        
        //this.uploadedFileIds = [];
        for(let i = 0; i < uploadedFiles.length; i++) {
           this.uploadedFileIds.push(uploadedFiles[i].documentId);
        }
        console.log("documentIds: ",this.uploadedFileIds);        
        getFileTypeAndInsert( { fileName:this.fileName, expiryDate: this.expiryDate, uploadedFileIds:this.uploadedFileIds })
        .then(result => {
           console.log("Result: ",result);
           this.showFileNames = result;
           this.disableTypeselection = true;
        })
        .catch(error => {
            this.errorMsg = error;
        })
    }

    addRows(event) {
        console.log( 'add event fires here');
        let rowsToAdd = {
            instanceid: this.cmpInstanceId,
            isDisabled:true
        };
       // bookobjToDelete.RecordId = this.bookObjDetail.Id;
        this.dispatchEvent(new CustomEvent('addrowsclick', { detail : rowsToAdd} ));
    }

    deleteRows(event) {
        //console.log( 'delet event fires here');
        if(this.uploadedFileIds.length > 0){
            //console.log( "debug#1 ", JSON.stringify(this.uploadedFileIds));
            getFilesAndDelete( { fileIds:this.uploadedFileIds })
            .then(result => {
                let rowsToDelete = {
                    instanceid: this.cmpInstanceId                    
                };
                this.dispatchEvent(new CustomEvent('rowstodelete', { detail : rowsToDelete} ));
            })
            .catch(error => {
                this.errorMsg = error;
            })
        }else if(this.uploadedFileIds.length === 0) {
                let rowsToDelete = {
                    instanceid: this.cmpInstanceId
                    
                };
                this.dispatchEvent(new CustomEvent('rowstodelete', { detail : rowsToDelete} ));
        }
    }
    enableFileUpload() {
        if (this.fileName && this.expiryDate) {
            this.disableUploadFile = false; // Enable Upload
        } else {
            this.disableUploadFile = true; // Keep Disabled
        }
    }
}