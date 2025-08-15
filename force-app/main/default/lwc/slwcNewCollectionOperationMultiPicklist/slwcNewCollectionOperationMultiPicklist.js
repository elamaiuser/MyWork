import { LightningElement, track, api } from 'lwc';
import { classNames } from 'c/slwcUtils';
import { collectionOperationService } from 'c/dataService';
import { cloneDeep, extend, isArray, xor, groupBy, keyBy, isEqual } from 'c/lodash';
import { DateTime } from 'c/luxon';
import * as slwcUtils from 'c/slwcUtils';

const TERRITORY_TYPE = {
  ARC_REGION: 'ARC Region',
  DIVISION: 'Division',
  DISTRICT: 'District',
  COLLECTION_OPERATION: 'Collection Operation'
};

export default class SlwcNewCollectionOperationMultiPicklist extends LightningElement {
  @api container;
  @api collectionOperationSingleSelect = false;
  @api districtSingleSelect = false;
  @api regionSingleSelect = false;
  @api regionMaxSelections = 2;
  @api divisionSingleSelect = false;
  @api variant;
  @api dropdownPosition = 'left';
  @api timeBlockEnabled;
  @api sharedTimeBlockDisabled = false;

  @track _defaultValues = {
    divisions: [],
    arcRegions: [],
    districts: [],
    territoryCollectionOperations: [],
    timeBlocks: []
  };
  @api
  get defaultValues() {
    return this._defaultValues;
  }
  set defaultValues(value) {
    this._defaultValues = value || this._defaultValues;
  }

  @track _dateRange = {
    startDate: null,
    endDate: null
  }
  @api 
  get dateRange() {
    return this._dateRange;
  }
  set dateRange(value) {
    if(isEqual(value, this._dateRange)) {
      return;
    }

    this._dateRange = value || this._dateRange; 
    this.init();
  }

  allDivisionOptions = [];
  allARCRegionOptions = [];
  allDistrictOptions = [];
  allCollectionOperationOptions = [];
  
  @track territoryPopverState = {
    divisionOptions: [],
    arcRegionOptions: [],
    districtOptions: [],

    selectedDivisions: [],
    selectedARCRegions: [],
    selectedDistricts: []
  }
  @track clonedTerritoryPopverState = cloneDeep(this.territoryPopverState);

  @track collectionOperationPicklistState = {
    filters: {
      searchString: ''
    },
    collectionOperationOptions: [],
    collectionOperationTreeData: [],
    selectedTerritoryCollectionOperations: []
  }
  @track clonedCollectionOperationPicklistState = cloneDeep(this.collectionOperationPicklistState);

  @track timeBlockState = {
    timeBlockOptions: [],
    selectedTimeBlocks: [],
    disabled: false
  };

  @track showTerritoriesPopover = false;
  @track showCollectionOperationPicklist = false;
  @track territoriesPopoverPosition = null;
  @track collectionOperationPicklistPosition = null;

  @track loading = false;
  
  get inputDisabled() {
    return !this.dateRange || !this.dateRange.startDate || !this.dateRange.endDate || this.loading;
  }

  get showLabel() {
    return this.variant !== 'label-hidden'
  }

  get picklistElement() {
    return this.template.querySelector('.slds-button-group');
  }

  get picklistElementPosition() {
    if(!this.picklistElement) return null;
    return this.picklistElement.getBoundingClientRect();
  }
  
  get customClass() {
    return {
      territoriesPopover: classNames('slds-popover slds-popover_panel slds-nubbin_top-left territories-filters__popover', {
        'slds-fade-in-open': this.showTerritoriesPopover
      }),
      territoriesPopoverBackdrop: classNames('slds-backdrop', {
        'slds-backdrop--open': this.showTerritoriesPopover
      }),
      collectionOperationPicklist: classNames('bco-select__menu-container slds-lookup__menu slds-dropdown', {
        'slds-fade-in-open': this.showCollectionOperationPicklist
      })
    }
  }

  get customStyle() {
    return {
      territoriesPopover: this.territoriesPopoverPosition ? [
        `top: ${this.territoriesPopoverPosition.top}px`,
        `left: ${this.territoriesPopoverPosition.left}px`
      ].join(';') : '',
      collectionOperationPicklist: this.collectionOperationPicklistPosition ? [
        `top: ${this.collectionOperationPicklistPosition.top}px`,
        `left: ${this.dropdownPosition === 'left' ? this.collectionOperationPicklistPosition.left : this.collectionOperationPicklistPosition.left + this.collectionOperationPicklistPosition.width}px`,
        this.dropdownPosition === 'left' ? null : `transform: translateX(-100%)`
      ].filter(item => item).join(';') : ''
    }
  }

