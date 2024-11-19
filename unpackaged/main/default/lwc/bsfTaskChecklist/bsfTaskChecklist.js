import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedCheckistRecords from '@salesforce/apex/TaskChecklistController.getRelatedCheckistRecords';
import updateTaskChecklist from '@salesforce/apex/TaskChecklistController.updateTaskChecklist';
import checkEditAccess from '@salesforce/apex/TaskChecklistController.checkEditAccess';

export default class BsfTaskChecklist extends LightningElement {
    @track isLoaded = false;
    @track isProcessing = false;
    @track noDataFound = false;
    @track errMsg;
    @api recordId;
    @track column_1_items = [];
    @track column_2_items = [];
    @track disableEditAccess = false;
    @track recordData = {};

    connectedCallback() {

        checkEditAccess()
            .then(hasEditAccess => {
                console.log('checkEditAccess...', hasEditAccess);
                hasEditAccess ? this.disableEditAccess = false : this.disableEditAccess = true;
                console.log('hasEditAccess: ' + hasEditAccess);
            }
            ).catch(
                error => {
                    console.log('Error is :' + JSON.stringify(error));
                }
            );

        getRelatedCheckistRecords({ recordId: this.recordId })
            .then((result) => {
                console.log('<<TASK CHECKLIST>>: ' + JSON.stringify(result));
                this.processChecklistData(result);
                // Object.keys(result).forEach(key => {
                //     let name = key;
                //     let id = result[name].hasOwnProperty('recordId') ? result[name].recordId : '';
                //     let sectionHeader = result[name].hasOwnProperty('sectionHeader') ? result[name].sectionHeader : null;
                //     let column = result[name].column;
                //     let order = result[name].order;
                //     let uiElements = { id: '', fields: [] };
                //     // console.log('key==> ', JSON.stringify(key));
                //     if (column == 1) {
                //         uiElements.id = id;
                //         uiElements.fields = Object.values(result[name].inputs);
                //         if (sectionHeader != null) {
                //             let sectionElements = { sectionHeader: '', sectionItems: [] };
                //             let isSectionFound = false;
                //             sectionElements.sectionHeader = sectionHeader;
                //             this.column_1_items.filter((element) => {
                //                 if (element.sectionHeader == sectionHeader) {
                //                     isSectionFound = true;
                //                     element.sectionItems.push(uiElements);
                //                 }
                //             })
                //             if (!isSectionFound) {
                //                 sectionElements.sectionItems.push(uiElements);
                //                 this.column_1_items[order] = sectionElements;
                //             }
                //         } else {
                //             this.column_1_items[order] = uiElements;
                //         }

                //     } else {
                //         uiElements.id = id;
                //         uiElements.fields = Object.values(result[name].inputs);
                //         if (sectionHeader != null) {
                //             let sectionElements = { sectionHeader: '', sectionItems: [] };
                //             let isSectionFound = false;
                //             sectionElements.sectionHeader = sectionHeader;
                //             this.column_2_items.filter((element) => {
                //                 if (element.sectionHeader == sectionHeader) {
                //                     isSectionFound = true;
                //                     element.sectionItems.push(uiElements);
                //                 }
                //             })
                //             if (!isSectionFound) {
                //                 sectionElements.sectionItems.push(uiElements);
                //                 this.column_2_items[order] = sectionElements;
                //             }
                //         } else {
                //             this.column_2_items[order] = uiElements;
                //         }
                //     }
                // })
                // // console.log('column_1_items==> ', JSON.stringify(this.column_1_items));
                // this.column_1_items = this.removeNullsAndSort(this.column_1_items);
                // this.column_2_items = this.removeNullsAndSort(this.column_2_items);
                // console.log('column_1_items==> ', JSON.stringify(this.column_1_items));
                // console.log('column_2_items==> ', JSON.stringify(this.column_2_items));
            }
            ).catch((error) => {
                console.error('Error==> ', error.body.message);
                this.errMsg = 'Something went wrong!!!';
                this.noDataFound = true;
            }).finally(() => {
                this.isLoaded = true;
                if (this.errMsg == null & this.column_1_items.length <= 0 && this.column_2_items.length <= 0) {
                    this.errMsg = 'Checklist not available!!!';
                    this.noDataFound = true;
                }
            });
    }

