import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

import { CloseActionScreenEvent } from 'lightning/actions';
import {
  ShowToastEvent
} from 'lightning/platformShowToastEvent';
import { operationRecordService } from 'c/dataService';

export default class SlwcGenerateOperationRecordPdfModal extends NavigationMixin(LightningElement) {
  @api recordId;
  @api newAttachment;

  @track showSpinner = false;

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference) {
      this.recordId = currentPageReference.state.recordId;
      this.intialize();
    }
  }

  connectedCallback() {
    // this.recordId = 'a2L2i000000UrOFEA0';
    // this.intialize();
  }

  intialize() {
    this.showSpinner = true;
    return Promise.all([
      this.generatePdf()
    ])
      .catch((error) => {
        this.dispatchEvent(new ShowToastEvent({
          message: error.message,
          variant: 'error',
          mode: 'dismissable',
        }));
      })
      .finally(() => {
        this.showSpinner = false;
      });
  }

  generatePdf() {
    let service = new operationRecordService();
    return service.generateOperationRecordPdf({
      operationId: this.recordId
    })
    .then(result => {
      this.newAttachment = result;
    })
  }
  
  viewPdf() {
    window.open(`/servlet/servlet.FileDownload?file=${this.newAttachment.Id}&operationContext=S1`, '_blank');
    // this[NavigationMixin.Navigate]({
    //   type: 'standard__namedPage',
    //   attributes: {
    //       pageName: 'filePreview'
    //   },
    //   state : {
    //     selectedRecordId: this.newAttachment.Id
    //   }
    // });
  }

  handleClose() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}