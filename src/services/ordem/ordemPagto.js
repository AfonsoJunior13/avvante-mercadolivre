const logger = require('../../utils/logger');
const { getOrdensPagtoAberto } = require('../../repositories/ordemRepository');
const ordemPagtoUpdate = require('../../repositories/ordemPagtoRepository');
const { getOrdensPagto, MAX_ORDER_IDS } = require('./getOrdemPagto');

async function ordemPagtoAtualizar() {
  const ordensAbertas = await getOrdensPagtoAberto();
  console.log(`> Pagto ML — Ordens em aberto: ${ordensAbertas.length}`);

  for (let i = 0; i < ordensAbertas.length; i += MAX_ORDER_IDS) {
    const lote = ordensAbertas.slice(i, i + MAX_ORDER_IDS);
    const nLote = Math.floor(i / MAX_ORDER_IDS) + 1;
    console.log(`> Pagto ML — Lote ${nLote}: ${lote.length} ordem(ns)`);

    try {
      const mapaPagto = await getOrdensPagto(lote);

      for (const ordemID of lote) {
        try {
          console.log('> Pagto ML — Ordem: ' + ordemID);
          const dadosPagtoMl = mapaPagto.get(String(ordemID)) || {
            pagto_ml_data: null,
            pagto_ml_status: 'Aberto',
            pagto_ml_vlr: 0,
          };

          await ordemPagtoUpdate.ordemPagtoUpdate({
            ordem_id: ordemID,
            ...dadosPagtoMl,
          });
        } catch (error) {
          logger.logError(new Error(`Pagto ML ordem ${ordemID}: ${error.message || error}`));
        }
      }
    } catch (error) {
      logger.logError(new Error(`Pagto ML lote ${nLote}: ${error.message || error}`));
    }
  }
}

module.exports = { ordemPagtoAtualizar };
