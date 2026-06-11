const logger = require('../../utils/logger');
const { getPerguntasAll } = require('./getPerguntasAll');
const { getPergunta } = require('./getPergunta');
const perguntaUpdate = require('../../repositories/perguntaRepository');

function extrairDadosComprador(from) {
  if (!from) {
    return { buyer_nome: null, buyer_email: null, buyer_phone: null };
  }

  const nome = [from.first_name, from.last_name].filter(Boolean).join(' ').trim()
    || from.nickname
    || null;

  const phone = from.phone?.number || from.phone || null;

  return {
    buyer_nome: nome,
    buyer_email: from.email || null,
    buyer_phone: phone
  };
}

async function perguntasAtualizar() {
  const resPerguntas = await getPerguntasAll();

  for (const pergunta of resPerguntas) {
    try {
      console.log('> Pergunta :' + pergunta.id);
      const detalhe = await getPergunta(pergunta.id);
      const comprador = extrairDadosComprador(detalhe.from);

      const dadosPergunta = {
        question_id: detalhe.id,
        item_id: detalhe.item_id,
        seller_id: detalhe.seller_id,
        status: detalhe.status,
        text: detalhe.text,
        date_created: detalhe.date_created,
        from_user_id: detalhe.from?.id,
        hold: detalhe.hold ? 'S' : 'N',
        deleted_from_listing: detalhe.deleted_from_listing ? 'S' : 'N',
        answer_text: detalhe.answer?.text || null,
        answer_status: detalhe.answer?.status || null,
        answer_date: detalhe.answer?.date_created || null,
        ...comprador
      };

      await perguntaUpdate.perguntaUpdate(dadosPergunta);
    } catch (error) {
      logger.logError(new Error(`Pergunta ${pergunta.id}: ${error.message || error}`));
    }
  }
}

module.exports = { perguntasAtualizar };
