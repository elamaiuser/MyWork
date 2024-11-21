import { LightningElement, track, api } from 'lwc';
import { classNames, camelize } from 'c/slwcUtils';
import { uniqBy, each, orderBy, uniqueId, get } from 'c/lodash';

const TABS = {
    ALL_DRIVES: 'allDrives',
    ALLOCATED_DRIVES: 'allocatedDrives',
    UNALLOCATED_DRIVES: 'unallocatedDrives'
}

const actions = [
    { label: 'View details', name: 'show_details' },
];

export default class SlwcOptimizationQueueSummary extends LightningElement {
    @track _optimizationQueue;
    @track _dataGrouped;

    @track currentTab = TABS.ALL_DRIVES;

    @api
    get optimizationQueue() {
        return this._optimizationQueue;
    }

    set optimizationQueue(value) {
        this._optimizationQueue = value;
        this._dataGrouped = this.mapData(this._optimizationQueue.dataGrouped);
    }

    get TABS() {
        return TABS;
    }

    get showAllDrivesTab() {
        return this.currentTab === TABS.ALL_DRIVES;
    }

    get showAllocatedDrivesTab() {
        return this.currentTab === TABS.ALLOCATED_DRIVES;
    }

    get showUnallocatedDrivesTab() {
        return this.currentTab === TABS.UNALLOCATED_DRIVES;
    }

    get customClass() {
        return {
            allDrivesTab: classNames('slds-tabs_default__item', {
                'slds-is-active': this.showAllDrivesTab
            }),
            allocatedDrivesTab: classNames('slds-tabs_default__item', {
                'slds-is-active': this.showAllocatedDrivesTab
            }),
            unallocatedDrivesTab: classNames('slds-tabs_default__item', {
                'slds-is-active': this.showUnallocatedDrivesTab
            })
        }
    }

