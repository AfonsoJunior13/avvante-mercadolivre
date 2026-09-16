const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function putEstoque(itemId, availableQuantity) {
  const tokenConfig = await getTokenConfig();

  const response = await mlApi.request('putEstoque', {
    method: 'PUT',
    url: `https://api.mercadolibre.com/items/${itemId}`,
    headers: {
      Authorization: `Bearer ${tokenConfig.MLCN_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    data: {
      available_quantity: availableQuantity,
    },
  });

  return response.data;
}

module.exports = { putEstoque };
