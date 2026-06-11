const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function getOrdensAll() {

  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;
  const userID = tokenConfig.MLCN_USER_ID;

  try {
    const response = await mlApi.get('getOrdensAll', 'https://api.mercadolibre.com/orders/search?seller=' + userID, {
      headers: {
        Authorization: 'Bearer '+access_token
      }
    });
    
    const results = response.data.results;
    
    // Somente Ordens que podem ser faturadas...
    const idsOrdens = results
      .filter((order) => {
        const payment = order.payments?.[0];
        return order.status === 'paid' && payment?.status === 'approved';
      })
      .map((order) => order.id);

    return idsOrdens;
      
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getOrdensAll };
