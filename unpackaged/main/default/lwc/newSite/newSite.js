import { LightningElement,api,wire,track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import SITE_OBJECT from '@salesforce/schema/sked__Location__c';

import predictCollectionOperation from '@salesforce/apex/NewSiteController.predictCollectionOperations';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NAME from '@salesforce/schema/sked__Location__c.Name';
import PHYSICAL_LOCATION_TYPE from '@salesforce/schema/sked__Location__c.sked_Physical_Location_Type__c';
import SITE_CONTACT from '@salesforce/schema/sked__Location__c.sked_Site_Contact__c';
import SITE_MAIN_PHONE from '@salesforce/schema/sked__Location__c.sked_Site_Main_Phone__c';
import ADDRESS1 from '@salesforce/schema/sked__Location__c.sked_Address_1__c';
import ADDRESS2 from '@salesforce/schema/sked__Location__c.sked_Address_2__c';
import CITY from '@salesforce/schema/sked__Location__c.sked_City__c';
import COUNTRY from '@salesforce/schema/sked__Location__c.sked_County__c';
import STATE from '@salesforce/schema/sked__Location__c.sked_State__c';
import ZIP_CODE from '@salesforce/schema/sked__Location__c.sked_Zip_Code__c';
import DAYS_OF_WEEK_PREFERRED from '@salesforce/schema/sked__Location__c.sked_Days_of_Week_Preferred__c';
import DAYS_OF_WEEK_DECLINED from '@salesforce/schema/sked__Location__c.sked_Days_of_Week_Declined__c';
import SITE_INSPECTION_COMPLETED_BY from '@salesforce/schema/sked__Location__c.sked_Site_Inspection_Completed_By__c';
import SITE_INSPECTION_COMPLETED_COMMENTS from '@salesforce/schema/sked__Location__c.sked_Site_Inspection_Comments__c';
import DATE_SITE_INSPECTION_COMPLETED from '@salesforce/schema/sked__Location__c.sked_Date_Site_Inspection_Completed__c';
import Outlets_110 from '@salesforce/schema/sked__Location__c.sked_110_outlets__c';
import Air_conditioned from '@salesforce/schema/sked__Location__c.sked_Air_conditioned__c';
import Outlets_220 from '@salesforce/schema/sked__Location__c.sked_220_outlets__c';
import Unavailable_911 from '@salesforce/schema/sked__Location__c.sked_911_Unavailable__c';
import ARC_Vehicle_Parking_Directions from '@salesforce/schema/sked__Location__c.sked_ARC_Vehicle_Parking_Directions__c';
import Elevator_Type from '@salesforce/schema/sked__Location__c.sked_Elevator_Type__c';
import Emergency_Contact from '@salesforce/schema/sked__Location__c.Emergency_Contact__c';
import Break_location from '@salesforce/schema/sked__Location__c.sked_Break_location__c';
import Elevator_Open from '@salesforce/schema/sked__Location__c.sked_Elevator_Open__c';
import Canteen_Requirements from '@salesforce/schema/sked__Location__c.sked_Canteen_Requirements__c';
import Elevator_Close from '@salesforce/schema/sked__Location__c.sked_Elevator_Close__c';
import SITE_BUILDING from '@salesforce/schema/sked__Location__c.sked_Site_Building_Name__c';
import FLOOR_DESCRIPTION from '@salesforce/schema/sked__Location__c.sked_Floor_Description__c';
import ROOM_NAME from '@salesforce/schema/sked__Location__c.sked_Room_Name__c';
import ROOM_SIZE from '@salesforce/schema/sked__Location__c.sked_Room_Size__c';
import AUTOMATION_SUITABLITY from '@salesforce/schema/sked__Location__c.sked_Automation_Suitability__c';
import WIRELESS_POLICY from '@salesforce/schema/sked__Location__c.sked_Wireless_Policy__c';
import DIRECTION_FROM_COLLECTION_OPERATION from '@salesforce/schema/sked__Location__c.sked_Directions_From_CollectionOperation__c';
import Equipment_X_Ray_Require from '@salesforce/schema/sked__Location__c.sked_Equipment_X_Ray_Required__c';
import Escort_Required from '@salesforce/schema/sked__Location__c.sked_Escort_Required__c';
import Floor_Covering_Requirement from '@salesforce/schema/sked__Location__c.sked_Floor_Covering_Requirement__c';
import Heat from '@salesforce/schema/sked__Location__c.sked_Heat__c';
import Inside_stairs from '@salesforce/schema/sked__Location__c.sked_Inside_stairs__c';
import Max_Auto_Machines from '@salesforce/schema/sked__Location__c.sked_Max_Auto_Machines__c';
import Maximum_Beds from '@salesforce/schema/sked__Location__c.sked_Maximum_Beds__c';
import Maximum_Booths from '@salesforce/schema/sked__Location__c.sked_Maximum_Booths__c';
import No_Cell_Phones from '@salesforce/schema/sked__Location__c.sked_No_Cell_Phones__c';
import Site_Food_Canteen_Other from '@salesforce/schema/sked__Location__c.sked_On_Site_Food_Canteen_Other__c';
import On_Site_Food_Canteen_Requirements from '@salesforce/schema/sked__Location__c.sked_On_Site_Food_Canteen_Requirements__c';
import Pay_for_Parking from '@salesforce/schema/sked__Location__c.sked_Pay_for_Parking__c';
import Outside_stairs from '@salesforce/schema/sked__Location__c.sked_Outside_stairs__c';
import Pay_for_Parking_Details from '@salesforce/schema/sked__Location__c.sked_Pay_for_Parking_Details__c';
import Pre_Drive_Security_Due_Date from '@salesforce/schema/sked__Location__c.sked_Pre_Drive_Security_Due_Date__c';
import Restroom_Location from '@salesforce/schema/sked__Location__c.sked_Restroom_Location__c';
import Safety_Emergency_Action_Plan from '@salesforce/schema/sked__Location__c.sked_Safety_Emergency_Action_Plan__c';
import Security_Directions from '@salesforce/schema/sked__Location__c.sked_Security_Directions__c';
import Security_Information_Needed from '@salesforce/schema/sked__Location__c.sked_Security_Information_Needed__c';
import Site_Close from '@salesforce/schema/sked__Location__c.sked_Site_Close__c';
import Site_Contact_Email from '@salesforce/schema/sked__Location__c.sked_Site_Contact_Email__c';
import Site_Contact_Phone from '@salesforce/schema/sked__Location__c.sked_Site_Contact_Phone__c';
import Site_Open from '@salesforce/schema/sked__Location__c.sked_Site_Open__c';
import Site_Room_Phone from '@salesforce/schema/sked__Location__c.sked_Site_Room_Phone__c';
import Sponsor_Security_Form_Required from '@salesforce/schema/sked__Location__c.Sponsor_Security_Form_Required__c';
import Staff_List from '@salesforce/schema/sked__Location__c.sked_Staff_List__c';
import Unloading_Conditions from '@salesforce/schema/sked__Location__c.sked_Unloading_Conditions__c';
import Staff_Personal_Parking_Directions from '@salesforce/schema/sked__Location__c.sked_Staff_Personal_Parking_Directions__c';
import Unloading_Directions_Details from '@salesforce/schema/sked__Location__c.sked_Unloading_Directions_Details__c';
import Fixed_Site_Appointment_Pattern from '@salesforce/schema/sked__Location__c.sked_Fixed_Site_Appointment_Pattern__c';
import On_Site_Food_Conditions from '@salesforce/schema/sked__Location__c.sked_On_Site_Food_Conditions__c';
import Operation_Type from '@salesforce/schema/sked__Location__c.Operation_Type__c';

import SOURCE from '@salesforce/schema/sked__Location__c.Source__c';

export default class NewSite extends LightningElement {

// objectApiName is "Account" when this component is placed on an account record page
    @api objectApiName;
    @api recordId;
    @api recordTypeId;
    collectionOperList = [];
    isMobile = false;
    isFixed = false;
    isModalOpen = true;
    isAlertOpen = false;
    isSpinner = false;
    @track disableButton = false;
    input ={};
    fields = [PHYSICAL_LOCATION_TYPE, SITE_CONTACT,SITE_MAIN_PHONE,ADDRESS1,ADDRESS2,CITY,COUNTRY,STATE,ZIP_CODE,
        DAYS_OF_WEEK_PREFERRED,DAYS_OF_WEEK_DECLINED,SITE_INSPECTION_COMPLETED_BY,SITE_INSPECTION_COMPLETED_COMMENTS,
        DATE_SITE_INSPECTION_COMPLETED,SITE_BUILDING,FLOOR_DESCRIPTION,ROOM_NAME,ROOM_SIZE,
        AUTOMATION_SUITABLITY,WIRELESS_POLICY,DIRECTION_FROM_COLLECTION_OPERATION,
        Outlets_110,Air_conditioned,Outlets_220,Unavailable_911,ARC_Vehicle_Parking_Directions,Elevator_Type,
        Break_location,Elevator_Open,Elevator_Close,Canteen_Requirements,Emergency_Contact,
        Equipment_X_Ray_Require,Floor_Covering_Requirement,Escort_Required,Heat,Inside_stairs,Max_Auto_Machines,
        Maximum_Beds,Maximum_Booths,No_Cell_Phones,Site_Food_Canteen_Other,On_Site_Food_Canteen_Requirements,
        Pay_for_Parking,Outside_stairs,Pay_for_Parking_Details,Pre_Drive_Security_Due_Date,Restroom_Location,
        Safety_Emergency_Action_Plan,Security_Directions,Security_Information_Needed,Site_Close,Site_Contact_Email,
        Site_Contact_Phone,Site_Open,Site_Room_Phone,Sponsor_Security_Form_Required,Staff_List,
        Unloading_Conditions,Staff_Personal_Parking_Directions,Fixed_Site_Appointment_Pattern, 
        On_Site_Food_Conditions,Operation_Type];
   
    connectedCallback(){
        
    }

    @wire(getObjectInfo, {objectApiName: SITE_OBJECT})
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.isModalOpen = true;
            const params = new Proxy(new URLSearchParams(window.location.search), {
                get: (searchParams, prop) => searchParams.get(prop),
              });
              this.recordTypeId = params.recordTypeId;

            let recordTypeName = data.recordTypeInfos[this.recordTypeId].name;
            recordTypeName == 'Mobile Site' ? this.isMobile = true : this.isMobile = false;
            recordTypeName == 'Fixed Site' ? this.isFixed = true : this.isFixed = false;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    };
    
  
    async handleSubmit(event) {
        this.disableButton = true;
        event.preventDefault(); 
        this.input = JSON.parse(JSON.stringify(event.detail.fields));
        this.input.Source__c = 'Custom New Form'
        this.template.querySelector('lightning-record-edit-form').submit(this.input);
        /*this.input.Source__c = 'Custom New Form';
        let tempArray =[{inputZipcode:this.input.sked_Zip_Code__c, address:this.input.sked_Address_1__c+', '+this.input.sked_City__c+', '+this.input.sked_State__c+', '+this.input.sked_County__c, collectionOprName :''}];
        let zip = this.input.sked_Zip_Code__c;
       await predictCollectionOperation({zipCode:zip})
        .then((result) => {
            if(result !=''){
                tempArray.forEach(element => {
                    element.collectionOprName = result;
                });
            }
        })
        .catch((error) => {
            console.log('error>>',error);
        });
        this.collectionOperList = tempArray;
        this.isAlertOpen = true;*/

    }

    openModal() {
        this.isModalOpen = true;
    }
    closeModal() {
        this.isModalOpen = false;
        window.history.back();
        this.isMobile = false;
    }
    closeAlert() {
        this.isAlertOpen = false;
    }
    
    confirm(){
        this.template.querySelector('lightning-record-edit-form').submit(this.input);
        this.closeAlert();
    }
    handleSucess(event){
        this.isSpinner = false;
        this.showToast('Success','Site Created Successfully '+'Id '+event.detail.id,'success');
        //this.closeModal();
        const value = event.detail.id;
        const valueChangeEvent = new CustomEvent("save", {
            detail: { value }
        });
        // Fire the custom event
        this.dispatchEvent(valueChangeEvent);
    }

    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message:message,
            variant:variant
        });
        this.dispatchEvent(event);
    }

    handleError(){
        setInterval(() => {
            this.disableButton = false;
        }, 3000);
    }
}