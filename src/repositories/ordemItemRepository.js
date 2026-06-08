const { getConnection } = require('../config/database');
const { tratarErroOracle } = require('../utils/oracleErrorHandler');
const oracledb = require('oracledb');

async function ordemItemUpdate(data) {
  
  const connection = await getConnection();    

  try {
    
        await connection.execute(
            `BEGIN PRC_MLAPI_ORDEM_ITEM_UPDATE( :P_MLOI_ORDER_ID   ,
                                                :P_MLOI_PRODUTO_ID ,
                                                :P_MLOI_QUANTITY   ,
                                                :P_MLOI_UNIT_PRICE ,
                                                :P_MLOI_SKU        ,
                                                :P_MLOI_GTIN       ,
                                                :P_MLOI_SALE_FEE   ,
                                                :P_TRANSACTION     ); END;`,
                    {
                        P_MLOI_ORDER_ID: data.ordem_id,
                        P_MLOI_PRODUTO_ID: data.produto_id,
                        P_MLOI_QUANTITY: data.quantity,
                        P_MLOI_UNIT_PRICE: data.unit_price,
                        P_MLOI_SKU: data.sku,
                        P_MLOI_GTIN: data.gtin,
                        P_MLOI_SALE_FEE: data.sale_fee,
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
  ordemItemUpdate
};