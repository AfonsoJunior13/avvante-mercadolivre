const oracledb = require('oracledb');
const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const { logJsonEnv, logJsonRec } = require('../utils/jsonLogger');

require('dotenv').config();

function paraBuffer(valor) {
  if (!valor) {
    return null;
  }
  if (Buffer.isBuffer(valor)) {
    return valor;
  }
  if (valor instanceof Uint8Array) {
    return Buffer.from(valor);
  }
  if (typeof valor.getData === 'function') {
    return valor;
  }
  if (valor.type === 'Buffer' && Array.isArray(valor.data)) {
    return Buffer.from(valor.data);
  }
  if (typeof valor === 'string') {
    const hex = valor.replace(/\s/g, '');
    if (/^[0-9a-fA-F]+$/.test(hex) && hex.length % 2 === 0) {
      return Buffer.from(hex, 'hex');
    }
  }
  return null;
}

async function resolverFoto(valor) {
  const bruto = paraBuffer(valor);
  if (bruto && typeof bruto.getData === 'function') {
    return Buffer.from(await bruto.getData());
  }
  return bruto;
}

function mapearAnuncio(row) {
  return {
    unidade_empresarial_id: row.UNIDADE_EMPRESARIAL_ID,
    merc_livre_anuncio_id: row.MERC_LIVRE_ANUNCIO_ID,
    mlan_id: row.MLAN_ID,
    mlan_user_product_id: row.MLAN_USER_PRODUCT_ID,
    listing_type_id: row.MLTA_TP_ANUNCIO_ID,
    category_id: row.MLTA_CATEGORIA_ID,
    titulo: row.MLAN_TITULO,
    descricao: row.MLAN_DESCRICAO,
    preco: row.MLAN_PRECO,
    qtde: row.MLAN_QTDE,
    condicao: row.MLAN_CONDICAO,
    marca: row.MLTA_MARCA_DESCRICAO,
    modelo: row.MLAN_MODELO,
    gtin: row.MLAN_GTIN,
    sku: row.MLAN_SKU,
    grits: row.MLAN_GRITS,
    garantia_tipo: row.MLAN_GARANTIA_TIPO,
    garantia_tempo: row.MLAN_GARANTIA_TEMPO,
    altura_cm: row.MLAN_ALTURA_CM,
    comprimento_cm: row.MLAN_COMPRIMENTO_CM,
    largura_cm: row.MLAN_LARGURA_CM,
    peso: row.MLAN_PESO,
    modo_envio: row.MLAN_MODO_ENVIO,
    frete_gratis: row.MLAN_FRETE_GRATIS,
    acao: row.MLAN_ACAO,
  };
}

async function getAnunciosPendentes() {
  const connection = await getConnection();
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;

  try {
    logJsonEnv('getAnunciosPendentes', { UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID });

    const result = await connection.execute(
      `select V.UNIDADE_EMPRESARIAL_ID,
              V.MERC_LIVRE_ANUNCIO_ID,
              V.MLAN_ID,
              V.MLAN_USER_PRODUCT_ID,
              V.MLTA_TP_ANUNCIO_ID,
              V.MLTA_CATEGORIA_ID,
              V.MLAN_TITULO,
              V.MLAN_DESCRICAO,
              V.MLAN_PRECO,
              V.MLAN_QTDE,
              V.MLAN_CONDICAO,
              V.MLTA_MARCA_DESCRICAO,
              V.MLAN_MODELO,
              V.MLAN_GTIN,
              V.MLAN_SKU,
              V.MLAN_GRITS,
              V.MLAN_GARANTIA_TIPO,
              V.MLAN_GARANTIA_TEMPO,
              V.MLAN_ALTURA_CM,
              V.MLAN_COMPRIMENTO_CM,
              V.MLAN_LARGURA_CM,
              V.MLAN_PESO,
              V.MLAN_MODO_ENVIO,
              V.MLAN_FRETE_GRATIS,
              V.MLAN_ACAO
         from VIEW_MLAPI_ANUNCIO V
        where V.UNIDADE_EMPRESARIAL_ID = :UNIDADE_EMPRESARIAL_ID`,
      { UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID },
      {
        outFormat: oracledb.OUT_FORMAT_OBJECT,
        fetchInfo: { MLAN_DESCRICAO: { type: oracledb.STRING } },
      }
    );

    const anuncios = (result.rows || []).map(mapearAnuncio);

    logJsonRec('getAnunciosPendentes', { total: anuncios.length });
    return anuncios;
  } catch (err) {
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    }
    throw new Error('Erro inesperado: ' + err.message);
  } finally {
    await connection.close();
  }
}

