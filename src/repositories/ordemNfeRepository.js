const oracledb = require('oracledb');
const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const { logJsonEnv, logJsonRec } = require('../utils/jsonLogger');

require('dotenv').config();

async function getOrdensNfePendente() {
  const connection = await getConnection();
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;

  try {
    logJsonEnv('getOrdensNfePendente', { UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID });

    const result = await connection.execute(
      `select V.NFE_CHAVE,
              V.NFE,
              V.SR,
              V.NFE_XML,
              V.MLOR_ORDER_ID
         from VIEW_MLOR_NFE V
        where V.UNIDADE_EMPRESARIAL_ID = :UNIDADE_EMPRESARIAL_ID
          and V.MLOR_XML_DT_ENVIO is null`,
      { UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID },
      {
        outFormat: oracledb.OUT_FORMAT_OBJECT,
        fetchInfo: { NFE_XML: { type: oracledb.STRING } },
      }
    );

    const ordens = (result.rows || []).map((row) => ({
      ordem_id: row.MLOR_ORDER_ID,
      nfe_chave: row.NFE_CHAVE,
      nfe: row.NFE,
      sr: row.SR,
      nfe_xml: row.NFE_XML,
    }));

    logJsonRec('getOrdensNfePendente', { total: ordens.length });
    return ordens;
  } catch (err) {
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    }
    throw new Error('Erro inesperado: ' + err.message);
  } finally {
    await connection.close();
  }
}

async function ordemNfeXmlEnvioUpdate(data) {
  const connection = await getConnection();
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;

  try {
    const binds = {
      P_UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID,
      P_MLOR_ORDER_ID: data.ordem_id,
      P_TRANSACTION: 0,
    };

    logJsonEnv('ordemNfeXmlEnvioUpdate', binds);

    await connection.execute(
      `BEGIN PRC_MLAPI_NFE_XML_ENVIO( :P_UNIDADE_EMPRESARIAL_ID ,
                                      :P_MLOR_ORDER_ID          ,
                                      :P_TRANSACTION            ); END;`,
      binds
    );

    logJsonRec('ordemNfeXmlEnvioUpdate', { success: true, ordem_id: data.ordem_id });
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

module.exports = {
  getOrdensNfePendente,
  ordemNfeXmlEnvioUpdate,
};
