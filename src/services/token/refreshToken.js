const axios = require('axios');
const qs = require('qs');

async function refreshToken(clientID, clientSecret, refreshToken) {
    
    let data = qs.stringify({
      'grant_type': 'refresh_token',
      'client_id': clientID,
      'client_secret': clientSecret,
      'refresh_token': refreshToken
    });

    let config = {
        method: 'post',
        maxBodyLength: Infinity,
        url: 'https://api.mercadolibre.com/oauth/token',
        headers: { 
            'accept': 'application/json', 
            'content-type': 'application/x-www-form-urlencoded'
        },
        data : data
    };
    
    const response = await axios.request(config);
    return response.data;
  
}

module.exports = {refreshToken};