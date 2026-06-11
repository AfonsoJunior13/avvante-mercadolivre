const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

function findInAdditional(additionalInfo = [], type) {
  const t = (type || '').toUpperCase();
  const found = additionalInfo.find(i => (i.type || '').toUpperCase() === t);
  return found ? found.value : '';
}

async function getDadosFaturamento(ordemID) {
  if (!ordemID) return {};

  try {
    const tokenConfig = await getTokenConfig();
    const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

    // Consulta ao endpoint billing_info
    const res = await mlApi.get('getDadosFaturamento', `https://api.mercadolibre.com/orders/${ordemID}/billing_info`, {
      headers: { Authorization: `Bearer ${access_token}` },
    });

    const billing = res.data?.billing_info || {};
    const additional = Array.isArray(billing.additional_info) ? billing.additional_info : [];

    // Nome
    const firstName = findInAdditional(additional, 'FIRST_NAME') || findInAdditional(additional, 'NAME') || '';
    const lastName = findInAdditional(additional, 'LAST_NAME') || '';
    const nome = [firstName, lastName].filter(Boolean).join(' ').trim() || '';

    // Documento único CPF ou CNPJ
    let documento = billing.doc_number || findInAdditional(additional, 'DOC_NUMBER') || findInAdditional(additional, 'DOC') || '';
    let docLimpo = documento ? documento.replace(/\D/g, '') : '';

    let cpf_cnpj = null;
    if (docLimpo.length === 11) cpf_cnpj = docLimpo; // CPF
    else if (docLimpo.length === 14) cpf_cnpj = docLimpo; // CNPJ

    // Endereço
    const endereco = findInAdditional(additional, 'STREET_NAME') || findInAdditional(additional, 'STREET') || '';
    const numero = findInAdditional(additional, 'STREET_NUMBER') || findInAdditional(additional, 'STREETNUMBER') || '';
    const complemento = findInAdditional(additional, 'COMMENT') || findInAdditional(additional, 'COMPLEMENT') || '';
    const bairro = findInAdditional(additional, 'NEIGHBORHOOD') || '';
    const cidade = findInAdditional(additional, 'CITY_NAME') || findInAdditional(additional, 'CITY') || '';
    let uf = findInAdditional(additional, 'STATE_NAME') || findInAdditional(additional, 'STATE_CODE') || '';
    if (uf && uf.includes('-')) uf = uf.split('-').pop(); // "BR-GO" -> "GO"
    const cep = findInAdditional(additional, 'ZIP_CODE') || findInAdditional(additional, 'ZIP') || '';

    return {
      nome,
      cpf_cnpj,
      endereco,
      numero,
      complemento,
      bairro,
      cidade,
      uf,
      cep,
    };

  } catch (error) {
    console.error(`Erro ao buscar billing_info da ordem ${ordemID}:`, error?.response?.data || error);
    return {};
  }
}

module.exports = { getDadosFaturamento };