import { LightningElement,api } from 'lwc';

export default class Sfc360GenericDataTable extends LightningElement {
    @api data = [];
    @api columns = [];
    @api keyField = '';
}