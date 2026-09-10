const logger = require('../../utils/logger');
const {
  getAnunciosPendentes,
  getAnuncioImagens,
  anuncioEnvioUpdate,
} = require('../../repositories/anuncioRepository');
const { getVendedor } = require('./getVendedor');
const { postImagem } = require('./postImagem');
const { postAnuncio, postAnuncioValidar } = require('./postAnuncio');
const { putAnuncio } = require('./putAnuncio');
const { postDescricao } = require('./postDescricao');
const { montarPayload } = require('./montarPayload');

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

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function ordenarImagens(imagens) {
  const unicas = [];
  const vistos = new Set();

  const ordenadas = [...imagens].sort((a, b) => Number(b.principal) - Number(a.principal));

  for (const imagem of ordenadas) {
    const chave = imagem.foto_produto_id || `idx-${unicas.length}`;
    if (vistos.has(chave)) {
      continue;
    }
    vistos.add(chave);
    unicas.push(imagem);
  }

  return unicas;
}

async function enviarImagens(mercLivreAnuncioId) {
  const imagens = ordenarImagens(await getAnuncioImagens(mercLivreAnuncioId));
  const pictures = [];

  for (const imagem of imagens) {
    if (!imagem.foto?.length) {
      logger.logError(new Error(`Anúncio ${mercLivreAnuncioId}: foto ${imagem.foto_produto_id} sem conteúdo em FOPR_FOTO`));
      continue;
    }

    try {
      const enviada = await postImagem(imagem.foto, imagem.foto_produto_id);
      if (enviada?.id) {
        pictures.push({ id: enviada.id });
      }
    } catch (error) {
      logger.logError(
        new Error(`Anúncio ${mercLivreAnuncioId} foto ${imagem.foto_produto_id}: ${mensagemErroMl(error)}`)
      );
    }
  }

  return pictures;
}

async function gravarEnvio(anuncio, mlanId) {
  if (!mlanId) {
    throw new Error('ID do anúncio no Mercado Livre não retornado');
  }

  await anuncioEnvioUpdate({
    merc_livre_anuncio_id: anuncio.merc_livre_anuncio_id,
    mlan_id: mlanId,
    mlan_erro: null,
  });
}

async function gravarErro(anuncio, error) {
  const mlanErro = String(mensagemErroMl(error) || 'Erro ao publicar anúncio').slice(0, 4000);

  try {
    await anuncioEnvioUpdate({
      merc_livre_anuncio_id: anuncio.merc_livre_anuncio_id,
      mlan_id: anuncio.mlan_id || null,
      mlan_erro: mlanErro,
    });
  } catch (erroGravacao) {
    logger.logError(
      new Error(`Anúncio ${anuncio.merc_livre_anuncio_id} ao gravar MLAN_ERRO: ${erroGravacao.message || erroGravacao}`)
    );
  }
}

async function publicar(anuncio, userProductSeller) {
  const pictures = await enviarImagens(anuncio.merc_livre_anuncio_id);
  const payload = montarPayload(anuncio, {
    userProductSeller,
    pictures,
    incluirIdentidade: true,
  });

  await postAnuncioValidar(payload);
  const criado = await postAnuncio(payload);

  try {
    await postDescricao(criado.id, anuncio.descricao, false);
  } catch (error) {
    logger.logError(new Error(`Anúncio ${anuncio.merc_livre_anuncio_id} descrição: ${mensagemErroMl(error)}`));
  }

  await gravarEnvio(anuncio, criado.id);
}

async function atualizar(anuncio, userProductSeller) {
  if (!anuncio.mlan_id) {
    throw new Error('MLAN_ID ausente para ATUALIZAR');
  }

  const pictures = await enviarImagens(anuncio.merc_livre_anuncio_id);
  const payload = montarPayload(anuncio, {
    userProductSeller,
    pictures,
    incluirIdentidade: false,
  });

  const atualizado = await putAnuncio(anuncio.mlan_id, payload);

  try {
    await postDescricao(anuncio.mlan_id, anuncio.descricao, true);
  } catch (error) {
    logger.logError(new Error(`Anúncio ${anuncio.merc_livre_anuncio_id} descrição: ${mensagemErroMl(error)}`));
  }

  await gravarEnvio(anuncio, atualizado?.id || anuncio.mlan_id);
}

async function alterarStatus(anuncio, status) {
  if (!anuncio.mlan_id) {
    throw new Error(`MLAN_ID ausente para alterar status (${status})`);
  }

  const atualizado = await putAnuncio(anuncio.mlan_id, { status });
  await gravarEnvio(anuncio, atualizado?.id || anuncio.mlan_id);
}

async function excluir(anuncio) {
  if (!anuncio.mlan_id) {
    throw new Error('MLAN_ID ausente para EXCLUIR');
  }

  try {
    await putAnuncio(anuncio.mlan_id, { status: 'closed' });
  } catch (error) {
    const msg = mensagemErroMl(error);
    if (!/closed|deleted|forbidden|payment_required/i.test(msg) && error.response?.status !== 409) {
      throw error;
    }
  }

  try {
    await putAnuncio(anuncio.mlan_id, { deleted: 'true' });
  } catch (error) {
    if (error.response?.status === 409) {
      await sleep(2000);
      await putAnuncio(anuncio.mlan_id, { deleted: 'true' });
    } else {
      throw error;
    }
  }

  await gravarEnvio(anuncio, anuncio.mlan_id);
}

async function processarAnuncio(anuncio, userProductSeller) {
  const acao = String(anuncio.acao || '').toUpperCase();

  console.log(`> Anúncio ${anuncio.merc_livre_anuncio_id} — ${acao} — ${anuncio.titulo || ''}`);

  switch (acao) {
    case 'PUBLICAR':
      await publicar(anuncio, userProductSeller);
      break;
    case 'ATUALIZAR':
      await atualizar(anuncio, userProductSeller);
      break;
    case 'PAUSAR':
      await alterarStatus(anuncio, 'paused');
      break;
    case 'ATIVAR':
      await alterarStatus(anuncio, 'active');
      break;
    case 'ENCERRAR':
      await alterarStatus(anuncio, 'closed');
      break;
    case 'EXCLUIR':
      await excluir(anuncio);
      break;
    default:
      throw new Error(`Ação não suportada: ${acao || '(vazia)'}`);
  }
}

async function anunciosEnviar() {
  const anuncios = await getAnunciosPendentes();
  console.log(`> Anúncios pendentes: ${anuncios.length}`);

  let userProductSeller = false;
  try {
    const vendedor = await getVendedor();
    userProductSeller = Array.isArray(vendedor.tags) && vendedor.tags.includes('user_product_seller');
    console.log(`> User Products: ${userProductSeller ? 'sim' : 'não'}`);
  } catch (error) {
    logger.logError(new Error(`Vendedor (tag User Products): ${mensagemErroMl(error)}`));
  }

  for (const anuncio of anuncios) {
    try {
      await processarAnuncio(anuncio, userProductSeller);
    } catch (error) {
      const mensagem = mensagemErroMl(error);
      logger.logError(new Error(`Anúncio ${anuncio.merc_livre_anuncio_id}: ${mensagem}`));
      await gravarErro(anuncio, error);
    }
  }
}

module.exports = { anunciosEnviar };
