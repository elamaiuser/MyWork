import mockData from './data';
import { isEqual } from 'c/lodash';

export default (mockFunctions) => {
  mockFunctions.getLoginUser = (params) => {
    return Promise.resolve()
    .then(() => {
      let mockFound = mockData.find(mock => {
        const paramsMatched = isEqual(mock.params, params);
        return paramsMatched;
      })

      if(!mockFound) {
        mockFound = mockData.find(mock => {
          return !mock.params;
        })
      }

      return mockFound ? mockFound.result : null;
    });
  }
}