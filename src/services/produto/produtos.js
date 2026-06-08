const getProdutosAll = require('./getProdutosAll');
const getProduto = require('./getProduto');
const produtoUpdate = require('../../repositories/produtoRepository');

async function produtosAtualizar() {
  try {
    const resProdutosAll = await getProdutosAll.getProdutosAll();    
    
    for (const produtoID of resProdutosAll) {       
       const resProduto = await getProduto.getProduto(produtoID);
       
       if (resProduto) {
            const produto = {
                        id: resProduto.id,                    
                        title: resProduto.title, 
                        seller_id: resProduto.seller_id, 
                        category_id: resProduto.category_id, 
                        user_product_id: resProduto.user_product_id, 
                        price: resProduto.price, 
                        base_price: resProduto.base_price, 
                        original_price: resProduto.original_price, 
                        initial_quantity: resProduto.initial_quantity, 
                        available_quantity: resProduto.available_quantity, 
                        sold_quantity: resProduto.sold_quantity, 
                        listing_type_id: resProduto.listing_type_id, 
                        start_time: resProduto.start_time, 
                        stop_time: resProduto.stop_time, 
                        end_time: resProduto.end_time, 
                        expiration_time: resProduto.expiration_time, 
                        permalink: resProduto.permalink, 
                        date_created: resProduto.date_created, 
                        last_updated: resProduto.last_updated, 
                        gtin: await extractGTIN(resProduto.attributes),
                        sku:  await extractSKU(resProduto.attributes)
                    }
            
            await produtoUpdate.produtoUpdate(produto);
        }
    }
  } catch (error) {
    console.error('Erro ao processar produtos.');
    throw error;
  }
}

async function extractSKU(attributes) {
  const skuAttr = attributes.find(attr => attr.id === 'SELLER_SKU');
  return skuAttr?.value_name || null;
}

async function extractGTIN(attributes) {
  const skuAttr = attributes.find(attr => attr.id === 'GTIN');
  return skuAttr?.value_name || null;
}

module.exports = { produtosAtualizar };