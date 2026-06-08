const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');

require('dotenv').config();

async function ordemUpdate(data) {
  
  const connection = await getConnection();  
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;
  
  try {    
        await connection.execute(
            `BEGIN PRC_MLAPI_ORDEM_UPDATE( :P_UNIDADE_EMPRESARIAL_ID ,
                                           :P_MLOR_ORDER_ID          ,
                                           :P_MLOR_STATUS            ,
                                           :P_MLOR_DATE_CREATED      ,
                                           :P_MLOR_DATE_CLOSED       ,
                                           :P_MLOR_VALOR             ,                                           
                                           :P_MLOR_ENDERECO          ,
                                           :P_MLOR_NUMERO            ,
                                           :P_MLOR_COMPLEMENTO       ,
                                           :P_MLOR_BAIRRO            ,
                                           :P_MLOR_CIDADE            ,
                                           :P_MLOR_UF                ,
                                           :P_MLOR_CEP               ,
                                           :P_MLOR_CPF_CNPJ          ,
                                           :P_MLOR_NOME              , 
                                           :P_MLOR_VLR_FRETE         ,
                                           :P_MLOR_VLR_TAXA_ML       ,
                                           :P_MLOR_DESCONTO          ,                                          
                                           :P_TRANSACTION            ); END;`,
                    {
                        P_UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID,
                        P_MLOR_ORDER_ID: data.ordem_id,
                        P_MLOR_STATUS: data.status,
                        P_MLOR_DATE_CREATED: new Date(data.data_created),
                        P_MLOR_DATE_CLOSED: new Date(data.data_closed),
                        P_MLOR_VALOR: data.vlr_total,                        
                        P_MLOR_ENDERECO: data.endereco,
                        P_MLOR_NUMERO: data.numero,
                        P_MLOR_COMPLEMENTO: data.complemento,
                        P_MLOR_BAIRRO: data.bairro,
                        P_MLOR_CIDADE: data.cidade,
                        P_MLOR_UF: data.uf,
                        P_MLOR_CEP: data.cep, 
                        P_MLOR_CPF_CNPJ: data.cpf_cnpj,
                        P_MLOR_NOME: data.nome,
                        P_MLOR_VLR_FRETE: data.vlr_frete,
                        P_MLOR_VLR_TAXA_ML: data.vlr_taxa_ml,
                        P_MLOR_DESCONTO: data.vlr_desconto,
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
  ordemUpdate
};