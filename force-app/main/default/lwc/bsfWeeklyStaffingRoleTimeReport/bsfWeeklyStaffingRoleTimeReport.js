import { LightningElement, track, api} from 'lwc';
import searchRoleTimeReport from '@salesforce/apex/BSFWeeklyStaffingRoleTimeController.searchRoleTimeReport';
export default class BSFWeeklyStaffingRoleTimeReport extends LightningElement {
    @track wrapper = {};
    @track dataArry=[];
    @track loaded = false;
    @track hasError = false;
    @track hasRecords = false;
    @track hasLunchBreak = false;
    @track showPopup = false;
    @track errorMessageToDisplay = '';
    @track prepopulatevalues=false;
    @api vfdata;
    @api selecteddivision;
    @api selectedregion;
    @api selecteddistict;
    @api selectedcollopp;
    @api selectedstartdate;
    @api selectedenddate;
    @api selecteddrivetype;
    @api selecteddrivedispatched;
    @api frommobile = false;

    isInitialized = false;
    enablelastrow = true;

    connectedCallback () {
      if(this.vfdata === 'true'){
        this.prepopulatevalues = true;
      }
      this.initializeWrapper();
    }

    renderedCallback(){
      if(!this.isInitialized && this.prepopulatevalues){
        if(this.selecteddivision != null && this.selectedregion != null && this.selecteddistict != null
            && this.selectedcollopp != null && this.selectedstartdate != null && this.selectedenddate != null
            && this.selecteddrivetype != null && this.selecteddrivedispatched != null){
              this.search();
        }
      }
      this.isInitialized = true;
    }

    initializeWrapper () {
        this.wrapper = {
            'division': '',
            'region': '',
            'startDate' : this.getDate(),
            'endDate' : this.getDate(),
            'dristict' : [],
            'collectionop' : [],
            'drivetype' : [],
            'drivedispatchyes' : true,
            'drivedispatchno' : false
        };
        this.loaded = false;
        this.hasRecords = false;
        this.hasError = false;
        this.hasLunchBreak = false;
    }

    handleViewPdf(){
        this.showPopup = true;
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
        this.wrapper.drivetype= [];
        this.wrapper.drivedispatchyes= true;
        this.wrapper.drivedispatchno= false;
        this.hasError = false;
        this.hasRecords = false;
        this.hasLunchBreak = false;
    }

    handleSelectedValues (event) {
      console.log('change event RT '+JSON.stringify(event.detail));
      this.wrapper.startDate= event.detail.startDate; 
      this.wrapper.endDate= event.detail.endDate; 
      this.wrapper.division= event.detail.division;
      this.wrapper.region= event.detail.region;
      this.wrapper.dristict= event.detail.dristict;
      this.wrapper.collectionop= event.detail.collectionop;
      this.wrapper.drivetype= event.detail.drivetype;
      this.wrapper.drivedispatchyes= event.detail.drivedispatchyes;
      this.wrapper.drivedispatchno= event.detail.drivedispatchno;
      this.hasError = false;
      this.hasRecords = false;
      this.hasLunchBreak = false;
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

      let drvdisp;
      if(this.wrapper.drivedispatchyes === true && this.wrapper.drivedispatchno === true){
        drvdisp = 'Both';
      } 
      if(this.wrapper.drivedispatchyes === true && this.wrapper.drivedispatchno === false){
        drvdisp = 'Yes';
      }
      if(this.wrapper.drivedispatchyes === false && this.wrapper.drivedispatchno === true){
        drvdisp = 'No';
      }

      let drivetypes = `${this.wrapper.drivetype}`;

      let clopids = `${this.wrapper.collectionop}`;

      window.open('/apex/bsfWeeklyStaffingRTReportPdf?startdate='+startdate+'&enddate='+enddate+'&dispatch='+drvdisp+'&drivetypes='+drivetypes+'&collopids='+clopids+'&force_download=true');
    }

    get getPopUpRedirectUrl () {
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getDate ();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getDate ();  

      let startdate = `${start}`;
      let enddate = `${end}`;

      let drvdisp;
      if(this.wrapper.drivedispatchyes === true && this.wrapper.drivedispatchno === true){
        drvdisp = 'Both';
      } 
      if(this.wrapper.drivedispatchyes === true && this.wrapper.drivedispatchno === false){
        drvdisp = 'Yes';
      }
      if(this.wrapper.drivedispatchyes === false && this.wrapper.drivedispatchno === true){
        drvdisp = 'No';
      }

      let drivetypes = `${this.wrapper.drivetype}`;

      let clopids = `${this.wrapper.collectionop}`;

      return '/apex/bsfWeeklyStaffingRTReportPdf?startdate='+startdate+'&enddate='+enddate+'&dispatch='+drvdisp+'&drivetypes='+drivetypes+'&collopids='+clopids;
    }

    get disablePdfButton(){
        return !this.hasRecords;
    }
    
    search () {
      this.loaded = true;
      this.hasRecords = false;
      this.hasLunchBreak = false;
      this.dataArry = [];
      console.log(JSON.stringify(this.wrapper));
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getDate ();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getDate ();  
      let drvdisp;
      if(this.wrapper.drivedispatchyes === true && this.wrapper.drivedispatchno === true){
        drvdisp = 'Both';
      } 
      if(this.wrapper.drivedispatchyes === true && this.wrapper.drivedispatchno === false){
        drvdisp = 'Yes';
      }
      if(this.wrapper.drivedispatchyes === false && this.wrapper.drivedispatchno === true){
        drvdisp = 'No';
      }
      searchRoleTimeReport({startDate: start, endDate: end, drivedispatch: drvdisp, collOpIdList: `${this.wrapper.collectionop}`, driveType: `${this.wrapper.drivetype}`, isForPDF: false})
          .then(result => {
              console.log('result:-'+JSON.stringify(result));
              this.loaded = false;
              if (result && result.length > 0) {
                  this.hasRecords = true;
                  this.hasError = false;
                  this.dataArry = result;
                  // Check if any records have lunch breaks
                  this.hasLunchBreak = result.some(wrapper => wrapper.hasLunchBreak === true);
                  console.log('dataArry:-'+JSON.stringify(this.dataArry));
              }else{
                this.hasRecords = false;
                this.hasError = true;
                this.errorMessageToDisplay = 'No data found.';
              }
          })
          .catch(error => {
              console.log(error);
              this.hasRecords = false;
              this.loaded = false;
              this.hasError = true;
              this.errorMessageToDisplay = error.body.message;
              console.log(JSON.stringify(error));
          });
    }
}