import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { fireEvent } from 'c/pubsub';
import * as slwcUtils from 'c/slwcUtils';
import { tagService, tagQueryModel } from 'c/dataService';
import { cloneDeep } from 'c/lodash';

export default class SlwcDriveShiftTagModal extends LightningElement {
  @api action;
  @api driveShift;
  @api type;
  @api allocationMode;

  @track model = {
    tag: null,
    minimumQuantity: null
  };

  @track showModal = false;

  @wire(CurrentPageReference) pageRef;

  get modalHeader() {
    switch (this.action) {
      case "create":
        return "New Drive Shift Tag";
      case "edit":
        return "Update Drive Shift Tag";
    }
  }

  connectedCallback() {
    registerListener('showDriveShiftTagModal', this.handleShowModal, this);
  }

  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  /** Custom functions **/
  closeModal() {
    fireEvent(this.pageRef, 'closeDriveShiftTagModal');
    this.showModal = false;
  }

  handleShowModal(detail) {
    this.action = detail.action;
    this.type = detail.type;
    this.driveShift = detail.driveShift;
    this.allocationMode = !!detail.allocationMode;

    switch (this.action) {
      case "create":
        this.model = {
          key: Math.random().toString(36).substring(2, 15),
          driveShiftId: detail.driveShift.id
        };
        break;
      case "edit":
        this.model = cloneDeep(detail.driveShiftTag);
        break;
    }
    this.showModal = true;
  }
  validate() {
    let allInputsCorrect = [
      ...this.template.querySelectorAll("lightning-input"),
      ...this.template.querySelectorAll("c-slwc-lookup")
    ];
    return allInputsCorrect.reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
    }, true);
  }
  handleOnChange(event) {
    let targetName = event.target.name;
    let targetValue = slwcUtils.getValueFromEvent(event);
    this.model[targetName] = targetValue
  }
  handleSelectTag(event) {
    if (event.detail && event.detail.selection) {
      this.model.tag = event.detail.selection;
      this.model.tagId = event.detail.selection.id;
      this.model.tagName = event.detail.selection.name;
    }
  }
  handleSearchTag(searchData) {
    let objectSearchField = searchData.searchField ? searchData.searchField : 'Name';
    let query = new tagQueryModel();
    query.nonSystem = true;
    query.queryText = searchData.searchTerm;
    query.searchColumns = [objectSearchField];
    query.excludedRecordIds = searchData.selectedIds;
    let svc = new tagService();
    return svc.query(query);
  }
  handleSave() {
    if(!this.validate()) return;
    let eventValues = { action: this.action, driveShift: this.driveShift, driveShiftTag: this.model };
    if (!this.allocationMode) {
      fireEvent(this.pageRef, 'saveDriveShiftTag', eventValues);
    } else {
      eventValues = { ...eventValues }
      fireEvent(this.pageRef, 'saveDriveShiftTagInAllocationModal', eventValues);
    }
    this.closeModal();
  }

}