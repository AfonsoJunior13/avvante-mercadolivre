const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function postDescricao(itemId, plainText, atualizar = false) {
  const tokenConfig = await getTokenConfig();
  const texto = String(plainText || '').trim();

  if (!texto) {
    return null;
  }

  const url = atualizar
    ? `https://api.mercadolibre.com/items/${itemId}/description?api_version=2`
    : `https://api.mercadolibre.com/items/${itemId}/description`;

  const response = await mlApi.request('postDescricao', {
    method: atualizar ? 'PUT' : 'POST',
    url,
    headers: {
      Authorization: `Bearer ${tokenConfig.MLCN_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    data: { plain_text: texto },
  });

  return response.data;
}

module.exports = { postDescricao };
