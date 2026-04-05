import _getSObjectName from '@salesforce/apex/slwcDataService.getSObjectName';
import _getCustomSettings from '@salesforce/apex/slwcDataService.getCustomSettings';
import _executeQuery from '@salesforce/apex/slwcDataService.executeQuery';
import _executeQueries from '@salesforce/apex/slwcDataService.executeQueries';
import _dynamicDelete from '@salesforce/apex/slwcDataService.dynamicDelete';
import _dynamicUpsert from '@salesforce/apex/slwcDataService.dynamicUpsert';
import _getPicklistOptions from '@salesforce/apex/slwcDataService.getPicklistOptions';
import _getMapDependentOptions from '@salesforce/apex/slwcDataService.getMapDependentOptions';

import _getSkedRegionId from '@salesforce/apex/slwcCollectionOperationService.getSkedRegionId';
import _getSkedRegionIdUsingTaxonomy from '@salesforce/apex/slwcCollectionOperationService.getSkedRegionIdUsingTaxonomy';//HRP-13791

import _getAddressPredictions from '@salesforce/apex/slwcSkedApiService.getAddressPredictions';
import _getGeocode from '@salesforce/apex/slwcSkedApiService.getGeocode';
import _getPlaceDetails from '@salesforce/apex/slwcSkedApiService.getPlaceDetails';
import _calculateDistanceMatrix from '@salesforce/apex/slwcSkedApiService.calculateDistanceMatrix';

import _getEventTypeSettings from '@salesforce/apex/slwcAdminConsoleController.getEventTypeSettings';

import _approveReject from '@salesforce/apex/slwcApprovalService.approveReject';
import _canApprove from '@salesforce/apex/slwcApprovalService.canApprove';
import _getApprovalHistoryList from '@salesforce/apex/slwcApprovalService.getApprovalHistoryList';
import _getCurrentApprovalData from '@salesforce/apex/slwcApprovalService.getCurrentApprovalData';
import _saveDesignatedApprover from '@salesforce/apex/slwcApprovalService.saveDesignatedApprover';
import _isPendingApproval from '@salesforce/apex/slwcApprovalService.isPendingApproval';
import _withdraw from '@salesforce/apex/slwcApprovalService.withdraw';
import _getLatestDCRStatus from '@salesforce/apex/slwcApprovalService.getLatestDCRStatus';

import _getAssetDataCompact from '@salesforce/apex/slwcAllocationService.getAssetDataCompact';
import _getResourceData from '@salesforce/apex/slwcAllocationService.getResourceData';
import _getLinkedDrivesResourceIds from '@salesforce/apex/slwcAllocationService.getLinkedDrivesResourceIds';

import _getPatternResources  from '@salesforce/apex/skedLexResourceController.getPatternResources';
import _getResourceTemplates  from '@salesforce/apex/skedLexResourceController.getResourceTemplates';
import _saveCallOut  from '@salesforce/apex/slwcResourceService.saveCallOut';

import _cloneOpportunity from '@salesforce/apex/slwcOpportunityService.cloneOpportunity';

import _getLoginUser from '@salesforce/apex/slwcUserService.getLoginUser';

import _dispatchDrives from '@salesforce/apex/slwcDriveService.dispatchDrives';
import _captureDriveImpact from '@salesforce/apex/slwcDriveService.captureDriveImpact';
import _searchDriveSite from '@salesforce/apex/slwcDriveService.searchDriveSite';
import _getTerritoryKeys from '@salesforce/apex/slwcDriveService.getTerritoryKeys';
import _validateDraftDrive from '@salesforce/apex/slwcDriveService.validateDraftDrive';

import _initiateOptimizationRun from '@salesforce/apex/slwcOptimizationService.initiateOptimizationRun';
import _getOptimizationRuns from '@salesforce/apex/slwcOptimizationService.getOptimizationRuns';
import _getOptimizationRunStatistics from '@salesforce/apex/slwcOptimizationService.getOptimizationRunStatistics'; // HRP-12511
import _getOptimizedJobAllocation from '@salesforce/apex/slwcOptimizationService.getOptimizedJobAllocation';

import _generateOperationRecords from '@salesforce/apex/slwcOperationRecordService.generateOperationRecords';
import _operationRecord_getResourceData from '@salesforce/apex/slwcOperationRecordService.getResourceData';
import _populateExternalIds from '@salesforce/apex/slwcOperationRecordService.populateExternalIds';
import _submitOperationRecord from '@salesforce/apex/slwcOperationRecordService.submitOperationRecord';

import _getStandardAddress from '@salesforce/apex/slwcArcApiService.getStandardAddress';

import _searchMarket from '@salesforce/apex/slwcAccountService.searchMarket';

import _getScheduleList from '@salesforce/apex/slwcAdminConsoleController.getScheduleList';
import _executeSchedule from '@salesforce/apex/slwcAdminConsoleController.executeSchedule';

import _validateShiftTrades from '@salesforce/apex/slwcDriveShiftTradeService.validateShiftTrades';
import _autoProcessRequest from '@salesforce/apex/slwcDriveShiftTradeService.autoProcessRequest';

import _getTimezone from '@salesforce/apex/slwcSkedApiService.getTimezone';

import _manualRefreshTravelTimeIndexes from '@salesforce/apex/slwcSiteCollectionOperationService.manualRefreshTravelTimeIndexes';
import _isManualRefreshInProgress from '@salesforce/apex/slwcSiteCollectionOperationService.isManualRefreshInProgress';
import _hasInvalidTravelTimeData from '@salesforce/apex/slwcSiteCollectionOperationService.hasInvalidTravelTimeData';
import _getRelatedSiteInfo from '@salesforce/apex/slwcSiteCollectionOperationService.getRelatedSiteInfo';
import _isUserOverrideEnabled from '@salesforce/apex/slwcSiteCollectionOperationService.isUserOverrideEnabled';

