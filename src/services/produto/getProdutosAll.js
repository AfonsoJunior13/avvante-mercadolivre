const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

const LIMIT = 50;
const OFFSET_MAX = 1000;

function urlBusca(userID, query) {
  return 'https://api.mercadolibre.com/users/' + userID + '/items/search?' + query;
}

async function buscarPagina(url, access_token) {
  const response = await mlApi.get('getProdutosAll', url, {
    headers: {
      Authorization: 'Bearer ' + access_token,
    },
  });
  return response.data;
}

async function getProdutosPorScan(userID, access_token) {
  const ids = [];
  let scrollId;

  while (true) {
    let query = `search_type=scan&limit=${LIMIT}`;
    if (scrollId) {
      query += `&scroll_id=${encodeURIComponent(scrollId)}`;
    }

    const data = await buscarPagina(urlBusca(userID, query), access_token);
    const results = data.results || [];
    ids.push(...results);

    scrollId = data.scroll_id || null;
    if (!scrollId || results.length === 0) {
      break;
    }
  }

  return ids;
}

async function getProdutosAll() {
  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;
  const userID = tokenConfig.MLCN_USER_ID;

  try {
    // API devolve 50 por página (máx. 100). Offset só até 1000; acima disso exige search_type=scan.
    const primeira = await buscarPagina(
      urlBusca(userID, `limit=${LIMIT}&offset=0`),
      access_token
    );
    const results = primeira.results || [];
    const total = primeira.paging?.total || results.length;

    if (total > OFFSET_MAX) {
      return getProdutosPorScan(userID, access_token);
    }

    const ids = [...results];
    let offset = LIMIT;
    while (offset < total) {
      const data = await buscarPagina(
        urlBusca(userID, `limit=${LIMIT}&offset=${offset}`),
        access_token
      );
      const page = data.results || [];
      if (page.length === 0) {
        break;
      }
      ids.push(...page);
      offset += LIMIT;
    }

    return ids;
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getProdutosAll };
