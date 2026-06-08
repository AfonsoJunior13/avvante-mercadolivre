const axios = require('axios');
const getToken = require('../token/getToken');

async function getEndereco(ordem_id, shippingID) {
  if (!shippingID) return {};

  try {
        const resToken = await getToken.getToken();
        const access_token = resToken[0].MLCN_ACCESS_TOKEN;        
        
        const resShipping = await axios.get(`https://api.mercadolibre.com/shipments/${shippingID}`, {
          headers: {
            Authorization: `Bearer ${access_token}`,
          },
        });

        const receiver = resShipping.data.receiver_address;
    
        return {
            ordem_id: ordem_id,
            endereco: receiver?.street_name || '',
            numero: receiver?.street_number || '',
            complemento: receiver?.comment || '',      
            bairro: receiver?.neighborhood?.name || '',
            cidade: receiver?.city?.name || '',
            uf: receiver?.state?.name || '',
            cep: receiver?.zip_code || ''
        };

      } catch (errShip) {
        console.error(`Erro ao buscar endereço do shippingID ${shippingID}:`, errShip?.response?.data || errShip);
      }
    
}

module.exports = { getEndereco };
