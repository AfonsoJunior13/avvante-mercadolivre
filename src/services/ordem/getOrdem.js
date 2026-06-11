const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function getOrdem(ordemID) {

  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

  try {
    const response = await mlApi.get('getOrdem', 'https://api.mercadolibre.com/orders/' + ordemID, {
      headers: {
        Authorization: 'Bearer '+access_token
      }
    });
    return response.data;
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getOrdem };
