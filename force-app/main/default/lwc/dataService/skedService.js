import auraProxy from 'c/auraProxy';

class skedService {
  getAddressPredictions = (params) => auraProxy.getInstance().getAddressPredictions(params);
  getGeocode = (params) => auraProxy.getInstance().getGeocode(params);
  getPlaceDetails = (params) => auraProxy.getInstance().getPlaceDetails(params);
  calculateDistanceMatrix = (params) => auraProxy.getInstance().calculateDistanceMatrix(params);
}

export {
  skedService
}