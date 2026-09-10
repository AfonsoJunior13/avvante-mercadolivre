function valorPresente(valor) {
  return valor !== null && valor !== undefined && String(valor).trim() !== '';
}

function freteGratis(valor) {
  return String(valor || '').trim().toUpperCase() === 'SIM';
}

function mapearCondicao(valor) {
  const value_id = String(valor || '').trim();
  const condition = value_id === '2230581' ? 'used' : 'new';
  return { condition, value_id };
}

function pushAtributo(attributes, id, valueName) {
  if (!valorPresente(valueName)) {
    return;
  }
  attributes.push({ id, value_name: String(valueName).trim() });
}

function pushMedida(attributes, id, valor, unidade) {
  if (!valorPresente(valor) || Number(valor) === 0) {
    return;
  }
  attributes.push({ id, value_name: `${Number(valor)} ${unidade}` });
}

function montarAtributos(anuncio) {
  const { condition, value_id } = mapearCondicao(anuncio.condicao);
  const attributes = [];

  if (valorPresente(value_id)) {
    attributes.push({ id: 'ITEM_CONDITION', value_id });
  }
  pushAtributo(attributes, 'BRAND', anuncio.marca);
  pushAtributo(attributes, 'MODEL', anuncio.modelo);
  pushAtributo(attributes, 'GTIN', anuncio.gtin);
  pushAtributo(attributes, 'SELLER_SKU', anuncio.sku);
  pushAtributo(attributes, 'GRITS_NUMBER', anuncio.grits);
  pushMedida(attributes, 'SELLER_PACKAGE_HEIGHT', anuncio.altura_cm, 'cm');
  pushMedida(attributes, 'SELLER_PACKAGE_LENGTH', anuncio.comprimento_cm, 'cm');
  pushMedida(attributes, 'SELLER_PACKAGE_WIDTH', anuncio.largura_cm, 'cm');
  pushMedida(attributes, 'SELLER_PACKAGE_WEIGHT', anuncio.peso, 'g');

  return { condition, attributes };
}

function montarSaleTerms(anuncio) {
  const saleTerms = [];

  if (valorPresente(anuncio.garantia_tipo)) {
    saleTerms.push({ id: 'WARRANTY_TYPE', value_name: String(anuncio.garantia_tipo).trim() });
  }
  if (valorPresente(anuncio.garantia_tempo)) {
    saleTerms.push({ id: 'WARRANTY_TIME', value_name: String(anuncio.garantia_tempo).trim() });
  }

  return saleTerms;
}

function montarPayload(anuncio, { userProductSeller = false, pictures = [], incluirIdentidade = true } = {}) {
  const { condition, attributes } = montarAtributos(anuncio);
  const saleTerms = montarSaleTerms(anuncio);
  const payload = {
    price: Number(anuncio.preco),
    available_quantity: Number(anuncio.qtde),
    currency_id: 'BRL',
    buying_mode: 'buy_it_now',
    condition,
    channels: ['marketplace'],
    shipping: {
      mode: valorPresente(anuncio.modo_envio) ? String(anuncio.modo_envio).trim() : 'me2',
      local_pick_up: false,
      free_shipping: freteGratis(anuncio.frete_gratis),
    },
    attributes,
  };

  if (userProductSeller) {
    payload.family_name = anuncio.titulo;
  } else {
    payload.title = anuncio.titulo;
  }

  if (incluirIdentidade) {
    payload.category_id = anuncio.category_id;
    payload.listing_type_id = anuncio.listing_type_id;
  }

  if (pictures.length) {
    payload.pictures = pictures;
  }

  if (saleTerms.length) {
    payload.sale_terms = saleTerms;
  }

  return payload;
}

module.exports = { montarPayload, mapearCondicao };
