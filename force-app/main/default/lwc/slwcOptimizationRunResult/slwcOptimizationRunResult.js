import TIME_ZONE from '@salesforce/i18n/timeZone';
import { LightningElement, track, api, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from "c/pubsub";
import * as autoMapper from 'c/autoMapper';
import { uniqBy, each, get, groupBy, orderBy, uniqueId } from 'c/lodash';
import { sObjectType, driveService, optimizationQueueService, optimizationQueueQueryModel, optimizationRunService } from 'c/dataService';
import { classNames, camelize } from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import customLWCStyle from '@salesforce/resourceUrl/skedLWCCustomStyle'

export default class SlwcOptimizationRunResult extends LightningElement {
    _optimizationRun;
    @api
    get optimizationRun() {
        return this._optimizationRun;
    }
    set optimizationRun(value) {
        this._optimizationRun = value;
        if(this.initialized) {
            this.getOptimizedJobAllocationIds();
            this.getOptimizationQueues();
        }
    }
        
    @track showSpinnerCount = 0;
    @track initialized = false;    
    @track optimizationQueues = [];    
    optimizedJobAllocatedIds = [];
    optDriveRunResult;    
    optRunResultColumns;
    optRoleList = [];   

    @wire(CurrentPageReference) pageRef;
    get dateUtils() {
        return slwcDateUtils.getInstance({
            timezone: TIME_ZONE
        });
    }
    get showSpinner() {
        return this.showSpinnerCount > 0;
    }    
    
    connectedCallback() {
        //init settings
        if (!this.initialized) {
        }
    }
    registerEvents = () => {
        registerListener('optimizationSummary:refresh', this.getOptimizationQueues, this);
    }
    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, customLWCStyle)
        ])
        .then(() => {

        })

        if(!this.initialized) {
            this.getOptimizedJobAllocationIds();
            this.getOptimizationQueues();            
            this.initialized = true;
        }
        this.registerEvents();
    }

    /** Custom functions **/
    showLoading = () => {
        this.showSpinnerCount++;
    }
    hideLoading = () => {
        this.showSpinnerCount--;
        if (this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        }
    }    

    fillInDataForAPeriod = (data, startDate, endDate) => {
        const dateGrouped = groupBy(data, 'driveDate');
        const _startDate = this.dateUtils.dateIso2DateTime(startDate);
        const _endDate = this.dateUtils.dateIso2DateTime(endDate);
        const diff = this.dateUtils.diffDays(_startDate.date, _endDate.date);
        const result = {};
        for(let i = 0; i <= diff; i++) {
            const currentDate = DateTime.fromJSDate(_startDate.date).plus({
                days: i
            });
            const currentDateIso = this.dateUtils.date2dateIso(currentDate.toJSDate());

            result[currentDateIso] = dateGrouped[currentDateIso] || [];
        }
        return result;
    }

    getOptimizedJobAllocationIds(){
        this.optimizedJobAllocatedIds = [];
        let optimizedJobAllocationSvc = new optimizationRunService();
        optimizedJobAllocationSvc.getOptimizedJobAllocation({optimizationId: this.optimizationRun.id})
        .then((result) => {
            let optJobAllocs = autoMapper.autoMapperInstance.mapToArray('sked__Job_Allocation__c', result.returnedData || []);            
            this.optimizedJobAllocatedIds = (optJobAllocs || []).map((optJobAlloc => {
                return optJobAlloc.id;                
            }));                 
        })
        .catch(error => this.exceptionHandler(error, true));
    }   

    getOptimizationQueues = () => {
        if (!this.optimizationRun) {
            //TODO: error handler
            return;
        }       

        let optimizationQueueSvc = new optimizationQueueService();
        let optimizationQueueQuery = new optimizationQueueQueryModel();
        optimizationQueueQuery.optimizationRunIds = [this.optimizationRun.id];
        optimizationQueueQuery.subQueryIndicator = sObjectType.OPTIMIZATION_QUEUE_ITEM;            

        this.showLoading();
        optimizationQueueSvc.query(optimizationQueueQuery)
        .then(result => {            
            let promises = (result || []).map(optimizationQueue => {
                let driveSvc = new driveService();
                let driveIds = [];
                (optimizationQueue.optimizationQueueItems || []).forEach((item) => {
                    driveIds.push(item.driveId);
                });
    
                return driveSvc.getDrivesByIds(driveIds, false, true)
                .then(result => {                    
                    return {
                        ...optimizationQueue,
                        drives: result || []
                    }
                })
            })

            return Promise.all(promises);
        })
        .then(result => {
            this.optimizationQueues = result || [];            

            this.optimizationQueues.forEach(optimizationQueue => {                                
                const dataGrouped = this.fillInDataForAPeriod(optimizationQueue.drives, optimizationQueue.startDate, optimizationQueue.endDate); 
                let arrGrouped = [];
                each(dataGrouped, (item, dateIso) => {
                    arrGrouped.push({ data: item, dateIso: dateIso });
                })                
                optimizationQueue.dataGrouped = this.mapData(arrGrouped);                
            })            
            this.toggleExpandAll();
        })
        .catch(error => this.exceptionHandler(error, true))
        .finally(this.hideLoading);
    }

    exceptionHandler = (error, silentError = false) => {
        console.log(error);

        if (!silentError) {
        }
    }

    setCss(allocation, quantity) {
        if(allocation === undefined || quantity === undefined) {
            return 'color-gray background-gray-light important'
        } else if (allocation == 0) {
            return 'color-gray background-red-light important'
        } else if (allocation == quantity) {
            return 'color-gray background-green-light important'
        } else if (allocation < quantity) {
            return 'color-gray background-yellow-light important'
        } else {
            return 'color-gray background-gray-light important'
        }
    }   

    generateSectionClass(item) {
        return classNames('slds-section', {
            'has-data': item.hasData,
            'slds-is-open': item.expanded
        });
    }

    getOptRunResult(drive){
        let driveRecordData = {
            name: `${drive.name} - ${drive.ufid}`,
            driveId: drive.id
        };
        const driveShiftRecordData = drive.driveShifts.map(driveShiftItem => {
            let driveShiftItemRecordData = {
                name: driveShiftItem.name,
                id: driveShiftItem.id,
                driveId: drive.id,
            };

            let jobRecordData = (driveShiftItem.jobs || []).map((job) => {                                                
                let optJobData = {};
                let jobAllocRecordData = {};
                if (job.driveShiftId == driveShiftItem.id && ! job.assetType && job.resourceRole) {                     
                    const fieldName = camelize(job.resourceRole);
                    let roleTag = (job.jobTags || []).find(jobTag => {
                        return jobTag.tag && jobTag.tag.name === (job.resourceRole);
                    });                    
                    let rolePriority = roleTag ? roleTag.tag.priority : Number.MAX_SAFE_INTEGER;                    
                    this.optRoleList.push({
                        priority: rolePriority,
                        role: job.resourceRole
                    });
                    
                    optJobData = {
                        id: job.id,
                        driveId: job.driveId,
                        driveName: job.driveName,
                        driveShiftId: job.driveShiftId,
                        driveShiftName: job.driveShiftName,
                        jobRole: fieldName,
                        jobQuantity: job.quantity                        
                    };                        
                             
                    jobAllocRecordData = (job.jobAllocations || []).map(jobAllocation => {
                        let optJobAllocData = {
                            id: jobAllocation.id,
                            jobId: job.id,
                            role: jobAllocation.resourceRole,
                            status: jobAllocation.status                                                                        
                        };                                                        
                        if(this.optimizedJobAllocatedIds.includes(jobAllocation.id) && jobAllocation.optimizationRunId === this.optimizationRun.id){                                    
                            optJobAllocData['optAllocResource'] = jobAllocation.resourceName;
                            optJobAllocData['optAlloc'] = 1;
                        } else if(jobAllocation.optimizationRunId === this.optimizationRun.id){
                            optJobAllocData['optAllocResource'] = jobAllocation.resourceName;
                            optJobAllocData['optAlloc'] = 1;
                        } 
                        if(jobAllocation.status !== 'Deleted'){
                            optJobAllocData['userAllocResource'] = jobAllocation.resourceName;
                        }
                        return optJobAllocData;
                    });                    
                    optJobData['jobAllocations'] = jobAllocRecordData;
                }
                return optJobData;                               
            });            
            driveShiftItemRecordData['jobs'] = jobRecordData;
            return driveShiftItemRecordData;
        });
        driveRecordData['driveShifts'] = driveShiftRecordData;
        return driveRecordData;
    }

    mapData(arrGrouped) {
        let dataGrouped = [];
        each(arrGrouped, itemGrouped => {
            const rawData = itemGrouped.data;                        
            let data = [];
            this.optDriveRunResult = [];
            const res = rawData.map(drive => {
                const optDriveRunResult = this.getOptRunResult(drive);            
                this.optDriveRunResult.push(optDriveRunResult);                                                
                data = this.getOptRunResultData(this.optDriveRunResult);                                        
            })            
            this.optRoleList = uniqBy(this.optRoleList, item => item.role);            
            this.optRoleList = orderBy(this.optRoleList, ['priority', 'role'], ['asc', 'asc']);            
            this.optRunResultColumns = this.getOptRunResultColumns(this.optRoleList);            

            let newItem = {
                key: uniqueId(),
                dateIso: itemGrouped.dateIso,
                data: data,
                columns: this.optRunResultColumns,
                hasData: data.length,
                expanded: false 
            };
            newItem.class = this.generateSectionClass(newItem);            
            dataGrouped.push(newItem);
        })
        return dataGrouped;
    }

    getOptRunResultData(driveRunResult){
        let optRunData = [];        
        driveRunResult.forEach(drive => {
            let rowData = {
                drive: drive.name                
            };                        

            drive.driveShifts.forEach(shift => {
                shift.jobs.forEach(job => {
                    if(job.jobQuantity!== null && job.jobQuantity !== undefined) {
                        rowData[job.jobRole] = {
                            jobQuantity: 0,
                            optAllocTotal: 0,
                            optAllocResources: '',
                            userAllocResources: '',
                            optAllocStatuses: ''
                        };                                                                
                    }
                });
            });
            
            drive.driveShifts.forEach(shift => {
                shift.jobs.forEach(job => {                    
                    if(job.jobQuantity!== null && job.jobQuantity !== undefined) {
                        let roleData = rowData[job.jobRole];                        
                        roleData.jobQuantity += job.jobQuantity;                                                

                        job.jobAllocations.forEach(allocation => {
                            if(allocation!== null && allocation!== undefined){
                                roleData.optAllocTotal += allocation.optAlloc || 0;
                                let optAllocResource = allocation.optAllocResource || '';
                                let userAllocResource = allocation.userAllocResource || '';
                                let optAllocStatus = allocation.status || '';                                                                
                                if(optAllocResource){
                                    if(roleData.optAllocResources){
                                        roleData.optAllocResources += `, ${optAllocResource}`;
                                        roleData.optAllocStatuses += `, ${optAllocStatus}`;
                                    } 
                                    else {                                        
                                        roleData.optAllocResources = optAllocResource; 
                                        roleData.optAllocStatuses = optAllocStatus;                                                                                  
                                    }
                                }
                                if(userAllocResource){
                                    if(roleData.userAllocResources){
                                        roleData.userAllocResources += `, ${userAllocResource}`;
                                    }
                                    else {
                                        roleData.userAllocResources = userAllocResource;
                                    }
                                }                                
                            }                            
                        });
                        rowData[job.jobRole + ' Class'] = this.setCss(roleData.optAllocTotal, roleData.jobQuantity);
                        rowData[job.jobRole + ' Render'] = this.transformJobRoleData(rowData[job.jobRole]);                        
                    }
                    
                });
            });           
            optRunData.push(rowData);
        });
        return optRunData;
    }

    transformJobRoleData (roleData){        
        let allocResources = ''; 
        let allOptAllocStatusesDeleted = true;
        if(roleData.optAllocResources === '') {
            roleData.optAllocResources = 'None';
        }

        if(roleData.optAllocResources === 'None' && roleData.userAllocResources === ''){
            allocResources = roleData.optAllocResources;            
        } else if (roleData.optAllocResources !== 'None' && roleData.userAllocResources === ''){
            const optAllocStatusesArray = roleData.optAllocStatuses.split(',').map(status => status.trim());            
            allOptAllocStatusesDeleted = optAllocStatusesArray.every(status => status === 'Deleted');            
            if (allOptAllocStatusesDeleted && roleData.userAllocResources === '') {
                allocResources = `${roleData.optAllocResources}, > None`;
            } else {
                allocResources = roleData.optAllocResources; 
            }         
        } else if (roleData.optAllocResources === roleData.userAllocResources){
            allocResources = roleData.userAllocResources;
        } else if (roleData.optAllocResources === 'None' && roleData.userAllocResources !== ''){ 
            allocResources = `${roleData.optAllocResources}, > ${roleData.userAllocResources}`;
            roleData.optAllocStatuses = 'Deleted';
        } else {            
            allocResources = `${roleData.optAllocResources}, > ${roleData.userAllocResources}`;                                   
        }

        const allocOptResource = allocResources.split(',').map(allocResource => allocResource.trim());
        const statuses = roleData.optAllocStatuses.split(',').map(status => status.trim());        
        const allocResourceArray = allocOptResource.map((allocResource, index) => {
            const nextAllocResource = allocOptResource[index + 1];
            return {
                key: `subSpan${index + 1}`,
                class: statuses[index] === 'Deleted' ? 'optimization-changed-allocation slds-cell-wrap' : 'slds-cell-wrap',
                text: allocResource,
                hasComma: nextAllocResource && !nextAllocResource.startsWith('>')
            };
        });

        return [
            {
                key: 'span1',
                class: 'slds-cell-wrap slds-p-left_x-small',
                text: `${roleData.optAllocTotal}/${roleData.jobQuantity}` ,
                single: true                              
            },
            {
                key: 'span2',
                class: 'slds-cell-wrap slds-p-left_x-small',
                text: allocResourceArray,                
                single: false
            }
        ];
    }

    getOptRunResultColumns(optRoleList) {        
        optRoleList = optRoleList.map(item => ({
            type: 'optimizationRunResultCell',
            typeAttributes: {
                cellValue: {
                    fieldName: camelize(item.role) + ' Render'
                }
            }, 
            label: item.role,
            cellAttributes: {
                class: {
                    fieldName: camelize(item.role) + ' Class'
                },
                wrapText: true
            }
        }));

        optRoleList = [{
            type: 'text',
            fieldName: 'drive',
            label: "Drive Name - Drive ID",
            wrapText: true,
            cellAttributes: { wrapText: true },
            initialWidth: 380,
        },
         ...optRoleList];
         return optRoleList;
    }
    
    toggleExpand(event) {
        const dateIso = event.currentTarget.dataset['dateIso'];
        const optimizationQueueId = event.currentTarget.dataset['optimizationQueueId'];
        let optimizationQueue = this.optimizationQueues.find(item => item.id === optimizationQueueId);
        if(!optimizationQueue) return;

        let item = optimizationQueue.dataGrouped.find(item => item.dateIso === dateIso);
        if(!item) return;

        item.expanded = !item.expanded;
        item.class = this.generateSectionClass(item);
    }

    toggleCollapseAll(event) {
        const optimizationQueueId = get(event, 'currentTarget.dataset.optimizationQueueId');
        let optimizationQueue = this.optimizationQueues.find(item => item.id === optimizationQueueId);
        let optimizationQueues = [];
        if(optimizationQueue) {
            optimizationQueues = [optimizationQueue]
        } else {
            optimizationQueues = this.optimizationQueues;
        }

        optimizationQueues.forEach(optimizationQueue => {
            optimizationQueue.dataGrouped.forEach(item => {
                item.expanded = false;
                item.class = this.generateSectionClass(item);
            })
        })
    }

    toggleExpandAll(event) {
        const optimizationQueueId = get(event, 'currentTarget.dataset.optimizationQueueId');
        let optimizationQueue = this.optimizationQueues.find(item => item.id === optimizationQueueId);
        let optimizationQueues = [];
        if(optimizationQueue) {
            optimizationQueues = [optimizationQueue]
        } else {
            optimizationQueues = this.optimizationQueues;
        }

        optimizationQueues.forEach(optimizationQueue => {
            optimizationQueue.dataGrouped.forEach(item => {
                item.expanded = true;
                item.class = this.generateSectionClass(item);
            })
        })
    }

    handleClose() {
        const closeEvent = new CustomEvent('close', {});
        this.dispatchEvent(closeEvent);
    }    
}