  get selectionLabel() {
    if(this.loading) return 'Loading...';

    let selectedOptions = [];
    this.getSelectedTerritoryCollectionOperations(this.collectionOperationPicklistState.collectionOperationTreeData, selectedOptions);
    if (!selectedOptions || selectedOptions.length == 0) {
        return `Select Option(s)`;
    }
    else if (selectedOptions.length == 1) {
        return selectedOptions[0].collectionOperation.label;
    }
    else if (selectedOptions.length == this.collectionOperationPicklistState.collectionOperationOptions.length) {
        return 'All options selected';
    }
    else {
        return selectedOptions.length + ' options selected';
    }
  }

  connectedCallback() {
    this.init();
  }

  showLoading() {
    this.loading = true;
  }

  hideLoading() {
    this.loading = false;
  }

  init() {
    if(!this.dateRange || !this.dateRange.startDate || ! this.dateRange.endDate) {
      this.collectionOperationPicklistState = {
        filters: {
          searchString: ''
        },
        collectionOperationOptions: [],
        collectionOperationTreeData: [],
        selectedTerritoryCollectionOperations: []
      }
      this.clonedCollectionOperationPicklistState = cloneDeep(this.collectionOperationPicklistState);

      //data changed
      const pickValuesChangeEvent = new CustomEvent('change', {
        detail: { 
          selectedDivisions: [],
          selectedARCRegions: [],
          selectedDistricts: [],
          selectedTerritoryCollectionOperations: [],
        }
      });
      this.dispatchEvent(pickValuesChangeEvent);
      return;
    }

    this.showLoading();
    let service = new collectionOperationService();
    service.getCollectionOperationDataNew({
      startDate: this.dateRange.startDate,
      endDate: this.dateRange.endDate 
    })
    .then((data) => {
        const territories = data.territories || [];
        const collectionOperations = data.collectionOperations || [];
        const territoryCollectionOperations = data.territoryCollectionOperations || [];        
        const {validDistricts, validARCRegions, validDivisions} = this.filterValidTerritoryOptions(territoryCollectionOperations,territories);

        this.allDivisionOptions = this.buildPicklistOptions(validDivisions);
        this.allARCRegionOptions = this.buildPicklistOptions(validARCRegions);
        this.allDistrictOptions = this.buildPicklistOptions(validDistricts);
        this.allCollectionOperationOptions = this.buildPicklistOptions(collectionOperations, territoryCollectionOperations);
        
        this.mapTerritoryCollectionOperations = this.buildMapTerritoryCollectionOperations(this.allCollectionOperationOptions, territoryCollectionOperations);

        //set default values
        this.initDefaultValues(true);

        if (this.timeBlockEnabled) {
          this.refreshTimeBlockData();
        }
    })
    .catch((e) => {
      console.log(e);
    })
    .finally(() => this.hideLoading());
  }

  filterValidTerritoryOptions = (territoryCollectionOperations, allTerritories) => {
    if (!territoryCollectionOperations || !territoryCollectionOperations.length) return [];

    let validDistricts = allTerritories.filter(item => {
      return (territoryCollectionOperations.map(item => item.territoryId).includes(item.id)) && item.recordTypeName === TERRITORY_TYPE.DISTRICT;
    });

    let validARCRegions = allTerritories.filter(item => {
      return (validDistricts.map(item => item.parentId).includes(item.id)) && item.recordTypeName === TERRITORY_TYPE.ARC_REGION;
    });

    let validDivisions = allTerritories.filter(item => {
      return (validARCRegions.map(item => item.parentId).includes(item.id)) && item.recordTypeName === TERRITORY_TYPE.DIVISION;
    });

    return {
      validDistricts,
      validARCRegions,
      validDivisions
    };
  }

