const oracledb = require('oracledb');
const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const { logJsonEnv, logJsonRec } = require('../utils/jsonLogger');

require('dotenv').config();

async function perguntaUpdate(data) {
  const connection = await getConnection();
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;

  try {
    const binds = {
      P_UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID,
      P_MLQT_QUESTION_ID: data.question_id,
      P_MLQT_ITEM_ID: data.item_id,
      P_MLQT_SELLER_ID: data.seller_id,
      P_MLQT_STATUS: data.status,
      P_MLQT_TEXT: data.text,
      P_MLQT_DATE_CREATED: data.date_created ? new Date(data.date_created) : null,
      P_MLQT_FROM_USER_ID: data.from_user_id,
      P_MLQT_HOLD: data.hold,
      P_MLQT_DELETED_LISTING: data.deleted_from_listing,
      P_MLQT_ANSWER_TEXT: data.answer_text,
      P_MLQT_ANSWER_STATUS: data.answer_status,
      P_MLQT_ANSWER_DATE: data.answer_date ? new Date(data.answer_date) : null,
      P_MLQT_BUYER_NOME: data.buyer_nome,
      P_MLQT_BUYER_EMAIL: data.buyer_email,
      P_MLQT_BUYER_PHONE: data.buyer_phone,
      P_TRANSACTION: 0
    };

    logJsonEnv('perguntaUpdate', binds);

    await connection.execute(
      `BEGIN PRC_MLAPI_PERGUNTA_UPDATE( :P_UNIDADE_EMPRESARIAL_ID ,
                                         :P_MLQT_QUESTION_ID       ,
                                         :P_MLQT_ITEM_ID           ,
                                         :P_MLQT_SELLER_ID         ,
                                         :P_MLQT_STATUS            ,
                                         :P_MLQT_TEXT              ,
                                         :P_MLQT_DATE_CREATED      ,
                                         :P_MLQT_FROM_USER_ID      ,
                                         :P_MLQT_HOLD              ,
                                         :P_MLQT_DELETED_LISTING   ,
                                         :P_MLQT_ANSWER_TEXT       ,
                                         :P_MLQT_ANSWER_STATUS     ,
                                         :P_MLQT_ANSWER_DATE       ,
                                         :P_MLQT_BUYER_NOME        ,
                                         :P_MLQT_BUYER_EMAIL       ,
                                         :P_MLQT_BUYER_PHONE       ,
                                         :P_TRANSACTION            ); END;`,
      binds
    );

    logJsonRec('perguntaUpdate', { success: true, question_id: data.question_id });
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
  perguntaUpdate
};
