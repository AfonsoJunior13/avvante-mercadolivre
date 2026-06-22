const logger = require('../../utils/logger');
const { getOrdensNfePendente, ordemNfeXmlEnvioUpdate } = require('../../repositories/ordemNfeRepository');
const { getOrdem } = require('./getOrdem');
const { postNfeXml } = require('./postNfeXml');

async function ordemNfeEnviar() {
  const ordensPendentes = await getOrdensNfePendente();

  for (const ordem of ordensPendentes) {
    try {
      console.log(`> NF-e ML — Ordem: ${ordem.ordem_id} — NF: ${ordem.nfe}`);

      if (!ordem.nfe_xml?.trim()) {
        throw new Error('XML da NF-e ausente na VIEW_MLOR_NFE');
      }

      const resOrdem = await getOrdem(ordem.ordem_id);
      const shipmentId = resOrdem.shipping?.id;

      if (!shipmentId) {
        throw new Error('Envio (shipment_id) não encontrado na ordem ML');
      }

      await postNfeXml(shipmentId, ordem.nfe_xml.trim());
      await ordemNfeXmlEnvioUpdate({ ordem_id: ordem.ordem_id });
    } catch (error) {
      const msg = error.response?.data?.message || error.message || error;
      logger.logError(new Error(`NF-e ML ordem ${ordem.ordem_id}: ${msg}`));
    }
  }
}

module.exports = { ordemNfeEnviar };