    get dataGrouped() {
        return this._dataGrouped;
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

    setCssDriveShift(allocation, quantity) {
        if(allocation === undefined || quantity === undefined) {
            return 'color-default-text background-gray-super-light important'
        } else if (allocation == 0) {
            return 'color-default-text background-red-super-light important'
        } else if (allocation == quantity) {
            return 'color-default-text background-green-super-light important'
        } else if (allocation < quantity) {
            return 'color-default-text background-yellow-super-light important'
        } else {
            return 'color-default-text background-gray-super-light important'
        }
    }

    mapData(arrGrouped) {
        let dataGrouped = [];
        each(arrGrouped, itemGrouped => {
            const rawData = itemGrouped.data;
            let roleList = []
            let data = []
            const res = rawData.map(drive => {
                let driveRecord = {
                    id: drive.id,
                    name: `${drive.name} - ${drive.ufid}`,
                    driveId: drive.id,
                    projectedRegisteredDonors:drive.projectedRegisteredDonors,
                    hasException: drive.hasException,
                    hasExceptionClass: drive.hasException ? 'slds-current-color color-error': 'hide-exception'
                };

                let driveShiftRecords = drive.driveShifts.map(driveShiftItem => {
                    let driveShiftItemRecord = {
                        name: driveShiftItem.name,
                        id: driveShiftItem.id,
                        driveId: drive.id,
                        hasJobs: false
                    };

                    (driveShiftItem.jobs || []).forEach((job) => {
                        if (!(job.resourceRole || job.assetType)) return;
                        if (!!job.quantity
                            && (this.currentTab === TABS.ALLOCATED_DRIVES && (job.jobAllocationCount < job.quantity)
                                || this.currentTab === TABS.UNALLOCATED_DRIVES && (job.jobAllocationCount >= job.quantity))) {
                            return;
                        }

                        driveShiftItemRecord.hasJobs = true;
                        const fieldName = camelize(job.resourceRole || job.assetType);

                        driveShiftItemRecord[fieldName + 'Class'] = this.setCssDriveShift()
                        driveShiftItemRecord["hasExceptionClass"] = 'hide-exception';

                        if (job.driveShiftId == driveShiftItem.id) {
                            
                            driveShiftItemRecord[fieldName] = `${job.jobAllocationCount}/${job.quantity}`;
                            driveShiftItemRecord[fieldName + 'Class'] = this.setCssDriveShift(job.jobAllocationCount, job.quantity)
                            if (driveRecord[fieldName]) {
                                const numberArr = driveRecord[fieldName].split('/');
                                driveRecord[fieldName] = `${parseInt(numberArr[0]) + job.jobAllocationCount}/${parseInt(numberArr[1]) + job.quantity}`
                                driveRecord[fieldName + 'Class'] = this.setCss(parseInt(numberArr[0]) + job.jobAllocationCount, parseInt(numberArr[1]) + job.quantity)
                            } else {
                                driveRecord[fieldName] = `${job.jobAllocationCount}/${job.quantity}`
                                driveRecord[fieldName + 'Class'] = this.setCss(job.jobAllocationCount, job.quantity)
                            }
                        }

                        let roleTag = (job.jobTags || []).find(jobTag => {
                            return jobTag.tag && jobTag.tag.name === (job.resourceRole || job.assetType);
                        })
                        let rolePriority = roleTag ? roleTag.tag.priority : Number.MAX_SAFE_INTEGER;
                        
                        roleList.push({
                            priority: rolePriority,
                            role: job.resourceRole || job.assetType
                        });
                    })
                    

                    return driveShiftItemRecord;
                });
                
                driveShiftRecords = driveShiftRecords.filter(driveShift => driveShift.hasJobs);
                if (driveShiftRecords.length > 0) {
                    driveRecord["_children"] = driveShiftRecords;
                    data.push(driveRecord);
                }
            });

            roleList = uniqBy(roleList, item => item.role);
            roleList = orderBy(roleList, ['priority', 'role'], ['asc', 'asc']);
            roleList = roleList.map(item => ({
                type: 'text',
                fieldName: camelize(item.role),
                cellAttributes: { class: { fieldName: camelize(item.role) + 'Class' }},
                label: item.role
            }));

            roleList = [{
                type: 'text',
                fieldName: 'name',
                label: "Drive Name - Drive ID",
                wrapText: true,
                cellAttributes: { wrapText: true },
                initialWidth: 380,
            },
            {
                type: 'action',
                typeAttributes: { rowActions: actions },
                cellAttributes: {iconName: 'utility:info', class: {fieldName: 'hasExceptionClass'}},
                initialWidth: 40
            },
            ...roleList]

            let newItem = {
                key: uniqueId(),
                dateIso: itemGrouped.dateIso,
                data: data,
                columns: roleList,
                hasData: data.length,
                expanded: true 
            };
            newItem.class = this.generateSectionClass(newItem);
            dataGrouped.push(newItem);
        });
        return dataGrouped;
    }

    handleTabChange(event) {
        const newTab = event.currentTarget.dataset['value'];
        this.currentTab = newTab;
        this._dataGrouped = this.mapData(this._optimizationQueue.dataGrouped);
    }

    generateSectionClass(item) {
        return classNames('slds-section', {
            'has-data': item.hasData,
            'slds-is-open': item.expanded
        });
    }

    toggleCollapseAll(event) {
        this._dataGrouped.forEach(item => {
            item.expanded = false;
            item.class = this.generateSectionClass(item);
        });
    }
 
    toggleExpandAll(event) {
        this._dataGrouped.forEach(item => {
            item.expanded = true;
            item.class = this.generateSectionClass(item);
        });
    }

    toggleExpand(event) {
        const dateIso = event.currentTarget.dataset['dateIso'];
        let item = this._dataGrouped.find(item => item.dateIso === dateIso);

        if (!item) {
            return;
        }

        item.expanded = !item.expanded;
        item.class = this.generateSectionClass(item);
    }

    handleCellClick(event) {
        let driveId = event.detail.row.driveId;
        let driveShiftId = event.detail.row.id;
        let role = event.detail.columnName;
        let jobId = this.getJobId(driveShiftId, role);

        const onchangeEvent = new CustomEvent('roleclick', {
            detail: {
                driveId: driveId,
                jobId: jobId
            }
        });
        this.dispatchEvent(onchangeEvent);

    }

    getJobId(driveShiftId, role) {
        if (!driveShiftId) return;

        let driveShift;
        each(this._optimizationQueue.dataGrouped, itemGrouped => {
            each(itemGrouped.data, drive => {
                each(drive.driveShifts, shift => {
                    if (shift.id === driveShiftId) {
                        driveShift = shift;
                    }
                });
            })
        });

        let job = driveShift?.jobs?.find(job => camelize(job.resourceRole || job.assetType || "") === role);
        return job?.id;
    }
}