const axios = require('axios');
const getToken = require('../token/getToken');

async function getTpAnuncios() {

  const resToken = await getToken.getToken();    
  const access_token = resToken[0].MLCN_ACCESS_TOKEN;    
  
  try {
    const response = await axios.get('https://api.mercadolibre.com/sites/MLB/listing_types', {
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
