import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import addAccountTeamMember from '@salesforce/apex/AddTeamMemberToAccount.addAccountTeamMember';
import getAccountNames from '@salesforce/apex/AddTeamMemberToAccount.getAccountNames';
import startDatePastAllowed from '@salesforce/apex/AccountBasedPortfolioClass.startDatePastAllowed';
import {fireEvent} from 'c/pubsub';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

export default class AddTeamMemberToAccountlwcCmp extends NavigationMixin(LightningElement) {
    @api accountIds;
    @api TargetObjectName;

    userid;
    teamRoleName;
    accountaccesslevel;
    caseaccesslevel;
    blooddriveaccesslevel;
    isPageLoading = false;
    accountnames;
    Start_Date;
    end_date;
    coveragereason;
    iserrormsg = false;
	errorMessageText;
    isStartDatePastAllowed;

    constructor() {
        super();
        startDatePastAllowed( { } )
        .then(result =>{
            console.log('startdateallowed',result);
            this.isStartDatePastAllowed = result;
        })
         .catch(error =>{
             this.errorMsg = error;
         })
    }

    connectedCallback(){
        this.isPageLoading = true;
        this.TargetObjectName = 'user';

        if( this.accountIds != null ){
            //this.isPageLoading = false;


            // create List from concatenated string
            let accids ;
            accids = [];
            
            accids = this.accountIds.split(';');
            let updatedaccids = accids.filter(elem=>{
                return elem !== '';
            });


            getAccountNames( { selectedIdsList : updatedaccids} )
            .then(result =>{
                console.log(result);
                this.accountnames = [];
                this.accountnames = result;

                this.isPageLoading = false;
             })
             .catch(error =>{
                 this.errorMsg = error;
             })



        }
    }

    @wire(CurrentPageReference) pageRef;

    saveAndRedirect(event){
        let st_date = this.template.querySelector(".accteamstartdate").value;
        let ed_date = this.template.querySelector(".accteamenddate").value ;
        var AddTeamMember={
            userId:this.userid,
            teamRole:this.teamRoleName,
            accountAccessLevel:this.accountaccesslevel,
            caseAccessLevel:this.caseaccesslevel,
            bloodDriveAccessLevel:this.blooddriveaccesslevel,
            coverageReason:this.coveragereason,
            startDate:st_date,
            endDate:ed_date
            
        }
       
        // create List from concatenated string
        let accids ;
        accids = [];
        console.log('Account Ids: ',this.accountIds);
        accids = this.accountIds.split(';');
        console.log( "acc ids " , accids);

        let updatedaccids = accids.filter(elem=>{
            return elem !== '';
        });

        console.log( "updatedaccids ids " , updatedaccids);

        if( !this.validateDates(event) && !this.validatecoverageblank(event) ){
            console.log( 'validate successfull' );
            this.iserrormsg = false;
            this.errorMessageText = '';
            console.log( 'AddTeamMember is ' , JSON.stringify(AddTeamMember) );
            addAccountTeamMember({inputString:JSON.stringify(AddTeamMember) , selectedIdsList:updatedaccids })
            .then(result =>{
                console.log(result);
                const eventPayload = {};
                this.dispatchEvent(
                    new CustomEvent('saveandredirect', {
                        detail: { updatedaccids }
                    })
                );
            })
            .catch(error =>{
                this.errorMsg = error;
                let errorMessage;
                if ( error.body.message) {
                    errorMessage =error.body.message;
                }
                this.iserrormsg = true;
                this.errorMessageText = errorMessage ;
            })
        }


        
    }

    choosenrecord(event){
        const choosenrecid = event.detail;
        console.log( "choosenrecid is ", choosenrecid.recordId);
        this.userid = choosenrecid.recordId;
    }

