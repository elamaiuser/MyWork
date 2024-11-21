import { LightningElement, track, api, wire} from 'lwc';
//import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Account_Type from '@salesforce/schema/Account.Type';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Opp_Type from '@salesforce/schema/Opportunity.Type_of_Drive__c';
import getOpptiesForPromotion from '@salesforce/apex/OpportunityForPromotion.getOpptiesForPromotion';
import getRegionDistricCollOpp from '@salesforce/apex/OpportunityForPromotion.getRegionDistricCollOpp';

import applyOppPromotion from '@salesforce/apex/OpportunityForPromotion.applyOppPromotion';

const columns = [
    
    { label: 'Name', fieldName: 'drivenanme', editable:true},
    { label: 'StageName', fieldName: 'drivestage'},
    { label: 'Drive Date', fieldName: 'drivedate'},
    { label: 'Quantity', fieldName: 'quantity',editable: true},
    { label: 'Delivery ID', fieldName: 'deliveryId',editable: true}

    ];
    console.log('columns '+ JSON.stringify(columns));
    
export default class ApplyToEnMassContainer extends LightningElement {
    
    @track options = [
        { label: '', value:null},
        { label: 'Mobile Opp', value: 'Mobile Opp' },
        { label: 'Fixed Site Opp', value: 'Fixed Site Opp' },
        { label: 'Mobile Opp & Fixed Site Opp', value: 'Mobile Opp & Fixed Site Opp' },
    ];
    @api recordId;
    @track AccType;
    @track AccType1;
    @track TypDrive;
    @track TypDrive1=[];
    @track TypDrive2=[];
    @track TypDrive3;
    @track region ='';
    @track region1;
    @track district;
    @track distric1;
    @track collOpp;
    @track collOpp1;
    @track error;
    @track picklistValue;
    @track values;
    @track data;
    columns = columns;
    @track lstSelectedRec;
    draftValues = [];
    selecteddatas;
    isError = false;
    

    
    @wire(getPicklistValues, {
        recordTypeId : '012000000000000AAA',
        fieldApiName : Account_Type
    })
        wiredAccount({ error, data }) {
            if (data) {
                //console.log(' Picklist values for account types are ', JSON.stringify(data.values));
                this.AccType = [ { label: '', value:null}, ...data.values];
                this.error = undefined;
                
            } else if (error) {
                console.log(` Error while fetching Picklist values  ${error}`);
                this.error = error;
                this.AccType = undefined;
                
            }
        }
    @wire(getPicklistValues, {
        recordTypeId : '012000000000000AAA',
        fieldApiName : Opp_Type
    })
        wiredOpportunity({ error, data }) {
            if (data) {
                    //console.log(` Picklist values for opportunity types are `, JSON.stringify(data.values));
                    this.TypDrive = data.values;
                    this.error = undefined;
                    
            } else if (error) {
                    console.log(` Error while fetching Picklist values  ${error}`);
                    this.error = error;
                    this.TypDrive = undefined;
                    
            }
        }
        


        getRegionDistricCollOpp(result) {
            let RegionPicklist=[];
            if (result.data) {
                console.log('checking ',JSON.stringify(result.data));
                RegionPicklist = [ { label: 'Select State', value: '', selected: true }, ...result.data.values[key].region ];
            } else if (result.error) {
                alert('ERROR');
            }
            console.log('RegionPicklist',RegionPicklist);
        }
        
