const mlApi = require('../../utils/mlApi');
const { getTokenConfig } = require('../token/getToken');

async function postNfeXml(shipmentId, xmlContent) {
  const tokenConfig = await getTokenConfig();
  const access_token = tokenConfig.MLCN_ACCESS_TOKEN;

  const response = await mlApi.request('postNfeXml', {
    method: 'POST',
    url: `https://api.mercadolibre.com/shipments/${shipmentId}/invoice_data/?siteId=MLB`,
    headers: {
      Authorization: `Bearer ${access_token}`,
      'Content-Type': 'application/xml',
    },
    data: xmlContent,
  });

  return response.data;
}

module.exports = { postNfeXml };
