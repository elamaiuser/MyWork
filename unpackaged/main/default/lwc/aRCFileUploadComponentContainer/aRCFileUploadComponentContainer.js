import { LightningElement, track, api, wire } from 'lwc';

export default class ARCFileUploadComponentContainer extends LightningElement {
    @api recordId;

    @track iteratorObject;
    @track iteratorObjectArray;
    displaydeleteIconFirstrow = true;
    displaydeleteIconOtherrows = true;
    defaultRow=true;
    defaultRowOthers=false;
    disableDefaultAddbutton = false;
    hideDefaultRow = true;

    connectedCallback(){
        this.iteratorObjectArray = [];
        this.iteratorObject = {};

        
    }

    populateIteratorArray(event){
        console.log( 'add row here' , this.iteratorObjectArray.length );
        
        
        if( this.iteratorObjectArray.length == 0 && event.detail.instanceid == null ){ // check If Array Length is 0 , User clicked on Add files button of the default component
            //console.log( "rows added from First" ); 
            // create first Instance
            this.iteratorObject = {};
            this.iteratorObject.instanceid = 1;

            this.disableDefaultAddbutton = true;
            this.iteratorObjectArray.push( this.iteratorObject );
        }else if( event.detail.instanceid != null ){ // User clicked on Add files button of the other components    
           
            this.iteratorObject = {};
           
            let instanceid = event.detail.instanceid;
            
            //First step: set previous component disabled True, so User should not able to click on Add file button
            this.iteratorObjectArray.forEach( elem=>{
                if( elem.instanceid === instanceid ){
                    elem.isDisabled = event.detail.isDisabled;
                }
            });

            // create next component where disabled is default False, User can add files for next component
                instanceid = parseInt(instanceid) +  1;
                this.iteratorObject.instanceid = instanceid;
                this.iteratorObject.isDisabled = false;

                this.iteratorObjectArray.push( this.iteratorObject );
        }
    }

    deleteRows(event){
        //console.log( 'delete row here' , this.iteratorObjectArray.length ); 
        const result = this.iteratorObjectArray.filter(elem=>{
            if( elem.instanceid !== event.detail.instanceid ){
                return elem;
            }
        });
            
        this.iteratorObjectArray = result ;

        // Enable Add button for the last component
        let lastIndexOfArray ;
        if( this.iteratorObjectArray.length > 0 ){
            lastIndexOfArray = this.iteratorObjectArray.length-1;
            this.iteratorObjectArray[lastIndexOfArray].isDisabled = false;
        }
        
       

        if(this.iteratorObjectArray.length===0 && event.detail.instanceid !== null && this.hideDefaultRow === true){
            this.disableDefaultAddbutton = false;       
        }
        else if(this.iteratorObjectArray.length===0 && event.detail.instanceid === null){
            //close the modal
            console.log("closing the modal1");
            this.closeTheModal();
        }
        else if(this.iteratorObjectArray.length > 0 && event.detail.instanceid === null){
            this.hideDefaultRow = false;
        }
        else if(this.iteratorObjectArray.length === 0 && event.detail.instanceid !== null && this.hideDefaultRow === false){
            //close the modal
            console.log("closing the modal2");
            this.closeTheModal();
        }
    }

    closeTheModal(){
        console.log( 'Closing the modal event fires here');
        let closethemodalobj = {};
        this.dispatchEvent(new CustomEvent('closethemodal', { detail : closethemodalobj} ));
    }

}