import { LightningElement, api, track, wire } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
const POPOVER_TRIGGER = {
  CLICK: 'click',
  HOVER: 'hover'
}

const POPOVER_EVENT = {
  HIDE_ALL: 'popover:hideAll'
}

const NUBBIN_SIZE = 16;

export default class SlwcPopover extends LightningElement {
  @api position = null;
  @api trigger = null;
  @api theme = null;
  @api container = null;
  @api size = null;
  @api width = null;
  
  @track initialized = false;
  @track showPopover = false;
  @track popoverStyle = null;
  @track nubbinClass = null;

  @wire(CurrentPageReference) pageRef;

  get POSITION_ACTION_MAP() {
    return {
      'left': [this.showLeft, this.showRight, this.showTop, this.showBottom],
      'right': [this.showRight, this.showLeft, this.showTop, this.showBottom],
      'top': [this.showTop, this.showBottom, this.showLeft, this.showRight],
      'bottom': [this.showBottom, this.showTop, this.showLeft, this.showRight],
      'bottom|right': [this.showBottomRight, this.showTopRight],
      'top|right': [this.showTopRight, this.showBottomRight]
    }
  }

  get popoverElement() {
    return this.template.querySelector('.slds-popover');
  }

  get referenceElement() {
    return this.template.querySelector('slot[name="reference"]');
  }

  get showCloseButton() {
    return this.trigger === POPOVER_TRIGGER.CLICK;
  }

  get popoverClass() {
    return `slds-popover slds-popover_panel ${this.nubbinClass} slds-popover_${this.size} slds-popover_${this.theme}`;
  }

  connectedCallback() {
  }

  renderedCallback() {
    this.registerEvents();
  }

  disconnectedCallback() {
    this.unregisterEvents();
  }

  registerEvents = () => {
    if(this.initialized) return;

    this.unregisterEvents();

    const triggerEvent = this.trigger || POPOVER_TRIGGER.HOVER;
    if (triggerEvent === POPOVER_TRIGGER.CLICK) {
      this.referenceElement.addEventListener('click', (event) => this.handleShowPopover(event));
      //TODO: click outside
    }

    if (triggerEvent === POPOVER_TRIGGER.HOVER) {
      this.referenceElement.addEventListener('mouseover', (event) => this.handleShowPopover(event));
      this.referenceElement.addEventListener('mouseleave', (event) => this.handleHidePopover(event));
    }

    registerListener('popover:event', this.handlePopoverEvent, this);

    this.initialized = true;
  }

  unregisterEvents = () => {
    this.referenceElement.removeEventListener('click', (event) => this.handleShowPopover(event));
    this.referenceElement.removeEventListener('mouseover', (event) => this.handleShowPopover(event));
    this.referenceElement.removeEventListener('mouseleave', (event) => this.handleHidePopover(event));

    unregisterAllListeners(this);
  }
  
  exceedContainer = (top, left, popoverRect, containerRect) => {
    const exceedTop = top < 0;
    const exceedBottom = top + popoverRect.height > (containerRect.bottom - containerRect.top);
    const exceedLeft = left < 0;
    const exceedRight = left + popoverRect.width > (containerRect.right - containerRect.left);
    return exceedTop || exceedBottom || exceedLeft || exceedRight;
  }

  showLeft = (el, containerEl) => {
    const targetRect = el.getBoundingClientRect();
    const containerRect = this.getContainerRect();
    const popoverRect = this.popoverElement.getBoundingClientRect();
    const scrollTop = containerEl.pageYOffset || containerEl.scrollTop;
    let left = targetRect.left - containerRect.left - popoverRect.width - NUBBIN_SIZE;
    let top = targetRect.top - containerRect.top - scrollTop + (targetRect.height / 2) - (popoverRect.height / 2);

    const exceedTop = -top;
    const exceedBottom = top + popoverRect.height - (containerRect.bottom - containerRect.top);
    let nubbinClass = 'slds-nubbin_right';

    if(exceedTop > 0) {
      top = top + exceedTop;
      nubbinClass = null;
    }

    if (exceedBottom > 0) {
      top = top - exceedBottom;
      nubbinClass = null;
    }

    if(this.exceedContainer(top, left, popoverRect, containerRect)) {
      return null;
    }

    return {
      popoverStyle: `
        width: ${this.width};
        z-index: 99; 
        position: fixed;
        opacity: 1;
        top: ${top}px; 
        left: ${left}px;
        opacity: 1;
      `,
      nubbinClass: nubbinClass
    }
  }

