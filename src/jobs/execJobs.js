const cron = require('node-cron');
const logger = require('../utils/logger');
const getToken = require('../services/token/getToken');
const tpAnuncios = require('../services/tpAnuncio/tpAnuncios');
const categorias = require('../services/categoria/categorias');
const produtos = require('../services/produto/produtos');
const ordens = require('../services/ordem/ordens');

require('dotenv').config();

async function refreshToken() {
  console.log('*** Token ***');
  try {    
    await getToken.getToken();    
  } catch (error) {
    console.error('Erro Token: ', error);
    logger.logError(error);
  }    
}

async function tpAnuncioSave() {
  console.log('*** Tipo de Anuncio ***');
  try {    
    await tpAnuncios.tpAnunciosAtualizar();        
  } catch (error) {
    console.error('Erro Tipo Anuncio: ', error);
    logger.logError(error);  
  }  
}

async function categoriasSave() {
  console.log('*** Categoria ***');
  try {    
    await categorias.categoriasAtualizar();        
  } catch (error) {
    console.error('Erro Categoria: ', error);
    logger.logError(error);  
  }  
}

async function produtosSave() {
  console.log('*** Produto ***');
  try {    
    await produtos.produtosAtualizar();        
  } catch (error) {
    console.error('Erro Produto: ', error);
    logger.logError(error);  
  }  
}

async function ordensSave() {
  console.log('*** Ordens ***');
  try {    
    await ordens.ordensAtualizar();        
  } catch (error) {
    console.error('Erro Ordem: ', error);
    await logger.logError(error);  
  }  
}

async function Iniciar() {
  //console.log(`<< INICIO ${new Date().toLocaleString()} >>`);
  await refreshToken();
  await tpAnuncioSave();
  await categoriasSave();
  await produtosSave();
  await ordensSave();
  //console.log(`<< FIM ${new Date().toLocaleString()} >>`);
}

// Executa imediatamente
Iniciar();

cron.schedule('*/30 * * * *', refreshToken); // 30 minutos
cron.schedule('0 */12 * * *', tpAnuncioSave); // 12 horas
cron.schedule('0 */12 * * *', categoriasSave); // 12 horas
cron.schedule('*/5 * * * *', produtosSave); // 5 minutos
cron.schedule('*/5 * * * *', ordensSave); // 5 minutos