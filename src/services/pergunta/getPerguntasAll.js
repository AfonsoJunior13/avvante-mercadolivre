const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function getPerguntasAll(status) {
  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

  const limit = 50;
  let offset = 0;
  let total = 0;
  const questions = [];

  try {
    do {
      let url = `https://api.mercadolibre.com/my/received_questions/search?api_version=4&limit=${limit}&offset=${offset}`;
      if (status) {
        url += `&status=${status}`;
      }

      const response = await mlApi.get('getPerguntasAll', url, {
        headers: {
          Authorization: 'Bearer ' + access_token
        }
      });

      const data = response.data;
      total = data.total || 0;
      questions.push(...(data.questions || []));
      offset += limit;
    } while (offset < total);

    return questions;
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getPerguntasAll };
