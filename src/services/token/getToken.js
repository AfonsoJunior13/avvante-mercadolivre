const configRepository = require('../../repositories/configRepository');
const findToken = require('./findToken');
const refreshToken = require('./refreshToken');

require('dotenv').config();

async function getToken() {
  try {
    const unidade_empresarial_id = process.env.UNIDADE_EMPRESARIAL_ID;

    let configML = await configRepository.configFind(unidade_empresarial_id);

    if (!configML?.[0]) {
      throw new Error('Configuração Mercado Livre não encontrada no Oracle.');
    }

    let code = configML[0].MLCN_CODE;
    let token = configML[0].MLCN_TOKEN;
    const clientID = configML[0].MLCN_CLIENT_ID;
    const clientSecret = configML[0].MLCN_CLIENT_SECRET;
    const expires = configML[0].EXPIRES;
    const uri = configML[0].MLCN_REDIRECT_URI;

    if (expires == 'N') {
      return configML;
    }

    if (code) {
      try {
        const resFind = await findToken.findToken(clientID, clientSecret, code, uri);
        if (resFind?.refresh_token) {
          console.log('> Primeiro Token');
          token = resFind.refresh_token;
        }
      } catch (err) {
        console.error('Erro ao obter token inicial (authorization_code):', err?.response?.data || err.message);
      }
    }

    console.log('> Refresh Token');
    const resToken = await refreshToken.refreshToken(clientID, clientSecret, token);

    console.log('> Update Token');
    await configRepository.configUpdate(
      unidade_empresarial_id,
      resToken.refresh_token,
      resToken.access_token,
      resToken.user_id,
      resToken.expires_in
    );

    configML = await configRepository.configFind(unidade_empresarial_id);
    return configML;
  } catch (error) {
    console.error('Erro Carregar Token >> ', error);
    throw error;
  }
}

async function getTokenConfig() {
  const configML = await getToken();

  if (!configML?.[0]) {
    throw new Error('Token OAuth indisponível: nenhuma configuração retornada do Oracle.');
  }

  const row = configML[0];

  if (!row.MLCN_ACCESS_TOKEN) {
    throw new Error('Token OAuth indisponível: MLCN_ACCESS_TOKEN ausente.');
  }

  return row;
}

module.exports = { getToken, getTokenConfig };
