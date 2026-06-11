const mlApi = require('../../utils/mlApi');
const qs = require('qs');

async function findToken(clientID, clientSecret, code, redirectURI) {
  
    let data = qs.stringify({
      'grant_type': 'authorization_code',
      'client_id': clientID,
      'client_secret': clientSecret,
      'code': code,
      'redirect_uri': redirectURI,
      'code_verifier': '$CODE_VERIFIER'
    });

    let config = {
      method: 'post',
      maxBodyLength: Infinity,
      url: 'https://api.mercadolibre.com/oauth/token',
      headers: {
        'accept': 'application/json',
        'content-type': 'application/x-www-form-urlencoded'
      },
      data: data
    };

    const response = await mlApi.request('findToken', config);
    return response.data;
  
}

module.exports = {findToken};