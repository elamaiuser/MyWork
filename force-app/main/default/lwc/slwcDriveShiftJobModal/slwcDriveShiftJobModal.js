import { LightningElement, track, api, wire } from 'lwc';
import { max } from 'c/lodash';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { fireEvent } from 'c/pubsub';
import * as slwcUtils from 'c/slwcUtils';
import { debugLogService, tagService, tagQueryModel } from 'c/dataService';
import { DriveHelper, DriveFetch } from 'c/slwcDriveGenerator';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { DRIVE_TYPE, MANUALLY_CREATED_FROM, RESOURCE_TYPE, VOLUNTEER_COUNTS_ADJUSTMENT_REASON } from 'c/slwcConstants';

export default class SlwcDriveShiftJobModal extends LightningElement {
    helper = new DriveHelper();

    /* api */
    @api job;
    @api enableAddress = false;
    @api action;
    @api drive;
    @api driveShift;
    @api resourceType;
    @api type;
 
    @track showModal = false;
    @track showSpinner = false;
    @track isVolunteerQuantityChanged = false;
    @track isOtherVolunteerAdjustmentReasonNeeded = false;

    @track isPersonResource;
    @track isVolunteerResource;
    @track isVehicleResource;
    @track isEquipmentResource;
    @track errorMessages = [];

    @wire(CurrentPageReference) pageRef;
    masterData = {};
    resourceRoleGroupRoleTimeDataMap = {};

    get modalHeader() {
        switch (this.action) {
            case "create":
                return "New Job";
            case "edit":
                return "Update Job";
        }
    }

    get driveSite() {
        return this.drive ? this.drive.driveSite : null
    }

    get showTags() {
        return this.isPersonResource || this.isVolunteerResource;
    }

    get aptRequired() {
        return this.drive && this.drive.aptRequired;
    }

    get disabledSave() {
        if(this.isVehicleResource) {
            return this.drive.doNotUseVehicle;
        }

        return false;
    }

    get quantityDisabled() {
        if(this.isVehicleResource) {
            return true;
        }

        return this.isVolunteerResource || this.showAptQuantityFields;
    }

    get showAptQuantityFields() {
        return this.job && this.job.resourceRole === 'VP/HH';
    }

    get isEditMode() {
        return this.job && this.job.id;
    }

    get isFixedSiteDrive() {
        return this.drive && this.drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE;
    }

    get isOtherVolunteerAdjustmentReasonSelected() {
        return this.job && this.job.volunteerAdjustmentReason === VOLUNTEER_COUNTS_ADJUSTMENT_REASON.OTHER;
    }
    get isDualRoleEditMode() {
        return this.job && this.job.id && this.job.dualRole;
    }

    get secondaryRoleOptions() {
        const roleMap = {
            '2RBC': ['Driver', 'Driver Support', 'OJI', 'None'],
            'Charge': ['Driver', 'Driver Support', 'None'],
            'Trainee': ['Driver Support', 'None'],
            'Driver': ['Competent Driver', 'OJI', 'None'],
            'Driver Support': ['OJI', 'None'],
            'VP/HH': ['OJI', 'None'],
            'Apheresis': ['OJI', 'None'],
            'Plasma': ['OJI', 'None']
          }
  
        return (roleMap[this.job.resourceRole] || [])
            .filter(role => role === 'None' || this.driveShift.jobs?.find(_job => _job.resourceRole === role) || this.driveShift.jobs?.find(_job => _job.key === this.job.key && _job.resourceRole === this.job.resourceRole && _job.dualRole === role))
            .map(role => {
                return {
                    label: role,
                    value: role
                }
        });
    }
    
