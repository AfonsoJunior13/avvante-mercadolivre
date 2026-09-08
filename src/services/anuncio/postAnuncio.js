const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

function headersJson(accessToken) {
  return {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
    Accept: 'application/json',
  };
}

async function postAnuncioValidar(payload) {
  const tokenConfig = await getTokenConfig();

  await mlApi.request('postAnuncioValidar', {
    method: 'POST',
    url: 'https://api.mercadolibre.com/items/validate',
    headers: headersJson(tokenConfig.MLCN_ACCESS_TOKEN),
    data: payload,
    validateStatus: (status) => status === 204 || status === 200,
  });
}

async function postAnuncio(payload) {
  const tokenConfig = await getTokenConfig();

  const response = await mlApi.request('postAnuncio', {
    method: 'POST',
    url: 'https://api.mercadolibre.com/items',
    headers: headersJson(tokenConfig.MLCN_ACCESS_TOKEN),
    data: payload,
  });

  return response.data;
}

module.exports = { postAnuncio, postAnuncioValidar };
