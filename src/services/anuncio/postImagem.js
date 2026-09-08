const FormData = require('form-data');
const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

function detectarImagem(buffer) {
  if (buffer?.length >= 8 && buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) {
    return { mime: 'image/png', ext: 'png' };
  }
  return { mime: 'image/jpeg', ext: 'jpg' };
}

async function postImagem(buffer, fotoProdutoId) {
  const tokenConfig = await getTokenConfig();
  const { mime, ext } = detectarImagem(buffer);
  const form = new FormData();

  form.append('file', buffer, {
    filename: `foto-${fotoProdutoId || 'anuncio'}.${ext}`,
    contentType: mime,
    knownLength: buffer.length,
  });

  const response = await mlApi.request('postImagem', {
    method: 'POST',
    url: 'https://api.mercadolibre.com/pictures/items/upload',
    headers: {
      Authorization: `Bearer ${tokenConfig.MLCN_ACCESS_TOKEN}`,
      ...form.getHeaders(),
    },
    data: form,
    maxBodyLength: Infinity,
    maxContentLength: Infinity,
  });

  return response.data;
}

module.exports = { postImagem };
