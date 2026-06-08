const axios = require('axios');
const getToken = require('../token/getToken');

async function getProdutosAll() {

  const resToken = await getToken.getToken();    
  const access_token = resToken[0].MLCN_ACCESS_TOKEN; 
  const userID = resToken[0].MLCN_USER_ID;
  
  try {
    const response = await axios.get('https://api.mercadolibre.com/users/'+userID+'/items/search', {
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
