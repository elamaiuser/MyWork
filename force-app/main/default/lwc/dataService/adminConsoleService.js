import auraProxy from 'c/auraProxy';

class adminConsoleService {
  getScheduleList = (params) => auraProxy.getInstance().getScheduleList(params);
  executeSchedule = (params) => auraProxy.getInstance().executeSchedule(params);
}

export {
  adminConsoleService
}