  showRight = (el, containerEl) => {
    const targetRect = el.getBoundingClientRect();
    const containerRect = this.getContainerRect();
    const popoverRect = this.popoverElement.getBoundingClientRect();
    const scrollTop = containerEl.pageYOffset || containerEl.scrollTop;
    let left = targetRect.right - containerRect.left + NUBBIN_SIZE;
    let top = targetRect.top - containerRect.top - scrollTop + (targetRect.height / 2) - (popoverRect.height / 2);

    const exceedTop = -top;
    const exceedBottom = top + popoverRect.height - (containerRect.bottom - containerRect.top);
    let nubbinClass = 'slds-nubbin_left';

    if(exceedTop > 0) {
      top = top + exceedTop;
      nubbinClass = null;
    }

    if (exceedBottom > 0) {
      top = top - exceedBottom;
      nubbinClass = null;
    }

    if(this.exceedContainer(top, left, popoverRect, containerRect)) {
      return null;
    }

    return {
      popoverStyle: `
        width: ${this.width};
        z-index: 99; 
        position: fixed;
        opacity: 1; 
        top: ${top}px; 
        left: ${left}px;
      `,
      nubbinClass: nubbinClass
    }
  }

  showTop = (el, containerEl) => {
    const targetRect = el.getBoundingClientRect();
    const containerRect = this.getContainerRect();
    const popoverRect = this.popoverElement.getBoundingClientRect();
    const scrollTop = containerEl.pageYOffset || containerEl.scrollTop;
    let left = targetRect.right - containerRect.left - (targetRect.width / 2) - (popoverRect.width / 2);
    let top = targetRect.top - containerRect.top - scrollTop - popoverRect.height - NUBBIN_SIZE;

    const exceedLeft = -left;
    const exceedRight = left + popoverRect.width - (containerRect.right - containerRect.left);
    let nubbinClass = 'slds-nubbin_bottom';

    if(exceedLeft > 0) {
      left = left + exceedLeft;
      nubbinClass = null;
    }

    if (exceedRight > 0) {
      left = left - exceedRight;
      nubbinClass = null;
    }

    if(this.exceedContainer(top, left, popoverRect, containerRect)) {
      return null;
    }

    return {
      popoverStyle: `
        width: ${this.width};
        z-index: 99; 
        position: fixed;
        opacity: 1; 
        top: ${top}px; 
        left: ${left}px;
      `,
      nubbinClass: nubbinClass
    }
  }

  showBottom = (el, containerEl) => {
    const targetRect = el.getBoundingClientRect();
    const containerRect = this.getContainerRect();
    const popoverRect = this.popoverElement.getBoundingClientRect();
    const scrollTop = containerEl.pageYOffset || containerEl.scrollTop;
    let left = targetRect.right - containerRect.left - (targetRect.width / 2) - (popoverRect.width / 2);
    let top = targetRect.bottom - containerRect.top - scrollTop + NUBBIN_SIZE;
    
    const exceedLeft = -left;
    const exceedRight = left + popoverRect.width - (containerRect.right - containerRect.left);
    let nubbinClass = 'slds-nubbin_top';

    if(exceedLeft > 0) {
      left = left + exceedLeft;
      nubbinClass = null;
    }

    if (exceedRight > 0) {
      left = left - exceedRight;
      nubbinClass = null;
    }

    if(this.exceedContainer(top, left, popoverRect, containerRect)) {
      return null;
    }

    return {
      popoverStyle: `
        width: ${this.width};
        z-index: 99; 
        position: fixed;
        opacity: 1; 
        top: ${top}px; 
        left: ${left}px;
      `,
      nubbinClass: nubbinClass
    }
  }

