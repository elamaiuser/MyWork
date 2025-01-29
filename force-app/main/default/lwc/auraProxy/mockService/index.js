import initGetLoginUser from './getLoginUser/getLoginUser';

class mockService {
  constructor() {
    initGetLoginUser(this)
  }
}

const mockServiceInstance = new mockService();
export default mockServiceInstance;