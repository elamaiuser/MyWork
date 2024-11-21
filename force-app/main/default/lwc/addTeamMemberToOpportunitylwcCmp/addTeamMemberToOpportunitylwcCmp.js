import { LightningElement, track, api, wire } from 'lwc';
import addOpportunityTeamMember from '@salesforce/apex/AddTeamMemberToOpportunity.addOpportunityTeamMember';

export default class AddTeamMemberToOpportunitylwcCmp extends LightningElement {
    @api opportunityids;
    @api TargetObjectName;

    userid;
    teamRoleName;
    accountaccesslevel;
    caseaccesslevel;
    blooddriveaccesslevel;

    connectedCallback(){
        
        this.TargetObjectName = 'user';
    }

    

    saveAndRedirect(event){

        var AddTeamMember={
            userId:this.userid,
            teamRole:this.teamRoleName,
            bloodDriveAccessLevel:this.blooddriveaccesslevel
            
        }
       
        // create List from concatenated string
        let oppids ;
        oppids = [];
        oppids = this.opportunityids.split(';');

        let updatedOppids = oppids.filter(elem=>{
            return elem !== '';
        });


        addOpportunityTeamMember({inputString:JSON.stringify(AddTeamMember) , selectedIdsList:updatedOppids })
        .then(result =>{
            console.log(result);
            const eventPayload = {};
            this.dispatchEvent(
            new CustomEvent('saveandredirect', {
                detail: { eventPayload }
            })
        );
         })
         .catch(error =>{
             this.errorMsg = error;
         })

        
    }

    choosenrecord(event){
        const choosenrecid = event.detail;
        console.log( "choosenrecid is ", choosenrecid.recordId);
        this.userid = choosenrecid.recordId;
    }

    get teamroleOptions(){
        return [
            { label:'District Manager', value:'District Manager' },
            { label:'Recruiter', value:'Recruiter' },
            { label:'Area Booking Manager', value:'Area Booking Manager' },
            { label:'Account Manager', value:'Account Manager' },
            { label:'Account Specialist', value:'Account Specialist' },
            { label:'National Account Manager', value:'National Account Manager' },
            { label:'Sickle Cell Account Manager', value:'Sickle Cell Account Manager' },
            { label:'Market Manager', value:'Market Manager' },
            { label:'Donor Recruitment Associate', value:'Donor Recruitment Associate' },
            { label:'Booking Support', value:'Booking Support'},
            { label:'Temporary Account Manager', value:'Temporary Account Manager' }
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


    teamRoleChangeHandler(event){
        this.teamRoleName = event.detail.value;;
    }
    // accountChangeHandler( event ){
    //     this.accountaccesslevel = event.detail.value;
    //     //console.log( "accountaccesslevel is ", accountaccesslevel );
    // }

    // caseChangeHandler( event ){
    //     this.caseaccesslevel = event.detail.value;
    //     //console.log( "caseaccesslevel is ", caseaccesslevel );
    // }

    opportunityChangeHandler( event ){
        this.blooddriveaccesslevel = event.detail.value;
        //console.log( "blooddriveaccesslevel is ", blooddriveaccesslevel );
    }
}