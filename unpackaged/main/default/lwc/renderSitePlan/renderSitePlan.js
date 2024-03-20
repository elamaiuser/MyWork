import { LightningElement, api, wire} from 'lwc';
import getImage from '@salesforce/apex/RenderSitePlanController.getImage';
import getOperationTemplateId from '@salesforce/apex/RenderSitePlanController.getOperationTemplateId';
import { subscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import recordSelected from '@salesforce/messageChannel/Record_Selected__c';

export default class RenderSitePlan extends LightningElement {
    @api objectApiName;
    @api recordId;
    image;
    hasImage = false;
    isLoaded = true;
    message;

    connectedCallback() {
        this.subscribeToMessageChannel();
        if (this.objectApiName === 'sked_Operation_Record__c') {
            this.handleOperationRecord();
        }
    }

    @wire(MessageContext)
    messageContext;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                recordSelected,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleMessage(message) {
        this.isLoaded = false;
        if (this.objectApiName === 'sked__Location__c') {
           let result = message.recordId;    
            this.handleImageLoad(result);
        }
    }

    handleOperationRecord() {
        if (this.recordId != undefined) {
            getOperationTemplateId({operationRecId: this.recordId})
            .then(result => {
                if (result != null) {
                    this.isLoaded = false;
                    this.handleImageLoad(result);
                }
            })
            .catch(error => {
                this.error = error;
            });
        }
    }

    handleImageLoad(templateId) {
        if (templateId != undefined) {
            getImage({templateId: templateId})
            .then(result => {
                this.isLoaded = true;
                console.log(result);
                if (!result.includes('No Site Plan found!')) {
                    this.hasImage = true;
                    this.image = "data:image/png;base64, " + result;
                }else if (result.includes('No Site Plan found!')) {
                    this.message = result;
                }else{
                    console.log(result);
                }
            })
            .catch(error => {
                this.error = error;
            });
        }
    }
}