import { LightningElement,track,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import getAccountPortfolioData from '@salesforce/apex/AccountBasedPortfolioClass.getAccountPortfolioData';
import createAccountPortfolioData from '@salesforce/apex/AccountBasedPortfolioClass.createAccountPortfolioData';
import getNonGeoPortfolioData from '@salesforce/apex/AccountBasedPortfolioClass.getNonGeoPortfolioData';
import startDatePastAllowed from '@salesforce/apex/AccountBasedPortfolioClass.startDatePastAllowed';
import isAllowedForNonGeographicData from '@salesforce/apex/AccountBasedPortfolioClass.isAllowedForNonGeographicData';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import AccountPortfolioAssignment_OBJECT from '@salesforce/schema/Account_Portfolio_Assignment__c';
import AccountBasedReason_FIELD from '@salesforce/schema/Account_Portfolio_Assignment__c.Account_Based_Reason__c';

export default class AccountBasedPortfolioAssignment extends LightningElement {

    

    
    accportfoliovalue = '';
    portfolioType = '';
   // AccountBasedReason = '';
    nongeoportfoliotypevalue = '';
    portfolioarray
    @api portfoliooptions;
    nongeodata;
    @api accrecordid;
    //@api AccountBasedReasons;
    @api accrecord;
    accountPortfolioWrapperobj;
	iserrormsg = false;
	errorMessageText;
	isLoading = false;
    isStartPastAllowed = false;
    accid=[];
    
    
    

    //isError = false;

    @track isTypeChanged = false;
    selectedReasons = '';
    _selected = [];
    



    // to get the default record type id, if you dont' have any recordtypes then it will get master
    

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
        this.iserrormsg = false;

        this.accountPortfolioWrapperobj = {};
        this.accountPortfolioWrapperobj.selectedPortfolioType ='';
        this.accountPortfolioWrapperobj.selectedAccountbasedreason = []; //9654
        this.accountPortfolioWrapperobj.accountRecid = '';
        this.accountPortfolioWrapperobj.portfolioRecId = '';
        this.accountPortfolioWrapperobj.Start_Date = '';
        this.accountPortfolioWrapperobj.End_Date = '';
        
}

    
    get portfolioTypeoptions(){
        return [
            { label:'Account Portfolio', value:'Account Manager' },
            //{ label:'Account Specialist', value:'Account Specialist' },HRP-6028
           // { label:'Supervisor', value:'Supervisor' },
            { label:'National Account Manager', value:'National Account Manager' },
            { label:'Sickle Cell Account Manager', value:'Sickle Cell Account Manager' },
            { label:'Booking Support', value:'Booking Support' },
            { label:'Fixed Site', value:'Fixed Site' },
            { label:'Relationship Manager', value:'Relationship Manager' }
        ];
    }
    
   /* get AccountBasedReasons(){
    
        return [
            { label:'Hospital Partner', value:'Hospital Partner' },
            { label:'Education Segment', value:'Education Segment' },
            { label:'Military Segment', value:'Military Segment' },
            { label:'Corporate Partner', value:'Corporate Partner' },
            { label:'Segmented Portfolio', value:'Segmented Portfolio' },
            { label:'Diversity Strategy', value:'Diversity Strategy' },
            { label:'Growth Strategy', value:'Growth Strategy' },
            { label:'BPL Request (rare)', value:'BPL Request (rare)' },
            { label:'Geographic Anomaly (very rare)', value:'Geographic Anomaly (very rare)' }
            
        ];

    }*/
    AccountBasedReasonChange(event){
        //this.selectedReasons = [];
        this._selected = event.detail.value;

       // console.log("this._selected : ", this._selected);
       
        /*console.log('this.__selected', this.__selected);
        //this.selectedReasons = event.detail.value;
        console.log('this.__selected2..', this._selected[0]);
        //this._selected.forEach(myfuction);
        
        for (let i = 0; i <= this.__selected.length; i++) {
            
            if(this.selectedReasons == null)
            {
                this.selectedReasons = "'";
            }
            if(i < this.__selected.length)
            {
            this.selectedReasons.concat(this._selected[i],";");
            }
            else
            {
                this.selectedReasons.concat(this._selected[i],"'");
            }
            }
        console.log("retriveeeeee..",this.selectedReasons);*/

       }
       
   

    portfolioTypeChange(event) {
        this.portfolioType = event.detail.value;	
        

        console.log('portfolioType',this.portfolioType);
        isAllowedForNonGeographicData()
        .then((result)=>{
            if(result === true ){                
                this.accid.push(this.accrecordid);  
                console.log('accid',this.accid);          
                getNonGeoPortfolioData({selectedPortfolioType:this.portfolioType,AccountId:this.accid})
                .then( (result)=>{
                    this.nongeodata = result;   
                    this.isLoading = false;  
                    this.isTypeChanged = true;    
                    
                    let portfolioarray = [];
                    if( this.nongeodata ){

                    this.nongeodata.forEach((elem)=>{
                        console.log('elem.Portfolio_Name',elem.Portfolio_Name);
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

    

    portfolioChange(event) {
        this.accportfoliovalue = event.detail.value;		
    }
    /*portfoliotypeChange(event){
        this.nongeoportfoliotypevalue = event.detail.value;
    }*/


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
        
            
        
        
    
            
        
        console.log('startDatePastAllowed',this.isStartPastAllowed);
		this.iserrormsg = false;
        this.errorMessageText = '';
		
        const localOffset = new Date().getTimezoneOffset(); // in minutes
        const localOffsetMillis = 60 * 1000 * localOffset;

        let accountPortfolioWrapperobjArray = [];
        this.accountPortfolioWrapperobj.selectedPortfolioType = this.portfolioType;
        this.accountPortfolioWrapperobj.selectedAccountbasedreason = this._selected;// 9654
        this.accountPortfolioWrapperobj.accountRecid = this.accrecord.Id;
        this.accountPortfolioWrapperobj.portfolioRecId = this.accportfoliovalue;
        this.accountPortfolioWrapperobj.Start_Date = this.template.querySelector(".portfoliostartdate").value ;
        this.accountPortfolioWrapperobj.End_Date = this.template.querySelector(".portfolioenddate").value ;        
        accountPortfolioWrapperobjArray.push(this.accountPortfolioWrapperobj);
        
		let st_date = this.template.querySelector(".portfoliostartdate").value;
        let ed_date = this.template.querySelector(".portfolioenddate").value ;
        let current_date = new Date();
        //console.log( 'st_date is ' , st_date,  ' getDate is ' , current_date.getDate(), ' getMonth is ' , current_date.getMonth(), ' fullyear is ' , current_date.getFullYear() );
        let start_Date = new Date(st_date);
        let end_Date = new Date(ed_date);
        
        let curr_year = current_date.getFullYear() ;
        let curr_month = current_date.getMonth()+1 ;
        curr_month = curr_month <10? '0'+ curr_month : curr_month;
        let curr_day = current_date.getDate() ;
        let cur_date = new Date( curr_year + '-' + curr_month + '-' + curr_day ); 

        let portStartDate;
        let portEndDate;
        console.log('Current Date is -> '+cur_date + ' ' +start_Date +' ' +end_Date);
        this.nongeodata.forEach((elem)=>{
            if(this.accportfoliovalue === elem.portfolioid){
                portStartDate = new Date(elem.Start_Date);
                portEndDate = new Date(elem.End_Date);
            }
        });

        
        start_Date = new Date(start_Date.getTime() + localOffsetMillis);
        end_Date = new Date(end_Date.getTime() + localOffsetMillis);
        cur_date = new Date(cur_date.getTime() + localOffsetMillis);
        portStartDate = new Date(portStartDate.getTime() + localOffsetMillis);
        portEndDate = new Date(portEndDate.getTime() + localOffsetMillis);
        
        let toast = false;
        let dateErrorMsg = '';
        if( end_Date.getTime() < start_Date.getTime() ){
            toast = true;
            dateErrorMsg = 'End Date cannot less than Start date';
        }else if( end_Date.getTime() < cur_date.getTime() ){
            toast = true;
            dateErrorMsg = 'End Date cannot be a past date';
        }else if(typeof portStartDate !== 'undefined' && (start_Date.getTime() < portStartDate.getTime() || end_Date.getTime() < portStartDate.getTime())){
            toast = true;
            dateErrorMsg = 'Start/End Date cannot be less than Portfolio Start Date '+ (portStartDate.getMonth() + 1) + '/' + portStartDate.getDate() + '/' +  portStartDate.getFullYear();
        }else if(typeof portEndDate !== 'undefined' && ( start_Date.getTime() > portEndDate.getTime() || end_Date.getTime() > portEndDate.getTime())){
            toast = true;
            dateErrorMsg = 'Start/End Date cannot be greater than Portfolio End Date '+(portEndDate.getMonth() + 1) + '/' + portEndDate.getDate() + '/' +  portEndDate.getFullYear();
        }else if(start_Date.getTime() < cur_date.getTime()){
            
           
            if(this.isStartPastAllowed==false){
            toast = true;
            dateErrorMsg = 'Start Date cannot be a past date';
            }
            
        }
        //HRP-9654
        if(this._selected.length == 0){
            this.showToast( 'Account Based Reason is required.', '', 'error');
            
        }
        //HRP-9654
        else if( toast ){
            this.showToast( dateErrorMsg, '', 'error');
        }
		else if( this.template.querySelector(".portfoliostartdate").value && this.template.querySelector(".portfolioenddate").value && this.accrecord.Id && this.accportfoliovalue){
            this.isLoading = true;
           
            createAccountPortfolioData( { accportfoliodata : JSON.stringify(accountPortfolioWrapperobjArray) } )
            .then((result)=>{
                this.isLoading = false;
                this.showToast('Account Portfolio record is created', '', 'success');
                this.closeQuickActionFunc();
            })
            .catch((error)=>{
                this.isLoading = false;
                let errorMessage;
                if ( error.body.message) {
                    errorMessage =error.body.message;
                }
                this.showToast('error in creating Account Portfolio record', errorMessage, 'error');
                this.closeQuickActionFunc();
            })
        }else{
            this.showToast('Please select all required fields', '', 'error');
        }


    }
    oncancelclick(event){
        this.closeQuickActionFunc();
    }

    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }

    closeQuickActionFunc(){
        let bookobjToDelete = {};
        this.dispatchEvent(new CustomEvent('closequickaction', { detail : bookobjToDelete} ));
    }
}