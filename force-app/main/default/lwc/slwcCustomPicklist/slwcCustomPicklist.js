import { LightningElement, api } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';
import CustomPicklistMobile from './CustomPicklistMobile.html'
import CustomPicklistDesktop from './CustomPicklistDesktop.html'
export default class SlwcCustomPicklist extends LightningElement {
    @api name;
    @api label;
    @api objectApiName;
    @api selectedValue;
    @api pickListfieldApiName;
    @api variant;

    get isMobile(){
        return slwcUtils.isMobile();
    }
    handleOnChange(event){
        this.dispatchEvent
        const _event = new CustomEvent('custompicklistchange', event);
        this.dispatchEvent(_event);
    }
    render(){
        if(this.isMobile) {
            return CustomPicklistMobile
        } else {
            return CustomPicklistDesktop
        }
    }
}