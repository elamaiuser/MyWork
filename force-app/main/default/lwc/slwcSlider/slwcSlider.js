import { LightningElement, api } from 'lwc';

const THUMBS = ['start', 'end'];

export default class SlwcSlider extends LightningElement {
  @api label;
  @api labelNotNeeded = false;
  @api
  get min() {
    return this._min;
  }
  set min(value) {
    this._min = parseFloat(value);
    this.initSlider();
  }
  @api
  get max() {
    return this._max;
  }
  set max(value) {
    this._max = parseFloat(value);
    this.initSlider();
  }

  @api
  get step() {
    return this._step;
  }
  set step(value) {
    this._step = parseFloat(value);
    this.initSlider();
  }

  @api
  get start() {
    return this._start;
  };
  set start(value) {
    this._start = this.setBoundries(value);
    this.initSlider();
  }
  @api
  get end() {
    return this._end;
  };
  set end(value) {
    this._end = this.setBoundries(value);
    this.initSlider();
  }

  get rangeValue() {
    return Math.abs(this.end - this.start);
  }

  _max = 100;
  _min = 0;
  _step = 1;
  _start = 0;
  _end = 30;
  _startValueInPixels;
  _endValueInPixels;

  // Elements
  slider;
  sliderRange;
  currentThumb;

  currentThumbName;   // selected Thumb name
  currentThumbPositionX; // shift x - selected thumb left position
  maxRange = 300; // right edge of slider

  isMoving = false;
  rendered = false;

  renderedCallback() {
    if (!this.rendered) {
      this.initSlider();
      this.rendered = true;
    }
  }

  initSlider() {
    this.slider = this.template.querySelector('.slider');
    this.sliderRange = this.template.querySelector('.range');
    const thumb = this.template.querySelector('.thumb');
    if (this.slider && thumb) {
      // this.maxRange = this.slider.offsetWidth - thumb.offsetWidth;
      // set initial thumbs
      this._startValueInPixels = this.convertValueToPixels(this.start);
      this._endValueInPixels = this.convertValueToPixels(this.end);
      this.setThumb('start', this._startValueInPixels);
      this.setThumb('end', this._endValueInPixels);
      this.setRange(this._startValueInPixels, this._endValueInPixels);
    }
  }

  setBoundries(value) {
    let _value = typeof value === 'number' ? value : parseFloat(value);
    _value = _value < 0 ? 0 : value; // MIN
    return _value > this.max ? this.max : _value; // MAX
  }

  convertValueToPixels(value) {
    return parseFloat(((value / this.max) * this.maxRange).toFixed(2));
  }

  convertPixelsToValue(value, step = 1) {
    let _value = parseFloat((value / this.maxRange) * this.max);
    // round to step value
    _value = step > 0 ? Math.round(_value / step) * step : _value;
    return parseFloat(_value.toFixed(2));
  }


  handleMouseDown(event) {
    const thumbId = event.target.dataset.name;
    // allow move
    if (THUMBS.includes(thumbId)) {
      this.currentThumbName = thumbId;
      this.currentThumb = event.target;
      const startX = event.clientX || event.touches[0].clientX;
      this.currentThumbPositionX = startX - this.currentThumb.getBoundingClientRect().left;
      this.toggleActiveThumb(true);
      this.isMoving = true;
    }
    else {
      event.preventDefault();
    }
  }


  onMouseMove(event) {
    // track mouse mouve only when toggle true
    if (this.isMoving) {
      const currentX = event.clientX || event.targetTouches[0].clientX;
      let moveX = currentX - this.currentThumbPositionX - this.slider.getBoundingClientRect().left;

      let moveValue = this.convertPixelsToValue(moveX, this.step);
      // lock the thumb within the bounaries
      moveValue = this.setBoundries(moveValue);
      moveX = this.convertValueToPixels(moveValue);

      switch (this.currentThumbName) {
        case 'start':
          this._startValueInPixels = moveX;
          this._start = moveValue;
          break;
        case 'end':
          this._endValueInPixels = moveX;
          this._end = moveValue;
          break;
      }
      this.setThumb(this.currentThumbName, moveX);
      this.setRange(this._endValueInPixels, this._startValueInPixels);
    }
    else {
      event.preventDefault();
    }
  }

  onMouseUp(event) {
    this.isMoving = false;
    this.toggleActiveThumb(false);
    // publish
    this.onChangeValue();
    event.preventDefault();
  }


  setThumb(thumbName, valueInPixels) {
    const thumbs = this.slider.querySelectorAll('.thumb');
    thumbs.forEach(thumb => {
      if (thumb.dataset.name === thumbName) {
        thumb.style.setProperty('left', `${valueInPixels}px`);
      }
    });
  }

  toggleActiveThumb(toggle = true) {
    const color = toggle ? '#BB202D' : '#1B5297';
    this.currentThumb?.style.setProperty('background', color);
  }

  setRange(start, end) {
    const maxThumb = Math.max(start, end);
    const minThumb = Math.min(start, end);
    const width = Math.abs(maxThumb - minThumb);
    this.sliderRange.style.setProperty('left', `${minThumb}px`);
    this.sliderRange.style.setProperty('width', `${width}px`);
  }

  onChangeValue() {
    this.dispatchEvent(new CustomEvent('change', {
      detail: {
        start: this.start,
        end: this.end,
        range: this.rangeValue
      }
    }));
  }

}