import { LightningElement, api } from "lwc";

import { tooltipTextClasses, tooltipTextStyles } from "./computeStyles";

export default class LwcTooltip extends LightningElement {
  
  @api content = "";
  @api align = "top-right";
  get computeTooltipTextClasses() {
    return tooltipTextClasses(this.align);
  }
  get computeTooltipTextStyles() {
    return tooltipTextStyles(this.content);
  }
}