import { LightningElement, track, wire, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSiteSuitabilitychecklist from '@salesforce/apex/SiteSuitabilityController.getSiteSuitabilitychecklist';
import checkEditAccess from '@salesforce/apex/SiteSuitabilityController.checkEditAccess';

export default class BsfSiteSuitabilityChecklist extends LightningElement {

    @track siteSuitabilityFields = [];
    @track section1 = { sectionHeader: '', fields: [] };
    @track section2 = {};
    @track section3 = { sectionHeader: '', fields: [] };
    @track section4 = { sectionHeader: '', fields: [] };
    @track section5 = { sectionHeader: '', fields: [] };
    @track section6 = { sectionHeader: '', fields: [] };
    @track isLoaded = false;
    @track noDataFound = false;
    @track errMsg = 'Something went wrong!!!';
    @api recordId;
    @api siteSuitabilityId;
    @track disableEditAccess = false;
    CATEGORY1 = 'To Compare Site Suitability:';
    CATEGORY2 = 'Site Availability:';
    CATEGORY3 = 'Parking, Loading and Unloading (Staff, Truck, Donor and SCU):';
    CATEGORY4 = 'Drive Setup:';
    CATEGORY5 = 'Multi-Day Blood Drives:';
    CATEGORY6 = 'Table and Chairs:';
    CATEGORY7 = 'tableData';
    CATEGORY8 = 'Note:';
    staticTextMap = {};
    STATICTEXTFIELDLIST = [
        'Static_Text_1', 'Static_Text_2',
        'Static_Text_3', 'Static_Text_4',
        'Static_Text_5', 'Static_Text_6',
        'Static_Text_7', 'Static_Text_8'
    ];

    tableData = [];

    connectedCallback() {

        checkEditAccess()
            .then(
                hasEditAccess => {
                    hasEditAccess ? this.disableEditAccess = false : this.disableEditAccess = true;
                    console.log('hasEditAccess: ' + hasEditAccess);
                }
            ).catch(
                error => {
                    console.log('Error is :' + JSON.stringify(error));
                }
            )

        getSiteSuitabilitychecklist({ siteId: this.recordId })
            .then((result) => {
                console.log('result==> ', JSON.stringify(result));
                Object.keys(result).forEach(key => {
                    let name = key;
                    let id = result[name].hasOwnProperty('Id') ? result[name].Id : '';
                    let label = result[name].label;
                    let category = result[name].category;
                    let value = result[name].hasOwnProperty('value') ? JSON.parse(result[name].value) : '';
                    let additional_text = result[name].hasOwnProperty('additional_text') ? result[name].additional_text : '';
                    if (this.CATEGORY1.localeCompare(category) == 0) {
                        this.section1.sectionHeader = category;
                        this.section1.fields.push({ id: id, name: name, label: label, value: value });
                    } else if (this.CATEGORY3.localeCompare(category) == 0) {
                        this.section3.sectionHeader = category;
                        this.section3.fields.push({ id: id, name: name, label: label, value: value, additional_text: additional_text });
                    } else if (this.CATEGORY4.localeCompare(category) == 0) {
                        this.section4.sectionHeader = category;
                        this.section4.fields.push({ id: id, name: name, label: label, value: value });
                    } else if (this.CATEGORY5.localeCompare(category) == 0) {
                        this.section5.sectionHeader = category;
                        this.section5.fields.push({ id: id, name: name, label: label, value: value });
                    } else if (this.CATEGORY6.localeCompare(category) == 0) {
                        this.section6.sectionHeader = category;
                        this.section6.fields.push({ id: id, name: name, label: label, value: value });
                    } else if (this.CATEGORY7.localeCompare(category) == 0) {
                        let rawData = [(label).split(';')];
                        rawData.forEach(row => {
                            row.forEach(cell => {
                                this.tableData.push(cell.split('/'))
                            })
                        })
                        // console.log('Table Data: ', this.tableData);
                    } else if (this.STATICTEXTFIELDLIST.includes(name)) {
                        this.staticTextMap[name] = { label: label, sectionHeader: category }
                        // if (this.STATICTEXTFIELDLIST[1].localeCompare(category) == 0) {
                        //     this.staticTextMap[name] = label.split('/');
                        // } else {
                        //     this.staticTextMap[name] = label;
                        // }

                    } else {
                        console.log(`Dooesn't belong to a valid category.`);
                    }
                })
                console.log('this.staticTextMap=> ', JSON.stringify(this.staticTextMap));
                console.log('section1==> ', JSON.stringify(this.section1));
            })
            .catch((error) => {
                console.error('Error==> ', error.body.message);
                this.noDataFound = true;
            }).finally(() => {
                this.isLoaded = true;
            });
    }

    handleChecklist(event) {
        const id = event.target.name;
        const fieldValue = event.target.checked;
        console.log('id: ', id);
        console.log('fieldValue: ', fieldValue);
        const fields = {};
        fields.Id = id;
        fields['Value__c'] = fieldValue;
        const recordInput = {
            fields: fields
        };
        console.log('recordInput==> ', JSON.stringify(recordInput));
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record updated',
                        variant: 'success'
                    })
                );
                console.log('Checklist Updated');
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

}