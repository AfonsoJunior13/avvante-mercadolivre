const logger = require('../../utils/logger');
const { getEstoques } = require('../../repositories/estoqueRepository');
const { putEstoque } = require('./putEstoque');

function mensagemErroMl(error) {
  const data = error.response?.data;
  if (!data) {
    return error.message || String(error);
  }
  if (typeof data === 'string') {
    return data;
  }

  const causas = Array.isArray(data.cause)
    ? data.cause.map((item) => item.message || JSON.stringify(item)).join('; ')
    : '';

  return [data.message, causas].filter(Boolean).join(' — ') || error.message;
}

function quantidadeApi(qtde) {
  const valor = Number(qtde);
  if (!Number.isFinite(valor)) {
    return 0;
  }
  return Math.max(0, Math.trunc(valor));
}

async function estoquesEnviar() {
  const itens = await getEstoques();
  console.log(`> Estoques: ${itens.length}`);

  for (const item of itens) {
    try {
      if (!item.mlpd_id) {
        throw new Error('MLPD_ID ausente');
      }

      const qtde = quantidadeApi(item.qtde);
      console.log(`> Estoque ${item.mlpd_id} — qtde ${qtde}`);
      await putEstoque(item.mlpd_id, qtde);
    } catch (error) {
      logger.logError(
        new Error(`Estoque ${item.mlpd_id || item.merc_livre_produto_id}: ${mensagemErroMl(error)}`)
      );
    }
  }
}

module.exports = { estoquesEnviar };
