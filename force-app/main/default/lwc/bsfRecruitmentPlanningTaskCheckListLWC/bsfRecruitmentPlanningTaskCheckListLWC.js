import { LightningElement, track, wire, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkTaskSubject from '@salesforce/apex/RecruitmentPlanningController.checkTaskSubject';
import getMetadata from '@salesforce/apex/RecruitmentPlanningController.fetchMetadata';
import getRecruitmentChecklist from '@salesforce/apex/RecruitmentPlanningController.getRecruitmentChecklist';
export default class BsfRecruitmentPlanningTaskCheckListLWC extends LightningElement {
    @api recordId;
    @track notARecruitmenttask = false;
    @track showMessage = 'Nothing to See Here!!!'
    @track isLoaded = false;
    @track showData;
    @track details = {};
    @track section1 = { sectionHeader: '', fields: [] };
    @track section2 = { sectionHeader: '', fields: [] };
    @track section3 = { sectionHeader: '', fields: [] };
    CATEGORY1 = 'Dummy Data';
    CATEGORY2 = 'Double Data';
    CATEGORY3 = 'url data';

    connectedCallback() {
        console.log('Record ID:', this.recordId);

        checkTaskSubject({taskId: this.recordId})
        .then(result => {
            console.log('Result:', result);
            if(result == true){
                getRecruitmentChecklist({taskId: this.recordId})
                .then(result => {
                    console.log('Result:', JSON.stringify(result));
                    Object.keys(result).forEach(key => {
                        console.log('key',key);
                        let name = key;
                        let id = result[name].hasOwnProperty('Id') ? result[name].Id : '';
                        let label = result[name].label;
                        let category = result[name].category;
                        let url = result[name].url;
                        let tooltip = result[name].tooltip;
                        let value = result[name].hasOwnProperty('value') ? JSON.parse(result[name].value) : '';
                        let details = result[name].hasOwnProperty('details') ? result[name].details : '';
                        let AA = result[name].hasOwnProperty('AA') ? result[name].AA : '';
                        let latino = result[name].hasOwnProperty('latino') ? result[name].latino : '';
                        if (this.CATEGORY1.localeCompare(category) == 0) {
                            this.section1.sectionHeader = category;
                            this.details[id] = details;
                            this.section1.fields.push({ id: id, name: name, label: label, value: value, details: details, tooltip: tooltip });
                        }
                        else if(this.CATEGORY2.localeCompare(category) == 0){
                            this.section2.sectionHeader = category;
                            this.details[id] = {['AA']:AA,
                                                ['Latino']:latino};
                            this.section2.fields.push({ id: id, name: name, label: label, value: value, AA: AA, latino: latino, tooltip: tooltip});
                        }
                        else if (this.CATEGORY3.localeCompare(category) == 0) {
                            this.section3.sectionHeader = category;
                            this.details[id] = {};
                            this.section3.fields.push({ id: id, name: name, label: label, value: value, url: url, details: details, tooltip: tooltip});
                        }
                    })
                    // console.log('section1==> ', JSON.stringify(this.section1));
                    // console.log('section2==> ', JSON.stringify(this.section2));
                    // console.log('section3==> ', JSON.stringify(this.section3));
                    // console.log('all details==> ', JSON.stringify(this.details));
                })
                .catch(error => {
                    console.log('Error:', error);
                });
            }
            else if(result == false){
                this.notARecruitmenttask = true;
            }
        }).catch(error => {
            console.log('Error:', error);
        }).finally(() => {
            console.log('Done');
            this.isLoaded = true;
        });
    }

    onCheckboxClick(event) {
        // console.log('track checkbox', event.target.checked);
        // console.log('id',event.target.name);
        // console.log('Details:', JSON.stringify(this.details[event.target.name]));
        // console.log('Details:', JSON.stringify(this.details[event.target.name]['AA']));
        // console.log('Details:', JSON.stringify(this.details[event.target.name]['Latino']));
        const fields = {};
        const id = event.target.name;
        const fieldValue = event.target.checked;
        fields.Id = id;
        fields['Checkbox__c'] = fieldValue;
        const fieldDetails = this.details[event.target.name];
        const fieldAA = this.details[event.target.name]['AA'];
        const fieldLatino = this.details[event.target.name]['Latino'];
        if ((fieldAA !== undefined && isNaN(Number(fieldAA))) || 
        (fieldLatino !== undefined && isNaN(Number(fieldLatino)))) {
        // Show error toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'AA Projection and Latino Projection must be numbers',
                variant: 'error'
            })
        );
        event.target.checked = false;
        return;
    }
        fields['Details__c'] = (fieldValue == true || fieldDetails != undefined) ? fieldDetails : '';
        fields['AA_Projection__c'] = (fieldValue == true || fieldAA || fieldAA != undefined) ? fieldAA : '';
        fields['Latino_Projection__c'] = (fieldValue == true || fieldLatino || fieldLatino != undefined) ? fieldLatino : '';
        
        const recordInput = {
            fields: fields
        };
        console.log('recordInput==> ', JSON.stringify(recordInput));
        updateRecord(recordInput)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record Updated',
                    variant: 'success'
                }),
            );
            console.log('Updated Record:');
        })
        .catch(error => {
            console.log('Error:', error);
        });

    }
    
    onType(event) {
    this.details[event.target.name] = event.target.value;
    console.log('value Details:', this.details[event.target.name] );
    }
    onTypeDualBox(event) {
        this.details[event.target.name][event.target.label] = event.target.value;
        console.log('dual Details:', this.details[event.target.name][event.target.label]);
    }
}