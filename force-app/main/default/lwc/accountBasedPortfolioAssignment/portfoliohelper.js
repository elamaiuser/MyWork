let portfolio_map_filter = (map_obj, f ) => {    
    for (let [k, v] of Object.entries(map_obj) ) {
       f(k, v);
    }
  }

  export {
    portfolio_map_filter
  }