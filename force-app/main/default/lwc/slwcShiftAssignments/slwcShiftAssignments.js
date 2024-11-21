import { LightningElement, track, api } from 'lwc';

const columns = [
    { label: 'Resource Name', fieldName: 'resourceName', type: 'text' },
    { label: 'Role', fieldName: 'resourceRole', type: 'text' },
    { label: 'Status', fieldName: 'status', type: 'text' }
];

export default class SlwcShiftAssignments extends LightningElement {
    @track jobAllocationList;
    @track columns = columns;

    @api
    set jobAllocations(inputJobAllocations) {
        this.jobAllocationList = [];
        inputJobAllocations.forEach((ja) => {
            let jobAllocation = {
                id: ja.id,
                resourceName: ja.resource ? ja.resource.name : "",
                resourceRole: ja.resourceRole ? ja.resourceRole : ja.assetType,
                status: ja.status
            }
            this.jobAllocationList.push(jobAllocation);
        });
    }
    get jobAllocations() {
        return this.jobAllocationList;
    }
}