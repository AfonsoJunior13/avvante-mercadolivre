const oracledb = require('oracledb');
const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const { logJsonEnv, logJsonRec } = require('../utils/jsonLogger');

require('dotenv').config();

async function getEstoques() {
  const connection = await getConnection();
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;

  try {
    logJsonEnv('getEstoques', { UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID });

    const result = await connection.execute(
      `select V.UNIDADE_EMPRESARIAL_ID,
              V.MERC_LIVRE_PRODUTO_ID,
              V.MLPD_ID,
              V.QTDE
         from VIEW_MLAPI_ESTOQUE V
        where V.UNIDADE_EMPRESARIAL_ID = :UNIDADE_EMPRESARIAL_ID
          and V.MLPD_ID is not null`,
      { UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const estoques = (result.rows || []).map((row) => ({
      unidade_empresarial_id: row.UNIDADE_EMPRESARIAL_ID,
      merc_livre_produto_id: row.MERC_LIVRE_PRODUTO_ID,
      mlpd_id: row.MLPD_ID,
      qtde: row.QTDE,
    }));

    logJsonRec('getEstoques', { total: estoques.length });
    return estoques;
  } catch (err) {
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    }
    throw new Error('Erro inesperado: ' + err.message);
  } finally {
    await connection.close();
  }
}

module.exports = { getEstoques };
