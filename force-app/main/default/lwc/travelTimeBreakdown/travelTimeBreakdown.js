import { LightningElement, wire, track, api } from 'lwc';
import getData from '@salesforce/apex/BSF_TravelTimePanelController.getData';
import saveUpdatedRecords from '@salesforce/apex/BSF_TravelTimePanelController.saveUpdatedRecords';
import isEditable from '@salesforce/apex/BSF_TravelTimePanelController.isEditable';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TravelTimeBreakdown extends LightningElement {
    @api recordId;
    @track records = [];
    @track isEditMode = false;
    daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    @track userOverride = false;
    isOpenModel = false;
    initialRecords = [];
    @track modifiedRecordIds = [];
    @track errorMessage = '';
    

    @wire(getData, { siteCO_Id: '$recordId' })
    wiredData({ error, data }) {
        console.log('Received data:', data); 
        if (data) {
            this.records = data.map(record => {
                let newRecord = {...record,hasBeenModified: false,inputsDisabled: !record.isEditMode};
    
                if (Array.isArray(record.travelTimeBreakdownData)) {
                    let slots = this.extractTimeSlots(record.travelTimeBreakdownData);
    
                    record.travelTimeBreakdownData.forEach(ttbd => {
                        let timeSlot = `${ttbd.startTime}-${ttbd.endTime}`;
                        if (slots[timeSlot]) {
                            slots[timeSlot][ttbd.weekday] = ttbd.travelTime;
                        }
                    });
    
                    newRecord.timeSlots = Object.keys(slots).map(key => ({
                        timeRange: key,
                        travelTimes: this.daysOfWeek.map(day => slots[key][day] || '')
                    }));
                } else {
                    console.error('travelTimeBreakdownData is not an array for record:', record);
                    newRecord.timeSlots = [];
                }
                //return {...record, hasBeenModified: false};
                return newRecord;
                
            });
            this.initialRecords = JSON.parse(JSON.stringify(this.records));

            const systemOverrideRecordsToUpdate = data.filter(record => record.systemOverride === true);                     
            if(systemOverrideRecordsToUpdate.length > 0){
                saveUpdatedRecords({ updatedRecords: systemOverrideRecordsToUpdate })
                .then(result => {
                    console.log('Records updated successfully');
                    /*this.exitEditMode();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Records updated successfully',
                            variant: 'success'
                        })
                    );*/
                    //window.location.reload();                
                })
                .catch(error => {
                    //this.exitEditMode();
                    console.error('Error in updating records:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error updating records',
                            variant: 'error'
                        })
                    );
                });
            }
            
        } else if (error) {
            console.error('Error fetching data:', error);
        }
    }

    extractTimeSlots(data) {
        let slots = {};
        data.forEach(item => {
            let timeSlot = `${item.startTime}-${item.endTime}`;
            if (!slots[timeSlot]) {
                slots[timeSlot] = {};
                this.daysOfWeek.forEach(day => slots[timeSlot][day] = null);
            }
        });
        return slots;
    }
    handleEditRecord(event) {
        const indexId = event.target.dataset.indexId;
    
        isEditable()
            .then(result => {
                if (result) {
                    console.log('profile is valid');
                    this.enableEditMode(indexId);
                    
                } else {
                    
                    console.log('profile is invalid');
                    //this.showError('You do not have permission to edit.');
                    this.disableEditMode(indexId);
                }
            })
            .catch(error => {
                this.showError('Error occurred while checking permissions.');
            });
    }
    
    enableEditMode(indexId) {
        this.records = this.records.map(record => {
            if (record.indexId === indexId) {
                return { 
                    ...record, 
                    isEditMode: true,
                    inputsDisabled: false
                };
            }
            return record;
        });
    }
    disableEditMode(indexId) {
        this.records = this.records.map(record => {
            if (record.indexId === indexId) {
                return { 
                    ...record, 
                    isEditMode: false,
                    inputsDisabled: true
                };
            }
            return record;
        });
    }
    handleCancel(event) {
        const indexId = event.target.dataset.indexId;
        this.records = this.records.map(record => {
            if (record.indexId === indexId) {
                const initialRecord = this.initialRecords.find(r => r.indexId === indexId);
                if (initialRecord) {
                    return { ...JSON.parse(JSON.stringify(initialRecord)), isEditMode: false, inputsDisabled: true  };
                }
                return record;
            }
            return record;
        });
    }
    
    handleReset(event) {
        const indexId = event.target.dataset.indexId;
        console.log('comes in reset '+indexId);
        this.records = this.records.map(record => {
            if (record.indexId === indexId) {
                const initialRecord = this.initialRecords.find(r => r.indexId === indexId);
                if (initialRecord) {
                    return {...JSON.parse(JSON.stringify(initialRecord)),isEditMode: true,inputsDisabled: false };
                }
                return record;
            }
            return record;
        });
    }
    handleTimeChange(event) {
        const indexId = event.target.dataset.indexId;
        const dayIndex = parseInt(event.target.dataset.dayIndex, 10);
        const timeSlotRange = event.target.dataset.timeSlot;
        let updatedValue = event.target.value;
        
        if (event.type === 'blur') {
        if (updatedValue === '' || updatedValue === '-' || updatedValue === null || isNaN(updatedValue)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'All time-blocks must be completed with positive values.',
                    variant: 'error'
                })
            );
            const originalRecord = this.initialRecords.find(r => r.indexId === indexId);
            const originalTime = originalRecord?.timeSlots?.find(t => t.timeRange === timeSlotRange)?.travelTimes[dayIndex];
            event.target.value = originalTime;
            updatedValue = originalTime;
            }
        }
        
        
        this.records = this.records.map(record => {
            if (record.indexId === indexId) {
                let updatedRecord = JSON.parse(JSON.stringify(record));
                let originalRecord = this.initialRecords.find(r => r.indexId === indexId);
                let valueChanged = false;
                updatedRecord.timeSlots.forEach(slot => {
                    if (slot.timeRange === timeSlotRange) {
                        const originalTime = originalRecord?.timeSlots?.find(t => t.timeRange === timeSlotRange)?.travelTimes[dayIndex];
                        if (originalTime !== updatedValue) {
                            valueChanged = true;
                        }
                            slot.travelTimes[dayIndex] = updatedValue;
                        }
                });
                const editedDay = this.daysOfWeek[dayIndex];
                const ttbdIndex = updatedRecord.travelTimeBreakdownData.findIndex(ttbd => ttbd.weekday === editedDay && ttbd.startTime === timeSlotRange.split('-')[0] && ttbd.endTime === timeSlotRange.split('-')[1]);

                if (ttbdIndex !== -1) {
                    updatedRecord.travelTimeBreakdownData[ttbdIndex].travelTime = updatedValue;
                    if (valueChanged) {
                        updatedRecord.userOverride = true;
                    }
                }
                console.log(`Updated record##: ${JSON.stringify(updatedRecord)}`);
                updatedRecord.hasBeenModified = true;
                return updatedRecord;
            }
            return record;
        });
    }
    
    handleCommentChange(event) {
        const recordIndexId = event.target.dataset.indexId;
        const commentValue = event.target.value;
        this.records = this.records.map(record => {
            if (record.indexId === recordIndexId) {
                let updatedRecord = { ...record, overrideComment: commentValue };
                console.log('Updated Record with Comment:', JSON.stringify(updatedRecord));
                if (commentValue.length > 255) {
                    updatedRecord.commentError = 'Comment cannot exceed 255 characters.';
                } else {
                    updatedRecord.commentError = ''; 
                }
                return updatedRecord;
            }
            return record;
        });
    }

    handleUserOverrideChange(event) {
        const recordIndexId = event.target.dataset.indexId;
        const updatedUserOverride = event.target.checked;
        console.log('recordIndexId:', recordIndexId);
        console.log('updatedUserOverride:', updatedUserOverride);
    
        this.records = this.records.map(record => {
            console.log('record.indexId:', record.indexId);
            if (record.indexId === recordIndexId) {
                console.log('Entering the if block');
                console.log('updatedUserOverride1:', updatedUserOverride);
                const updatedRecord = { ...record, userOverride: updatedUserOverride };
                console.log('Updated Record with userOverride:', JSON.stringify(updatedRecord));
                return updatedRecord;
            }
            return record;
        });
    }

    handleSave() {
        let updatedRecords = this.records.filter(record => record.isEditMode);
        console.log('Updated Records:', JSON.stringify(updatedRecords));
        let hasNegativeValues = false;
        
        let updatedDataWrappers = updatedRecords.map(record => {
            //console.log(`ROriginal Travel Time Data:`, JSON.stringify(record.travelTimeBreakdownData, null, 2));
            let travelTimeData = record.travelTimeBreakdownData.flatMap(ttbd => {
                let parsedTime = Number(ttbd.travelTime);                
    
                if (!isNaN(parsedTime) && parsedTime > 0) {
                    let timeData = {
                        weekday: ttbd.weekday,
                        travelTime: parsedTime, 
                        startTime: ttbd.startTime, 
                        endTime: ttbd.endTime, 
                        travelDistance: ttbd.travelDistance,
                        travelTimeKey:ttbd.travelTimeKey,
                    };
                    //console.log('Updated Travel Time Data:', JSON.stringify(timeData, null, 2));
                    return timeData;
                } else {
                    //console.error(`Incorrect or missing time data for ${ttbd.weekday}:`, ttbd.travelTime);
                    hasNegativeValues = true;
                    return null; 
                }
            }).filter(timeData => timeData !== null); 
    
            const comment = record.overrideComment;
            const override = record.userOverride;
            const dataWrapper = {
                indexId: record.indexId,
                overrideComment: comment,
                userOverride:override, 
                travelTimeBreakdownData: travelTimeData,
            };
            return dataWrapper;
         });

         if (hasNegativeValues) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'All time-blocks must be completed with positive values.',
                    variant: 'error'
                })
            );
            return;
        }
    
        console.log('Data Wrappers Being Sent to Apex:', JSON.stringify(updatedDataWrappers, null, 2));
    
        saveUpdatedRecords({ updatedRecords: updatedDataWrappers })
            .then(result => {
                console.log('Records updated successfully');
                this.exitEditMode();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully',
                        variant: 'success'
                    })
                );
                //window.location.reload();                
            })
            .catch(error => {
                //this.exitEditMode();
                console.error('Error in updating records:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error updating records',
                        variant: 'error'
                    })
                );
            });
    }
    
    exitEditMode() {
        this.records = this.records.map(record => ({ ...record, isEditMode: false }));
        this.isEditMode = false;
    }
    
    generateDCR() {
        console.log('generate button DCR press');
        console.log('this.isOpenModel 1 '+this.isOpenModel);
        //this.isOpenModel = true;
        console.log('this.isOpenModel '+this.isOpenModel);

        const modifiedRecordIds = this.records
                                .filter(record => record.hasBeenModified)
                                .map(record => record.indexId);
                                
        console.log('All records:', this.records);
        console.log('Modified record IDs in child component:', modifiedRecordIds);
        this.modifiedRecordIds = modifiedRecordIds;  
        this.isOpenModel = true;                     
    }
    handleclose(event){
        console.log('event get in parent');
        console.log('event.detail.isShowModal',event.detail.isShowModal);
        this.isOpenModel = event.detail.isShowModal;
        //this.isOpenModel = event.detail.value;
    }
    
    
    
}