  buildPicklistOptions = (data) => {
    return data.map(item => {
      const { startDate, endDate } = item;
      const startDateString = this.formatDate(startDate);
      const endDateString = this.formatDate(endDate);

      let description = '';
      if(startDate && !endDate) {
        description = `Valid from ${startDateString}`
      } else if (!startDate && endDate) {
        description = `Valid to ${endDateString}`
      } else if (startDate && endDate) {
        description = `Valid from ${startDateString} to ${endDateString}`
      }
      
      return {
        ...item,
        value: item.id,
        label: item.name,
        description: item.recordTypeName !== TERRITORY_TYPE.DIVISION ? description : null,
        parentId: item.parentId || item.territoryId,
        recordType: item.recordTypeName || TERRITORY_TYPE.COLLECTION_OPERATION,
        selected: false
      }
    })
  }
  
  initDefaultValues = (firstLoad = false) => {
    this.territoryPopverState.divisionOptions = this.allDivisionOptions;
    this.territoryPopverState.selectedDivisions = cloneDeep(this.territoryPopverState.divisionOptions.filter(item => {
      return !!this.defaultValues.divisions.find(selected => selected.value === item.value);
    }))

    this.territoryPopverState.arcRegionOptions = this.filterARCRegionOptions(this.allARCRegionOptions, this.territoryPopverState.selectedDivisions);
    this.territoryPopverState.selectedARCRegions = cloneDeep(this.territoryPopverState.arcRegionOptions.filter(item => {
      return !!this.defaultValues.arcRegions.find(selected => selected.value === item.value); 
    }))

    this.territoryPopverState.districtOptions = this.filterDistrictOptions(this.allDistrictOptions, this.territoryPopverState.selectedARCRegions);
    this.territoryPopverState.selectedDistricts = cloneDeep(this.territoryPopverState.districtOptions.filter(item => {
      return !!this.defaultValues.districts.find(selected => selected.value === item.value); 
    }))

    this.collectionOperationPicklistState.selectedTerritoryCollectionOperations = cloneDeep(this.defaultValues.territoryCollectionOperations);
    const data = this.buildCollectionOperationOptions(this.allCollectionOperationOptions, this.mapTerritoryCollectionOperations);
    this.collectionOperationPicklistState.collectionOperationTreeData = data.collectionOperationTreeData;
    this.collectionOperationPicklistState.collectionOperationOptions = data.collectionOperations;
    this.restoreSelectedCollectionOperationOptions(this.collectionOperationPicklistState); 

    this.timeBlockState.selectedTimeBlocks = cloneDeep(this.defaultValues.timeBlocks);

    if(firstLoad) {
      const currentSelectedTerritoryCollectionOperations = this.getSelectedTerritoryCollectionOperations(this.collectionOperationPicklistState.collectionOperationTreeData);
      const currentSelectedIds = currentSelectedTerritoryCollectionOperations.map(item => item.value);
      const defaultValues = this.defaultValues.territoryCollectionOperations.map(item => item.value);

      if(xor(defaultValues, currentSelectedIds).length) {
        //data changed
        this.clonedCollectionOperationPicklistState = cloneDeep(this.collectionOperationPicklistState);
        this.applyCollectionOperation();
      }
    }
  }

  restoreSelectedCollectionOperationOptions = (collectionOperationPicklistState) => {
    if(collectionOperationPicklistState.selectedTerritoryCollectionOperations && collectionOperationPicklistState.selectedTerritoryCollectionOperations.length) {
      const ids = collectionOperationPicklistState.selectedTerritoryCollectionOperations.map(item => item.value);

      this.updateItemInCollectionOperationTreeData(ids, collectionOperationPicklistState.collectionOperationTreeData, {
        selected: true
      });
    }
  } 

  setTeritotiesPopoverPosition = () => {
    if(!this.picklistElement) return;

    const picklistPosition = this.picklistElementPosition;
    this.territoriesPopoverPosition = {
      top: picklistPosition.y + picklistPosition.height,
      left: picklistPosition.x - 30,
      width: picklistPosition.width
    }
  }

  setCollectionOperationPicklistPosition = () => {
    if(!this.picklistElement) return;

    const picklistPosition = this.picklistElementPosition;
    this.collectionOperationPicklistPosition = {
      top: picklistPosition.y + picklistPosition.height + 1,
      left: picklistPosition.x,
      width: picklistPosition.width
    }
  }

  setCollectionOperationPosition = () => {
    if(!this.picklistElement) return;
  }

  openTerritoriesPopover = () => {
    if(this.inputDisabled) return;

    this.closeCollectionOperationPicklist();
    this.showTerritoriesPopover = true;
    this.setTeritotiesPopoverPosition();

    this.clonedTerritoryPopverState = cloneDeep(this.territoryPopverState);
  }

