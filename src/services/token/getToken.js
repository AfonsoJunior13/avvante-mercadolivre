const configRepository = require('../../repositories/configRepository');
const findToken = require('./findToken');
const refreshToken = require('./refreshToken');

require('dotenv').config();

async function getToken() {
  try {        
    // Busca informações no Banco de Dados...
    //console.log('<< Find Token BD >>');
    
    let unidade_empresarial_id = process.env.UNIDADE_EMPRESARIAL_ID;

    let configML = await configRepository.configFind(unidade_empresarial_id);    

    let code         = configML[0].MLCN_CODE;
    let token        = configML[0].MLCN_TOKEN;
    let accessToken  = configML[0].MLCN_ACCESS_TOKEN;
    let clientID     = configML[0].MLCN_CLIENT_ID;
    let clientSecret = configML[0].MLCN_CLIENT_SECRET; 
    let expires      = configML[0].EXPIRES;
    let uri          = configML[0].MLCN_REDIRECT_URI;

    if (expires == 'N'){
      return configML;
    }
        
    // Primeira busca de Token...
    try{      
      const resFind = await findToken.findToken(clientID, clientSecret, code, uri);
      if (resFind.status != '400'){
        console.log('> Primeiro Token');
        token = resFind.refresh_token;  
      }
    }
    catch{}
    
    // Refresh Token...
    console.log('> Refresh Token');
    const resToken = await refreshToken.refreshToken(clientID, clientSecret, token);    
    
    // Grava o Token no Banco de Dados...
    console.log('> Update Token');    
    await configRepository.configUpdate(unidade_empresarial_id, resToken.refresh_token, resToken.access_token, resToken.user_id, resToken.expires_in);

    configML = await configRepository.configFind(unidade_empresarial_id);    
    return configML; 

  } catch (error) {
    console.error('Erro Carregar Token >> ', error);
  }
}

module.exports = {getToken};
