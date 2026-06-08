const getTpAnuncios = require('./getTpAnuncios');
const tpAnuncioUpdate = require('../../repositories/tpAnuncioRepository');

async function tpAnunciosAtualizar() {
  try {
    const resTpAnuncios = await getTpAnuncios.getTpAnuncios();
    await tpAnuncioUpdate.tpAnuncioUpdate(resTpAnuncios);
  } catch (error) {
    console.error('Erro ao processar tipos de anúncio.');
    throw error;
  }
}

module.exports = { tpAnunciosAtualizar };
