const logger = require('../../utils/logger');
const getOrdensAll = require('./getOrdensAll');
const getOrdem = require('./getOrdem');
const ordemUpdate = require('../../repositories/ordemRepository');
const ordemEndUpdate = require('../../repositories/ordemEndRepository');
const ordemItemUpdate = require('../../repositories/ordemItemRepository');
const { getDadosFaturamento } = require('./getDadosFaturamento');
const { getEndereco } = require('./getEndereco');

async function ordensAtualizar() {
    const resOrdensAll = await getOrdensAll.getOrdensAll();

    for (const ordemID of resOrdensAll) {
      try {
        console.log('> Ordem :' + ordemID);
        const resOrdem = await getOrdem.getOrdem(ordemID);
        const shippingID = resOrdem.shipping?.id;

        const dadosFaturamento = await getDadosFaturamento(ordemID);
        const enderecoEntrega = await getEndereco(ordemID, shippingID);

        const dadosOrdem = {
          ordem_id: resOrdem.id,
          status: resOrdem.status,
          data_created: resOrdem.date_created,
          data_closed: resOrdem.date_closed,
          vlr_total: resOrdem.total_amount ?? 0,
          vlr_desconto: resOrdem.payments?.[0]?.coupon_amount ?? 0,
          vlr_frete: resOrdem.payments?.[0]?.shipping_cost ?? 0,
          vlr_taxa_ml: resOrdem.payments?.[0]?.marketplace_fee ?? 0,
          ...dadosFaturamento
        };

        const ordemItens = (resOrdem.order_items || []).map((item) => {
          return {
            ordem_id: resOrdem.id,
            produto_id: item.item.id,
            quantity: item.quantity,
            unit_price: item.unit_price,
            sku: '0',
            gtin: '0',
            sale_fee: item.sale_fee
          };
        });

        await ordemUpdate.ordemUpdate(dadosOrdem);
        await ordemEndUpdate.ordemEndUpdate(enderecoEntrega);

        for (const item of ordemItens) {
          await ordemItemUpdate.ordemItemUpdate(item);
        }
      } catch (error) {
        logger.logError(new Error(`Ordem ${ordemID}: ${error.message || error}`));
      }
    }
}

module.exports = { ordensAtualizar };