  closeTerritoriesPopover = () => {
    this.showTerritoriesPopover = false;
  }

  openCollectionOperationPicklist = () => {
    if(this.inputDisabled) return;

    this.collectionOperationPicklistState.filters.searchString = '';
    this.clonedCollectionOperationPicklistState = cloneDeep(this.collectionOperationPicklistState);

    this.closeTerritoriesPopover();
    this.showCollectionOperationPicklist = true;
    this.setCollectionOperationPicklistPosition();
  };

  closeCollectionOperationPicklist = () => {
    this.showCollectionOperationPicklist = false;
    this.closeTerritoriesPopover();
  };

  refreshTerritoriesPopover = () => {
    this.initDefaultValues();

    this.closeTerritoriesPopover();
    this.openCollectionOperationPicklist();
  }

  applyTerritoriesPopover = () => {
    this.territoryPopverState = cloneDeep(this.clonedTerritoryPopverState);
    const data = this.buildCollectionOperationOptions(this.allCollectionOperationOptions, this.mapTerritoryCollectionOperations);
    this.collectionOperationPicklistState.collectionOperationTreeData = data.collectionOperationTreeData;
    this.collectionOperationPicklistState.collectionOperationOptions = data.collectionOperations;
    this.restoreSelectedCollectionOperationOptions(this.collectionOperationPicklistState);

    this.closeTerritoriesPopover();
    this.openCollectionOperationPicklist();
  }

  toggleSelectAll = () => {
    this.updateItemInCollectionOperationTreeData(null, this.clonedCollectionOperationPicklistState.collectionOperationTreeData, {
      selected: true
    })
  }

  toggleDeselectAll = () => {
    this.updateItemInCollectionOperationTreeData(null, this.clonedCollectionOperationPicklistState.collectionOperationTreeData, {
      selected: false
    })
  }

  refreshTimeBlockData = () => {
    function findCommonTimeBlockIds(coList) {
      if (!coList || coList.length === 0) {
        return [];
      }
    
      const firstCoTimeBlocks = new Set(coList[0].collectionOperationTimeBlocks?.map(coTb => coTb.timeBlock.id));
      let commonTimeBlocks = new Set(firstCoTimeBlocks);
    
      for (let i = 1; i < coList.length; i++) {
        const currentCoTimeBlocks = new Set(coList[i].collectionOperationTimeBlocks?.map(coTb => coTb.timeBlock.id));
        const intersection = new Set();
        for (const timeBlockId of commonTimeBlocks) {
          if (currentCoTimeBlocks.has(timeBlockId)) {
            intersection.add(timeBlockId);
          }
        }
        commonTimeBlocks = intersection;
      }
    
      return Array.from(commonTimeBlocks);
    }    

    const collectionOperations = this.collectionOperationPicklistState.selectedTerritoryCollectionOperations?.map(territoryCo => territoryCo.collectionOperation);
    const sharedTimeBlockIds = findCommonTimeBlockIds(collectionOperations);

    let mapTimeBlockById = new Map()
    
    this.collectionOperationPicklistState.selectedTerritoryCollectionOperations?.forEach(territoryCo => {
      territoryCo.collectionOperation.collectionOperationTimeBlocks?.forEach(coTb => {
        if (this.dateRange) {
          const sharedTimeBlockRuleValid = this.sharedTimeBlockDisabled || sharedTimeBlockIds.includes(coTb.timeBlock.id);
          if (sharedTimeBlockRuleValid && coTb.effectiveStartDate <= this.dateRange.endDate && coTb.effectiveEndDate >= this.dateRange.startDate) {
            mapTimeBlockById.set(coTb.timeBlock.id, coTb.timeBlock)
          }
        }
      })
    })

    const timeBlocks = Array.from(mapTimeBlockById.values());
    const availableTimeBlockIds = timeBlocks?.map(tb => tb.id);
    let selectedTimeBlockIds = [];
    this.timeBlockState.selectedTimeBlocks?.forEach(selectedTb => {
      if (availableTimeBlockIds.includes(selectedTb.value)) {
        selectedTimeBlockIds.push(selectedTb.value);
      }
    });

    let timeBlockOptions = [];
    let selectedTimeBlocks = [];
    timeBlocks.forEach(timeBlock => {
      let option = {
        label: timeBlock.name,
        value: timeBlock.id,
        selected: selectedTimeBlockIds.includes(timeBlock.id)
      }
      timeBlockOptions.push(option)
      if (option.selected) {
        selectedTimeBlocks.push(option)
      }
    });

    this.timeBlockState.timeBlockOptions = timeBlockOptions;
    this.timeBlockState.selectedTimeBlocks = selectedTimeBlocks;
    this.timeBlockState.disabled = timeBlockOptions.length === 0;

    this.applyTimeBlock();
  }

