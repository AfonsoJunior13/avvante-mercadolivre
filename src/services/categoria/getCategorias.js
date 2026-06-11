const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function getCategorias() {

  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

  try {
    const response = await mlApi.get('getCategorias', 'https://api.mercadolibre.com/sites/MLB/categories', {
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

module.exports = { getCategorias };
