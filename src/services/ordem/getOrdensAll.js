const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

function ordemPagamentoAprovado(order) {
  const payments = order.payments || [];
  return order.status === 'paid' && payments.some((payment) => payment.status === 'approved');
}

function getOrdemDias() {
  const dias = Number(process.env.ORDEM_DIAS);
  if (!Number.isInteger(dias) || dias <= 0) {
    throw new Error('ORDEM_DIAS deve ser um inteiro positivo no .env (ex.: ORDEM_DIAS=90)');
  }
  return dias;
}

function periodoOrdens(dias) {
  const to = new Date();
  const from = new Date(to);
  from.setUTCDate(from.getUTCDate() - dias);
  return {
    from: from.toISOString(),
    to: to.toISOString(),
  };
}

async function getOrdensAll() {
  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;
  const userID = tokenConfig.MLCN_USER_ID;

  const dias = getOrdemDias();
  const { from, to } = periodoOrdens(dias);

  const limit = 50;
  let offset = 0;
  let total = 0;
  const idsOrdens = [];

  try {
    // A API exige filtro além de seller (doc ML: search sem filtro não retorna pedidos).
    // Janela: ORDEM_DIAS no .env. Paginação quando total > limit (padrão 50).
    do {
      const url =
        `https://api.mercadolibre.com/orders/search?seller=${userID}` +
        `&order.status=paid` +
        `&order.date_created.from=${encodeURIComponent(from)}` +
        `&order.date_created.to=${encodeURIComponent(to)}` +
        `&sort=date_desc&limit=${limit}&offset=${offset}`;

      const response = await mlApi.get('getOrdensAll', url, {
        headers: {
          Authorization: 'Bearer ' + access_token,
        },
      });

      const data = response.data;
      total = data.paging?.total || 0;

      const pageIds = (data.results || [])
        .filter(ordemPagamentoAprovado)
        .map((order) => order.id);

      idsOrdens.push(...pageIds);
      offset += limit;
    } while (offset < total);

    return idsOrdens;
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getOrdensAll };