    get teamroleOptions(){
        return [
            { label:'Account Manager', value:'Account Manager' },
            { label:'District Manager', value:'District Manager' },
            { label:'Area Booking Manager', value:'Area Booking Manager' },
            { label:'Account Specialist', value:'Account Specialist' },
            { label:'National Account Manager', value:'National Account Manager' },
            { label:'Sickle Cell Account Manager', value:'Sickle Cell Account Manager' },
            { label:'Market Manager', value:'Market Manager' },
            { label:'Donor Recruitment Associate', value:'Donor Recruitment Associate' },
            { label:'Booking Support', value:'Booking Support'},
            { label:'Relationship Manager', value:'Relationship Manager' },
            { label:'Supervisor', value:'Supervisor' }
            
        ];
    }

    get accountaccessOptions(){
        return [
            { label:'Read/Write', value:'Edit'},
            { label:'Read Only', value:'Read'}
           
        ];
    }
    
    get otheraccessOptions(){
        return [
            { label:'Read/Write', value:'Edit'},
            { label:'Read Only', value:'Read'},            
            { label:'Private', value:'None'}
        ];
    }
    
    
    get coveragereasonoptions(){
        return [
            
            {label:'Leave of Absence (LOA)', value:'Leave of Absence (LOA)'},
            {label:'Vacant Territory', value:'Vacant Territory'}
        ];
    }


    teamRoleChangeHandler(event){
        this.teamRoleName = event.detail.value;
    }
    accountChangeHandler( event ){
        this.accountaccesslevel = event.detail.value;
        //console.log( "accountaccesslevel is ", accountaccesslevel );
    }

    caseChangeHandler( event ){
        this.caseaccesslevel = event.detail.value;
        //console.log( "caseaccesslevel is ", caseaccesslevel );
    }

    opportunityChangeHandler( event ){
        this.blooddriveaccesslevel = event.detail.value;
        //console.log( "blooddriveaccesslevel is ", blooddriveaccesslevel );
    }

    ondatechangehandle(event){
        
        this.validateDates(event);
        
    }

    coverageChangeHandler(event){

        this.coveragereason = event.detail.value;
        this.validatecoverageblank(event);
        
        //console.log( "coveragereason is ", coveragereason );
    }


    validatecoverageblank(event){
        this.iserrormsg = false;
        this.errorMessageText='';
        let cr = this.coveragereason;
        if( cr != 'Leave of Absence (LOA)' && cr != 'Vacant Territory')
        {
            this.iserrormsg = true;
            this.errorMessageText='Coverage reason cannot be blank for coverage recruiter';
        }
        if( this.iserrormsg ){
			this.showToast( this.errorMessageText, '', 'error');
		}

        return this.iserrormsg;
    }

    

    validateDates(event){
        this.iserrormsg = false;
        this.errorMessageText = '';

        let st_date = this.template.querySelector(".accteamstartdate").value;
        let ed_date = this.template.querySelector(".accteamenddate").value ;
        let current_date = new Date();
        //console.log( 'st_date is ' , st_date,  ' getDate is ' , current_date.getDate(), ' getMonth is ' , current_date.getMonth(), ' fullyear is ' , current_date.getFullYear() );
        let start_Date = new Date(st_date);
        let end_Date = new Date(ed_date);
        
        let curr_year = current_date.getFullYear() ;
        let curr_month = current_date.getMonth()+1 ;
        curr_month = curr_month <10? '0'+ curr_month : curr_month;
        let curr_day = current_date.getDate() ;
        let cur_date = new Date( curr_year + '-' + curr_month + '-' + curr_day ); 

        //console.log( 'curr date is ', cur_date );
        if( !this.isStartDatePastAllowed && ( start_Date.getTime() < cur_date.getTime() )){
            this.iserrormsg = true;
            this.errorMessageText = 'Start Date cannot be a past date';
        }
        else if( end_Date.getTime() < start_Date.getTime() ){
            this.iserrormsg = true;
            this.errorMessageText = 'End Date cannot less than Start date';
        }else if( end_Date.getTime() < cur_date.getTime() ){
            this.iserrormsg = true;
            this.errorMessageText = 'End Date cannot be a past date';
        }
		
		
        if( this.iserrormsg ){
			this.showToast( this.errorMessageText, '', 'error');
		}

        return this.iserrormsg;
    }
    
    
    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }

}