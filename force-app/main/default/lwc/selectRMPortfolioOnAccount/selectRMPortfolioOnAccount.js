import {api,LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPortfolioNames from '@salesforce/apex/AddUserToRMPortfolio.getPortfolioNames';
import createUserPortfolioMappingForRM from '@salesforce/apex/AddUserToRMPortfolio.createUserPortfolioMappingForRM';

export default class SelectRMPortfolioOnAccount extends LightningElement {
    userid;
    @api TargetObjectName;
    @api portfolioRecords = [];
    portfolioObjects;
    portfolioWrapperobj;
    isLoading = false;
    iserrormsg;
    errorMessageText;
    portfolioNames;
    startDate;
    endDate;

    
    connectedCallback(){
        
        this.TargetObjectName = 'user';
        this.isLoading = true;
        this.portfolioWrapperobj = {};

        console.log('portfolioRecordIds: ',this.portfolioRecords);

        if( this.portfolioRecords != null ){

            getPortfolioNames( { selectedIdsList : this.portfolioRecords} )
            .then(result =>{
                console.log(result);
                this.portfolioNames = [];
                this.portfolioNames = result;

                this.isLoading = false;
             })
             .catch(error =>{
                 this.errorMsg = error;
             })
        }
   
    }
	
    choosenrecord(event){
        const choosenrecid = event.detail;
        console.log( "choosenrecid is ", choosenrecid.recordId);
        this.userid = choosenrecid.recordId;
    }

    startDateChangeHandler( event ){
        this.startDate = event.detail.value;
        console.log( "startDate is ", this.startDate );
    }

    endDateChangeHandler( event ){
        this.endDate = event.detail.value;
        console.log( "endDate is ", this.endDate );
    }


    saveAndRedirect(event){
        this.iserrormsg = false;
        this.errorMessageText = '';
        let st_date = this.startDate;
        let ed_date = this.endDate;
        let current_date = new Date();
        console.log( 'st_date is ' , st_date,  ' getDate is ' , current_date.getDate(), ' getMonth is ' , current_date.getMonth(), ' fullyear is ' , current_date.getFullYear() );
        let start_Date = new Date(st_date);
        let end_Date = new Date(ed_date);


        if( end_Date.getTime() < start_Date.getTime() ){
            this.iserrormsg = true;
            this.errorMessageText = 'End Date cannot less than Start date';
        }

            var addUserToRMPortfolioWrapper={
                userId:this.userid,
                startDate:this.startDate,
                endDate:this.endDate               
            }
        //this.isLoading = true;
        if( !this.iserrormsg && this.template.querySelector(".portfoliostartdate").value && this.template.querySelector(".portfolioenddate").value){

            this.iserrormsg = false;
            this.errorMessageText = '';

            console.log('data is valid');

            createUserPortfolioMappingForRM({inputString:JSON.stringify(addUserToRMPortfolioWrapper) , selectedIdsList:this.portfolioRecords })
            .then(result =>{
                console.log(result);
                //this.isLoading = false;
                this.showToast('Toast Success','You have Successfully added User to all the below selected Portfolios!!','success');
                this.closeQuickActionFunc();
             })
             .catch(error =>{
                 this.errorMsg = error;
             })
        }
        else if(this.iserrormsg){
            this.iserrormsg = this.iserrormsg;
            this.errorMessageText = this.errorMessageText;
        }else{
            this.iserrormsg = true;
            this.errorMessageText = 'Please select all required fields';
        }



    }


    showToast(theTitle, theMessage, theVariant) {
        console.log('Inside showToast');

        this.dispatchEvent(
            new ShowToastEvent({
                      title: 'Success Toast',
                      message: theMessage,
                      variant: theVariant,
                      mode: 'dismissible'
                  })
        );          
    }
    onbackclick(event){
        this.closeQuickActionFunc();
    }

    closeQuickActionFunc(){
        console.log('Inside closeQuickActionFunc');
        let bookobjToDelete = {};
        this.dispatchEvent(new CustomEvent('closequickaction', { detail : bookobjToDelete} ));
    }
}