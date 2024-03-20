import { LightningElement, api, track, wire } from 'lwc';
import getAffiliations from '@salesforce/apex/ARCSearchAffiliationsClass.getAffiliations';
import getAffiliationTypes from '@salesforce/apex/ARCSearchAffiliationsClass.getAffiliationTypes';

export default class ARCSearchAffiliations extends LightningElement {
    @api rtypeid;
    @track typeoptions;
    @track affiliationvalues;
    initialized = false;
    @api isTemplate;
    @api currentrecordid;
    @api sobjectrecordid;
    @api affiliationid;affiliationvalues
    @api accountpostalcode;
    @api recruitedby;

    renderedCallback() {
        console.log('render called here #1');
        if (this.initialized) {
            return;
        }
        else{
            console.log('reInitialize false');

        }
        console.log('render called here #2');
        this.initialized = true;
        let listId = this.template.querySelector('datalist').id;
        this.template.querySelector(".afloptioncls").setAttribute("list", listId);
    }

    @wire( getAffiliationTypes, { objid: '$currentrecordid', isTemplate: '$isTemplate'} )
    affiliationtypes( {data, error} ){
        if(data){
            console.log( 'affilaition type are ====>', data );
            const affiliationtypevalues = data;
            let rtypeoptions = [];
            rtypeoptions.push( {label: '--select--', value:'none' } );
            affiliationtypevalues.forEach((elem)=>{
                rtypeoptions.push( { label:elem.rtypename, value:elem.rtypeid });
            });

            this.typeoptions = rtypeoptions;

        }else if (error){
            console.log( 'error occured while getAffiliationTypes===>', error );
        }
    }
    @wire( getAffiliations, { affiliationrecordtype: null, accountpostalcode: '$accountpostalcode', objid: '$currentrecordid', isTemplate: '$isTemplate'} )
    allaffiliations( {data, error} ){
        if(data){
            console.log( 'affilaition type are when wire called ====>', data );
            const afflvalues = data;
            let aflval = [];
            afflvalues.forEach( (elem)=>{
                aflval.push( { label:elem.recordname, value:elem.recordid} );
            });
            this.affiliationvalues = aflval;

        }else if (error){
            console.log( 'error occured while allaffiliations===>', error );
        }
    }

    handleChange(event){
        let rtypeid = event.detail.value != 'none' ? event.detail.value : null;
        console.log( 'rtypeid is now===> ' , rtypeid );
        this.affiliationvalues = [];            
        this.template.querySelector(".afloptioncls").value = null;        
        getAffiliations( { affiliationrecordtype: rtypeid, accountpostalcode: this.accountpostalcode, objid: this.currentrecordid, isTemplate: this.isTemplate} )
        .then((result)=>{
            console.log( 'affiliation options==>', result );
            const afflvalues = result;
            let aflval = [];
            afflvalues.forEach( (elem)=>{
                aflval.push( { label:elem.recordname, value:elem.recordid} );
            });
            this.affiliationvalues = aflval;
        })
        .catch((error)=>{
            console.log( 'error is ', error );
        });
    }

    handleAfflView(event){
        console.log( 'selected affiliation is ', event.target.value );
        const selcetedafl = event.target.value ;
        if(this.affiliationvalues){
            this.affiliationvalues.forEach( (elem)=>{
                if(elem.label === selcetedafl){
                    this.affiliationid = elem.value;
                }
            });
        }

        console.log( 'this.affiliationid is  ', this.affiliationid );
    }
    @api
    validate() {
    if(this.affiliationid) { 
        return { isValid: true }; 
    } 
    else {  
        return { 
            isValid: false, 
            errorMessage: 'Please select one affiliation to add.' 
         }; 
     }
    }
}