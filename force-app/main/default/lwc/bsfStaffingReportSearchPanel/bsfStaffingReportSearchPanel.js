import { LightningElement, track, api } from 'lwc';
import getDivisionNames from "@salesforce/apex/BSFWeeklyStaffingRoleTimeController.getDivisionNames";
import getRegionNames from "@salesforce/apex/BSFWeeklyStaffingRoleTimeController.getRegionNames";
import getDrictictNames from "@salesforce/apex/BSFWeeklyStaffingRoleTimeController.getDrictictNames";
import getCollectionOpNames from "@salesforce/apex/BSFWeeklyStaffingRoleTimeController.getCollectionOpNames";
import isDriveDispatchedCheckBoxEnable from '@salesforce/apex/BSFWeeklyStaffingRoleTimeController.isDriveDispatchedCheckBoxEnable';
export default class bsfStaffingReportSearchPanel extends LightningElement {
    @track wrapper = {
        'driveufid': '',
        'division': '',
        'region': '',
        'startDate' : this.getStartDate(),
        'endDate' : this.getEndDate(),
        'dristict' : [],
        'collectionop' : [],
        'drivetype' : [],
        'drivedispatchyes' : true,
        'drivedispatchno' : false,
        'driveappealyes' : true,
        'driveappealno' : false
    };
    @track divisionList;
    @track regionList;
    @track drictictList;
    @track collectionOpList;
    @track searchEnable = true;
    @track enableDispatchCheckBox = true;
    @api disableenddate;
    @api disabledivision;
    @api disableregion;
    @api disabledistict;
    @api disablecollopp;
    @api prepopulatevalues = false;
    @api enabledrivetype = false;
    @api enabledriveufid = false;
    @api selecteddivision;
    @api selectedregion;
    @api selecteddistict;
    @api selectedcollopp;
    @api selectedstartdate;
    @api selectedenddate;
    @api selecteddrivetype;
    @api selecteddrivedispatched;
    @api frommobile = false;


    drivetypes = [
        { label: 'Mobile Drive', value: 'mobile', selected: false },
        { label: 'Fixed Drive', value: 'fixed', selected: false }
    ];

    connectedCallback () {
        this.initializeWrapper();
        if(this.prepopulatevalues){
            if(this.selecteddivision != null && this.selectedregion != null && this.selecteddistict != null
                && this.selectedcollopp != null && this.selectedstartdate != null && this.selectedenddate != null
                && this.selecteddrivetype != null && this.selecteddrivedispatched != null){
                    this.wrapper.division = this.selecteddivision;
                    this.wrapper.region = this.selectedregion;
                    this.wrapper.dristict.push(this.selecteddistict);
                    this.wrapper.collectionop.push(this.selectedcollopp);
                    this.wrapper.drivetype.push(this.selecteddrivetype);
                    this.wrapper.startDate = this.selectedstartdate;
                    this.wrapper.endDate = this.selectedenddate;
                    if(this.selecteddrivedispatched === 'true'){
                        this.wrapper.drivedispatchyes = true;
                        this.wrapper.drivedispatchno = false;
                    }else if(this.selecteddrivedispatched === 'false'){
                        this.wrapper.drivedispatchyes = false;
                        this.wrapper.drivedispatchno = true;
                    }
                    console.log('this.selecteddistict ',this.selecteddistict);
                    console.log('this.selectedcollopp ',this.selectedcollopp);
                    this.getRegionList();
                    this.getDistrictList();
                    this.getCollectionOpList();
                    this.drivetypes
                    .filter((item) => item.value === `${this.selecteddrivetype}`)
                    .forEach((item) => (item.selected = true));
                    this.handlePushEvent();
                    this.handleSearchEnableOff();
            }
        }
    }

    initializeWrapper () {
        this.divisionList = [];
        this.regionList = [];
        this.drictictList = [];
        this.collectionOpList = [];
        this.wrapper = {
            'driveufid': '',
            'division': '',
            'region': '',
            'startDate' : this.getStartDate(),
            'endDate' : this.getEndDate(),
            'dristict' : [],
            'collectionop' : [],
            'drivetype' : [],
            'drivedispatchyes' : true,
            'drivedispatchno' : false,
            'driveappealyes' : true,
            'driveappealno' : false
        };
        this.searchEnable = true;
        this.profileCheck();
        this.getDivisionList();
    }
    