  handleTimeBlockChanged = (event) => {
    this.timeBlockState.selectedTimeBlocks = cloneDeep(event.detail.selectedValues);

    this.applyTimeBlock();
  }

  applyTimeBlock = () => {
    const selectedTerritoryCollectionOperations = this.getSelectedTerritoryCollectionOperations(this.collectionOperationPicklistState.collectionOperationTreeData);
    const selectedDivisions = this.territoryPopverState.selectedDivisions;
    const selectedARCRegions = this.territoryPopverState.selectedARCRegions;
    const selectedDistricts = this.territoryPopverState.selectedDistricts;
    this.collectionOperationPicklistState.selectedTerritoryCollectionOperations = cloneDeep(selectedTerritoryCollectionOperations);

    const eventDetail = {
      selectedDivisions: selectedDivisions,
      selectedARCRegions: selectedARCRegions,
      selectedDistricts: selectedDistricts,
      selectedTerritoryCollectionOperations: selectedTerritoryCollectionOperations,
      selectedTimeBlocks: this.timeBlockState.selectedTimeBlocks
    };

    const pickValuesChangeEvent = new CustomEvent('timeblockchange', {
      detail: eventDetail
    });
    this.dispatchEvent(pickValuesChangeEvent);
  }

  applyCollectionOperation = () => {
    this.collectionOperationPicklistState = cloneDeep(this.clonedCollectionOperationPicklistState);
    const selectedTerritoryCollectionOperations = this.getSelectedTerritoryCollectionOperations(this.collectionOperationPicklistState.collectionOperationTreeData);
    const selectedDivisions = this.territoryPopverState.selectedDivisions;
    const selectedARCRegions = this.territoryPopverState.selectedARCRegions;
    const selectedDistricts = this.territoryPopverState.selectedDistricts;
    this.collectionOperationPicklistState.selectedTerritoryCollectionOperations = cloneDeep(selectedTerritoryCollectionOperations);

    if (!this.timeBlockEnabled) {
      const pickValuesChangeEvent = new CustomEvent('change', {
        detail: { 
          selectedDivisions: selectedDivisions,
          selectedARCRegions: selectedARCRegions,
          selectedDistricts: selectedDistricts,
          selectedTerritoryCollectionOperations: selectedTerritoryCollectionOperations
        }
      });
      this.dispatchEvent(pickValuesChangeEvent);
    }
    else {
      this.refreshTimeBlockData();
    }

    this.closeCollectionOperationPicklist();
  }

  expandAllCollectionOperation = () => {
    this.updateItemInCollectionOperationTreeData(null, this.clonedCollectionOperationPicklistState.collectionOperationTreeData, {
      collapsed: false
    })
  }

  collapseAllCollectionOperation = () => {
    this.updateItemInCollectionOperationTreeData(null, this.clonedCollectionOperationPicklistState.collectionOperationTreeData, {
      collapsed: true
    })
  }

  formatDate = (dateIso) => {
    if(!dateIso) return '';
    return DateTime.fromString(dateIso, 'yyyy-MM-dd').toFormat('MM/dd/yyyy')
  }

  buildMapTerritoryCollectionOperations = (allCollectionOperationOptions = [], allTerritoryCollectionOperations = []) => {
    const mapCollectionOperationOptions = keyBy(allCollectionOperationOptions, 'id');

    return groupBy(allTerritoryCollectionOperations.map(item => {
      let collectionOperationOption = JSON.parse(JSON.stringify(mapCollectionOperationOptions[item.collectionOperationId]));
      const { startDate, endDate } = item;
      const startDateString = this.formatDate(startDate);
      const endDateString = this.formatDate(endDate);

      let description = '';
      if(startDate && !endDate) {
        description = `Valid from ${startDateString}`
      } else if (!startDate && endDate) {
        description = `Valid to ${endDateString}`
      } else if (startDate && endDate) {
        description = `Valid from ${startDateString} to ${endDateString}`
      }

      return {
        ...item,
        value: item.id,
        selected: false,
        description: description,
        recordType: TERRITORY_TYPE.COLLECTION_OPERATION,
        collectionOperation: collectionOperationOption
      };
    }), 'territoryId');
  }

