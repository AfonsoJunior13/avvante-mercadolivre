const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');


async function ordemEndUpdate(data) {
  
  const connection = await getConnection();  
  
  try {    
        await connection.execute(
            `BEGIN PRC_MLAPI_ORDEM_END_UPDATE(:P_MLOE_ORDER_ID    ,
                                              :P_MLOE_ENDERECO    ,
                                              :P_MLOE_NUMERO      ,
                                              :P_MLOE_COMPLEMENTO ,
                                              :P_MLOE_BAIRRO      ,
                                              :P_MLOE_CIDADE      ,                                           
                                              :P_MLOE_UF          ,
                                              :P_MLOE_CEP         ,
                                              :P_TRANSACTION      ); END;`,
                    {
                        P_MLOE_ORDER_ID: data.ordem_id,
                        P_MLOE_ENDERECO: data.endereco,
                        P_MLOE_NUMERO: data.numero,
                        P_MLOE_COMPLEMENTO: data.complemento,
                        P_MLOE_BAIRRO: data.bairro,
                        P_MLOE_CIDADE: data.cidade,
                        P_MLOE_UF: data.uf,
                        P_MLOE_CEP: data.cep, 
                        P_TRANSACTION: 0
                    }
        );        
    return {success: true};

  } catch (err) {        
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    } else {
      throw new Error('Erro inesperado: ' + err.message);
    }
  } finally {
    await connection.close();
  }
}

module.exports = {  
  ordemEndUpdate
};