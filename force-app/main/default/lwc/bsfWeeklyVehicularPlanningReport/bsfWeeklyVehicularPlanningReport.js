import { LightningElement, track, api} from 'lwc';
import getAllResourceDataWithDate from '@salesforce/apex/BSFVehiclePlanningController.getAllResourceDataWithDate';
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

    enablelastrow = false;

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
            'collectionop' : []
        };
        this.loaded = false;
        this.hasRecords = false;
        this.hasError = false;
    }

    handleViewReport(){
      this.search();
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
      let clopids = `${this.wrapper.collectionop}`;

      window.open('/apex/bsfVehiclePlanningReportPDF?startdate='+startdate+'&enddate='+enddate+'&renderas=pdf&collopids='+clopids+'&force_download=true');
    
    }

    get getPopUpRedirectUrl () {
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate();  

      let startdate = `${start}`;
      let enddate = `${end}`;


      let clopids = `${this.wrapper.collectionop}`;

      return '/apex/bsfVehiclePlanningReportPDF?startdate='+startdate+'&enddate='+enddate+'&renderas=html&collopids='+clopids;

    }

    get disablePdfButton(){
        return !this.hasRecords;
    }
    
    search () {
      this.loaded = true;
      this.hasRecords = false;
      this.dataArry = [];
      console.log('search result'+JSON.stringify(this.wrapper));
      const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate();        
      const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate();
      console.log('search result start'+JSON.stringify(start));
      console.log('search result collop'+JSON.stringify(this.wrapper.collectionop));
      console.log('search result'+JSON.stringify(end));
      getAllResourceDataWithDate({startDate : start, endDate: end, collOpIdList: `${this.wrapper.collectionop}`})
          .then(result => {
            console.log('headerWrapper:', result.headerWrapper);
            console.log('dataWrapper:', result.dataWrapper);
              //this.dataArry = result;
              this.loaded = false;
              if (result.dataWrapper && result.dataWrapper.length > 0) {
                  this.hasRecords = true;
                  this.hasError = false;
                  this.showPopup = true;
              }else{
                this.hasRecords = false;
                this.hasError = true;
                this.showPopup = false;
                this.errorMessageToDisplay = 'No data found.';
              }
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