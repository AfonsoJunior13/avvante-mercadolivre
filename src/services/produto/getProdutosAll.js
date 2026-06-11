const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function getProdutosAll() {

  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;
  const userID = tokenConfig.MLCN_USER_ID;

  try {
    const response = await mlApi.get('getProdutosAll', 'https://api.mercadolibre.com/users/' + userID + '/items/search', {
      headers: {
        Authorization: 'Bearer '+access_token
      }
    });
    return response.data.results;
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getProdutosAll };
