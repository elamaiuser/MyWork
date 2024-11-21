import { LightningElement, api } from 'lwc';

const TYPE_RESOURCE = {
  RESOURCE: "Person",
  VEHICLE: "Vehicle",
  EQUIPMENT: "Equipment"
}
const ICON_DEFAULT = {
  EQUIPMENT:  'custom:custom19',
  PERSON: 'standard:user'
}
const VEHICLE_ICON_DEFAULT = {
  BUS: 'custom:custom36',
  SCU: 'custom:custom31'
}

export default class SlwcResourceAvatar extends LightningElement {
  @api resource = null;

  get resourceIcon() {
    if(!this.resource) return;
    if(this.resource.assetType === TYPE_RESOURCE.VEHICLE) {
        return VEHICLE_ICON_DEFAULT[(this.resource.category || '').toUpperCase()] || VEHICLE_ICON_DEFAULT.SCU;
    } else {
        return this.resource.assetType && ICON_DEFAULT[this.resource.assetType.toUpperCase()] || ICON_DEFAULT[TYPE_RESOURCE.RESOURCE.toUpperCase()]
    }
  }
}