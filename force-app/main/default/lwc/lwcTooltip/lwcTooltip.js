import { LightningElement, api } from "lwc";

import { tooltipTextClasses, tooltipTextStyles } from "./computeStyles";

export default class LwcTooltip extends LightningElement {
  /**
   * @property {string} - Text to display
   */
  @api content = "";

  /**
   * @property {string} - Tooltip alignment
   * @values top-right, top-left
   */
  @api align = "top-right";

  /**
   * @type {string} - Returns the classes for the tooltip text
   */
  get computeTooltipTextClasses() {
    return tooltipTextClasses(this.align);
  }

  /**
   * @type {string} - Returns the styles for the tooltip text
   */
  get computeTooltipTextStyles() {
    return tooltipTextStyles(this.content);
  }
}