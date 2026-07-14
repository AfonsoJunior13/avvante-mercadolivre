const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

function getPerguntasDias() {
  const dias = Number(process.env.PERGUNTAS_DIAS);
  if (!Number.isInteger(dias) || dias <= 0) {
    throw new Error('PERGUNTAS_DIAS deve ser um inteiro positivo no .env (ex.: PERGUNTAS_DIAS=30)');
  }
  return dias;
}

function dataLimitePerguntas(dias) {
  const from = new Date();
  from.setUTCDate(from.getUTCDate() - dias);
  return from;
}

function perguntaDentroDaJanela(question, from) {
  if (!question?.date_created) {
    return false;
  }
  return new Date(question.date_created) >= from;
}

async function getPerguntasAll(status) {
  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

  const dias = getPerguntasDias();
  const from = dataLimitePerguntas(dias);

  const limit = 50;
  let offset = 0;
  let total = 0;
  const questions = [];

  try {
    // API /my/received_questions/search não filtra por data — ordena DESC e corta pela janela PERGUNTAS_DIAS.
    do {
      let url =
        `https://api.mercadolibre.com/my/received_questions/search?api_version=4` +
        `&sort_fields=date_created&sort_types=DESC` +
        `&limit=${limit}&offset=${offset}`;
      if (status) {
        url += `&status=${status}`;
      }

      const response = await mlApi.get('getPerguntasAll', url, {
        headers: {
          Authorization: 'Bearer ' + access_token,
        },
      });

      const data = response.data;
      total = data.total || 0;
      const page = data.questions || [];

      if (page.length === 0) {
        break;
      }

      let saiuDaJanela = false;
      for (const question of page) {
        if (perguntaDentroDaJanela(question, from)) {
          questions.push(question);
        } else {
          // Ordenado do mais recente ao mais antigo — demais páginas estão fora da janela.
          saiuDaJanela = true;
          break;
        }
      }

      if (saiuDaJanela) {
        break;
      }

      offset += limit;
    } while (offset < total);

    return questions;
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getPerguntasAll };