import _getUnavailabilityStatistic from '@salesforce/apex/slwcAvailabilityService.getUnavailabilityStatistic';

import { ErrorHandler } from './errorHandler';

class auraService {
  execute = (fn, params) => {
    return fn(params)
    .then(result => {
      return result;
    })
    .catch(err => {
      let errors = ErrorHandler.fromLWC(err);
      if(errors.length > 0) {
        throw errors[0]
      }

      throw ErrorHandler.DEFAULT_LWC_ERROR;
    });
  }

  getSObjectName = (params) => this.execute(_getSObjectName, params);
  getCustomSettings = (params) => this.execute(_getCustomSettings, params);
  executeQuery = (params) => this.execute(_executeQuery, params);
  executeQueries = (params) => this.execute(_executeQueries, params);
  dynamicDelete = (params) => this.execute(_dynamicDelete, params);
  dynamicUpsert = (params) => this.execute(_dynamicUpsert, params);
  getPicklistOptions = (params) => this.execute(_getPicklistOptions, params);
  getMapDependentOptions = (params) => this.execute(_getMapDependentOptions, params);
  getSkedRegionId = (params) => this.execute(_getSkedRegionId, params);
  getSkedRegionIdUsingTaxonomy = (params) => this.execute(_getSkedRegionIdUsingTaxonomy, params);//HRP-13791
  getAddressPredictions = (params) => this.execute(_getAddressPredictions, params);
  getGeocode = (params) => this.execute(_getGeocode, params);
  getPlaceDetails = (params) => this.execute(_getPlaceDetails, params);
  calculateDistanceMatrix = (params) => this.execute(_calculateDistanceMatrix, params);
  getEventTypeSettings = (params) => this.execute(_getEventTypeSettings, params);
  approveReject = (params) => this.execute(_approveReject, params);
  canApprove = (params) => this.execute(_canApprove, params);
  getApprovalHistoryList = (params) => this.execute(_getApprovalHistoryList, params);
  getCurrentApprovalData = (params) => this.execute(_getCurrentApprovalData, params);
  saveDesignatedApprover = (params) => this.execute(_saveDesignatedApprover, params);
  isPendingApproval = (params) => this.execute(_isPendingApproval, params);
  withdraw = (params) => this.execute(_withdraw, params);
  getLatestDCRStatus = (params) => this.execute(_getLatestDCRStatus, params);
  getResourceData = (params) => this.execute(_getResourceData, params);
  getAssetDataCompact = (params) => this.execute(_getAssetDataCompact, params);
  getLinkedDrivesResourceIds = (params) => this.execute(_getLinkedDrivesResourceIds, params);
  getPatternResources = (params) => this.execute(_getPatternResources, params);
  getResourceTemplates = (params) => this.execute(_getResourceTemplates, params);
  saveCallOut = (params) => this.execute(_saveCallOut, params);
  cloneOpportunity = (params) => this.execute(_cloneOpportunity, params);
  getLoginUser = (params) => this.execute(_getLoginUser, params);
  dispatchDrives = (params) => this.execute(_dispatchDrives, params);
  captureDriveImpact = (params) => this.execute(_captureDriveImpact, params);
  searchDriveSite = (params) => this.execute(_searchDriveSite, params);
  getTerritoryKeys = (params) => this.execute(_getTerritoryKeys, params);
  validateDraftDrive = (params) => this.execute(_validateDraftDrive, params);
  initiateOptimizationRun = (params) => this.execute(_initiateOptimizationRun, params);
  getOptimizationRuns = (params) => this.execute(_getOptimizationRuns, params);
  getOptimizationRunStatistics = (params) => this.execute(_getOptimizationRunStatistics, params); // HRP-12511
  getOptimizedJobAllocation = (params) => this.execute(_getOptimizedJobAllocation, params);
  generateOperationRecords = (params) => this.execute(_generateOperationRecords, params);
  operationRecord_getResourceData = (params) => this.execute(_operationRecord_getResourceData, params);
  populateExternalIds = (params) => this.execute(_populateExternalIds, params);
  submitOperationRecord = (params) => this.execute(_submitOperationRecord, params);
  getStandardAddress = (params) => this.execute(_getStandardAddress, params);
  searchMarket = (params) => this.execute(_searchMarket, params);
  getScheduleList = (params) => this.execute(_getScheduleList, params);
  executeSchedule = (params) => this.execute(_executeSchedule, params);
  validateShiftTrades = (params) => this.execute(_validateShiftTrades, params);
  autoProcessRequest = (params) => this.execute(_autoProcessRequest, params);
  getTimezone = (params) => this.execute(_getTimezone, params);
  manualRefreshTravelTimeIndexes = (params) => this.execute(_manualRefreshTravelTimeIndexes, params);
  isManualRefreshInProgress = (params) => this.execute(_isManualRefreshInProgress, params);
  hasInvalidTravelTimeData = (params) => this.execute(_hasInvalidTravelTimeData, params);
  getRelatedSiteInfo = (params) => this.execute(_getRelatedSiteInfo, params);
  isUserOverrideEnabled = (params) => this.execute(_isUserOverrideEnabled, params);
  getUnavailabilityStatistic = (params) => this.execute(_getUnavailabilityStatistic, params);
}

const auraServiceInstance = new auraService();
export default auraServiceInstance;