        @wire (getRegionDistricCollOpp) wiredOpp({data,error}){
                if (error) {
                    console.log(error);
                }
				if (data) {
                       
                        //console.log( 'wiredopp data is ', JSON.stringify(data) );
                         let options_region =[];
                         let options_district =[];
                         let options_collection =[];
                         for (var key in data) {
                            if(data[key].region != 'null' ){
                                options_region.push({ label: data[key].region, value: data[key].region  });
                            }
							if(data[key].district != 'null' ){
                                options_district.push({ label: data[key].district, value: data[key].district  });
                            }
							 if(data[key].collOpp != 'null' ){
                                options_collection.push({ label: data[key].collOpp, value: data[key].collOpp  });
                            }
                        }
                        
                        var result = options_region.reduce((unique, o) => {
                            if(!unique.some(obj => obj.label === o.label && obj.value === o.value)) {
                              unique.push(o);
                            }
                            return unique;
                        },[]);
                        this.region=[ { label: '', value:null}, ...result];

                        var result1 = options_district.reduce((unique, o) => {
                            if(!unique.some(obj => obj.label === o.label && obj.value === o.value)) {
                              unique.push(o);
                            }
                            return unique;
                        },[]);
                        this.district=[ { label: '', value:null}, ...result1];
                        var result2 = options_collection.reduce((unique, o) => {
                            if(!unique.some(obj => obj.label === o.label && obj.value === o.value)) {
                              unique.push(o);
                            }
                            return unique;
                        },[]);
                        this.collOpp=[ { label: '', value:null}, ...result2];
                }
        }
        
          
        handleChange(event) {
                   
                this.AccType1=event.target.value;
            
        }
        handleChange1(event) {
           
            this.TypDrive3=event.target.value;
            //alert('Record type 3 ',this.TypDrive3);
        
        }
        handleChange2(event) {
        
            this.region1=event.target.value;
            //console.log('the new region value',this.region1)
            
        }
        handleChange3(event) {
        
            this.district1=event.target.value;
            //console.log('the new district value',this.district1);
        }
        handleChange4(event) {
        
            this.collOpp1=event.target.value;
            //console.log('the new collOpp1 value',this.collOpp1);
        }
        

    handleClick() {
        //console.log("drivetype234" + JSON.stringify(this.TypDrive1));
        //console.log('the type drive 222 ',this.TypDrive2);
        
        //console.log('recordid ',this.recordId,' ','acctype ',this.AccType1, ' ','drivetype',this.TypDrive3,' ','region ',this.region,' ' +'district ', this.district ,' ', 'collection opp' ,this.collOpp);
        getOpptiesForPromotion ({ recordid: this.recordId,acctype:this.AccType1,recordtype:this.TypDrive3, region:this.region1 , district:this.district1,collOpp:this.collOpp1 })
            .then((result) => {
                this.data = result;
                this.error = undefined;
                //console.log('check result::' , result);

            })
            .catch((error) => {
                this.error = error;
                this.data = undefined;
            });
    }
    handleSave1(event) {
        //console.log( 'event detail is ', JSON.stringify( event.detail.draftValues ) );
        const recordInputs =  event.detail.draftValues.slice().map(draft => {
           // console.log( 'draft valu is ' , draft );
            return draft ;            
        });
        //this.lstSelectedRec = recordInputs;
        
        console.log('recordInputs are::'+ JSON.stringify(event.detail.draftValues ) );
        //console.log('draft::'+recordInputs[0].deliveryId);
        var check = true;
        this.isError = false ;

        for ( var i = 0; i < recordInputs.length; i++ ) {
        
            if ( recordInputs[i].deliveryId != 'Drive' && recordInputs[i].deliveryId != 'AM' && recordInputs[i].deliveryId != 'Other'  ) {
                //console.log('deliveryId is 1',recordInputs[i].deliveryId);
                
                const evt = new ShowToastEvent({
                    message: 'You cannot give deliveryId other than AM/Drive/Other',
                    variant: 'error',
                });
                this.dispatchEvent( evt );
                check = false;
                this.isError = true;
            }
        }
        if ( check == true ) {
            this.isError = false;
            const evt = new ShowToastEvent({
                message: 'Record Saved',
                variant: 'success',
            });
            this.dispatchEvent( evt );

            this.lstSelectedRec = recordInputs;
                let driveidaaray = [];
                this.lstSelectedRec.forEach( (item)=>{
                    driveidaaray.push(item.driveid);
                });

                //console.log( 'driveidaaray is ', driveidaaray );

                let driveidobjectmap = new Map();
                this.lstSelectedRec.forEach( (item)=>{
                    driveidobjectmap.set( item.driveid, item );
                });

                //console.log( 'driveidobjectmap is ', driveidobjectmap );

                let modifieddata = [];
                this.data.forEach( (dataitem)=>{
                    let item = {... dataitem} ;
                    if( driveidaaray.includes( item.driveid ) ){
                        //console.log( 'obj is ' , JSON.stringify( driveidobjectmap.get(item.driveid) )  );
                        let editablefieldobj = driveidobjectmap.get(item.driveid) ;
                        //console.log( 'quantity is ' , editablefieldobj.quantity );
                        if( editablefieldobj.quantity ){
                            //console.log( 'quantity is inside ', editablefieldobj.quantity  );
                            item.quantity = editablefieldobj.quantity ;
                            //console.log( 'quantity is inside 2 ', editablefieldobj.quantity  );
                        }
                        
                        if( editablefieldobj.deliveryId ){
                            item.deliveryId = editablefieldobj.deliveryId ;
                            //console.log('delivery Id ',item.deliveryId);
                        }
                        
                    }

                    modifieddata.push(item);
                });
                this.data = modifieddata ;
                //console.log( 'updated data is ' , JSON.stringify( this.data ) );
        }


        
        
    }
    getSelectedName(event) {
        let selectedrowdriveids = [];
        let driveidobjectmap = new Map(); 
        this.selecteddatas = [];
        const selectedRows = event.detail.selectedRows;
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            //console.log('You selected: ' , selectedRows[i] );
            this.selecteddatas.push( selectedRows[i] );
            selectedrowdriveids.push( selectedRows[i].driveid);
            driveidobjectmap.set( selectedRows[i].driveid, selectedRows[i]  );
        }
        let modifieddatas = [];
        this.data.forEach( (items)=>{
            if( selectedrowdriveids.includes(items.driveid) ){
                modifieddatas.push( driveidobjectmap.get(items.driveid) );
            }else{
                modifieddatas.push(items);
            }
        });

