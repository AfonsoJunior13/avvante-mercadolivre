const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function getVendedor() {
  const tokenConfig = await getTokenConfig();
  const userId = tokenConfig.MLCN_USER_ID;

  const response = await mlApi.get(
    'getVendedor',
    `https://api.mercadolibre.com/users/${userId}`,
    {
      headers: {
        Authorization: `Bearer ${tokenConfig.MLCN_ACCESS_TOKEN}`,
      },
    }
  );

  return response.data;
}

module.exports = { getVendedor };
