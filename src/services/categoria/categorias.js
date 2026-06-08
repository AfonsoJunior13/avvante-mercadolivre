const getCategorias = require('./getCategorias');
const categoriaUpdate = require('../../repositories/categoriaRepository');

async function categoriasAtualizar() {
  try {
    const resCategorias = await getCategorias.getCategorias();
    await categoriaUpdate.categoriaUpdate(resCategorias);
  } catch (error) {
    console.error('Erro ao processar categorias.');
    throw error;
  }
}

module.exports = { categoriasAtualizar };