  buildDistrictCollectionOperations = (district, allCollectionOperations = [], mapTerritoryCollectionOperations = {}) => {
    if(!district || !allCollectionOperations.length) return [];
    return mapTerritoryCollectionOperations[district] || [];
  }

  buildCollectionOperationOptions = (allCollectionOperations = [], mapTerritoryCollectionOperations = {}) => {
    const selectedDivisions = this.territoryPopverState.selectedDivisions || [];
    const selectedARCRegions = this.territoryPopverState.selectedARCRegions || [];
    const selectedDistricts = this.territoryPopverState.selectedDistricts || [];
    const searchString = (this.clonedCollectionOperationPicklistState.filters.searchString || '').toLowerCase();

    let validCollectionOperations = [];
    let isSearchStringValid = false;
    let isDistrictValid = false;
    let isARCRegionValid = false;
    let isDivisionValid = false;
    let collectionOperationTreeData = selectedDivisions.map(division => {
      let childs = selectedARCRegions.filter(arcRegion => arcRegion.parentId === division.value);
      isSearchStringValid = division.label.toLowerCase().includes(searchString);
      isDivisionValid = childs.length > 0;
      isARCRegionValid = false;
      
      let tempDivision = {
        collapsed: false,
        item: division,
        childs: childs
          .map(arcRegion => {
            let childs = selectedDistricts.filter(district => district.parentId === arcRegion.value);
            isSearchStringValid = isSearchStringValid || arcRegion.label.toLowerCase().includes(searchString);
            isARCRegionValid = isARCRegionValid || childs.length > 0;
            isDistrictValid = false;

            let tempArcRegion = {
              collapsed: false,
              item: arcRegion,
              childs: childs
                .map(district => {
                  let childs = this.buildDistrictCollectionOperations(district.value, allCollectionOperations, mapTerritoryCollectionOperations);
                  isDistrictValid = isDistrictValid || childs.length > 0;
                  isSearchStringValid = isSearchStringValid || district.label.toLowerCase().includes(searchString);
                  validCollectionOperations = validCollectionOperations.concat(childs);

                  let isAnyCollectionOperationMatched = !!childs.find(item => item.collectionOperation.label.toLowerCase().includes(searchString));
                  let tempDistrict = {
                    collapsed: false,
                    item: district,
                    childs: childs
                      .map(territoryCollectionOperation => {
                        let isMatched = territoryCollectionOperation.collectionOperation.label.toLowerCase().includes(searchString);
                        isSearchStringValid = isSearchStringValid || isMatched;
                        return {
                          collapsed: false,
                          shown: isAnyCollectionOperationMatched ? isMatched : isSearchStringValid,
                          item: territoryCollectionOperation
                        }
                      })
                  }
                  tempDistrict.shown = childs.length > 0 && isSearchStringValid;
                  return tempDistrict;
                })
            };
            tempArcRegion.shown = childs.length > 0 && isDistrictValid && isSearchStringValid;
            return tempArcRegion;
          })
      };
      tempDivision.shown = childs.length > 0 && isARCRegionValid && isSearchStringValid;
      return tempDivision;
    })

    return {
      collectionOperations: validCollectionOperations,
      collectionOperationTreeData: collectionOperationTreeData
    }
  }

  getSelectedTerritoryCollectionOperations = (options = [], results = []) => {
    for(let i = 0; i < options.length; i++) {
      let option = options[i];
      if(option.item.recordType === TERRITORY_TYPE.COLLECTION_OPERATION && option.selected) {
        if(!results.find(item => item.id === option.item.id)) {
          results.push(option.item);
        }
      }

      if(option.childs && option.childs.length) {
        this.getSelectedTerritoryCollectionOperations(option.childs, results);
      }
    }

    return results;
  }

  updateItemInCollectionOperationTreeData = (id, options = [], data) => {
    for(let i = 0; i < options.length; i++) {
      let option = options[i];
      let isIdMatched = false;
      if(id && isArray(id)) {
        isIdMatched = id.includes(option.item.value);
      } else if (id) {
        isIdMatched = id === option.item.value;
      }

      if(!id || isIdMatched) {
        option = extend(option, data);
      }

      if(option.childs && option.childs.length) {
        this.updateItemInCollectionOperationTreeData(id, option.childs, data);
      }
    }
  }