  showBottomRight = (el, containerEl) => {
    const targetRect = el.getBoundingClientRect();
    const containerRect = this.getContainerRect();
    const popoverRect = this.popoverElement.getBoundingClientRect();
    const scrollTop = containerEl.pageYOffset || containerEl.scrollTop;
    const left = targetRect.right - containerRect.left + (targetRect.width / 2) - popoverRect.width;
    const top = targetRect.bottom - containerRect.top - scrollTop + NUBBIN_SIZE;

    if(this.exceedContainer(top, left, popoverRect, containerRect)) {
      return null;
    }

    return {
      popoverStyle: `
        width: ${this.width};
        z-index: 99; 
        position: fixed;
        opacity: 1; 
        top: ${top}px; 
        left: ${left}px;
      `,
      nubbinClass: 'slds-nubbin_top-right'
    }
  }

  showTopRight = (el, containerEl) => {
    const targetRect = el.getBoundingClientRect();
    const containerRect = this.getContainerRect();
    const popoverRect = this.popoverElement.getBoundingClientRect();
    const scrollTop = containerEl.pageYOffset || containerEl.scrollTop;
    const left = targetRect.right - containerRect.left + (targetRect.width / 2) - popoverRect.width;
    const top = targetRect.top - containerRect.top - scrollTop - popoverRect.height - NUBBIN_SIZE;

    if(this.exceedContainer(top, left, popoverRect, containerRect)) {
      return null;
    }

    return {
      popoverStyle: `
        width: ${this.width};
        z-index: 99; 
        position: fixed;
        opacity: 1; 
        top: ${top}px; 
        left: ${left}px;
      `,
      nubbinClass: 'slds-nubbin_bottom-right'
    }
  }

  getContainerRect = () => {
    const rect = this.containerEl.getBoundingClientRect();
    if(this.container === 'html') {
      return {
        top: rect.top,
        left: rect.left,
        bottom: rect.top + this.containerEl.clientHeight,
        right: rect.left + this.containerEl.clientWidth,
        height: this.containerEl.clientHeight,
        width: this.containerEl.clientWidth
      }
    } 
    return rect;
  }

  handleShowPopover = (event) => {
    const el = event.target;
    if (!el) return;

    if(!this.container) {
      this.container = 'html';
    }

    this.containerEl = event.target.closest(this.container);
    this.containerEl.addEventListener('scroll', this.handleContainerScroll, false);

    if(!this.showPopover) {
      this.showPopover = true;
    
      this.popoverStyle = `
        width: ${this.width};
        position: fixed;
        opacity: 0;
      `;
    }
    
    setTimeout(() => {
      if(!this.popoverElement) return;

      const actions = this.POSITION_ACTION_MAP[this.position];
      const result = actions.reduce((result, action) => {
        if(result) return result;
        return action(el, this.containerEl);
      }, null)

      if(result) {
        const { popoverStyle, nubbinClass } = result; 
        this.popoverStyle = popoverStyle;
        this.nubbinClass = nubbinClass; 
      } else {
        //TODO: force show
      }
    }, 100)
  }

  handleHidePopover = () => {
    this.showPopover = false;
    
    if(this.containerEl) {
      this.containerEl.removeEventListener('scroll', this.handleContainerScroll, false);
    } 
  }

  handlePopoverEvent = (data) => {
    if (data.event === POPOVER_EVENT.HIDE_ALL) {
      this.handleHidePopover();
    }
  }

  handleContainerScroll = (event) => {
    this.handleHidePopover();
  }
}