    processChecklistData(checklistData) {
        let columnItems = [];
        Object.keys(checklistData).forEach(key => {
            let name = key;
            let id = checklistData[name].hasOwnProperty('recordId') ? checklistData[name].recordId : '';
            let sectionHeader = checklistData[name].hasOwnProperty('sectionHeader') ? checklistData[name].sectionHeader : null;
            let column = checklistData[name].column;
            let order = checklistData[name].order;
            let uiElements = { id: '', fields: [] };
            uiElements.id = id;
            uiElements.column = column;
            console.log(`${name}==> ${JSON.stringify(Object.values(checklistData[name].inputs))}`);
            uiElements.fields = Object.values(checklistData[name].inputs);
            if (sectionHeader != null) {
                let sectionElements = { column: column, sectionHeader: '', sectionItems: [] };
                let isSectionFound = false;
                sectionElements.sectionHeader = sectionHeader;
                columnItems.filter((element) => {
                    if (element.sectionHeader == sectionHeader) {
                        isSectionFound = true;
                        element.sectionItems.push(uiElements);
                    }
                })
                if (!isSectionFound) {
                    sectionElements.sectionItems.push(uiElements);
                    columnItems[order] = sectionElements;
                }
            } else {
                columnItems[order] = uiElements;
            }


        })

        //console.log('columnItems=> ', JSON.stringify(this.removeNullsAndSort(columnItems)));
        this.removeNullsAndSort(columnItems);
    }

    removeNullsAndSort(dataItems) {
        let filteredData = dataItems.filter(item => item !== null);
        console.log('filteredData=> ', JSON.stringify(filteredData));
        filteredData.filter(item => {
            if (item.sectionItems) {
                item.sectionItems.sort((a, b) => {
                    const orderA = a.fields[0].order;
                    const orderB = b.fields[0].order;
                    return orderA - orderB;
                });
            }
        });

        this.column_1_items = filteredData.filter(item => item.column === 1);
        this.column_2_items = filteredData.filter(item => item.column === 2);
        console.log('columnItems one=> ', JSON.stringify(this.column_1_items));
        console.log('columnItems two => ', JSON.stringify(this.column_2_items));
    }


    handleInputChange(event) {
        // console.log('handleInputChange...');
        let record = event.detail.data;
        if (this.recordData.hasOwnProperty(record.id)) {
            this.recordData[record.id][record.name] = record.value;
        } else {
            this.recordData[record.id] = { Id: record.id };
            this.recordData[record.id][record.name] = record.value;
        }
        // console.log('this.data: ', JSON.stringify(record));
        console.log('this.recordData: ', JSON.stringify(this.recordData));
    }

    handleSave() {
        let updateStatus = {};
        console.log('Object.values(this.recordData)==> ', JSON.stringify(Object.values(this.recordData)));
        if (Object.keys(this.recordData).length != 0) {
            this.isProcessing = true;
            let recordJSON = JSON.stringify(Object.values(this.recordData))
            let updateStatus;
            updateTaskChecklist({ recordData: recordJSON })
                .then((result) => {
                    console.log('result==>', JSON.stringify(result));
                    updateStatus = result;
                    console.log('updateStatus==> ', JSON.stringify(updateStatus));
                }
                ).catch((error) => {
                    console.error('Error==> ', error.body.message);
                }).finally(() => {
                    this.isProcessing = false;
                    this.recordData = {};
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: updateStatus.title,
                            message: updateStatus.message,
                            variant: updateStatus.variant
                        })
                    );
                });
        }

    }
}