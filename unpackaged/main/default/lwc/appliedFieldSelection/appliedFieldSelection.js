import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldsFromFieldSets from '@salesforce/apex/FutureDrivesController.getFieldsFromFieldSets';

export default class AppliedFieldSelection extends LightningElement {

    _selected = [];
    fieldresult;
    @track fieldnames = [];
    @track defaultOptions=[];
    doselect = true;
    dodeselect = false;

    connectedCallback(){

        getFieldsFromFieldSets()
        .then( (result)=>{
            this.fieldresult = result;
            result.forEach( (item)=>{
                this.fieldnames.push( { label: item.fieldlabel , value: item.fieldapiname } );
            });
            this.fieldnames.push( { label: 'Drive Affiliations' , value: 'Drive Affiliations' } );
        this.fieldnames.push( { label: 'Drive Service Roles' , value: 'Drive Service Roles' } );
        })
        .catch( (error)=>{

        })
    }
    get fieldsapinames() {
        
        return this.fieldnames;
    }
    get allfieldsapinames(){
        return this.defaultOptions;
    }

    get selected() {
        return this._selected.length ? this._selected : 'none';
    }

    handleChange(e) {
        this._selected = e.detail.value;
        //console.log( 'field selection is ' , JSON.stringify( this._selected ) );
        //let isdisable = this._selected.length ? false : true;
        let selectionarray = [ ...this._selected ];
        
        //console.log( 'field selection is ' , selectionarray );

        let fieldsopted = {};
        fieldsopted.selectedfields = selectionarray;
        this.dispatchEvent(new CustomEvent('selectionfields', { detail : fieldsopted} ));
       

    }
    selectallnow(event){
        this.doselect = false;
        this.dodeselect = true;
        this.defaultOptions = [];

        this.fieldnames.forEach( (item)=>{
            //this.defaultOptions.push( { label: item.fieldlabel , value: item.fieldapiname }  );
            this.defaultOptions.push( item.value  );
        });

        // console.log( 'this.defaultOptions is before ' + this.defaultOptions );
        // console.log( 'this._selected is before ' + this._selected );

        this._selected = [...this.defaultOptions];

        // console.log( 'this._selected is after ' + this._selected );
        // console.log( 'this.defaultOptions is after ' + this.defaultOptions );
        // console.log( 'this._selected is after 2 ' + this._selected );

        let fieldsopted = {};
        fieldsopted.selectedfields = this._selected;
        this.dispatchEvent(new CustomEvent('selectionfields', { detail : fieldsopted} ));
        
    }

    deselectallnow(event){
        this.doselect = true;
        this.dodeselect = false;

        this.defaultOptions = [];
        this._selected = [];

        //console.log( 'this._selected is after 3 ' + this._selected );

        let fieldsopted = {};
        fieldsopted.selectedfields = this._selected;
        this.dispatchEvent(new CustomEvent('selectionfields', { detail : fieldsopted} ));


    }
}