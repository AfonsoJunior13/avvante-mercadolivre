const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const oracledb = require('oracledb');
require('dotenv').config();

async function produtoUpdate(data) {
  
  const connection = await getConnection();  
  const unidadeEmpresarialID = process.env.UNIDADE_EMPRESARIAL_ID;

  try {
    
        await connection.execute(
            `BEGIN PRC_MLAPI_PRODUTO_UPDATE(  :P_UNIDADE_EMPRESARIAL_ID  ,
                                              :P_MLPD_ID                 ,
                                              :P_MLPD_TITLE              ,
                                              :P_MLPD_SELLER_ID          ,
                                              :P_MLPD_CATEGORY_ID        ,
                                              :P_MLPD_USER_PRODUCT_ID    ,
                                              :P_MLPD_PRICE              ,
                                              :P_MLPD_BASE_PRICE         ,
                                              :P_MLPD_ORIGINAL_PRICE     ,
                                              :P_MLPD_INITIAL_QUANTITY   ,
                                              :P_MLPD_AVAILABLE_QUANTITY ,
                                              :P_MLPD_SOLD_QUANTITY      ,
                                              :P_MLPD_LISTING_TYPE_ID    ,
                                              :P_MLPD_PERMALINK          ,
                                              :P_MLPD_DATE_CREATED       ,
                                              :P_MLPD_LAST_UPDATED       ,
                                              :P_MLPD_GTIN               ,
                                              :P_MLPD_SKU                , 
                                              :P_TRANSACTION             ); END;`,
                    {
                        P_UNIDADE_EMPRESARIAL_ID: unidadeEmpresarialID,
                        P_MLPD_ID: data.id,                    
                        P_MLPD_TITLE: data.title, 
                        P_MLPD_SELLER_ID: data.seller_id, 
                        P_MLPD_CATEGORY_ID: data.category_id, 
                        P_MLPD_USER_PRODUCT_ID: data.user_product_id, 
                        P_MLPD_PRICE: data.price, 
                        P_MLPD_BASE_PRICE: data.base_price, 
                        P_MLPD_ORIGINAL_PRICE: data.original_price, 
                        P_MLPD_INITIAL_QUANTITY: data.initial_quantity, 
                        P_MLPD_AVAILABLE_QUANTITY: data.available_quantity, 
                        P_MLPD_SOLD_QUANTITY: data.sold_quantity, 
                        P_MLPD_LISTING_TYPE_ID: data.listing_type_id, 
                        P_MLPD_PERMALINK: data.permalink, 
                        P_MLPD_DATE_CREATED: new Date(data.date_created), 
                        P_MLPD_LAST_UPDATED: new Date(data.last_updated),
                        P_MLPD_GTIN: data.gtin,    
                        P_MLPD_SKU: data.sku,                    
                        P_TRANSACTION: 0
                    }
        );        
    return {success: true};

  } catch (err) {        
    if (err.errorNum === 20000) {
      throw new Error(tratarErroOracle(err.message));
    } else {
      throw new Error('Erro inesperado: ' + err.message);
    }
  } finally {
    await connection.close();
  }
}

module.exports = {  
  produtoUpdate
};
