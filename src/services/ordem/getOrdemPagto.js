const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

const STATUS_QUITADO = 'Quitado';
const STATUS_ABERTO = 'Aberto';

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
    return {
      pagto_ml_data: null,
      pagto_ml_status: STATUS_ABERTO,
      pagto_ml_vlr: 0,
    };
  }

  const quitado = paymentInfo.money_release_status === 'released';

  return {
    pagto_ml_data: quitado ? paymentInfo.money_release_date : null,
    pagto_ml_status: quitado ? STATUS_QUITADO : STATUS_ABERTO,
    pagto_ml_vlr: calcularValorPago(result),
  };
}

async function getOrdemPagto(ordemID) {
  const vazio = {
    pagto_ml_data: null,
    pagto_ml_status: STATUS_ABERTO,
    pagto_ml_vlr: 0,
  };

  if (!ordemID) return vazio;

  try {
    const tokenConfig = await getTokenConfig();
    const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

    const res = await mlApi.get(
      'getOrdemPagto',
      'https://api.mercadolibre.com/billing/integration/group/ML/order/details',
      {
        headers: { Authorization: `Bearer ${access_token}` },
        params: { order_ids: ordemID },
      }
    );

    const result = res.data?.results?.[0];
    if (!result) return vazio;

    return mapearPagtoMl(result);
  } catch (error) {
    console.error(`Erro ao buscar pagamento ML da ordem ${ordemID}:`, error?.response?.data || error);
    return vazio;
  }
}

module.exports = { getOrdemPagto, STATUS_QUITADO, STATUS_ABERTO };
