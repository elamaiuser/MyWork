import { dataService, queryModelBase } from './base';

class driveShiftTagService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Drive_Shift_Tag__c';
  }
}

class driveShiftTagQueryModel extends queryModelBase  {
}

export {
  driveShiftTagService,
  driveShiftTagQueryModel
}