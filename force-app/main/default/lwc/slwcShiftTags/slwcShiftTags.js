import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class SlwcShiftTags extends LightningElement {
  @api isReadonly;
  @api driveShiftTags;
  @api shift;
  @api allocationMode;

  get buttonEnabled() {
    return !this.isReadonly;
  }

  @wire(CurrentPageReference) pageRef;

  get columns() {
    let columns = [];

    columns.push({ label: 'Tag Name', fieldName: 'tagName', type: 'text', cellAttributes: { alignment: 'left' } });
    columns.push({ label: 'Minimum Quantity', fieldName: 'minimumQuantity', type: 'number', cellAttributes: { alignment: 'left' } });

    if (!this.isReadonly) {
      let rowActions = [];
      rowActions.push({ label: 'Edit', name: 'edit' });
      rowActions.push({ label: 'Delete', name: 'delete' });
      columns.push({ type: 'action', fieldName: 'key', typeAttributes: { rowActions: rowActions, clickAction: (event) => this.clickAction(event) } });
    }
    return columns;
  }

  handleNew() {
    let eventValues = {action : "create", driveShift: this.shift, allocationMode: this.allocationMode };
    fireEvent(this.pageRef, 'showDriveShiftTagModal', eventValues);
  }

  handleEdit(driveShiftTag) {
    let eventValues = { action: "edit", driveShift: this.shift, driveShiftTag: driveShiftTag, allocationMode: this.allocationMode };
    fireEvent(this.pageRef, 'showDriveShiftTagModal', eventValues);
  }

  handleDelete(driveShiftTag) {
    let eventValues = { action: "deleteDriveShiftTag", driveShift: this.shift, driveShiftTag: driveShiftTag };
    if(!this.allocationMode) {
      fireEvent(this.pageRef, 'openDriveShiftConfirmModal', eventValues);
    } else {
      fireEvent(this.pageRef, 'showDeleteDriveShiftTagConfirmModal', eventValues);
    }
  }

  clickAction(event) {
    const actionName = event.currentTarget.name
    const key = event.currentTarget.dataset.value
    const row = find(this.driveShiftTags, (item) => item.key === key)
    switch (actionName) {
      case 'edit':
        this.handleEdit(row);
        break;
      case 'delete':
        this.handleDelete(row);
        break;
    }
  }

  handleRowActions(event) {
    let actionName = event.detail.action.name;
    let row = { ...event.detail.row };

    switch (actionName) {
      case 'edit':
        this.handleEdit(row);
        break;
      case 'delete':
        this.handleDelete(row);
        break;
    }
  }
}