  findItemsInCollectionOperationTreeData = (id, options = [], result = []) => {
    for(let i = 0; i < options.length; i++) {
      let option = options[i];
      if(option.item.value === id) {
        result.push(option);
      }

      if(option.childs && option.childs.length) {
        this.findItemsInCollectionOperationTreeData(id, option.childs, result);
      }
    }
    
    return result;
  }

  toggleCollapsed = (event) => {
    const id = event.currentTarget.dataset['item'];
    setTimeout(() => {
      const items = this.findItemsInCollectionOperationTreeData(id, this.clonedCollectionOperationPicklistState.collectionOperationTreeData);
      items.forEach(item => {
        item.collapsed = !item.collapsed;
      })
    });
  }

  toggleSelected = (event) => {
    const id = event.currentTarget.dataset['item'];
    setTimeout(() => {
      if(this.collectionOperationSingleSelect) {
        this.updateItemInCollectionOperationTreeData(null, this.clonedCollectionOperationPicklistState.collectionOperationTreeData, {
          selected: false
        });
      }
      const items = this.findItemsInCollectionOperationTreeData(id, this.clonedCollectionOperationPicklistState.collectionOperationTreeData);
      items.forEach(item => {
        item.selected = !item.selected; 
      })
    })
  }

  filterARCRegionOptions = (allOptions = [], selectedDivisions = []) => {
    const selectedIds = selectedDivisions.map(item => item.value);
    return allOptions.filter(item => selectedIds.includes(item.parentId));
  }

  filterDistrictOptions = (allOptions = [], selectedARCRegions = []) => {
    const selectedIds = selectedARCRegions.map(item => item.value);
    return allOptions.filter(item => selectedIds.includes(item.parentId));
  }

  recheckSelectedOptions = (selectedOptions = [], options = []) => {
    let optionIds = options.map(item => item.value);
    let selected = selectedOptions.filter(item => optionIds.includes(item.value));
    // if(!selected.length) {
    //   //if empty => select all
    //   selected = cloneDeep(options);
    // }

    return selected;
  }

  handleDivisionChanged = (event) => {
    this.clonedTerritoryPopverState.selectedDivisions = cloneDeep(event.detail.selectedValues);

    this.clonedTerritoryPopverState.arcRegionOptions = this.filterARCRegionOptions(this.allARCRegionOptions, this.clonedTerritoryPopverState.selectedDivisions);
    const selectedARCRegions = this.recheckSelectedOptions(this.clonedTerritoryPopverState.selectedARCRegions, this.clonedTerritoryPopverState.arcRegionOptions); 
    this.handleARCRegionChanged({
      detail: {
        selectedValues: selectedARCRegions
      }
    })
  }

  handleARCRegionChanged = (event) => {
    this.clonedTerritoryPopverState.selectedARCRegions = cloneDeep(event.detail.selectedValues);

    this.clonedTerritoryPopverState.districtOptions = this.filterDistrictOptions(this.allDistrictOptions, this.clonedTerritoryPopverState.selectedARCRegions);
    const selectedDistricts = this.recheckSelectedOptions(this.clonedTerritoryPopverState.selectedDistricts, this.clonedTerritoryPopverState.districtOptions); 
    this.handleDistrictChanged({
      detail: {
        selectedValues: selectedDistricts
      }
    })
  }

  handleDistrictChanged = (event) => {
    this.clonedTerritoryPopverState.selectedDistricts = cloneDeep(event.detail.selectedValues);
  }

  handleSearch(event) {
    event.stopPropagation(); //must have

    let targetValue = slwcUtils.getValueFromEvent(event);

    clearTimeout(this.timeoutId); // no-op if invalid id
    this.timeoutId = setTimeout(() => {
      this.clonedCollectionOperationPicklistState.filters.searchString = targetValue;
      const data = this.buildCollectionOperationOptions(this.allCollectionOperationOptions, this.mapTerritoryCollectionOperations);
      this.clonedCollectionOperationPicklistState.collectionOperationTreeData = data.collectionOperationTreeData;
      this.clonedCollectionOperationPicklistState.collectionOperationOptions = data.collectionOperations;
      this.restoreSelectedCollectionOperationOptions(this.clonedCollectionOperationPicklistState); 
    }, 500);
  }
}