async function getAnuncioImagens(mercLivreAnuncioId) {
  const connection = await getConnection();

  try {
    logJsonEnv('getAnuncioImagens', { MERC_LIVRE_ANUNCIO_ID: mercLivreAnuncioId });

    // FOPR_FOTO é LONG RAW: fetch como Buffer. Bytes da imagem não vão para o log JSON.

    const result = await connection.execute(
      `select V.MERC_LIVRE_ANUNCIO_ID,
              V.MLAN_ID,
              V.FOTO_PRODUTO_ID,
              V.FOPR_FOTO,
              V.PRINCIPAL
         from VIEW_MLAPI_ANUNCIO_IMAGEM V
        where V.MERC_LIVRE_ANUNCIO_ID = :MERC_LIVRE_ANUNCIO_ID`,
      { MERC_LIVRE_ANUNCIO_ID: mercLivreAnuncioId },
      {
        outFormat: oracledb.OUT_FORMAT_OBJECT,
        fetchInfo: { FOPR_FOTO: { type: oracledb.BUFFER } },
      }
    );

    const imagens = [];

    for (const row of result.rows || []) {
      const foto = await resolverFoto(row.FOPR_FOTO);
      imagens.push({
        merc_livre_anuncio_id: row.MERC_LIVRE_ANUNCIO_ID,
        mlan_id: row.MLAN_ID,
        foto_produto_id: row.FOTO_PRODUTO_ID,
        foto,
        principal: String(row.PRINCIPAL || '').toUpperCase() === 'SIM',
      });
    }

    logJsonRec('getAnuncioImagens', {
      total: imagens.length,
      fotos: imagens.map((img) => ({
        foto_produto_id: img.foto_produto_id,
        principal: img.principal,
        bytes: img.foto?.length || 0,
      })),
    });

    return imagens;
  } catch (err) {
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    }
    throw new Error('Erro inesperado: ' + err.message);
  } finally {
    await connection.close();
  }
}

async function anuncioEnvioUpdate(data) {
  const connection = await getConnection();

  try {
    const binds = {
      P_MERC_LIVRE_ANUNCIO_ID: data.merc_livre_anuncio_id,
      P_MLAN_ID: data.mlan_id || null,
      P_MLAN_ERRO: data.mlan_erro || null,
    };

    logJsonEnv('anuncioEnvioUpdate', binds);

    await connection.execute(
      `BEGIN PRC_MLAPI_AUNCIOS_ENV(:P_MERC_LIVRE_ANUNCIO_ID, :P_MLAN_ID, :P_MLAN_ERRO); END;`,
      binds
    );

    logJsonRec('anuncioEnvioUpdate', {
      success: true,
      merc_livre_anuncio_id: data.merc_livre_anuncio_id,
      mlan_id: data.mlan_id || null,
      mlan_erro: data.mlan_erro || null,
    });

    return { success: true };
  } catch (err) {
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    }
    throw new Error('Erro inesperado: ' + err.message);
  } finally {
    await connection.close();
  }
}

module.exports = {
  getAnunciosPendentes,
  getAnuncioImagens,
  anuncioEnvioUpdate,
};
