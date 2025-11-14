import { LightningElement,api } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';
import CustomModalDesktop from './customModalDesktop.html';
import CustomModalMobile from './customModalMobile.html';
export default class SlwcCustomModal extends LightningElement {

    @api header;
    @api saveBtnLabel = null;
    @api disabledSave = false;
    @api cancelBtnLabel = null;
    @api compactView = false;
    @api modalSize = '';
    @api overflowInitial = false;

    get customClass() {
        return {
            modal: slwcUtils.classNames(`slds-modal slds-fade-in-open slds-modal_${this.modalSize}`, {
                'compact-view': this.compactView,
            }),
            content: slwcUtils.classNames('slds-modal__content slds-p-around_medium slds-scrollable_y', {
                'overflow-initial': this.overflowInitial
            })
        }
    }
    
    get isMobile(){
        return slwcUtils.isMobile()
    }

    render() {
        if(this.isMobile){
            return CustomModalMobile;
        } else {
            return CustomModalDesktop;
        }
    }

    closeModal(){
        console.log("closeModal");
        const _event = new CustomEvent('closecustommodal', {
        });
        this.dispatchEvent(_event);
    }
    handleSave(){
        console.log("handleSave");
        const _event = new CustomEvent('savecustommodal', {
        });
        this.dispatchEvent(_event);
    }
}