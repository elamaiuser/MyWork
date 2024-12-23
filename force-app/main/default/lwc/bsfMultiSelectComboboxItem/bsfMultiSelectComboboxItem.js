import { api, LightningElement } from 'lwc';
export default class BsfMultiSelectComboboxItem extends LightningElement {
  @api item;
  @api resetselection = false;
  @api selecteditem = [];

  get itemClass() {
    let itemdata;
    if(this.resetselection && this.selecteditem === '-Select-'){
      this.resetselection = false;
      itemdata = `slds-listbox__item ${''}`;
    }else{
      itemdata = `slds-listbox__item ${this.item.selected ? 'slds-is-selected' : ''}`;
    }
    return itemdata;
  }

  handleClick() {
    this.dispatchEvent(
      new CustomEvent('change', {
        detail: { item: this.item, selected: !this.item.selected }
      })
    );
  }
}