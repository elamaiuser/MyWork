import auraProxy from 'c/auraProxy';

class approvalService {
  canApprove = (params) => auraProxy.getInstance().canApprove(params);
  approveReject = (params) => auraProxy.getInstance().approveReject(params);
  getApprovalHistoryList = (params) => auraProxy.getInstance().getApprovalHistoryList(params);
  getCurrentApprovalData = (params) => auraProxy.getInstance().getCurrentApprovalData(params);
  saveDesignatedApprover = (params) => auraProxy.getInstance().saveDesignatedApprover(params);
  isPendingApproval = (params) => auraProxy.getInstance().isPendingApproval(params);
  withdraw = (params) => auraProxy.getInstance().withdraw(params);
}

export {
  approvalService
}