import { LightningElement, api, track } from 'lwc';

export default class SlwcCalendarDrag extends LightningElement {
    eventRegistered = false;
    @api calendarDays = [];
    @api timeslots = [];
    @api gridRenderSettings = null;

    isDragging = false;
    startX = null;
    startY = null;
    endX = null;
    endY = null;

    @track timeslotMap = {};

    get windowElement() {
        return this.template.ownerDocument;
    }

    get dragZoneElement() {
        return this.template.querySelector('.drag-zone');
    }

    get dragZonePosition() {
        return this.dragZoneElement.getBoundingClientRect();
    }

    get timeslotHeight() {
        return this.gridRenderSettings.slotSize.h * parseFloat(getComputedStyle(document.documentElement).fontSize);
    }
    
    get timeslotWidth() {
        return this.gridRenderSettings.slotSize.w * parseFloat(getComputedStyle(document.documentElement).fontSize);
    }

    get customStyle() {
        const gridRenderSettings = this.gridRenderSettings;
        return {
          dayColumn: [
            `width: ${gridRenderSettings.slotSize.w}rem`
          ].join(';')
        }
    }

    get columns() {
        return this.calendarDays.map((day, columnIndex) => {
            let timeslotData = this.timeslotMap[columnIndex];
            return {
                key: day.dateIso,
                style: !timeslotData ? 'display: none' : [
                    `display: block`,
                    `top: ${timeslotData.top}px`,
                    `bottom: ${timeslotData.bottom}px`
                ].join(';')
            }
        });
    }

    connectedCallback() {
        //init settings
    }

    renderedCallback() {
        this.registerEvents();
    }

    disconnectedCallback() {
        this.unregisterEvents();
    }

    registerEvents = () => {
        if(this.eventRegistered) return;
        this.dragZoneElement.addEventListener('mousedown', this.handleDragStart);
    }

    unregisterEvents = () => {
        this.dragZoneElement.removeEventListener('mousedown', this.handleDragStart);
        this.windowElement.removeEventListener('mousemove', this.handleDrag);
        this.windowElement.removeEventListener('mouseup', this.handleDragEnd);
    }

    isDisabled = () => {
        return false;
    }

    isDraggingIgnored = (paths) => {
        var isDraggingIgnored = false;

        isDraggingIgnored = (paths || []).find(function(path) {
            return path.dataset && !!path.dataset['draggingIgnored'];
        })

        return isDraggingIgnored;
    };

    handleDragStart = (event) => {
        if (event.which !== 1 || 
            this.isDisabled() || 
            this.isDraggingIgnored(event.path)) {
            this.isDragging = false;
            this.clearTimeslotMap();
            return;
        } 
        
        this.startX = (Math.floor((event.clientX - this.dragZonePosition.left) / this.timeslotWidth)) * this.timeslotWidth;
        this.startY = (Math.floor((event.clientY - this.dragZonePosition.top) / this.timeslotHeight)) * this.timeslotHeight;

        if (this.startX < 0 || this.startY < 0) {
            this.isDragging = false;
            this.clearTimeslotMap();
            return;
        }

        this.isDragging = true;

        this.endX = this.startX;
        this.endY = this.startY;

        // console.log('Start drag', this.startX, this.startY);

        this.windowElement.addEventListener('mousemove', this.handleDrag);
        this.windowElement.addEventListener('mouseup', this.handleDragEnd);

        this.generateTimeslotMap();
    }

    handleDrag = (event) => {
        if(!this.isDragging) return;

        this.endX = (Math.floor((event.clientX - this.dragZonePosition.left) / this.timeslotWidth)) * this.timeslotWidth;
        if (this.endX < 0) {
            this.endX = 0;
        } else if (this.endX > (this.dragZonePosition.width - this.timeslotWidth)) {
            this.endX = this.dragZonePosition.width - this.timeslotWidth;
        }

        this.endY = (Math.floor((event.clientY - this.dragZonePosition.top) / this.timeslotHeight)) * this.timeslotHeight;
        if (this.endY < 0) {
            this.endY = 0;
        } else if (this.endY > (this.dragZonePosition.height - this.timeslotHeight)) {
            this.endY = this.dragZonePosition.height - this.timeslotHeight;
        }

        //re-render timeslot
        this.generateTimeslotMap();

        // console.log('Dragging', this.endX, this.endY);
    }

    handleDragEnd = (event) => {
        if(!this.isDragging) return;

        // console.log('End drag', this.startX, this.startY, this.endX, this.endY);

        this.isDragging = false;

        this.windowElement.removeEventListener('mousemove', this.handleDrag);
        this.windowElement.removeEventListener('mouseup', this.handleDragEnd);

        this.clearTimeslotMap();

        //callback
        console.log('callback', this.identifyDateTime())
        const selectTimesEvent = new CustomEvent('addevent', {
            bubbles: true,
            composed: true,
            detail: this.identifyDateTime()
        });
        this.dispatchEvent(selectTimesEvent);
    }

    clearTimeslotMap = () => {
        this.timeslotMap = {};
    }

    generateTimeslotMap = () => {
        let start = this.identifyTimeSlot(this.startX, this.startY);
        let finish = this.identifyTimeSlot(this.endX, this.endY);

        if(start.column > finish.column || (start.column === finish.column && start.row > finish.row)) {
            let temp = start;
            start = finish; 
            finish = temp;
        }

        let timeslotMap = {};

        for(let i = start.column; i <= finish.column; i++) {
            let isFirst = i === start.column;
            let isLast = i === finish.column;
            timeslotMap[i] = {
                top: isFirst ? start.row * this.timeslotHeight : 0,
                bottom: isLast ? ((this.timeslots.length - 1) - (finish.row + 1)) * this.timeslotHeight : 0
            } 
        }
        this.timeslotMap = timeslotMap;
    }

    identifyDateTime = () => {
        var start = this.identifyTimeSlot(this.startX, this.startY);
        var finish = this.identifyTimeSlot(this.endX, this.endY);

        if(start.column > finish.column || (start.column === finish.column && start.row > finish.row)) {
            let temp = start;
            start = finish; 
            finish = temp;
        }
        
        return {
            start: {
                date: this.calendarDays[start.column].dateIso,
                time: this.timeslots[start.row].start,
            },
            finish:  {
                date: this.calendarDays[finish.column].dateIso,
                time: this.timeslots[finish.row].end,
            },
        };
    };

    identifyTimeSlot = (postionX, positionY) => {
        var rowIndex = Math.floor(positionY / this.timeslotHeight);
        var columnIndex = Math.floor(postionX / this.timeslotWidth);

        return {
            row: rowIndex,
            column: columnIndex
        };
    };

}