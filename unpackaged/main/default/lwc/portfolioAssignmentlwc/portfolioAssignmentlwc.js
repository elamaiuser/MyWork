import { LightningElement,track,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountInstances from '@salesforce/apex/AccountBasedPortfolioClass.getAccountInstances';
import createAccountPortfolioData from '@salesforce/apex/AccountBasedPortfolioClass.createAccountPortfolioData';
import getNonGeoPortfolioData from '@salesforce/apex/AccountBasedPortfolioClass.getNonGeoPortfolioData';
import isAllowedForNonGeographicData from '@salesforce/apex/AccountBasedPortfolioClass.isAllowedForNonGeographicData';
import startDatePastAllowed from '@salesforce/apex/AccountBasedPortfolioClass.startDatePastAllowed';
//import getBaseURLExternalform from '@salesforce/apex/AccountBasedPortfolioClass.getBaseURLExternalform';

//import { portfolio_map_filter } from './portfoliohelper';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import AccountPortfolioAssignment_OBJECT from '@salesforce/schema/Account_Portfolio_Assignment__c';
import AccountBasedReason_FIELD from '@salesforce/schema/Account_Portfolio_Assignment__c.Account_Based_Reason__c';



export default class PortfolioAssignmentlwc extends LightningElement {

    accportfoliovalue = '';
    portfolioType = '';
    nongeoportfoliotypevalue = '';
    @api portfoliooptions;
    nongeodata;
    iserrormsg;
    errorMessageText;
    isSuccessmsg;
    successMessageText="The Account portfolioassignments are successfully done"
    @api accrecords = [];
    accountObjects;
    accountPortfolioWrapperobj;
    isLoading = false;
    isStartPastAllowed = false;
    accid=[];

    selectedReasons = '';//HRP-9654
    _selected = []; ////HRP-9654


    @wire(getObjectInfo, { objectApiName: AccountPortfolioAssignment_OBJECT})
    AccountPortObj;

    @wire(getPicklistValues,

        {

            recordTypeId: '$AccountPortObj.data.defaultRecordTypeId', 

            fieldApiName: AccountBasedReason_FIELD

        }

    )
    acccountBasedReasonPicklist;

    connectedCallback(){
        this.isLoading = false;
        this.accountPortfolioWrapperobj = {};
        this.accountPortfolioWrapperobj.accountRecid = '';
        this.accountPortfolioWrapperobj.portfolioRecId = '';
        this.accountPortfolioWrapperobj.selectedAccountbasedreason = []; //9654
        this.accountPortfolioWrapperobj.Start_Date = '';
        this.accountPortfolioWrapperobj.End_Date = '';


        //console.log("account record id ", JSON.stringify(this.accrecords) );
        getAccountInstances( { accids: this.accrecords } )
        .then((result)=>{
            console.log( "result of account array ", JSON.stringify(result) );
            this.accountObjects = result;
            // getNonGeoPortfolioData()
            // .then( (result)=>{
            //     this.nongeodata = result;   
            //     this.isLoading = false;             
            // })
            // .catch((error)=>{
            //     let errorMessage;
            //     if ( error.body.message) {
            //         errorMessage =error.body.message;
            //     }
            //     this.showToast('error in retrieving Non Geographical data', errorMessage, 'error');
            // })
        })
        .catch((error)=>{

        })

    }

    get portfolioTypeoptions(){
        /*return [
            { label:'Account Portfolio', value:'Account Portfolio' },
            { label:'Account Specialist', value:'Account Specialist' },
            { label:'Fixed Site Portfolio', value:'Fixed Site Portfolio' },
           // { label:'Supervisor', value:'Supervisor' },
            { label:'National Account Manager', value:'National Account Manager' },
            { label:'Sickle Cell Account Manager', value:'Sickle Cell Account Manager' },
            { label:'Booking Support', value:'Booking Support'},
            { label:'Relationship Manager', value:'Relationship Manager' }
        ];*/

        return [
            { label:'Account Portfolio', value:'Account Manager' },
            //{ label:'Account Specialist', value:'Account Specialist' },HRP-6028
           // { label:'Supervisor', value:'Supervisor' },
            { label:'National Account Manager', value:'National Account Manager' },
            { label:'Sickle Cell Account Manager', value:'Sickle Cell Account Manager' },
            { label:'Booking Support', value:'Booking Support'},
            { label:'Fixed Site', value:'Fixed Site' },
            { label:'Relationship Manager', value:'Relationship Manager' }
        ];
    }

    /*get portfoliooptions() {
        let portfolioarray = [];
        if( this.nongeodata ){
            this.nongeodata.forEach((elem)=>{
                portfolioarray.push( { label: elem.Portfolio_Name , value: elem.portfolioid } );                
            });
        }
        return portfolioarray;
    }*/

    portfolioChange(event) {
        this.accportfoliovalue = event.detail.value;		
    }

    AccountBasedReasonChange(event){
        //this.selectedReasons = [];
        this._selected = event.detail.value;
        console.log(" this._selected....", this._selected );
    }
    // portfoliotypeChange(event){
    //     this.nongeoportfoliotypevalue = event.detail.value;
    // }

    portfolioTypeChange(event) {
        this.portfolioType = event.detail.value;	
        

        console.log('portfolioType',this.portfolioType);
        isAllowedForNonGeographicData()
        .then((result)=>{
            if(result === true ){                
                getNonGeoPortfolioData({selectedPortfolioType:this.portfolioType,AccountId:this.accrecords})
                .then( (result)=>{
                    this.nongeodata = result;   
                    this.isLoading = false;  
                    this.isTypeChanged = true;    
                    
                    let portfolioarray = [];
                    if( this.nongeodata ){

                    this.nongeodata.forEach((elem)=>{
                        portfolioarray.push( { label: elem.Portfolio_Name , value: elem.portfolioid } );                
                    });

                    console.log('PortfolioArray:',JSON.stringify(portfolioarray));

                    this.portfoliooptions = [];

                    this.portfoliooptions = [...portfolioarray];

                    console.log('Portfolios: ',this.portfoliooptions)
        }

                })
            }else{
                this.iserrormsg = true;
                this.errorMessageText = 'You are not authorized';
			}
        })
        .catch((error)=>{

        })  

    }

    StartDateChange(event) {
        startDatePastAllowed()
            .then(result => {
                this.isStartPastAllowed = result;
                console.log('startDatePastAllowed',result);
                console.log('startDatePastAllowed',this.isStartPastAllowed);
            })
            .catch(error => {
                this.error = error;
            });
       	
    }

    onsaveclick(event){
        this.iserrormsg = false;
        this.errorMessageText = '';
        let accountPortfolioWrapperobjArray = [];
        console.log('portfolioType: ',this.accountPortfolioWrapperobj.selectedPortfolioType);
        let st_date = this.template.querySelector(".portfoliostartdate").value;
        let ed_date = this.template.querySelector(".portfolioenddate").value ;
        let current_date = new Date();
        console.log( 'st_date is ' , st_date,  ' getDate is ' , current_date.getDate(), ' getMonth is ' , current_date.getMonth(), ' fullyear is ' , current_date.getFullYear() );
        let start_Date = new Date(st_date);
        let end_Date = new Date(ed_date);
        
        let curr_year = current_date.getFullYear() ;
        let curr_month = current_date.getMonth()+1 ;
        curr_month = curr_month <10? '0'+ curr_month : curr_month;
        let curr_day = current_date.getDate() ;
        let cur_date = new Date( curr_year + '-' + curr_month + '-' + curr_day ); 

        

        //console.log( 'curr date is ', cur_date );
        /*if( start_Date.getTime() < cur_date.getTime() ){
            this.iserrormsg = true;
            this.errorMessageText = 'Start Date cannot be a past date';
        }*/
        if( end_Date.getTime() < start_Date.getTime() ){
            this.iserrormsg = true;
            this.errorMessageText = 'End Date cannot less than Start date';
        }else if( end_Date.getTime() < cur_date.getTime() ){
            this.iserrormsg = true;
            this.errorMessageText = 'End Date cannot be a past date';
        }else if(this.isStartPastAllowed==false && (start_Date.getTime() < cur_date.getTime()) ){
            this.iserrormsg = true;
            this.errorMessageText = 'Start Date cannot be a past date';
        }
         
        this.accrecords.forEach((item)=>{
            this.accountPortfolioWrapperobj = {};
            this.accountPortfolioWrapperobj.accountRecid = item;
            this.accountPortfolioWrapperobj.portfolioRecId = this.accportfoliovalue;
            this.accountPortfolioWrapperobj.selectedAccountbasedreason = this._selected;// HRP-9654
            this.accountPortfolioWrapperobj.Start_Date = this.template.querySelector(".portfoliostartdate").value ;
            this.accountPortfolioWrapperobj.End_Date = this.template.querySelector(".portfolioenddate").value ; 
            this.accountPortfolioWrapperobj.selectedPortfolioType = this.portfolioType;
            accountPortfolioWrapperobjArray.push(this.accountPortfolioWrapperobj);
        });

        if(this._selected.length == 0){
            // console.log("this._selected",this._selected.length);
           // this.showToast( 'Account Based Reason is required.', '', 'error');
           this.iserrormsg=true;
           this.errorMessageText='Account Based Reason is required.';
             
         }
       else if( !this.iserrormsg && this.template.querySelector(".portfoliostartdate").value && this.template.querySelector(".portfolioenddate").value && accountPortfolioWrapperobjArray.length > 0 && this.accportfoliovalue){
            this.iserrormsg = false;
            this.errorMessageText = '';
            this.isLoading = true;
            createAccountPortfolioData( { accportfoliodata : JSON.stringify( accountPortfolioWrapperobjArray ) } )
            .then((result)=>{
                this.isLoading = false;
                this.isSuccessmsg=true;
                
                /*const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'The Account Portfolio Assignments are successfully done ',
                    variant: 'success'
                });
                this.dispatchEvent(event);*/
                this.closeQuickActionFunc();
                
            })
            .catch((error)=>{
                this.isLoading = false;
                let errorMessage;
                if ( error.body.message) {
                    errorMessage =error.body.message;
                }
                this.showToast('error in creating Account Portfolio record', errorMessage, 'error');
            })
        }else if(this.iserrormsg){
            this.iserrormsg = this.iserrormsg;
            this.errorMessageText = this.errorMessageText;
            this.showToast('Error', errorMessageText, 'error');
        }else {
            this.iserrormsg = true;
            this.errorMessageText = 'Please select all required fields';
        }
        

    }
    // oncancelclick(event){
    //     this.closeQuickActionFunc();
    // }

    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }
    onbackclick(event){
        this.closeQuickActionFunc();
    }

   

    closeQuickActionFunc(){
        let bookobjToDelete = {};
        this.dispatchEvent(new CustomEvent('closequickaction', { detail : bookobjToDelete} ));
    }
    

}