        this.data = modifieddatas ;
    }
    /*getSelectedRec() {
        var selectedRecords =  
      this.template.querySelector("lightning-datatable").getSelectedRows();  
      console.log('selectedRecords are ',selectedRecords);
      this.lstSelectedRec = selectedRecords;
    }
    handleRemove(event){
        const valueRemoved = event.target.name;
        this.TypDrive1.splice(this.TypDrive1.indexOf(valueRemoved), 1);
    }*/
    
    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }

    applynow(event){
        if( this.isError == false){
            let modifieddatas = [];
            this.data.forEach( (dataitem)=>{
                this.selecteddatas.forEach( (selitem)=>{
                    if( selitem.driveid === dataitem.driveid ){
                        modifieddatas.push( dataitem );
                    }
                });
            });

            console.log('promotion recordid ',this.recordId);
            //var selectedRecords = modifieddatas; // this.selecteddatas; //this.template.querySelector("lightning-datatable").getSelectedRows();  
            this.lstSelectedRec = modifieddatas;
            console.log('modifieddatas ',JSON.stringify(modifieddatas));
            console.log('list of opp record to apply ',JSON.stringify( this.lstSelectedRec));
            this.isLoading = true;
            
            applyOppPromotion( { Opportunities: JSON.stringify( this.lstSelectedRec),recordid: this.recordId } )
            
            .then( (result)=>{
                this.isLoading = false;
                this.showToast('Opportunity Promotion applied successfully', '', 'success');
                this.closeQuickActionFunc();
            })
            .catch( (error)=>{
                this.isLoading = false;
                let errorMessage;
                if ( error.body.message) {
                    errorMessage =error.body.message;
                }
                this.showToast('error in error in applying opportunity promotion', errorMessage, 'error');
            })
        }else{
            const evt = new ShowToastEvent({
                message: 'You cannot give deliveryId other than AM/Drive/Other',
                variant: 'error',
            });
            this.dispatchEvent( evt );
        }
          

        
    }
    oncancelclick(event){
        this.closeQuickActionFunc();
    }

    closeQuickActionFunc(){
        let bookobjToDelete = {};
        this.dispatchEvent(new CustomEvent('closequickaction', { detail : bookobjToDelete} ));
    }
}