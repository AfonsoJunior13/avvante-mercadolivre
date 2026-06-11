const logger = require('../../utils/logger');
const { getOrdensPagtoAberto } = require('../../repositories/ordemRepository');
const ordemPagtoUpdate = require('../../repositories/ordemPagtoRepository');
const { getOrdemPagto } = require('./getOrdemPagto');

async function ordemPagtoAtualizar() {
  const ordensAbertas = await getOrdensPagtoAberto();

  for (const ordemID of ordensAbertas) {
    try {
      console.log('> Pagto ML — Ordem: ' + ordemID);
      const dadosPagtoMl = await getOrdemPagto(ordemID);

      await ordemPagtoUpdate.ordemPagtoUpdate({
        ordem_id: ordemID,
        ...dadosPagtoMl,
      });
    } catch (error) {
      logger.logError(new Error(`Pagto ML ordem ${ordemID}: ${error.message || error}`));
    }
  }
}

module.exports = { ordemPagtoAtualizar };
