import { LightningElement,api } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';
import CustomTableDesktop from './CustomTableDesktop.html'
import CustomTableMobile from './CustomTableMobile.html'
export default class SlwcCustomTable extends LightningElement {
    @api record;
    @api columns;
    @api hideCheckboxColumn;
    @api styled;
    @api keyField;
    @api resizeColumnDisabled;
    get isMobile(){
        return slwcUtils.isMobile()
    }
    get notEmpty(){
        return this.record && this.record.length > 0
    }
    handleRowActions(event) {
        this.dispatchEvent(
            new CustomEvent(
                'rowaction', 
                event)
        );
    }
    render(){
        if(this.isMobile){
            return CustomTableMobile
        } else {
            return CustomTableDesktop
        }
    }
}