const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

const CONCORRENCIA = 5;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function folhaPublicavel(categoria) {
  const filhos = categoria.children_categories || [];
  if (filhos.length) {
    return false;
  }

  const modos = categoria.settings?.buying_modes || [];
  return categoria.settings?.listing_allowed === true && modos.includes('buy_it_now');
}

function nomeCategoria(categoria) {
  const caminho = (categoria.path_from_root || []).map((item) => item.name).filter(Boolean);
  if (caminho.length) {
    return caminho.join(' > ');
  }
  return categoria.name;
}

async function getCategoria(id, access_token) {
  let tentativa = 0;

  while (true) {
    try {
      const response = await mlApi.get(
        'getCategoria',
        'https://api.mercadolibre.com/categories/' + id,
        {
          headers: { Authorization: 'Bearer ' + access_token },
          skipJsonLog: true,
        }
      );
      return response.data;
    } catch (error) {
      const status = error.response?.status;
      tentativa += 1;
      if ((status === 429 || status >= 500) && tentativa <= 5) {
        await sleep(1000 * tentativa);
        continue;
      }
      throw error;
    }
  }
}

async function coletarFolhas(raizId, access_token) {
  const folhas = [];
  const fila = [raizId];
  let processadas = 0;

  while (fila.length) {
    const lote = fila.splice(0, CONCORRENCIA);
    const detalhes = await Promise.all(
      lote.map(async (id) => {
        try {
          return await getCategoria(id, access_token);
        } catch (error) {
          console.error(`Erro categoria ${id}: ${error.response?.status || error.message}`);
          return null;
        }
      })
    );

    for (const categoria of detalhes) {
      if (!categoria) {
        continue;
      }

      processadas += 1;
      if (processadas % 100 === 0) {
        console.log(`> Categorias percorridas: ${processadas} (fila ${fila.length})`);
      }

      const filhos = categoria.children_categories || [];
      if (filhos.length) {
        for (const filho of filhos) {
          fila.push(filho.id);
        }
        continue;
      }

      if (folhaPublicavel(categoria)) {
        folhas.push({
          id: categoria.id,
          name: nomeCategoria(categoria),
        });
      }
    }
  }

  return folhas;
}

async function getCategorias() {
  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

  try {
    const response = await mlApi.get('getCategorias', 'https://api.mercadolibre.com/sites/MLB/categories', {
      headers: {
        Authorization: 'Bearer ' + access_token,
      },
    });

    const raizes = response.data || [];
    const folhas = [];

    for (const raiz of raizes) {
      console.log(`> Categoria raiz: ${raiz.id} — ${raiz.name}`);
      const daRaiz = await coletarFolhas(raiz.id, access_token);
      console.log(`> Folhas publicáveis em ${raiz.id}: ${daRaiz.length}`);
      folhas.push(...daRaiz);
    }

    return folhas;
  } catch (error) {
    console.error('Erro ao acessar API do Mercado Livre.');
    throw error;
  }
}

module.exports = { getCategorias };
