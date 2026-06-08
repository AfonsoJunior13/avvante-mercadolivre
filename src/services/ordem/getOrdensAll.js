const axios = require('axios');
const getToken = require('../token/getToken');

async function getOrdensAll() {

  const resToken = await getToken.getToken();    
  const access_token = resToken[0].MLCN_ACCESS_TOKEN; 
  const userID = resToken[0].MLCN_USER_ID;
  
  try {
    const response = await axios.get('https://api.mercadolibre.com/orders/search?seller='+userID, {
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