    getDivisionList() {
        const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate ();        
        const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate ();  
        getDivisionNames({startDate : start, endDate : end})
          .then((result) => {
             let divisionList = [];
            if (result) {
              result.forEach(r => {
                divisionList.push({
                  label: r.Name,
                  value: `${r.Id}`,
                });
              });
            }
            this.divisionList = divisionList;
          })
          .catch((error) => {
            console.log(error);
          });
    }

    getRegionList() {
        const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate ();        
        const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate ();  
        getRegionNames({startDate : start, endDate : end, divId : `${this.wrapper.division}`})
          .then((result) => {
             let regionList = [];
            if (result) {
              result.forEach(r => {
                regionList.push({
                  label: r.Name,
                  value: `${r.Id}`,
                });
              });
            }
            this.regionList = regionList;
          })
          .catch((error) => {
            console.log(error);
          });
    }

    getDistrictList() {
        console.log('getDistrictList method called ');
        const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate ();        
        const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate ();  
        getDrictictNames({startDate : start, endDate : end, regId : `${this.wrapper.region}`})
          .then((result) => {
             let drictictList = [];
            if (result) {
              result.forEach(r => {
                drictictList.push({
                  label: r.Name,
                  value: `${r.Id}`,
                  selected: false
                });
              });
            }
            if(this.prepopulatevalues && this.selecteddistict != null){
                let drictictName = '';
                drictictList
                .filter((item) => item.value === `${this.selecteddistict}`)
                .forEach((item) => (item.selected = true));
                drictictList
                .filter((item) => item.selected === true)
                .forEach((item) => {drictictName = item.label});
                this.selecteddistict = null;
                this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
                    if (element.name === 'district') {
                        element.selectedItems = drictictName;
                    }
               });
            }
            this.drictictList = drictictList;
            console.log('getDistrictList',this.drictictList);
          })
          .catch((error) => {
            console.log(error);
          });
    }

    getCollectionOpList() {
        const start = this.wrapper.startDate ? this.wrapper.startDate : this.getStartDate ();        
        const end = this.wrapper.endDate ? this.wrapper.endDate : this.getEndDate ();  
        getCollectionOpNames({startDate : start, endDate : end, distIdList : `${this.wrapper.dristict}`})
          .then((result) => {
             let collectionOpList = [];
            if (result) {
              result.forEach(r => {
                collectionOpList.push({
                  label: r.Name,
                  value: `${r.Id}`,
                  selected: false
                });
              });
            }
            if(this.prepopulatevalues && this.selectedcollopp != null){
                let clopName = '';
                collectionOpList
                .filter((item) => item.value === `${this.selectedcollopp}`)
                .forEach((item) => (item.selected = true));
                collectionOpList
                .filter((item) => item.selected === true)
                .forEach((item) => {clopName = item.label});
                this.selectedcollopp = null;
                this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
                    if (element.name === 'collectionop') {
                        element.selectedItems = clopName;
                    }
               });
            }
            this.collectionOpList = collectionOpList;
          })
          .catch((error) => {
            console.log(error);
          });
    }
    
    handleSelectionDivision (event) {
        this.wrapper.division = event.target.value;
        this.regionList = [];
        this.drictictList = [];
        this.collectionOpList = [];
        this.wrapper.region = '';
        this.wrapper.dristict = [];
        this.wrapper.collectionop = [];
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'district') {
                element.selectedItems = '-Select-';
                element.showOptions = false;
            }
            if (element.name === 'collectionop') {
                element.selectedItems = '-Select-';
                element.showOptions = false;
            }
            if (element.name === 'drivetype') {
                element.showOptions = false;
            }
       });
        this.handlePushEvent();
        this.getRegionList();
        console.log("selected division "+this.wrapper.division);
    }

    handleSelectionRegion (event) {
        this.wrapper.region = event.target.value;
        this.drictictList = [];
        this.collectionOpList = [];
        this.wrapper.dristict = [];
        this.wrapper.collectionop = [];
        
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'district') {
                element.selectedItems = '-Select-';
                element.options = [];
                element.showOptions = false;
                element.overritecurrent();
            }
            if (element.name === 'collectionop') {
                element.selectedItems = '-Select-';
                element.options = [];
                element.showOptions = false;
            }
            if (element.name === 'drivetype') {
                element.showOptions = false;
            }
       });
        this.handlePushEvent();
        this.getDistrictList();
        console.log("selected region "+this.wrapper.region);
    }

    handleSelectionDistrict (event) {
        let dist =[];
        for(let key in event.detail) {
            if (event.detail[key] !== null || event.detail[key].value !== '') {
                dist.push(event.detail[key].value);
                this.drictictList
                .filter((item) => item.value === event.detail[key].value)
                .forEach((item) => (item.selected = true));
            }
        }
        this.wrapper.dristict = dist;
        this.collectionOpList = [];
        this.wrapper.collectionop = [];
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'collectionop') {
                element.selectedItems = '-Select-';
                element.options = [];
                element.showOptions = false;
                element.overritecurrent();
            }
            if (element.name === 'drivetype') {
                element.showOptions = false;
            }
       });
        this.handlePushEvent();
        this.getCollectionOpList();
        console.log("selected dristict "+this.wrapper.dristict);
    }

    handleSelectionCollectionOp (event) {
        let colop =[];
        for(let key in event.detail) {
            if (event.detail[key] !== null || event.detail[key].value !== '') {
                colop.push(event.detail[key].value);
                this.collectionOpList
                .filter((item) => item.value === event.detail[key].value)
                .forEach((item) => (item.selected = true));
            }
        }
        this.wrapper.collectionop = colop;
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'district') {
                element.showOptions = false;
            }
            if (element.name === 'drivetype') {
                element.showOptions = false;
            }
       });
        this.handlePushEvent();
        console.log("selected collection op "+this.wrapper.collectionop);
    }

    handleSelectionDriveType (event) {
        console.log("selected event "+JSON.stringify(event));
        let drvtype =[];
        for(let key in event.detail) {
            if (event.detail[key] !== null || event.detail[key].value !== '') {
                drvtype.push(event.detail[key].value);
                this.drivetypes
                .filter((item) => item.value === event.detail[key].value)
                .forEach((item) => (item.selected = true));
            }
        }
        this.wrapper.drivetype = drvtype;
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'district') {
                element.showOptions = false;
            }
            if (element.name === 'collectionop') {
                element.showOptions = false;
            }
       });
        this.handlePushEvent();
        console.log("selected drive type "+this.wrapper.drivetype);
    }

    handleSelectionDriveDispatchYes (event) {
        this.wrapper.drivedispatchyes = event.target.checked;
        if(this.wrapper.drivedispatchyes === false){
            this.wrapper.drivedispatchno = true;
        }
        this.handlePushEvent();
        console.log("this.wrapper.drivedispatchyes "+this.wrapper.drivedispatchyes);
    }

    handleSelectionDriveDispatchNo (event) {
        this.wrapper.drivedispatchno = event.target.checked;
        if(this.wrapper.drivedispatchno === false){
            this.wrapper.drivedispatchyes = true;
        }
        this.handlePushEvent();
        console.log("this.wrapper.drivedispatchno "+this.wrapper.drivedispatchno);
    }

    handleSelectionDriveAppealYes (event) {
        this.wrapper.driveappealyes = event.target.checked;
        if(this.wrapper.driveappealyes === false){
            this.wrapper.driveappealno = true;
        }
        if(this.wrapper.driveappealyes === true){
            this.wrapper.driveappealno = false;
        }
        this.handlePushEvent();
        console.log("this.wrapper.driveappealyes "+this.wrapper.driveappealyes);
    }

    handleSelectionDriveAppealNo (event) {
        this.wrapper.driveappealno = event.target.checked;
        if(this.wrapper.driveappealno === false){
            this.wrapper.driveappealyes = true;
        }
        if(this.wrapper.driveappealno === true){
            this.wrapper.driveappealyes = false;
        }
        this.handlePushEvent();
        console.log("this.wrapper.driveappealno "+this.wrapper.driveappealno);
    }

    handleChange (event) {
        this.wrapper[event.target.dataset.id] = event.target.value;
        console.log("disableenddate "+this.disableenddate);
        if(this.disableenddate === 'true' && event.target.dataset.id === 'startDate'){
            console.log("this.wrapper.startDate "+this.wrapper.startDate);
            let edate = new Date(this.wrapper.startDate);
            edate.setDate(edate.getDate() + 6);
            this.wrapper.endDate = edate.toISOString().slice(0, 10);
            console.log("this.wrapper.endDate "+this.wrapper.endDate);
        }
        if(event.target.dataset.id === 'startDate' || event.target.dataset.id === 'endDate'){
            this.divisionList = [];
            this.regionList = [];
            this.drictictList = [];
            this.collectionOpList = [];
            this.wrapper.division = '';
            this.wrapper.region = '';
            this.wrapper.dristict = [];
            this.wrapper.collectionop = [];
            this.getDivisionList();
            this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
                if (element.name === 'district') {
                    element.selectedItems = '-Select-';
                    element.showOptions = false;
                }
                if (element.name === 'collectionop') {
                    element.selectedItems = '-Select-';
                    element.showOptions = false;
                }
           });
        }
        this.handlePushEvent();
        console.log(this.wrapper[event.target.dataset.id]);
    }

    handleSearchEnableOn() {
        this.searchEnable = true;
    }
      
    handleSearchEnableOff() {
        this.searchEnable = false;
    }

    handleOnFocus(){
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'district') {
                element.showOptions = false;
            }
            if (element.name === 'collectionop') {
                element.showOptions = false;
            }
            if (element.name === 'drivetype') {
                element.showOptions = false;
            }
       });
    }

    handleDistrictClick(){
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'collectionop') {
                element.showOptions = false;
            }
            if (element.name === 'drivetype') {
                element.showOptions = false;
            }
       });
    }

    handleCollOpClick(){
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'district') {
                element.showOptions = false;
            }
            if (element.name === 'drivetype') {
                element.showOptions = false;
            }
       });
    }

    handleDriveTypeClick(){
        this.template.querySelectorAll('c-bsf-multi-select-combobox').forEach(element => {
            if (element.name === 'collectionop') {
                element.showOptions = false;
            }
            if (element.name === 'district') {
                element.showOptions = false;
            }
       });
    }

    profileCheck(){
        isDriveDispatchedCheckBoxEnable({})
            .then(result => {
                this.enableDispatchCheckBox = result;
            })
            .catch(error => {
                console.log(error);
            });
    }

    get disableCheckBox(){
        return !this.enableDispatchCheckBox;
    }

    get disabledrivetype(){
        return !this.enabledrivetype;
    }

    get disabledriveufid(){
        return !this.enabledriveufid;
    }
    
    getStartDate () {
        let startDate = new Date();
        return startDate.toISOString().slice(0, 10);
    }

    getEndDate () {
        let endDate = new Date();
        if(this.disableenddate === 'true'){
            endDate.setDate(endDate.getDate() + 6);
        }
        return endDate.toISOString().slice(0, 10);
    }

    handlePushEvent(){
        console.log('this.wrapper handlePushEvent',this.wrapper);
        this.dispatchEvent(new CustomEvent('selectevent', { detail: {startDate: this.wrapper.startDate, 
                                                                endDate: this.wrapper.endDate, 
                                                                division: this.wrapper.division,
                                                                region: this.wrapper.region,
                                                                dristict: this.wrapper.dristict,
                                                                collectionop: this.wrapper.collectionop,
                                                                drivetype: this.wrapper.drivetype,
                                                                drivedispatchyes: this.wrapper.drivedispatchyes,
                                                                drivedispatchno: this.wrapper.drivedispatchno,
                                                                driveappealyes: this.wrapper.driveappealyes,
                                                                driveappealno: this.wrapper.driveappealno,
                                                                driveufid: this.wrapper.driveufid}}));
    }

    handleResetEvent(){
        this.dispatchEvent(new CustomEvent('resetevent', { detail: {value: true}}));
    }
}