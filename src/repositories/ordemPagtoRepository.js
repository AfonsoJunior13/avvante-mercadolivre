const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const { logJsonEnv, logJsonRec } = require('../utils/jsonLogger');

require('dotenv').config();

async function ordemPagtoUpdate(data) {
  const connection = await getConnection();
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;

  try {
    const binds = {
      P_UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID,
      P_MLOR_ORDER_ID: data.ordem_id,
      P_MLOR_PAGTO_ML_DATA: data.pagto_ml_data ? new Date(data.pagto_ml_data) : null,
      P_MLOR_PAGTO_ML_STATUS: data.pagto_ml_status ?? null,
      P_MLOR_PAGTO_ML_VLR: data.pagto_ml_vlr ?? 0,
      P_TRANSACTION: 0,
    };

    logJsonEnv('ordemPagtoUpdate', binds);

    await connection.execute(
      `BEGIN PRC_MLAPI_ML_PAGTO( :P_UNIDADE_EMPRESARIAL_ID ,
                                :P_MLOR_ORDER_ID          ,
                                :P_MLOR_PAGTO_ML_DATA     ,
                                :P_MLOR_PAGTO_ML_STATUS   ,
                                :P_MLOR_PAGTO_ML_VLR      ,
                                :P_TRANSACTION            ); END;`,
      binds
    );

    logJsonRec('ordemPagtoUpdate', { success: true, ordem_id: data.ordem_id });
    return { success: true };
  } catch (err) {
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    }
    throw new Error('Erro inesperado: ' + err.message);
  } finally {
    await connection.close();
  }
}

module.exports = { ordemPagtoUpdate };
