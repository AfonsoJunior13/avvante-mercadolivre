const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

const STATUS_QUITADO = 'Quitado';
const STATUS_ABERTO = 'Aberto';
/** Limite da API ML: até 60 order_ids por consulta em /order/details */
const MAX_ORDER_IDS = 60;

function pagtoVazio() {
  return {
    pagto_ml_data: null,
    pagto_ml_status: STATUS_ABERTO,
    pagto_ml_vlr: 0,
  };
}

function calcularValorPago(result) {
  const paymentInfo = result?.payment_info?.[0];
  if (paymentInfo?.money_release_status !== 'released') {
    return 0;
  }

  const salesInfo = (result.details || []).flatMap((d) => d.sales_info || []);
  const transactionAmount = salesInfo.reduce(
    (max, s) => Math.max(max, Number(s.transaction_amount) || 0),
    0
  );

  if (!transactionAmount) {
    return 0;
  }

  const cobrancas = (result.details || [])
    .filter((d) => d.charge_info?.debited_from_operation === 'YES')
    .reduce((sum, d) => sum + (Number(d.charge_info?.detail_amount) || 0), 0);

  const retencoes = (paymentInfo.tax_details || []).reduce(
    (sum, t) =>
      sum + (Number(t.original_amount) || 0) - (Number(t.refunded_amount) || 0),
    0
  );

  const valor = transactionAmount - cobrancas - retencoes;
  return Math.max(0, Math.round(valor * 100) / 100);
}

function mapearPagtoMl(result) {
  const paymentInfo = result?.payment_info?.[0];

  if (!paymentInfo) {
    return pagtoVazio();
  }

  const quitado = paymentInfo.money_release_status === 'released';

  return {
    pagto_ml_data: quitado ? paymentInfo.money_release_date : null,
    pagto_ml_status: quitado ? STATUS_QUITADO : STATUS_ABERTO,
    pagto_ml_vlr: calcularValorPago(result),
  };
}

/**
 * Consulta repasse de várias ordens (até 60 por request).
 * @returns {Map<string, {pagto_ml_data, pagto_ml_status, pagto_ml_vlr}>}
 */
async function getOrdensPagto(ordemIDs) {
  const ids = [...new Set((ordemIDs || []).filter(Boolean).map(String))];
  const mapa = new Map(ids.map((id) => [id, pagtoVazio()]));

  if (ids.length === 0) {
    return mapa;
  }

  if (ids.length > MAX_ORDER_IDS) {
    throw new Error(`getOrdensPagto: no máximo ${MAX_ORDER_IDS} order_ids por chamada`);
  }

  try {
    const tokenConfig = await getTokenConfig();
    const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

    const res = await mlApi.get(
      'getOrdemPagto',
      'https://api.mercadolibre.com/billing/integration/group/ML/order/details',
      {
        headers: { Authorization: `Bearer ${access_token}` },
        params: { order_ids: ids.join(',') },
      }
    );

    for (const result of res.data?.results || []) {
      if (result?.order_id == null) continue;
      mapa.set(String(result.order_id), mapearPagtoMl(result));
    }

    return mapa;
  } catch (error) {
    console.error(
      `Erro ao buscar pagamento ML das ordens [${ids.join(',')}]:`,
      error?.response?.data || error
    );
    return mapa;
  }
}

async function getOrdemPagto(ordemID) {
  if (!ordemID) return pagtoVazio();
  const mapa = await getOrdensPagto([ordemID]);
  return mapa.get(String(ordemID)) || pagtoVazio();
}

module.exports = {
  getOrdemPagto,
  getOrdensPagto,
  MAX_ORDER_IDS,
  STATUS_QUITADO,
  STATUS_ABERTO,
};
