const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function getTpAnuncios() {

  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

  try {
    const response = await mlApi.get('getTpAnuncios', 'https://api.mercadolibre.com/sites/MLB/listing_types', {
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

module.exports = { getTpAnuncios };
