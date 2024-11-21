import { LightningElement, track} from 'lwc';
import validateInput from '@salesforce/apex/BSFStagingSheetController.validateInput';
export default class BSFWeeklyStaffingRoleTimeReport extends LightningElement {
    @track wrapper = {};
    @track loaded = false;
    @track hasError = false;
    @track hasRecords = false;
    @track showPopup = false;
    @track errorMessageToDisplay = '';
    
    prepopulatevalues=false;
    frommobile = false;
    enablelastrow = true;

    connectedCallback () {
      this.initializeWrapper();
    }

    initializeWrapper () {
        this.wrapper = {
            'driveufid': '',
            'division': '',
            'region': '',
            'startDate' : this.getDate(),
            'endDate' : this.getDate(),
            'dristict' : [],
            'collectionop' : [],
            'driveappealyes' : true,
            'driveappealno' : false
        };
        this.loaded = false;
        this.hasRecords = false;
        this.hasError = false;
    }

    handleViewReport(){
        this.validate();
        console.log('showPopup '+this.showPopup);
    }

    handleClosePopupHandler(){
      this.showPopup = false;
    }

    handleResetValues (event) {
        console.log('change event RT '+JSON.stringify(event.detail));
        this.wrapper.startDate= this.getDate(); 
        this.wrapper.endDate= this.getDate(); 
        this.wrapper.division= '';
        this.wrapper.region= '';
        this.wrapper.dristict= [];
        this.wrapper.collectionop= [];
        this.hasError = false;
        this.hasRecords = false;
    }

    handleSelectedValues (event) {
      console.log('change event RT '+JSON.stringify(event.detail));
      this.wrapper.startDate= event.detail.startDate; 
      this.wrapper.endDate= event.detail.endDate; 
      this.wrapper.division= event.detail.division;
      this.wrapper.region= event.detail.region;
      this.wrapper.dristict= event.detail.dristict;
      this.wrapper.collectionop= event.detail.collectionop;
      this.wrapper.driveufid= event.detail.driveufid;
      this.wrapper.driveappealyes= event.detail.driveappealyes;
      this.wrapper.driveappealno= event.detail.driveappealno;
      this.hasError = false;
      this.hasRecords = false;
  }

    handleSearch (event) {
        if (event.target.name === 'search') {
            this.search();
        }
    }
    getDate () {
      let startDate = new Date();
      return startDate.toISOString().slice(0, 10);
    }

    exportToPdf () {
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getDate ();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getDate ();  

      let startdate = `${start}`;
      let enddate = `${end}`;

      let drvappeal;
      if(this.wrapper.driveappealyes === true && this.wrapper.driveappealno === false){
        drvappeal = 'Yes';
      }
      if(this.wrapper.driveappealyes === false && this.wrapper.driveappealno === true){
        drvappeal = 'No';
      }

      let clopids = `${this.wrapper.collectionop}`;
      let drvufid = `${this.wrapper.driveufid}`;

      window.open('/apex/BSFStagingSheetVF?startdate='+startdate+'&enddate='+enddate+'&appeal='+drvappeal+'&ufid='+drvufid+'&renderas=pdf&collopids='+clopids+'&force_download=true');
    }

    get getPopUpRedirectUrl () {
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getDate ();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getDate ();  

      let startdate = `${start}`;
      let enddate = `${end}`;

      let drvappeal;
      if(this.wrapper.driveappealyes === true && this.wrapper.driveappealno === false){
        drvappeal = 'Yes';
      }
      if(this.wrapper.driveappealyes === false && this.wrapper.driveappealno === true){
        drvappeal = 'No';
      }

      let clopids = `${this.wrapper.collectionop}`;
      let drvufid = `${this.wrapper.driveufid}`;

      return '/apex/BSFStagingSheetVF?startdate='+startdate+'&enddate='+enddate+'&appeal='+drvappeal+'&ufid='+drvufid+'&renderas=html&collopids='+clopids;
    }

    get disablePdfButton(){
        return !this.hasRecords;
    }
    
    validate () {
      this.loaded = true;
      this.hasRecords = false;
      console.log(JSON.stringify(this.wrapper));
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getDate ();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getDate ();  
      let drvappeal;
      if(this.wrapper.driveappealyes === true && this.wrapper.driveappealno === false){
        drvappeal = 'Yes';
      }
      if(this.wrapper.driveappealyes === false && this.wrapper.driveappealno === true){
        drvappeal = 'No';
      }
      validateInput({startDate : start, endDate: end, collOpIdList: `${this.wrapper.collectionop}`, ufid: `${this.wrapper.driveufid}`, appeal: drvappeal })
          .then(result => {
              console.log('result:-'+JSON.stringify(result));
              this.loaded = false;
              this.hasRecords = result;
              this.hasError = false;
              this.showPopup = true;
              console.log('hasRecords:-'+JSON.stringify(this.hasRecords));
          })
          .catch(error => {
              console.log(error);
              this.hasRecords = false;
              this.loaded = false;
              this.hasError = true;
              this.showPopup = false;
              this.errorMessageToDisplay = error.body.message;
              console.log(JSON.stringify(error));
          });
    }

}