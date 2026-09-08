const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function putAnuncio(itemId, payload) {
  const tokenConfig = await getTokenConfig();

  const response = await mlApi.request('putAnuncio', {
    method: 'PUT',
    url: `https://api.mercadolibre.com/items/${itemId}`,
    headers: {
      Authorization: `Bearer ${tokenConfig.MLCN_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    data: payload,
  });

  return response.data;
}

module.exports = { putAnuncio };
