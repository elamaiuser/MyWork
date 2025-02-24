import auraServiceInstance from './auraService';
// import mockServiceInstance from './mockService/index';

class auraProxyConfig {
  static enabledMock = false;

  static enableMock = () => {
    auraProxyConfig.enabledMock = true;
  }
}

export default {
  auraProxyConfig,
  getInstance: () => {
    return auraServiceInstance;

    // if(auraProxyConfig.enabledMock) {
    //   return mockServiceInstance;
    // } else {
    //   return auraServiceInstance;
    // } 
  }
};