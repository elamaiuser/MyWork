import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getOrderDetails from '@salesforce/apex/OrderService.getOrderDetails';

export default class OrderBanner extends LightningElement {
    @api recordId; 
    orderId;
    orderName;
    OrderNumber;

    @wire(getOrderDetails, { opportunityId: '$recordId' })
    wiredOrder({ error, data }) {
        if (data) {
            this.orderId = data.Id;
            this.orderName = data.Name;
            this.OrderNumber = data.OrderNumber;
        } else if (error) {
            console.error('Error fetching order details:', error);
        }
    }
}