    connectedCallback() {
        registerListener('showJobModal', this.handleShowJobModal, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    exceptionHandler = (error) => {
        new debugLogService().captureDebugLog(error, this.drive?.id);
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }
    
    showLoading = () => {
        this.showSpinner = true;
    }

    hideLoading = () => {
        this.showSpinner = false;
    }

    /** Custom functions **/
    handleSelectAddress(event) {
        if(!event || !event.detail || !event.detail.placeDetails) return;

        let placeDetails = event.detail.placeDetails;
        this.job.address = placeDetails.formattedAddress;
        this.job.latitude = placeDetails.geometry && placeDetails.geometry.lat;
        this.job.longitude = placeDetails.geometry && placeDetails.geometry.lng;
    }

    closeModal() {
        fireEvent(this.pageRef, 'closeJobModal');
        this.showModal = false;
    }

    getRoleTimeData(role) {
        const resourceRoleGroup = this.helper.getResourceRoleGroup(role, this.masterData);
        return  this.resourceRoleGroupRoleTimeDataMap[resourceRoleGroup];  
    }

    handleResourceRoleChange(event) {
        const name = event.target.name;
        const resourceRole = slwcUtils.getValueFromEvent(event);
        const roleTimeData = this.getRoleTimeData(resourceRole);

        let newJob = {
            [name]: resourceRole
        };

        if(roleTimeData) {
            newJob.leadTime = roleTimeData.leadTime || 0;
            newJob.travelTime = roleTimeData.travelTime || 0;
            newJob.siteLogisticsTo = roleTimeData.siteLogisticsTo || 0;
            newJob.setupTime = roleTimeData.setupTime || 0;
            newJob.breakdownTime = roleTimeData.breakdownTime || 0;
            newJob.travelTime2 = roleTimeData.travelTime2 || 0;
            newJob.wrapUpTime = roleTimeData.wrapUpTime || 0;
            newJob.siteLogisticsBack = roleTimeData.siteLogisticsBack || 0;
        }

        this.job = {
            ...this.job,
            ...newJob
        };
    }

    handleDualRoleChange(event) {
        const name = event.target.name;
        const dualRole = slwcUtils.getValueFromEvent(event);
    
        const compareAndGetValue = (fieldName, resourceRoleTimeData, dualRoleTimeData) => {
            if(!fieldName) return 0;
            if(!dualRoleTimeData) return resourceRoleTimeData[fieldName] || 0;
            
            const value1 = resourceRoleTimeData[fieldName] || 0;
            const value2 = dualRoleTimeData[fieldName] || 0;
            return max([value1, value2]);
        }

        const roleTimeData = this.getRoleTimeData(this.job.resourceRole);
        let newJob = {
            [name]: dualRole
        };
        let dualRoleTimeData;
        if(newJob.dualRole !== 'None') {
            dualRoleTimeData = this.getRoleTimeData(dualRole);
            if((this.driveShift.jobs?.find(_job => _job.resourceRole === this.job.resourceRole)?.quantity) < (this.driveShift.jobs?.find(_job => _job.resourceRole === newJob.dualRole)?.quantity)) {
                newJob.quantity = this.driveShift.jobs?.find(_job => _job.resourceRole === newJob.dualRole)?.quantity; //Update the quantity if secondary role has higher qunatity
            }
        }
        newJob.leadTime = compareAndGetValue('leadTime', roleTimeData, dualRoleTimeData);
        newJob.travelTime = compareAndGetValue('travelTime', roleTimeData, dualRoleTimeData) || 0;
        newJob.siteLogisticsTo = compareAndGetValue('siteLogisticsTo', roleTimeData, dualRoleTimeData) || 0;
        newJob.setupTime = compareAndGetValue('setupTime', roleTimeData, dualRoleTimeData) || 0;
        newJob.breakdownTime = compareAndGetValue('breakdownTime', roleTimeData, dualRoleTimeData) || 0;
        newJob.travelTime2 = compareAndGetValue('travelTime2', roleTimeData, dualRoleTimeData) || 0;
        newJob.siteLogisticsBack = compareAndGetValue('siteLogisticsBack', roleTimeData, dualRoleTimeData) || 0;
        newJob.wrapUpTime = compareAndGetValue('wrapUpTime', roleTimeData, dualRoleTimeData) || 0;
         

        newJob.jobTags = this.job.jobTags.filter(jobTag => jobTag.tag.name !== this.job.dualRole);

        this.job = {
            ...this.job,
            ...newJob
        };
    }

    handleOnChange(event) {
        const name = event.target.name
        let jobClone = {...this.job}
        jobClone[name] = slwcUtils.getValueFromEvent(event);
        if (name === 'redcrossVolunteerQuantity' || name === 'sponsorVolunteerQuantity') {
            jobClone.quantity = (jobClone.redcrossVolunteerQuantity || 0) + (jobClone.sponsorVolunteerQuantity || 0);
            this.isVolunteerQuantityChanged = true;
        }

        if (name === 'vphhQuantity' || name === 'aptQuantity') {
            jobClone.quantity = (jobClone.vphhQuantity || 0) + (jobClone.aptQuantity || 0);
        }

        if(name === 'volunteerAdjustmentReason' && jobClone[name] === VOLUNTEER_COUNTS_ADJUSTMENT_REASON.OTHER) {
            this.isOtherVolunteerAdjustmentReasonNeeded = true;
        }

        this.job = jobClone;
    }

    handleSelectTag(event) {
        if (event.detail && event.detail.selection) {
            let jobTags = [];
            event.detail.selection.forEach((item) => {
                jobTags.push({
                    tagId: item.id,
                    tag: item
                });
            });

            let currentSystemJobTags = (this.job.jobTags || []).filter(jobTag => {
                return jobTag.systemCreated;
            })

            this.job.jobTags = currentSystemJobTags.concat(jobTags);
        }
    }

    populateDefaultTags() {
        if(this.job.id || !this.isPersonResource) return;

        let fetch = new DriveFetch({
            driveType: this.drive.typeOfDrive
        })

        return Promise.all([
            fetch.retrieveDefaultTags(this.drive),
        ])
        .then(([driveTags]) => {
            const jobTagsMap = this.helper.calculateJobTagsMap({
                driveTags
            });
            const personTags = jobTagsMap[RESOURCE_TYPE.PERSON] || [];
            this.job.jobTags = personTags.map(item => {
                return {
                    ...item,
                    systemCreated: true
                }
            });
        })
    }

    populateRoleTimeData() {
        let fetch = new DriveFetch({
            driveType: this.drive.typeOfDrive
        })

        return Promise.all([
            fetch.retrieveDriveSite(this.drive),
            fetch.retrieveCustomSettings(),
            fetch.retrieveRoleTimeData(this.drive),
        ])
        .then(([driveSite, {
            resourceRoleGroups,
        }, roleTimeData]) => {
            return Promise.all([
                driveSite,
                resourceRoleGroups,
                roleTimeData,
                fetch.retrieveTravelTimeIndexItemMap({
                    ...this.drive,
                    driveSite
                })
            ])
        })
        .then(([driveSite, resourceRoleGroups, roleTimeData, travelTimeIndexItemMap ]) => {
            let siteCollectionOperation = (driveSite.siteCollectionOperations || []).find(item => {
                return item.startDate <= this.drive.driveDate && this.drive.driveDate <= item.endDate;
            });

            let { roleTimeDetailMap, roleTimeVarianceMap, roleGroupTimeDetailMap, roleGroupTimeVarianceMap } = this.helper.buildRoleTimeDetailMap(this.drive, {
                roleTimeData: roleTimeData,
                resourceRoleGroups: resourceRoleGroups
            });
            
            let masterData = {
                timezoneSidId: driveSite.timezoneSidId,
                resourceRoleGroups,
                travelTimeIndexItemMap,
                roleTimeDetailMap,
                roleTimeVarianceMap,
                roleGroupTimeDetailMap,
                roleGroupTimeVarianceMap
            };

            let driveResourceRoleGroupRoleTimeDataMap = this.helper.calculateDriveRoleTimeData({
                ...this.drive,
                siteCollectionOperation,
                collectionOperation: siteCollectionOperation.collectionOperation,
                driveSite
            }, masterData)
            let driveShiftResourceRoleGroupRoleTimeDataMap = this.helper.calculateDriveShiftRoleTimeData(
                masterData, {
                ...this.drive,
                driveShiftsMetadata: {
                    driveShifts: (this.drive.driveShifts || []).map(driveShift => {
                        return {
                            ...driveShift,
                            key: driveShift.id || driveShift.key
                        }
                    }),
                    resourceRoleGroupRoleTimeDataMap: driveResourceRoleGroupRoleTimeDataMap
                },
                collectionOperation: siteCollectionOperation.collectionOperation
            }, {
                ...this.driveShift,
                key: this.driveShift.id || this.driveShift.key
            })
            
            this.masterData = masterData;
            this.resourceRoleGroupRoleTimeDataMap = driveShiftResourceRoleGroupRoleTimeDataMap;
        })
    }

    handleShowJobModal(detail) {
        this.showLoading();
        Promise.resolve()
        .then(() => {
            this.showModal = true;
            this.enableAddress = !!detail.enableAddress;
            this.action = detail.action;
            this.resourceType = detail.resourceType;
            this.type = detail.type;
            this.driveShift = detail.driveShift;
            this.drive = detail.drive;  
            this.isVolunteerQuantityChanged = detail.isVolunteerQuantityChanged;  
            this.errorMessages = [];
            
            this.isPersonResource = this.resourceType == 'Person';
            this.isVolunteerResource = this.resourceType == 'Volunteer';
            this.isVehicleResource = this.resourceType == 'Vehicle';
            this.isEquipmentResource = this.resourceType == 'Equipment';
    
            switch(this.action) {
                case "create":
                    this.job = {
                        key: Math.random().toString(36).substring(2, 15),
                        driveId: this.drive.id,
                        driveShiftId: this.driveShift.id,
                        driveSiteId: this.drive.driveSiteId,
                        address: this.driveSite ? this.driveSite.address : null,
                        latitude: this.driveSite ? this.driveSite.geoLocationLatitude : null,
                        longitude: this.driveSite ? this.driveSite.geoLocationLongitude : null,
                        jobTags: [],
                        isManuallyCreated: true,
                        manuallyCreatedFrom: this.type === 'allocationModal' ? MANUALLY_CREATED_FROM.STAFFING_MODAL : MANUALLY_CREATED_FROM.DRIVE_SCHEDULING,
                        jobAllocationTimeSource: false
                    };
    
                    if (this.isVehicleResource) {
                        this.job.assetType = this.resourceType;
                    }
                    break;
                case "edit":
                    this.job = detail.job;
                    break;
            }
    
            this.selectedTags = [];
            if (this.job.jobTags && this.job.jobTags.length > 0) {
                this.job.jobTags.forEach((jobTag) => {
                    if(!jobTag.systemCreated) {
                        if (!jobTag.tag.label) {
                            this.selectedTags.push({...jobTag.tag, label: jobTag.tag.name});
                        } else {
                            this.selectedTags.push(jobTag.tag);
                        }
                    }
                    
                });
            }
        })
        .then(() => {
            return this.populateRoleTimeData()
        })
        .then(() => {
            return this.populateDefaultTags()
        })
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }

    validate() {
        this.errorMessages = [];

        const allValid = [
            ...this.template.querySelectorAll('lightning-input'), 
            ...this.template.querySelectorAll('c-slwc-picklist')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        
        if (this.job.quantity < 0 && this.isVolunteerResource) {
            this.errorMessages.push({
                message: 'Quantity must be greater than or equal to 0.'
            })
        } else if (this.job.quantity <= 0 && !this.isVolunteerResource) {
            this.errorMessages.push({
                message: 'Quantity must be greater than 0.'
            })
        }

        if(this.isPersonResource && this.action === 'create') {
            const existed = this.driveShift.jobs?.find(job => this.helper.isJobsSameRoles(job, this.job));
            if(existed) {
                this.errorMessages.push({
                    message: `${this.job.resourceRole} role already exists.`
                })
                return false;
            }
        }
        
        return allValid && !this.errorMessages.length;
    }

    handleSave() {
        if(!this.validate()) return;

        if(this.isVolunteerResource) {
            const existed = this.driveShift.jobs?.find(job => job.volunteerRole === this.job.volunteerRole);
            if(existed) {
                this.job = {
                    ...this.job,
                    key: existed.key,
                    id: existed.id
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Volunteer complement ${this.isVolunteerQuantityChanged ? 'quantity ': ''} has been updated!`,
                        variant: 'success'
                    })
                );
            }
        }
        
        const originalJob = this.driveShift.jobs?.find(_job => _job.resourceRole === this.job.resourceRole);
        const isDualRoleModified = this.isDualRoleEditMode && originalJob?.dualRole !== this.job.dualRole;
        const reducedDualRoleQuantity = this.isDualRoleEditMode ? Math.max(originalJob?.quantity - this.job.quantity, 0) : 0;
        this.job = {
            ...this.job,
            isDualRoleModified: isDualRoleModified,
            reducedDualRoleQuantity: reducedDualRoleQuantity
        };

        let eventValues = {action: this.action, shiftKey: this.driveShift.key, job: this.job};
        if(this.type != "allocationModal"){
            fireEvent(this.pageRef, 'saveJob', eventValues);
        } else {
            eventValues = {...eventValues, shiftId: this.driveShift.id }
            fireEvent(this.pageRef, 'saveJobModal', eventValues);
        }
        this.closeModal();
    }

    handleSearchTag = (searchData) => {
        let objectSearchField = searchData.searchField ? searchData.searchField : 'Name';
        let query = new tagQueryModel();
        query.nonSystem = true;
        query.queryText = searchData.searchTerm;
        query.searchColumns = [objectSearchField];
        query.resourceTypes = [RESOURCE_TYPE.PERSON];
        query.excludedRecordIds = searchData.selectedIds;
        let svc = new tagService();
        return svc.query(query);
    }
    
}