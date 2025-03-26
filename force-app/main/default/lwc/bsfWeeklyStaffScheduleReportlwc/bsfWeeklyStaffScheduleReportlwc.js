import { LightningElement, track, api} from 'lwc';
import searchReport from '@salesforce/apex/WeeklyStaffScheduleReportController.searchReport';
export default class BSFWeeklyStaffingRoleTimeReport extends LightningElement {
    @track wrapper = {};
    @track dataArry=[];
    @track columns=[];
    @track loaded = false;
    @track hasError = false;
    @track hasRecords = false;
    @track showPopup = false;
    @track errorMessageToDisplay = '';
    @api frommobile = false;

    enablelastrow = true;

    connectedCallback () {
      this.initializeWrapper();
    }

    initializeWrapper () {
        this.wrapper = {
            'division': '',
            'region': '',
            'startDate' : this.getStartDate(),
            'endDate' : this.getEndDate(),
            'dristict' : [],
            'collectionop' : [],
            'drivetype' : [],
            'drivedispatchyes' : true,
            'drivedispatchno' : false
        };
        this.loaded = false;
        this.hasRecords = false;
        this.hasError = false;
    }

    handleViewPdf(){
        this.showPopup = true;
    }

    handleClosePopupHandler(){
      this.showPopup = false;
    }

    handleResetValues (event) {
        console.log('change event RT '+JSON.stringify(event.detail));
        this.wrapper.startDate= this.getStartDate(); 
        this.wrapper.endDate= this.getEndDate(); 
        this.wrapper.division= '';
        this.wrapper.region= '';
        this.wrapper.dristict= [];
        this.wrapper.collectionop= [];
        this.wrapper.drivetype= [];
        this.wrapper.drivedispatchyes= true;
        this.wrapper.drivedispatchno= false;
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
      this.wrapper.drivetype= event.detail.drivetype;
      this.wrapper.drivedispatchyes= event.detail.drivedispatchyes;
      this.wrapper.drivedispatchno= event.detail.drivedispatchno;
      this.hasError = false;
      this.hasRecords = false;
  }

    handleSearch (event) {
        if (event.target.name === 'search') {
            this.search();
        }
    }
    getStartDate () {
      let startDate = new Date();
      return startDate.toISOString().slice(0, 10);
    }

    getEndDate () {
        let endDate = new Date();
        return endDate.toISOString().slice(0, 10);
    }

    exportToPdf () {
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate();  

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

      window.open('/apex/BSFWeeklyStaffScheduleReportPDF?startdate='+startdate+'&enddate='+enddate+'&dispatch='+drvdisp+'&drivetypes='+drivetypes+'&collopids='+clopids+'&force_download=true');
    }

    get getPopUpRedirectUrl () {
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate();  

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

      return '/apex/BSFWeeklyStaffScheduleReportPDF?startdate='+startdate+'&enddate='+enddate+'&dispatch='+drvdisp+'&drivetypes='+drivetypes+'&collopids='+clopids;
    }

    get disablePdfButton(){
        return !this.hasRecords;
    }
    
    search () {
      this.loaded = true;
      this.hasRecords = false;
      this.dataArry = [];
      console.log(JSON.stringify(this.wrapper));
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate();  
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
      searchReport({startDate: start, endDate: end, drivedispatch: drvdisp, collOpIdList: `${this.wrapper.collectionop}`, driveType: `${this.wrapper.drivetype}`, isForPDF: false})
          .then(result => {
              console.log('result:-'+JSON.stringify(result));
              this.loaded = false;
              this.columns = result.columnsInfo;
              this.dataArry = result.dataWrapper;
              if (this.dataArry && this.dataArry.length > 0) {
                  this.hasRecords = true;
                  this.hasError = false;
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