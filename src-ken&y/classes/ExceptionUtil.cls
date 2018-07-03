@isTest
public with sharing class ExceptionUtil {
	
	public static final String EXCEPTION_TYPE_EXCEPTION = 'Exception';
	public static final String EXCEPTION_TYPE_INFO = 'Info';

	//KNDY-8790
	public static TaskType POLINE_INVOICE_STATUS_CLOSED {
		get {
			if(POLINE_INVOICE_STATUS_CLOSED == null) {
				POLINE_INVOICE_STATUS_CLOSED = new TaskType();
				POLINE_INVOICE_STATUS_CLOSED.code = 'SI-POLINVSTATUS000001';
				POLINE_INVOICE_STATUS_CLOSED.label = 'Matching is not allowed against a Purchase Order Line which is closed for invoicing.';
				POLINE_INVOICE_STATUS_CLOSED.description = 'Matching is not allowed against a Purchase Order Line which is closed for invoicing.';
				POLINE_INVOICE_STATUS_CLOSED.typeName = 'Exception';
			}
			return POLINE_INVOICE_STATUS_CLOSED;
		}	
	}
	
	//KNDY-4298
	public static TaskType SO_INVOICE_LINE_PRICE_MISMATCH {
		get {
			if(SO_INVOICE_LINE_PRICE_MISMATCH == null) {
				SO_INVOICE_LINE_PRICE_MISMATCH = new TaskType();
				SO_INVOICE_LINE_PRICE_MISMATCH.code = 'SO-INV00001';
				SO_INVOICE_LINE_PRICE_MISMATCH.label = 'Invoice has a price discrepancy';
				SO_INVOICE_LINE_PRICE_MISMATCH.description = 'This invoice has a price conflict with its related Sales Order.  Adjust the Expected Price to manage this discrepancy.';
				SO_INVOICE_LINE_PRICE_MISMATCH.typeName = 'Exception';
			}
			return SO_INVOICE_LINE_PRICE_MISMATCH;
		}	
	}
    
    public static TaskType SO_CUSTOMER_NOT_APPROVED{
        get {
            if(SO_CUSTOMER_NOT_APPROVED == null){
                    SO_CUSTOMER_NOT_APPROVED = new TaskType();
                    SO_CUSTOMER_NOT_APPROVED.code = 'SO-CNA00001';
                    SO_CUSTOMER_NOT_APPROVED.label = 'Corporate Parent Customer has not been approved';
                    SO_CUSTOMER_NOT_APPROVED.description = 'The Corporate Parent Customer has not been approved. You can manage the approval status by editing the Corporate Parent Status.';
                    SO_CUSTOMER_NOT_APPROVED.typeName = 'Exception';
            }
            return SO_CUSTOMER_NOT_APPROVED;
        }
    }
    
    public static TaskType SO_SOLD_TO_CUSTOMER_NOT_APPROVED{
        get {
            if(SO_SOLD_TO_CUSTOMER_NOT_APPROVED == null){
                    SO_SOLD_TO_CUSTOMER_NOT_APPROVED = new TaskType();
                    SO_SOLD_TO_CUSTOMER_NOT_APPROVED.code = 'SO-CNA00002';
                    SO_SOLD_TO_CUSTOMER_NOT_APPROVED.label = 'Sold To Customer has not been approved';
                    SO_SOLD_TO_CUSTOMER_NOT_APPROVED.description = 'The Sold To Customer has not been approved. You can manage the approval status by editing the Customer Status.';
                    SO_SOLD_TO_CUSTOMER_NOT_APPROVED.typeName = 'Exception';
            }
            return SO_SOLD_TO_CUSTOMER_NOT_APPROVED;
        }
    }
    public static TaskType SO_BILL_TO_CUSTOMER_NOT_APPROVED{
        get {
            if(SO_BILL_TO_CUSTOMER_NOT_APPROVED == null){
                    SO_BILL_TO_CUSTOMER_NOT_APPROVED = new TaskType();
                    SO_BILL_TO_CUSTOMER_NOT_APPROVED.code = 'SO-CNA00003';
                    SO_BILL_TO_CUSTOMER_NOT_APPROVED.label = 'Bill To Customer has not been approved';
                    SO_BILL_TO_CUSTOMER_NOT_APPROVED.description = 'The Bill To Customer has not been approved. You can manage the approval status by editing the Customer Status.';
                    SO_BILL_TO_CUSTOMER_NOT_APPROVED.typeName = 'Exception';
            }
            return SO_BILL_TO_CUSTOMER_NOT_APPROVED;
        }
    }
    public static TaskType SO_SHIP_TO_CUSTOMER_NOT_APPROVED{
        get {
            if(SO_SHIP_TO_CUSTOMER_NOT_APPROVED == null){
                    SO_SHIP_TO_CUSTOMER_NOT_APPROVED = new TaskType();
                    SO_SHIP_TO_CUSTOMER_NOT_APPROVED.code = 'SO-CNA00004';
                    SO_SHIP_TO_CUSTOMER_NOT_APPROVED.label = 'Ship To Customer has not been approved';
                    SO_SOLD_TO_CUSTOMER_NOT_APPROVED.description = 'The Ship To Customer has not been approved. You can manage the approval status by editing the Customer Status.';
                    SO_SHIP_TO_CUSTOMER_NOT_APPROVED.typeName = 'Exception';
            }
            return SO_SHIP_TO_CUSTOMER_NOT_APPROVED;
        }
    }
	public static TaskType PRODUCT_IS_BLOCKED {
		get {
			if(PRODUCT_IS_BLOCKED == null) {
				PRODUCT_IS_BLOCKED = new TaskType();
				PRODUCT_IS_BLOCKED.code = 'SO-SUB00001';
				PRODUCT_IS_BLOCKED.label = 'Product is blocked';
				PRODUCT_IS_BLOCKED.description = 'This product is currently on block.  You can manage this under the Substitution Rules.';
				PRODUCT_IS_BLOCKED.typeName = 'Exception';
			}
			return PRODUCT_IS_BLOCKED;
		}
	}
	
	public static TaskType PRODUCT_IS_MISSING_VALID_PRICE {
		get {
			if(PRODUCT_IS_MISSING_VALID_PRICE == null) {
				PRODUCT_IS_MISSING_VALID_PRICE = new TaskType();
				PRODUCT_IS_MISSING_VALID_PRICE.code = 'SO-PRC00001';
				PRODUCT_IS_MISSING_VALID_PRICE.label = 'Product is missing valid pricing';
				PRODUCT_IS_MISSING_VALID_PRICE.description = 'This product is missing valid pricing.  You can manage this under Pricebooks.';
				PRODUCT_IS_MISSING_VALID_PRICE.typeName = 'Exception';
			}
			return PRODUCT_IS_MISSING_VALID_PRICE;
		}	
	}
	
	public static TaskType SO_OVER_WEIGHT_EXCEPTION {
		get {
			if(SO_OVER_WEIGHT_EXCEPTION == null) {
				SO_OVER_WEIGHT_EXCEPTION = new TaskType();
				SO_OVER_WEIGHT_EXCEPTION.code = 'SO-WGT0001';
				SO_OVER_WEIGHT_EXCEPTION.label = 'Order is over the maximum weight.';
				SO_OVER_WEIGHT_EXCEPTION.description = 'This order (and its shipment) is over the maximum allowable weight.  Reduce the quantity or number of line items to manage this weight.';
				SO_OVER_WEIGHT_EXCEPTION.typeName = 'Exception';
			}
			return SO_OVER_WEIGHT_EXCEPTION;
		}	
	}	
	
	public static TaskType SO_UNDER_WEIGHT_EXCEPTION { 
		get {
			if(SO_UNDER_WEIGHT_EXCEPTION == null) {
				SO_UNDER_WEIGHT_EXCEPTION = new TaskType();
				SO_UNDER_WEIGHT_EXCEPTION.code = 'SO-WGT0003';
				SO_UNDER_WEIGHT_EXCEPTION.label = 'Order is under minimum allowable weight.';
				SO_UNDER_WEIGHT_EXCEPTION.description = 'This order (and its shipment) is under the minimum allowable weight.  This can be managed by adjusting the number of products in the order.';
				SO_UNDER_WEIGHT_EXCEPTION.typeName = 'Exception';
			}
			return SO_UNDER_WEIGHT_EXCEPTION;
		}	 
	}	        
	
	public static TaskType SHIP_AGG_OVER_WEIGHT_EXCEPTION {
		get {
			if(SHIP_AGG_OVER_WEIGHT_EXCEPTION == null) {
				SHIP_AGG_OVER_WEIGHT_EXCEPTION = new TaskType();
				SHIP_AGG_OVER_WEIGHT_EXCEPTION.code = 'SO-WGT0002';
				SHIP_AGG_OVER_WEIGHT_EXCEPTION.label = 'Aggregated Order is overweight';
				SHIP_AGG_OVER_WEIGHT_EXCEPTION.description = 'After Aggregation, this order is overweight.  This can be managed under Sales Order Aggregation.';
				SHIP_AGG_OVER_WEIGHT_EXCEPTION.typeName = 'Exception';
			}
			return SHIP_AGG_OVER_WEIGHT_EXCEPTION;
		}	
	}
	
	public static TaskType SHIPMENT_OVER_WEIGHT_EXCEPTION {
		get {
			if(SHIPMENT_OVER_WEIGHT_EXCEPTION == null) {
				SHIPMENT_OVER_WEIGHT_EXCEPTION = new TaskType();
				SHIPMENT_OVER_WEIGHT_EXCEPTION.code = 'SH-WGT0001';
				SHIPMENT_OVER_WEIGHT_EXCEPTION.label = 'Shipment is overweight';
				SHIPMENT_OVER_WEIGHT_EXCEPTION.description = 'The shipment weighs more than the maximum weight capacity of the means of transport.';
				SHIPMENT_OVER_WEIGHT_EXCEPTION.typeName = 'Exception';
			}
			return SHIPMENT_OVER_WEIGHT_EXCEPTION;
		}	
	}	
	
	public static TaskType SO_ON_HOLD {
		get {
			if(SO_ON_HOLD == null) {
				SO_ON_HOLD = new TaskType();
				SO_ON_HOLD.code = 'SO-PLAN001';
				SO_ON_HOLD.label = 'Sales Order is on hold.';
				SO_ON_HOLD.description = 'This Sales Order is on hold. Please remove hold and try again.';
				SO_ON_HOLD.typeName = 'Exception';
			}
			return SO_ON_HOLD;
		}	
	}
	
	public static TaskType SO_NO_LINES_TO_PLAN {
		get {
			if(SO_NO_LINES_TO_PLAN == null) {
				SO_NO_LINES_TO_PLAN = new TaskType();
				SO_NO_LINES_TO_PLAN.code = 'SO-PLAN002';
				SO_NO_LINES_TO_PLAN.label = 'Sales Order has no lines to be planned.';
				SO_NO_LINES_TO_PLAN.description = 'This Sales Order has no eligible lines to release. Please check the lines for exceptions.';
				SO_NO_LINES_TO_PLAN.typeName = 'Exception';
			}
			return SO_NO_LINES_TO_PLAN;
		}	
	}
	
	public static TaskType SO_CREDIT_LIMIT_EXCEEDED {
		get {
			if(SO_CREDIT_LIMIT_EXCEEDED == null) {
				SO_CREDIT_LIMIT_EXCEEDED = new TaskType();
				SO_CREDIT_LIMIT_EXCEEDED.code = 'SO-PLAN003';
				SO_CREDIT_LIMIT_EXCEEDED.label = 'Sales Order exceeds the customer credit limit.';
				SO_CREDIT_LIMIT_EXCEEDED.description = 'This Sales Order exceeds the credit limit for the customer. Please check the limits on the customer.';
				SO_CREDIT_LIMIT_EXCEEDED.typeName = ExceptionUtil.EXCEPTION_TYPE_EXCEPTION;
			}
			return SO_CREDIT_LIMIT_EXCEEDED;
		}	
	}

	public static TaskType SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP {
		get {
			if(SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP == null) {
				SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP = new TaskType();
				SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP.code = 'SO-PLAN003';
				SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP.label = 'Sales Order exceeds the customer credit limit.';
				SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP.description = 'This Sales Order exceeds the credit limit for the customer. Please check the limits on the customer.';
				SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP.typeName = ExceptionUtil.EXCEPTION_TYPE_EXCEPTION;
			}
			return SO_CREDIT_LIMIT_EXCEEDED_DROPSHIP;
		}	
	}

	public static TaskType SO_PLAN_INVALID_STATUS {
		get {
			if(SO_PLAN_INVALID_STATUS == null) {
				SO_PLAN_INVALID_STATUS = new TaskType();
				SO_PLAN_INVALID_STATUS.code = 'SO-PLAN00004';
				SO_PLAN_INVALID_STATUS.label = 'Sales order cannot be planned in the current status.';
				SO_PLAN_INVALID_STATUS.description = 'Sales order cannot be planned in Closed, Cancel or Hold statuses.';
				SO_PLAN_INVALID_STATUS.typeName = 'Exception';
			}
			return SO_PLAN_INVALID_STATUS;
		}	
	}
	
	public static TaskType SOL_MISSING_SHIP_FROM_LOCATION {
		get {
			if(SOL_MISSING_SHIP_FROM_LOCATION == null) {
				SOL_MISSING_SHIP_FROM_LOCATION = new TaskType();
				SOL_MISSING_SHIP_FROM_LOCATION.code = 'SOL-PLAN00005';
				SOL_MISSING_SHIP_FROM_LOCATION.label = 'Missing ship from location.';
				SOL_MISSING_SHIP_FROM_LOCATION.description = 'Sales order line is missing ship from location. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_MISSING_SHIP_FROM_LOCATION.typeName = 'Exception';
			}
			return SOL_MISSING_SHIP_FROM_LOCATION;
		}	
	}
    public static TaskType SOL_MISSING_RECEIVING_LOCATION {
		get {
			if(SOL_MISSING_RECEIVING_LOCATION == null) {
				SOL_MISSING_RECEIVING_LOCATION = new TaskType();
				SOL_MISSING_RECEIVING_LOCATION.code = 'SOL-PLAN00014';
				SOL_MISSING_RECEIVING_LOCATION.label = 'Missing receiving location.';
				SOL_MISSING_RECEIVING_LOCATION.description = 'Sales order line is missing receiving location. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_MISSING_RECEIVING_LOCATION.typeName = 'Exception';
			}
			return SOL_MISSING_RECEIVING_LOCATION;
		}	
	}	
	public static TaskType SOL_INVALID_ORDER_QUANTITY {
		get {
			if(SOL_INVALID_ORDER_QUANTITY == null) {
				SOL_INVALID_ORDER_QUANTITY = new TaskType();
				SOL_INVALID_ORDER_QUANTITY.code = 'SOL-PLAN00006';
				SOL_INVALID_ORDER_QUANTITY.label = 'Quantity Ordered is invalid.';
				SOL_INVALID_ORDER_QUANTITY.description = 'Sales order line has an invalid value for Quantity Ordered. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_INVALID_ORDER_QUANTITY.typeName = 'Exception';
			}
			return SOL_INVALID_ORDER_QUANTITY;
		}	
	}
	
	public static TaskType SOL_MISSING_PRODUCT {
		get {
			if(SOL_MISSING_PRODUCT == null) {
				SOL_MISSING_PRODUCT = new TaskType();
				SOL_MISSING_PRODUCT.code = 'SOL-PLAN00007';
				SOL_MISSING_PRODUCT.label = 'Missing product.';
				SOL_MISSING_PRODUCT.description = 'Sales order line is missing product information. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_MISSING_PRODUCT.typeName = 'Exception';
			}
			return SOL_MISSING_PRODUCT;
		}	
	}
	
	public static TaskType SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH {
		get {
			if(SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH == null) {
				SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH = new TaskType();
				SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH.code = 'SOL-PLAN00008';
				SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH.label = 'Ship from location does not match.';
				SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH.description = 'Sales order line has a different ship from location than other lines on the order. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH.typeName = 'Exception';
			}
			return SOL_SHIP_FROM_LOCATION_DOES_NOT_MATCH;
		}	
	}
	
	public static TaskType SOL_MISSING_ITEM_SPECIFICATION {
		get {
			if (SOL_MISSING_ITEM_SPECIFICATION == null) {
				SOL_MISSING_ITEM_SPECIFICATION = new TaskType();
				SOL_MISSING_ITEM_SPECIFICATION.code = 'SOL-PLAN00009';
				SOL_MISSING_ITEM_SPECIFICATION.label = 'Sales Order Line with Kit/Build To Order Item Source or Build To Order Fulfillment Source is missing Item Specification.';
				SOL_MISSING_ITEM_SPECIFICATION.description = 'Sales Order Line with Kit or Build To Order Item Source or Build To Order Fulfillment Source is missing Item Specification. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_MISSING_ITEM_SPECIFICATION.typeName = 'Exception';
				SOL_MISSING_ITEM_SPECIFICATION.ProhibitOverride = true;
			}
			return SOL_MISSING_ITEM_SPECIFICATION;
		}
	}

	public static TaskType SO_PLAN_INVALID_TYPE {
		get {
			if(SO_PLAN_INVALID_TYPE == null) {
				SO_PLAN_INVALID_TYPE = new TaskType();
				SO_PLAN_INVALID_TYPE.code = 'SO-PLAN00009';
				SO_PLAN_INVALID_TYPE.label = 'Sales order type is not supported for planning.';
				SO_PLAN_INVALID_TYPE.description = 'Only sales orders of type \'Standard\' can be planned.';
				SO_PLAN_INVALID_TYPE.typeName = 'Exception';
			}
			return SO_PLAN_INVALID_TYPE;
		}	
	}
	
	public static TaskType SO_NO_SHIPMENT_SELECTED {
		get {
			if(SO_NO_SHIPMENT_SELECTED == null) {
				SO_NO_SHIPMENT_SELECTED = new TaskType();
				SO_NO_SHIPMENT_SELECTED.code = 'SO-PLAN00010';
				SO_NO_SHIPMENT_SELECTED.label = 'No shipment selected to release the sales order';
				SO_NO_SHIPMENT_SELECTED.description = 'There are existing shipments created for this sales order. Please select a shipment to release the sales order.';
				SO_NO_SHIPMENT_SELECTED.typeName = 'Exception';
			}
			return SO_NO_SHIPMENT_SELECTED;
		}	
	}
	

	public static TaskType SO_ALL_LINES_SAME_FULFILLMENT_SOURCE {
		get {
			if(SO_ALL_LINES_SAME_FULFILLMENT_SOURCE == null) {
				SO_ALL_LINES_SAME_FULFILLMENT_SOURCE = new TaskType();
				SO_ALL_LINES_SAME_FULFILLMENT_SOURCE.code = 'SO-PLAN00011';
				SO_ALL_LINES_SAME_FULFILLMENT_SOURCE.label = 'Sales Order Lines have mixed Fulfillment Source';
				SO_ALL_LINES_SAME_FULFILLMENT_SOURCE.description = 'Sales Order lines must have the same Fulfillment Source.';
				SO_ALL_LINES_SAME_FULFILLMENT_SOURCE.typeName = 'Exception';
			}
			return SO_ALL_LINES_SAME_FULFILLMENT_SOURCE;
		}	
	}

	public static TaskType SO_CUSTOMER_MISSING {
		get {
			if(SO_CUSTOMER_MISSING == null) {
				SO_CUSTOMER_MISSING = new TaskType();
				SO_CUSTOMER_MISSING.code = 'SO-PLAN00012';
				SO_CUSTOMER_MISSING.label = 'Sales order does not have a customer.';
				SO_CUSTOMER_MISSING.description = 'Only sales orders that have a valid customer can be planned.';
				SO_CUSTOMER_MISSING.typeName = 'Exception';
				SO_CUSTOMER_MISSING.ProhibitOverride = true;
			}
			return SO_CUSTOMER_MISSING;
		}	
	}

	public static TaskType SO_NO_PAYMENT_TERM_SELECTED {
		get {
			if(SO_NO_PAYMENT_TERM_SELECTED == null) {
				SO_NO_PAYMENT_TERM_SELECTED = new TaskType();
				SO_NO_PAYMENT_TERM_SELECTED.code = 'SO-PLAN00013';
				SO_NO_PAYMENT_TERM_SELECTED.label = 'Sales order does not have a value for payment terms.';
				SO_NO_PAYMENT_TERM_SELECTED.description = 'Only sales orders that have a valid payment term can be planned.';
				SO_NO_PAYMENT_TERM_SELECTED.typeName = 'Exception';
				SO_NO_PAYMENT_TERM_SELECTED.ProhibitOverride = true;
			}
			return SO_NO_PAYMENT_TERM_SELECTED;
		}	
	}

	public static TaskType SOL_REQUIRED_DATE_MISSING {
		get {
			if(SOL_REQUIRED_DATE_MISSING == null) {
				SOL_REQUIRED_DATE_MISSING = new TaskType();
				SOL_REQUIRED_DATE_MISSING.code = 'SOL-PLAN00012';
				SOL_REQUIRED_DATE_MISSING.label = 'The Sales Order Line is missing the Required Date or Product Item Lead Time.';
				SOL_REQUIRED_DATE_MISSING.description = 'Please provide the Sales Order Line Required Date or Item Lead Time.';
				SOL_REQUIRED_DATE_MISSING.typeName = 'Exception';
			}
			return SOL_REQUIRED_DATE_MISSING;
		}	
	}

	public static TaskType SOL_INACTIVE_ITEM_SPECIFICATION {
		get {
			if (SOL_INACTIVE_ITEM_SPECIFICATION == null) {
				SOL_INACTIVE_ITEM_SPECIFICATION = new TaskType();
				SOL_INACTIVE_ITEM_SPECIFICATION.code = 'SOL-PLAN00015';
				SOL_INACTIVE_ITEM_SPECIFICATION.label = 'Sales Order Line has inactive Item Specification.';
				SOL_INACTIVE_ITEM_SPECIFICATION.description = 'Sales Order Line has inactive Item Specification. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_INACTIVE_ITEM_SPECIFICATION.typeName = 'Exception';
			}
			return SOL_INACTIVE_ITEM_SPECIFICATION;
		}
	}

	public static TaskType SO_LINE_ALLOCATION_EXCEPTION {
		get {
			if(SO_LINE_ALLOCATION_EXCEPTION == null) {
				SO_LINE_ALLOCATION_EXCEPTION = new TaskType();
				SO_LINE_ALLOCATION_EXCEPTION.code = 'SO-ALC00001';
				SO_LINE_ALLOCATION_EXCEPTION.label = 'Product is current on allocation';
				SO_LINE_ALLOCATION_EXCEPTION.description = 'Product is current on allocation. There is no quantity available for sale. \n You can maintain this under Product —> Manage Allocation Rules.';
				SO_LINE_ALLOCATION_EXCEPTION.typeName = 'Exception';
			}
			return SO_LINE_ALLOCATION_EXCEPTION;
		}	
	}	
	
	public static TaskType SO_ALLOCATE_INVALID_STATUS {
		get {
			if(SO_ALLOCATE_INVALID_STATUS == null) {
				SO_ALLOCATE_INVALID_STATUS = new TaskType();
				SO_ALLOCATE_INVALID_STATUS.code = 'SO-ALC00002';
				SO_ALLOCATE_INVALID_STATUS.label = 'Sales order cannot be allocated in the current status.';
				SO_ALLOCATE_INVALID_STATUS.description = 'Sales order cannot be allocated in Closed, Cancel or Hold statuses.';
				SO_ALLOCATE_INVALID_STATUS.typeName = 'Exception';
			}
			return SO_ALLOCATE_INVALID_STATUS;
		}	
	}
	
	public static TaskType SO_ALLOCATE_CUSTOMER_NOT_APPROVED {
		get {
			if(SO_ALLOCATE_CUSTOMER_NOT_APPROVED == null) {
				SO_ALLOCATE_CUSTOMER_NOT_APPROVED = new TaskType();
				SO_ALLOCATE_CUSTOMER_NOT_APPROVED.code = 'SO-ALC00003';
				SO_ALLOCATE_CUSTOMER_NOT_APPROVED.label = Label.Top_Parent_Customer_not_status_Approved;
				SO_ALLOCATE_CUSTOMER_NOT_APPROVED.description = 'Sales order cannot be allocated for a non-approved customer.';
				SO_ALLOCATE_CUSTOMER_NOT_APPROVED.typeName = 'Exception';
			}
			return SO_ALLOCATE_CUSTOMER_NOT_APPROVED;
		}	
	}
	
	public static TaskType SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE {
		get {
			if(SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE == null) {
				SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE = new TaskType();
				SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE.code = 'SO-ALC00004';
				SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE.label = 'Sales order line cannot be allocated due to insufficient quantity.';
				SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE.description = 'Sales order line cannot be allocated due to insufficient quantity.';
				SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE.typeName = 'Exception';
			}
			return SO_LINE_ALLOCATE_QUANTITY_NOT_AVAILABLE;
		}	
	}

	public static TaskType SO_RELEASED_TO_3PL {
		get {
			if(SO_RELEASED_TO_3PL == null) {
				SO_RELEASED_TO_3PL = new TaskType();
				SO_RELEASED_TO_3PL.code = 'SO-GEN00001';
				SO_RELEASED_TO_3PL.label = 'Sales Order has been released to 3PL';
				SO_RELEASED_TO_3PL.description = 'Sales Order has been relased to 3PL. No Modifications are allowed.';
				SO_RELEASED_TO_3PL.typeName = 'Exception';
			}
			return SO_RELEASED_TO_3PL;
		}	
	}

	public static TaskType SO_LINE_MIN_ORDER_QTY_EXCEPTION {
		get {
			if(SO_LINE_MIN_ORDER_QTY_EXCEPTION == null) {
				SO_LINE_MIN_ORDER_QTY_EXCEPTION = new TaskType();
				SO_LINE_MIN_ORDER_QTY_EXCEPTION.code = 'SO-QTY00001';
				SO_LINE_MIN_ORDER_QTY_EXCEPTION.label = 'Quantity Ordered must be a multiple of \'Quantity Factor\'';
				SO_LINE_MIN_ORDER_QTY_EXCEPTION.description = 'Order quantity should be even with Product\'s layer/pallet configuration. Please order in multiples of the same.';
				SO_LINE_MIN_ORDER_QTY_EXCEPTION.typeName = 'Exception';
			}
			return SO_LINE_MIN_ORDER_QTY_EXCEPTION;
		}	
	}
	
	public static TaskType SHPLN_SO_ON_HOLD {
		get {
			if(SHPLN_SO_ON_HOLD == null) {
				SHPLN_SO_ON_HOLD = new TaskType();
				SHPLN_SO_ON_HOLD.code = 'SHL-SO00001';
				SHPLN_SO_ON_HOLD.label = 'Sales order belonging to Shipment Line is on hold.';
				SHPLN_SO_ON_HOLD.description = 'Sales order belonging to Shipment Line is on hold: ';
				SHPLN_SO_ON_HOLD.typeName = 'Exception';
			}
			return SHPLN_SO_ON_HOLD;
		}	
	}

	public static TaskType SHPLN_SO_ON_CREDIT_HOLD {
		get {
			if(SHPLN_SO_ON_CREDIT_HOLD == null) {
				SHPLN_SO_ON_CREDIT_HOLD = new TaskType();
				SHPLN_SO_ON_CREDIT_HOLD.code = 'SHL-SO00002';
				SHPLN_SO_ON_CREDIT_HOLD.label = 'Sales order belonging to Shipment Line is on Credit Hold';
				SHPLN_SO_ON_CREDIT_HOLD.description = 'Sales order belonging to Shipment Line is on Credit Hold: ';
				SHPLN_SO_ON_CREDIT_HOLD.typeName = 'Exception';
			}
			return SHPLN_SO_ON_CREDIT_HOLD;
		}	
	}

	public static TaskType SHPLN_SO_RELEASED_TO_3PL {
		get {
			if(SHPLN_SO_RELEASED_TO_3PL == null) {
				SHPLN_SO_RELEASED_TO_3PL = new TaskType();
				SHPLN_SO_RELEASED_TO_3PL.code = 'SHL-SO00003';
				SHPLN_SO_RELEASED_TO_3PL.label = 'Sales order is released to 3PL. Shipping details are locked.';
				SHPLN_SO_RELEASED_TO_3PL.description = 'Sales order is released to 3PL. Shipping details are locked: ';
				SHPLN_SO_RELEASED_TO_3PL.typeName = 'Exception';
			}
			return SHPLN_SO_RELEASED_TO_3PL;
		}	
	}

	public static TaskType TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD {
		get {
			if(TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD == null) {
				TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD = new TaskType();
				TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD.code = 'SHL-CUS00001';
				TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD.label = 'Top Parent customer is currently on Credit Hold';
				TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD.description = 'Top Parent customer is currently on Credit Hold: ';
				TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD.typeName = 'Exception';
			}
			return TOP_PARENT_CUSTOMER_ON_CREDIT_HOLD;
		}	
	}

	public static TaskType TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED {
		get {
			if(TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED == null) {
				TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED = new TaskType();
				TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED.code = 'SHL-CUS00002';
				TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED.label = 'Top Parent customer status is not approved';
				TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED.description = 'Top Parent customer status is not approved: ';
				TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED.typeName = 'Exception';
			}
			return TOP_PARENT_CUSTOMER_NOT_STATUS_APPROVED;
		}	
	}
	
	public static TaskType PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE {
		get {
			if(PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE == null) {
				PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE = new TaskType();
				PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE.code = 'SO-PRC00002';
				PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE.label = 'Product is missing weight/volume based Price';
				PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE.description = 'This product is using weight-based pricing and cannot find a price.  You can manage this under the Pricebooks and Brackets.';
				PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE.typeName = 'Exception';
			}
			return PRODUCT_IS_MISSING_WEIGHT_VOLUME_BASED_VALID_PRICE;
		}	
	}
	
	public static TaskType PRICEBOOK_NOT_FOUND {
		get {
			if(PRICEBOOK_NOT_FOUND == null) {
				PRICEBOOK_NOT_FOUND = new TaskType();
				PRICEBOOK_NOT_FOUND.code = 'SO-PRC00003';
				PRICEBOOK_NOT_FOUND.label = 'Price not found. Please contact pricing administrator.';
				PRICEBOOK_NOT_FOUND.description = 'This sales order line does not have a pricebook associated with it. You can manage this under the Pricebooks.';
				PRICEBOOK_NOT_FOUND.typeName = 'Exception';
			}
			return PRICEBOOK_NOT_FOUND;
		}	
	}
	
	public static TaskType PRICEBOOK_LINE_NOT_FOUND {
		get {
			if(PRICEBOOK_LINE_NOT_FOUND == null) {
				PRICEBOOK_LINE_NOT_FOUND = new TaskType();
				PRICEBOOK_LINE_NOT_FOUND.code = 'SO-PRC00004';
				PRICEBOOK_LINE_NOT_FOUND.label = 'Price not found. Please contact pricing administrator.';
				PRICEBOOK_LINE_NOT_FOUND.description = 'The product does not have a line in the pricebook. You can manage this under the Pricebooks.';
				PRICEBOOK_LINE_NOT_FOUND.typeName = 'Exception';
			}
			return PRICEBOOK_LINE_NOT_FOUND;
		}	
	}
	
	public static TaskType PRODUCT_PRICE_MISMATCH_UNIT_PRICE {
		get {
			if(PRODUCT_PRICE_MISMATCH_UNIT_PRICE == null) {
				PRODUCT_PRICE_MISMATCH_UNIT_PRICE = new TaskType();
				PRODUCT_PRICE_MISMATCH_UNIT_PRICE.code = 'SO-PRC00005';
				PRODUCT_PRICE_MISMATCH_UNIT_PRICE.label = 'Product price does not match order unit price';
				PRODUCT_PRICE_MISMATCH_UNIT_PRICE.description = 'The product price does not match the unit price on the sales order line. You can manage this under the Pricebooks.';
				PRODUCT_PRICE_MISMATCH_UNIT_PRICE.typeName = 'Exception';
			}
			return PRODUCT_PRICE_MISMATCH_UNIT_PRICE;
		}	
	}
	
	public static TaskType SOL_MISSING_PRICE {
		get {
			if(SOL_MISSING_PRICE == null) {
				SOL_MISSING_PRICE = new TaskType();
				SOL_MISSING_PRICE.code = 'SO-PRC00006';
				SOL_MISSING_PRICE.label = 'Product price is missing';
				SOL_MISSING_PRICE.description = 'The price is missing for the sales order line. You can edit this value under Sales Order -> Add / Manage Sales Order Lines.';
				SOL_MISSING_PRICE.typeName = 'Exception';
				SOL_MISSING_PRICE.ProhibitOverride = true;				
			}
			return SOL_MISSING_PRICE;
		}	
	}
	
	public static TaskType SOL_MISMATCH_TRANSACTION_CURRENCY {
		get {
			if(SOL_MISMATCH_TRANSACTION_CURRENCY == null) {
				SOL_MISMATCH_TRANSACTION_CURRENCY = new TaskType();
				SOL_MISMATCH_TRANSACTION_CURRENCY.code = 'SO-PRC00007';
				SOL_MISMATCH_TRANSACTION_CURRENCY.label = 'Mismatch Transaction Currency between Pricebooks and Sales Orders.';
				SOL_MISMATCH_TRANSACTION_CURRENCY.description = 'The Transaction Currency on Pricebook does not match the Transaction Currency on Sales Order Line.';
				SOL_MISMATCH_TRANSACTION_CURRENCY.typeName = 'Exception';
				SOL_MISMATCH_TRANSACTION_CURRENCY.ProhibitOverride = true;		
			}
			return SOL_MISMATCH_TRANSACTION_CURRENCY;
		}	
	}

	public static TaskType NOT_ENOUGH_LEAD_TIME_TO_SHIP {
		get {
			if(NOT_ENOUGH_LEAD_TIME_TO_SHIP == null) {
				NOT_ENOUGH_LEAD_TIME_TO_SHIP = new TaskType();
				NOT_ENOUGH_LEAD_TIME_TO_SHIP.code = 'SH-DATE00001';
				NOT_ENOUGH_LEAD_TIME_TO_SHIP.label = 'Not enough lead time to ship';
				NOT_ENOUGH_LEAD_TIME_TO_SHIP.description = 'This order cannot be delivered to the customer on the required date. Please try a later date.';
				NOT_ENOUGH_LEAD_TIME_TO_SHIP.typeName = 'Exception';
			}
			return NOT_ENOUGH_LEAD_TIME_TO_SHIP;
		}	
	}

	public static TaskType ITEM_NOT_ACTIVE {
		get {
			if(ITEM_NOT_ACTIVE == null) {
				ITEM_NOT_ACTIVE = new TaskType();
				ITEM_NOT_ACTIVE.code = 'SOL-ITEM00001';
				ITEM_NOT_ACTIVE.label = 'Item is not active';
				ITEM_NOT_ACTIVE.description = 'This order cannot be released: Item associated is not active';
				ITEM_NOT_ACTIVE.typeName = 'Exception';
				ITEM_NOT_ACTIVE.ProhibitOverride = true;
			}
			return ITEM_NOT_ACTIVE;
		}
	}

	public static TaskType SHIP_DATE_OUT_OF_RANGE {
		get {
			if(SHIP_DATE_OUT_OF_RANGE == null) {
				SHIP_DATE_OUT_OF_RANGE = new TaskType();
				SHIP_DATE_OUT_OF_RANGE.code = 'SH-DATE00002';
				SHIP_DATE_OUT_OF_RANGE.label = 'Ship date is out of range.';
				SHIP_DATE_OUT_OF_RANGE.description = 'The planned ship date is out of the ship date range for the corresponding sales order line.';
				SHIP_DATE_OUT_OF_RANGE.typeName = 'Exception';
			}
			return SHIP_DATE_OUT_OF_RANGE;
		}	
	}
	
	public static TaskType MISSING_COMPANY {
		get {
			if(MISSING_COMPANY == null) {
				MISSING_COMPANY = new TaskType();
				MISSING_COMPANY.code = 'SI-COMP00001';
				MISSING_COMPANY.label = 'The company is not specified!';
				MISSING_COMPANY.description = 'The company is not specified!';
				MISSING_COMPANY.typeName = 'Exception';
			}
			return MISSING_COMPANY;
		}	
	}

	// Customer Receipt and Lines 
	public static TaskType CR_CUSTOMER_PARENT {
	    get{
	    	if(CR_CUSTOMER_PARENT == null) {
		        CR_CUSTOMER_PARENT = new TaskType();
		        CR_CUSTOMER_PARENT.code = 'CR-CUSPAR000001';
		        CR_CUSTOMER_PARENT.label = 'Customer Receipt missing Customer Parent';
		        CR_CUSTOMER_PARENT.description = 'Customer Parent could not be found';
		        CR_CUSTOMER_PARENT.typeName = 'Exception';
	    	}
	        return CR_CUSTOMER_PARENT;
	    }
	}

	// Customer Receipt and Lines 
	public static TaskType CRL_INVOICE_MISSING {
	    get{
	    	if(CRL_INVOICE_MISSING == null) {
		        CRL_INVOICE_MISSING = new TaskType();
		        CRL_INVOICE_MISSING.code = 'CRL-CUSINV000001';
		        CRL_INVOICE_MISSING.label = 'Customer Invoice missing';
		        CRL_INVOICE_MISSING.description = 'Customer Invoice could not be found';
		        CRL_INVOICE_MISSING.typeName = 'Exception';
	    	}
	        return CRL_INVOICE_MISSING;
	    }
	}

	// Customer Receipt and Lines 
	public static TaskType CRL_CREDITMEMO_MISSING {
	    get{
	    	if(CRL_CREDITMEMO_MISSING == null) {
		        CRL_CREDITMEMO_MISSING = new TaskType();
		        CRL_CREDITMEMO_MISSING.code = 'CRL-CUSCM000001';
		        CRL_CREDITMEMO_MISSING.label = 'Customer Credit Memo missing';
		        CRL_CREDITMEMO_MISSING.description = 'Customer Credit Memo could not be found';
		        CRL_CREDITMEMO_MISSING.typeName = 'Exception';
	    	}
	        return CRL_CREDITMEMO_MISSING;
	    }
	}
	
	public static TaskType MISSING_SUPPLIER {
		get {
			if(MISSING_SUPPLIER == null) {
				MISSING_SUPPLIER = new TaskType();
				MISSING_SUPPLIER.code = 'SI-SUPP00001';
				MISSING_SUPPLIER.label = 'The supplier is not specified!';
				MISSING_SUPPLIER.description = 'The supplier is not specified!';
				MISSING_SUPPLIER.typeName = 'Exception';
			}
			return MISSING_SUPPLIER;
		}	
	}

	public static TaskType MISSING_DATE_INVOICED {
		get {
			if(MISSING_DATE_INVOICED == null) {
				MISSING_DATE_INVOICED = new TaskType();
				MISSING_DATE_INVOICED.code = 'SI-DATE00001';
				MISSING_DATE_INVOICED.label = 'The date invoiced is not specified!';
				MISSING_DATE_INVOICED.description = 'The date invoiced is not specified!';
				MISSING_DATE_INVOICED.typeName = 'Exception';
			}
			return MISSING_DATE_INVOICED;
		}	
	}

	public static TaskType MISSING_INVOICE_NUMBER {
		get {
			if(MISSING_INVOICE_NUMBER == null) {
				MISSING_INVOICE_NUMBER = new TaskType();
				MISSING_INVOICE_NUMBER.code = 'SI-INV00001';
				MISSING_INVOICE_NUMBER.label = 'The invoice number is not specified!';
				MISSING_INVOICE_NUMBER.description = 'The invoice number is not specified!';
				MISSING_INVOICE_NUMBER.typeName = 'Exception';
			}
			return MISSING_INVOICE_NUMBER;
		}	
	}

	public static TaskType NEGATIVE_INVOICE_AMOUNT {
		get {
			if(NEGATIVE_INVOICE_AMOUNT == null) {
				NEGATIVE_INVOICE_AMOUNT = new TaskType();
				NEGATIVE_INVOICE_AMOUNT.code = 'SI-NEG00001';
				NEGATIVE_INVOICE_AMOUNT.label = 'Please enter a positive invoice amount!';
				NEGATIVE_INVOICE_AMOUNT.description = 'Please enter a positive invoice amount!';
				NEGATIVE_INVOICE_AMOUNT.typeName = 'Exception';
			}
			return NEGATIVE_INVOICE_AMOUNT;
		}	
	}

	public static TaskType POSITIVE_INVOICE_AMOUNT {
		get {
			if(POSITIVE_INVOICE_AMOUNT == null) {
				POSITIVE_INVOICE_AMOUNT = new TaskType();
				POSITIVE_INVOICE_AMOUNT.code = 'SI-POSI00001';
				POSITIVE_INVOICE_AMOUNT.label = 'Please enter a negative invoice amount!';
				POSITIVE_INVOICE_AMOUNT.description = 'Please enter a negative invoice amount!';
				POSITIVE_INVOICE_AMOUNT.typeName = 'Exception';
			}
			return POSITIVE_INVOICE_AMOUNT;
		}	
	}
	
	public static TaskType NEGATIVE_LINE_AMOUNT {
		get {
			if(NEGATIVE_LINE_AMOUNT == null) {
				NEGATIVE_LINE_AMOUNT = new TaskType();
				NEGATIVE_LINE_AMOUNT.code = 'SI-NEG00002';
				NEGATIVE_LINE_AMOUNT.label = 'Please enter a positive quantity and unit price on prepayment line!'; 
				NEGATIVE_LINE_AMOUNT.description = 'Please enter a positive quantity and unit price on prepayment line!';
				NEGATIVE_LINE_AMOUNT.typeName = 'Exception';
			}
			return NEGATIVE_LINE_AMOUNT;
		}	
	}
	
	public static TaskType MISSING_PURCHASE_ORDER {
		get {
			if(MISSING_PURCHASE_ORDER == null) {
				MISSING_PURCHASE_ORDER = new TaskType();
				MISSING_PURCHASE_ORDER.code = 'SI-PO00001';
				MISSING_PURCHASE_ORDER.label = 'The purchase order is not specified!';
				MISSING_PURCHASE_ORDER.description = 'The purchase order is not specified!';
				MISSING_PURCHASE_ORDER.typeName = 'Exception';
			}
			return MISSING_PURCHASE_ORDER;
		}	
	}

	public static TaskType MISMATCH_SI_PO {
		get {
			if(MISMATCH_SI_PO == null) {
				MISMATCH_SI_PO = new TaskType();
				MISMATCH_SI_PO.code = 'SI-PO00002';
				MISMATCH_SI_PO.label = 'The purchase order and the supplier do not match!';
				MISMATCH_SI_PO.description = 'The purchase order and the supplier do not match!';
				MISMATCH_SI_PO.typeName = 'Exception';
			}
			return MISMATCH_SI_PO;
		}	
	}

	public static TaskType MISMATCH_SI_SUM {
		get {
			if(MISMATCH_SI_SUM == null) {
				MISMATCH_SI_SUM = new TaskType();
				MISMATCH_SI_SUM.code = 'SI-SUM00001';
				MISMATCH_SI_SUM.label = 'The sum of all invoice lines must match the Invoice Amount.';
				MISMATCH_SI_SUM.description = 'The sum of all invoice lines must match the Invoice Amount.';
				MISMATCH_SI_SUM.typeName = 'Exception';
				MISMATCH_SI_SUM.ProhibitOverride = true;
			}
			return MISMATCH_SI_SUM;
		}	
	}
	
	public static TaskType SI_ZERO_QUANTITY {
		get {
			if(SI_ZERO_QUANTITY == null) {
				SI_ZERO_QUANTITY = new TaskType();
				SI_ZERO_QUANTITY.code = 'SI-ZERO001';
				SI_ZERO_QUANTITY.label = 'You must enter a non-zero Invoice Quantity!';
				SI_ZERO_QUANTITY.description = 'You must enter a non-zero Invoice Quantity!';
				SI_ZERO_QUANTITY.typeName = 'Exception';
				SI_ZERO_QUANTITY.ProhibitOverride = true;
			}
			return SI_ZERO_QUANTITY;
		}	
	}
	
	public static TaskType SI_PAYMENT_DUE_DATE {
        get {
            if(SI_PAYMENT_DUE_DATE == null) {
                SI_PAYMENT_DUE_DATE = new TaskType();
                SI_PAYMENT_DUE_DATE.code = 'SI-DUEDATE';
                SI_PAYMENT_DUE_DATE.label = 'A due date is required.';
                SI_PAYMENT_DUE_DATE.description = 'A due date is required.';
                SI_PAYMENT_DUE_DATE.typeName = 'Exception';
            }
            return SI_PAYMENT_DUE_DATE;
        }   
    }


	public static TaskType MISSING_CREDIT_MEMO_AMT {
		get {
			if(MISSING_CREDIT_MEMO_AMT == null) {
				MISSING_CREDIT_MEMO_AMT = new TaskType();
				MISSING_CREDIT_MEMO_AMT.code = 'SI-CM00001';
				MISSING_CREDIT_MEMO_AMT.label = 'The credit memo amount is not specified!';
				MISSING_CREDIT_MEMO_AMT.description = 'The credit memo amount is not specified!';
				MISSING_CREDIT_MEMO_AMT.typeName = 'Exception';
			}
			return MISSING_CREDIT_MEMO_AMT;
		}	
	}

	public static TaskType MISMATCH_CREDIT_MEMO_AMT {
		get {
			if(MISMATCH_CREDIT_MEMO_AMT == null) {
				MISMATCH_CREDIT_MEMO_AMT = new TaskType();
				MISMATCH_CREDIT_MEMO_AMT.code = 'SI-CM00002';
				MISMATCH_CREDIT_MEMO_AMT.label = 'The sum of the lines does not match the credit memo amount!';
				MISMATCH_CREDIT_MEMO_AMT.description = 'The sum of the lines does not match the credit memo amount!';
				MISMATCH_CREDIT_MEMO_AMT.typeName = 'Exception';
			}
			return MISMATCH_CREDIT_MEMO_AMT;
		}	
	}

	public static TaskType MISSING_INVOICE {
		get {
			if(MISSING_INVOICE == null) {
				MISSING_INVOICE = new TaskType();
				MISSING_INVOICE.code = 'SI-CM00003';
				MISSING_INVOICE.label = 'The Invoice to apply the credit memo is not specified!';
				MISSING_INVOICE.description = 'The Invoice to apply the credit memo is not specified!';
				MISSING_INVOICE.typeName = 'Exception';
			}
			return MISSING_INVOICE;
		}	
	}
	
	public static TaskType MISSING_LINE_TYPE {
		get {
			if(MISSING_LINE_TYPE == null) {
				MISSING_LINE_TYPE = new TaskType();
				MISSING_LINE_TYPE.code = 'SI-LT00001';
				MISSING_LINE_TYPE.label = 'You must specify a line type!';
				MISSING_LINE_TYPE.description = 'You must specify a line type!';   
				MISSING_LINE_TYPE.typeName = 'Exception';
			}
			return MISSING_LINE_TYPE;
		}	
	}
	
	public static TaskType MISSING_ITEM {
		get {
			if(MISSING_ITEM == null) {
				MISSING_ITEM = new TaskType();
				MISSING_ITEM.code = 'SI-IT00001';
				MISSING_ITEM.label = 'Item is invalid!';
				MISSING_ITEM.description = 'Item is invalid!';   
				MISSING_ITEM.typeName = 'Exception';
			}
			return MISSING_ITEM;
		}	
	}
	
	public static TaskType MISSING_ITEM_POREF {
		get {
			if(MISSING_ITEM_POREF == null) {
				MISSING_ITEM_POREF = new TaskType();
				MISSING_ITEM_POREF.code = 'SI-ITPO00001'; 
				MISSING_ITEM_POREF.label = 'Line type: PO can be associated with only PO matched invoice lines';
				MISSING_ITEM_POREF.description = 'Line type: PO can be associated with only PO matched invoice lines';   
				MISSING_ITEM_POREF.typeName = 'Exception';
			}
			return MISSING_ITEM_POREF;
		}	
	}
	
	public static TaskType MISSING_POLINE {
		get {
			if(MISSING_POLINE == null) {
				MISSING_POLINE = new TaskType();
				MISSING_POLINE.code = 'SI-POL000031';
				MISSING_POLINE.label = 'Please enter a Purchase Order Line!';
				MISSING_POLINE.description = 'Please enter a Purchase Order Line!';   
				MISSING_POLINE.typeName = 'Exception';
			}
			return MISSING_POLINE;
		}	
	}
	
	public static TaskType NEGATIVE_LINE_QTY {
		get {
			if(NEGATIVE_LINE_QTY == null) {
				NEGATIVE_LINE_QTY = new TaskType();
				NEGATIVE_LINE_QTY.code = 'SI-NEG00002';
				NEGATIVE_LINE_QTY.label = 'Please enter a positive quantity to invoice!';
				NEGATIVE_LINE_QTY.description = 'Please enter a positive quantity to invoice!';
				NEGATIVE_LINE_QTY.typeName = 'Exception';
			}
			return NEGATIVE_LINE_QTY;
		}	
	}
	
	public static TaskType NEGATIVE_LINE_PRICE {
		get {
			if(NEGATIVE_LINE_PRICE == null) {
				NEGATIVE_LINE_PRICE = new TaskType();
				NEGATIVE_LINE_PRICE.code = 'SI-NEG00003';
				NEGATIVE_LINE_PRICE.label = 'Please enter a positive unit price!';
				NEGATIVE_LINE_PRICE.description = 'Please enter a positive unit price!';
				NEGATIVE_LINE_PRICE.typeName = 'Exception';
			}
			return NEGATIVE_LINE_PRICE;
		}	
	}
	
	public static TaskType INVALID_ITEM {
		get {
			if(INVALID_ITEM == null) {
				INVALID_ITEM = new TaskType();
				INVALID_ITEM.code = 'SI-INV00001';
				INVALID_ITEM.label = 'The item is not valid for this line!';
				INVALID_ITEM.description = 'The item is not valid for this line!';
				INVALID_ITEM.typeName = 'Exception';
			}
			return INVALID_ITEM;
		}	
	}
	
	public static TaskType PO_MISMATCH {
		get {
			if(PO_MISMATCH == null) {
				PO_MISMATCH = new TaskType();
				PO_MISMATCH.code = 'SI-POMIS00001';
				PO_MISMATCH.label = 'The purchase order of the purchase order line for this line does not match the purchase order on the invoice!';
				PO_MISMATCH.description = 'The purchase order of the purchase order line for this line does not match the purchase order on the invoice!';
				PO_MISMATCH.typeName = 'Exception';
			}
			return PO_MISMATCH;
		}	
	}
	
	
	public static TaskType TO_LOTMISMATCH {
		get {
			if(TO_LOTMISMATCH == null) {
				TO_LOTMISMATCH = new TaskType();
				TO_LOTMISMATCH.code = 'TO-LOTMI900001';
				TO_LOTMISMATCH.label = 'LOT mismatch while receiving the order line';
				TO_LOTMISMATCH.description = 'LOT mismatch while receiving the order line';
				TO_LOTMISMATCH.typeName = 'Warning';
				TO_LOTMISMATCH.countFieldAPIName = 'Exceptions_Count__c';
			}
			return TO_LOTMISMATCH;
		}	
	}
	
	
	public static TaskType TO_QTYEXCEEDED {
		get {
			if(TO_QTYEXCEEDED == null) {
				TO_QTYEXCEEDED = new TaskType();
				TO_QTYEXCEEDED.code = 'TO-QTYEX900001';
				TO_QTYEXCEEDED.label = 'Quantity received is more than the shipped quantity';
				TO_QTYEXCEEDED.description = 'Quantity received is more than the shipped quantity';
				TO_QTYEXCEEDED.typeName = 'Warning';
				TO_QTYEXCEEDED.countFieldAPIName = 'Exceptions_Count__c';
			}
			return TO_QTYEXCEEDED;
		}	
	}
	
	
	public static TaskType INVOICE_MISMATCH {
		get {
			if(INVOICE_MISMATCH == null) {
				INVOICE_MISMATCH = new TaskType();
				INVOICE_MISMATCH.code = 'SI-INVMIS00001';
				INVOICE_MISMATCH.label = 'The invoice of the invoice line for this line does not match the invoice on the invoice!';
				INVOICE_MISMATCH.description = 'The invoice of the invoice line for this line does not match the invoice on the invoice!';
				INVOICE_MISMATCH.typeName = 'Exception';
			}
			return INVOICE_MISMATCH;
		}	
	}
	
	public static TaskType EXCEEDING_CREDIT_MEMO_AMT {
		get {
			if(EXCEEDING_CREDIT_MEMO_AMT == null) {
				EXCEEDING_CREDIT_MEMO_AMT = new TaskType();
				EXCEEDING_CREDIT_MEMO_AMT.code = 'SI-EXCM00001';
				EXCEEDING_CREDIT_MEMO_AMT.label = 'The total Credit Memo Amount for this line results in exceeding the associated total invoice line amount across all supplier credit memos!';
				EXCEEDING_CREDIT_MEMO_AMT.description = 'The total Credit Memo Amount for this line results in exceeding the associated total invoice line amount across all supplier credit memos!';
				EXCEEDING_CREDIT_MEMO_AMT.typeName = 'Exception';
			}
			return EXCEEDING_CREDIT_MEMO_AMT;
		}	
	}
	
	public static TaskType SI_MISSING_SEGMENT {
		get {
			if(SI_MISSING_SEGMENT == null) {
				SI_MISSING_SEGMENT = new TaskType();
				SI_MISSING_SEGMENT.code = 'SI-SEG00001';
				SI_MISSING_SEGMENT.label = 'Missing invoice line reference or segments!';
				SI_MISSING_SEGMENT.description = 'Missing invoice line reference or segments!';
				SI_MISSING_SEGMENT.typeName = 'Exception';
			}
			return SI_MISSING_SEGMENT;
		}	
	}
	
	public static TaskType SI_INVOICE_QUANTITY {
		get {
			if(SI_INVOICE_QUANTITY == null) {
				SI_INVOICE_QUANTITY = new TaskType();
				SI_INVOICE_QUANTITY.code = 'SI-INVQTY000001';
				SI_INVOICE_QUANTITY.label = 'You cannot invoice a quantity more than what you have received!';
				SI_INVOICE_QUANTITY.description = 'You cannot invoice a quantity more than what you have received!';
				SI_INVOICE_QUANTITY.typeName = 'Exception';
				SI_INVOICE_QUANTITY.ProhibitOverride = true;
			}
			return SI_INVOICE_QUANTITY;
		}	
	}
	
	public static TaskType SI_INVOICED_QTY_MORE_THAN_PURCHASED {// 2-way matching
		get {
			if(SI_INVOICED_QTY_MORE_THAN_PURCHASED == null) {
				SI_INVOICED_QTY_MORE_THAN_PURCHASED = new TaskType();
				SI_INVOICED_QTY_MORE_THAN_PURCHASED.code = 'SI-INVQTY000002';
				SI_INVOICED_QTY_MORE_THAN_PURCHASED.label = 'You cannot invoice a quantity more than what you have purchased!';
				SI_INVOICED_QTY_MORE_THAN_PURCHASED.description = 'You cannot invoice a quantity more than what you have purchased!';
				SI_INVOICED_QTY_MORE_THAN_PURCHASED.typeName = 'Exception';
			}
			return SI_INVOICED_QTY_MORE_THAN_PURCHASED;
		}	
	}
	
	public static TaskType SI_CLOSED_TWO_WAY_POLINE {// 2-way matching
		get {
			if(SI_CLOSED_TWO_WAY_POLINE == null) {
				SI_CLOSED_TWO_WAY_POLINE = new TaskType();
				SI_CLOSED_TWO_WAY_POLINE.code = 'SI-2WAYPOLCLOSED000001';
				SI_CLOSED_TWO_WAY_POLINE.label = 'Two Way Match is not allowed against a closed Purchase Order Line.';
				SI_CLOSED_TWO_WAY_POLINE.description = 'Two Way Match is not allowed against a closed Purchase Order Line.';
				SI_CLOSED_TWO_WAY_POLINE.typeName = 'Exception';
			}
			return SI_CLOSED_TWO_WAY_POLINE;
		}	
	}
	
	public static TaskType SI_PO_NOT_APPROVED {// 2-way matching
		get {
			if(SI_PO_NOT_APPROVED == null) {
				SI_PO_NOT_APPROVED = new TaskType();
				SI_PO_NOT_APPROVED.code = 'SI-PO_NA_0001';
				SI_PO_NOT_APPROVED.label = 'Validation Not Allowed - Unapproved PO';
				SI_PO_NOT_APPROVED.description = 'You can\'t validate invoices against purchase orders that are not approved.';
				SI_PO_NOT_APPROVED.typeName = 'Exception';
				SI_PO_NOT_APPROVED.ProhibitOverride = true;
			}
			return SI_PO_NOT_APPROVED;
		}	
	}
	public static TaskType SI_NEGATIVE_PRICE_QTY {
		get {
			if(SI_NEGATIVE_PRICE_QTY == null) {
				SI_NEGATIVE_PRICE_QTY = new TaskType();
				SI_NEGATIVE_PRICE_QTY.code = 'SI-NEGPRICEQTY000001';
				SI_NEGATIVE_PRICE_QTY.label = 'You cannot have a negative Unit Price and a negative Quantity!';
				SI_NEGATIVE_PRICE_QTY.description = 'You cannot have a negative Unit Price and a negative Quantity!';
				SI_NEGATIVE_PRICE_QTY.typeName = 'Exception';
			}
			return SI_NEGATIVE_PRICE_QTY;
		}	
	}

	//PTP-347 Segment validation on Save
	public static TaskType SI_MISSING_SEGMENT_FRGHTMISC {
		get {
			if(SI_MISSING_SEGMENT_FRGHTMISC == null) {
				SI_MISSING_SEGMENT_FRGHTMISC = new TaskType();
				SI_MISSING_SEGMENT_FRGHTMISC.code = 'SI-SEGMENT001';
				SI_MISSING_SEGMENT_FRGHTMISC.label = 'Accounting Segments are required on invoice lines for freight or miscellaneous items, and on those lines without items.';
				SI_MISSING_SEGMENT_FRGHTMISC.description = 'Accounting Segments are required on invoice lines for freight or miscellaneous items, and on those lines without items.';
				SI_MISSING_SEGMENT_FRGHTMISC.typeName = 'Exception';
				SI_MISSING_SEGMENT_FRGHTMISC.ProhibitOverride = true;//KNDY-9357
			}
			return SI_MISSING_SEGMENT_FRGHTMISC;
		}	
	}
	//PTP-372 Add Line Type to Supplier Invoice UI
	public static TaskType SI_INCORRECTITEM_FRGHTMISC {
		get {
			if(SI_INCORRECTITEM_FRGHTMISC == null) {
				SI_INCORRECTITEM_FRGHTMISC = new TaskType();
				SI_INCORRECTITEM_FRGHTMISC.code = 'SI-INCITEMFRGHTMISC001';
				SI_INCORRECTITEM_FRGHTMISC.label = 'Item Class Type should be Freight/Miscellaneous for Freight/Miscellanceous Invoice Lines!';
				SI_INCORRECTITEM_FRGHTMISC.description = 'Item Class Type should be Freight/Miscellaneous for Freight/Miscellanceous Invoice Lines!';
				SI_INCORRECTITEM_FRGHTMISC.typeName = 'Exception';
			}
			return SI_INCORRECTITEM_FRGHTMISC;
		}	
	}
		
	public static TaskType CM_INVOICE_QUANTITY {
		get {
			if(CM_INVOICE_QUANTITY == null) {
				CM_INVOICE_QUANTITY = new TaskType();
				CM_INVOICE_QUANTITY.code = 'SI-CMQTY000001';
				CM_INVOICE_QUANTITY.label = 'You cannot credit more than the order quantity on the purchase order line!';
				CM_INVOICE_QUANTITY.description = 'You cannot credit more than the order quantity on the purchase order line!';
				CM_INVOICE_QUANTITY.typeName = 'Exception';
			}
			return CM_INVOICE_QUANTITY;
		}	
	}
	
	public static TaskType CM_QUANTITY_CREDITED {
		get {
			if(CM_QUANTITY_CREDITED == null) {
				CM_QUANTITY_CREDITED = new TaskType();
				CM_QUANTITY_CREDITED.code = 'SI-CMQTY000002';
				CM_QUANTITY_CREDITED.label = 'Quantity Credited is more than the Quantity Returned to Supplier for Credit on the purchase order line!';
				CM_QUANTITY_CREDITED.description = 'Quantity Credited is more than the Quantity Returned to Supplier for Credit on the purchase order line!';
				CM_QUANTITY_CREDITED.typeName = 'Exception';
			}
			return CM_QUANTITY_CREDITED;
		}	
	}
	
	public static TaskType SI_UNIT_PRICE {
		get {
			if(SI_UNIT_PRICE == null) {
				SI_UNIT_PRICE = new TaskType();
				SI_UNIT_PRICE.code = 'SI-PRC000001';
				SI_UNIT_PRICE.label = 'Unit price must match related Purchase Order line unit price!';
				SI_UNIT_PRICE.description = 'Invoice Line unit price must match related Purchase Order line unit price!';
				SI_UNIT_PRICE.typeName = 'Exception';
			}
			return SI_UNIT_PRICE;
		}	
	}
	
	public static TaskType SI_FREIGHT {
		get {
			if(SI_FREIGHT == null) {
				SI_FREIGHT = new TaskType();
				SI_FREIGHT.code = 'SI-FRGHT000001';
				SI_FREIGHT.label = 'Freight line not allowed!';
				SI_FREIGHT.description = 'Freight line not allowed!';
				SI_FREIGHT.typeName = 'Exception';
			}
			return SI_FREIGHT;
		}	
	}
	
	public static TaskType SI_PAYMENT_TERMS {
		get {
			if(SI_PAYMENT_TERMS == null) {
				SI_PAYMENT_TERMS = new TaskType();
				SI_PAYMENT_TERMS.code = 'SI-TERMS000001';
				SI_PAYMENT_TERMS.label = 'Supplier Invoice Payment Terms must match Payment Terms on Purchase Order!';
				SI_PAYMENT_TERMS.description = 'Supplier Invoice Payment Terms must match Payment Terms on Purchase Order!';
				SI_PAYMENT_TERMS.typeName = 'Exception';
			}
			return SI_PAYMENT_TERMS;
		}	
	}
	
	public static TaskType SI_QTY_OVER_TOLERANCE {
		get {
			if(SI_QTY_OVER_TOLERANCE == null) {
				SI_QTY_OVER_TOLERANCE = new TaskType();
				SI_QTY_OVER_TOLERANCE.code = 'SI-QTYOVER000001';
				SI_QTY_OVER_TOLERANCE.label = 'Invoiced Quantity has exceeded the Purchase Order Quantity Tolerance Over %';
				SI_QTY_OVER_TOLERANCE.description = 'Invoiced Quantity has exceeded the Purchase Order Quantity Tolerance Over %';
				SI_QTY_OVER_TOLERANCE.typeName = 'Exception';
			}
			return SI_QTY_OVER_TOLERANCE;
		}	
	}
	
	/* public static TaskType SI_QTY_UNDER_TOLERANCE {
		get {
			if(SI_QTY_UNDER_TOLERANCE == null) {
				SI_QTY_UNDER_TOLERANCE = new TaskType();
				SI_QTY_UNDER_TOLERANCE.code = 'SI-QTYUNDER000001';
				SI_QTY_UNDER_TOLERANCE.label = 'Invoiced Quantity has exceeded the Purchase Order Quantity Tolerance Under %';
				SI_QTY_UNDER_TOLERANCE.description = 'Invoiced Quantity has exceeded the Purchase Order Quantity Tolerance Under %';
				SI_QTY_UNDER_TOLERANCE.typeName = 'Exception';
			}
			return SI_QTY_UNDER_TOLERANCE;
		}	
	} */
	
	public static TaskType SI_PRICE_OVER_TOLERANCE {
		get {
			if(SI_PRICE_OVER_TOLERANCE == null) {
				SI_PRICE_OVER_TOLERANCE = new TaskType();
				SI_PRICE_OVER_TOLERANCE.code = 'SI-PRICEOVER000001';
				SI_PRICE_OVER_TOLERANCE.label = 'Invoiced Unit Price has exceeded the Purchase Order Unit Price Tolerance Over %';
				SI_PRICE_OVER_TOLERANCE.description = 'Invoiced Unit Price has exceeded the Purchase Order Unit Price Tolerance Over %';
				SI_PRICE_OVER_TOLERANCE.typeName = 'Exception';
			}
			return SI_PRICE_OVER_TOLERANCE;
		}	
	}
	
	/* public static TaskType SI_PRICE_UNDER_TOLERANCE {
		get {
			if(SI_PRICE_UNDER_TOLERANCE == null) {
				SI_PRICE_UNDER_TOLERANCE = new TaskType();
				SI_PRICE_UNDER_TOLERANCE.code = 'SI-PRICEUNDER000001';
				SI_PRICE_UNDER_TOLERANCE.label = 'Invoiced Unit Price has exceeded the Purchase Order Unit Price Tolerance Under %';
				SI_PRICE_UNDER_TOLERANCE.description = 'Invoiced Unit Price  has exceeded the Purchase Order Unit Price Tolerance Under %';
				SI_PRICE_UNDER_TOLERANCE.typeName = 'Exception';
			}
			return SI_PRICE_UNDER_TOLERANCE;
		}	
	} */

    public static TaskType SI_AMOUNT_ORDER_OVER_TOLERANCE {
        get {
            if(SI_AMOUNT_ORDER_OVER_TOLERANCE == null) {
                SI_AMOUNT_ORDER_OVER_TOLERANCE = new TaskType();
                SI_AMOUNT_ORDER_OVER_TOLERANCE.code = 'SI-AMOUNTOVER000002';
                SI_AMOUNT_ORDER_OVER_TOLERANCE.label = 'Invoiced Amount has exceeded the Purchase Order Amount Tolerance';
                SI_AMOUNT_ORDER_OVER_TOLERANCE.description = 'Invoiced Amount has exceeded the Purchase Order Amount Tolerance';
                SI_AMOUNT_ORDER_OVER_TOLERANCE.typeName = 'Exception';
            }
            return SI_AMOUNT_ORDER_OVER_TOLERANCE;
        }   
    }
	
	public static TaskType SI_AMOUNT_OVER_TOLERANCE {
		get {
			if(SI_AMOUNT_OVER_TOLERANCE == null) {
				SI_AMOUNT_OVER_TOLERANCE = new TaskType();
				SI_AMOUNT_OVER_TOLERANCE.code = 'SI-AMOUNTOVER000001';
				SI_AMOUNT_OVER_TOLERANCE.label = 'Invoiced Amount has exceeded the Receipt Amount plus Tolerance';
				SI_AMOUNT_OVER_TOLERANCE.description = 'Invoiced Amount has exceeded the Receipt Amount plus Tolerance';
				SI_AMOUNT_OVER_TOLERANCE.typeName = 'Exception';
				SI_AMOUNT_OVER_TOLERANCE.ProhibitOverride = true;
			}
			return SI_AMOUNT_OVER_TOLERANCE;
		}	
	}
	
	// Customer Receipt and Lines 
	public static TaskType CR_BALANCE {
	    get{
	    	if(CR_BALANCE == null) {
		        CR_BALANCE = new TaskType();
		        CR_BALANCE.code = 'CR-BAL000001';
		        CR_BALANCE.label = 'Customer Receipt out of balance';
		        CR_BALANCE.description = 'The sum of the payment amount on the Customer Receipt Lines must equal the amount received on the Customer Receipt';
		        CR_BALANCE.typeName = 'Exception';
	    	}
	        return CR_BALANCE;
	    }
	}
	
	public static TaskType CRL_MISSING_INVOICE {
	    get{
	    	if(CRL_MISSING_INVOICE == null) {
		        CRL_MISSING_INVOICE = new TaskType();
		        CRL_MISSING_INVOICE.code = 'CRL-INVOICE000001';
		        CRL_MISSING_INVOICE.label = 'Customer Receipt Line missing Customer Invoice relationship';
		        CRL_MISSING_INVOICE.description = 'A payment, invoice deduction, writeoff, or discount must have a relationship to a Customer Invoice';
		        CRL_MISSING_INVOICE.typeName = 'Exception';
		        CRL_MISSING_INVOICE.ProhibitOverride = true;	
	    	}
	        return CRL_MISSING_INVOICE;
	    }
	}
	
	public static TaskType CRL_MISSING_CREDIT {
	    get{
	    	if(CRL_MISSING_CREDIT == null) {
		        CRL_MISSING_CREDIT = new TaskType();
		        CRL_MISSING_CREDIT.code = 'CRL-CREDIT000001';
		        CRL_MISSING_CREDIT.label = 'Customer Receipt Line missing Credit Memo relationship';
		        CRL_MISSING_CREDIT.description = 'An applied credit must have a relationship to a Credit Memo';
		        CRL_MISSING_CREDIT.typeName = 'Exception';
		        CRL_MISSING_CREDIT.ProhibitOverride = true;
	    	}
	        return CRL_MISSING_CREDIT;
	    }
	}
    
    public static TaskType CRL_MISSING_TYPE {
	    get{
	    	if(CRL_MISSING_TYPE == null) {
		        CRL_MISSING_TYPE = new TaskType();
		        CRL_MISSING_TYPE.code = 'CRL-TYPE000001';
		        CRL_MISSING_TYPE.label = 'Customer Receipt Line missing Type';
		        CRL_MISSING_TYPE.description = 'A Customer Receipt Line must have a type';
		        CRL_MISSING_TYPE.typeName = 'Exception';
		        CRL_MISSING_TYPE.ProhibitOverride = true;
	    	}
	        return CRL_MISSING_TYPE;
	    }
	}
	
	public static TaskType AEL_MISSING_COMPANY {
	    get{
	        AEL_MISSING_COMPANY = new TaskType();
	        AEL_MISSING_COMPANY.code = 'AEL-MCMPY000001';
	        AEL_MISSING_COMPANY.label = 'Missing Company';
	        AEL_MISSING_COMPANY.description = 'The Company is missing or unavailable for this Accounting Entry Line';
	        AEL_MISSING_COMPANY.typeName = 'Exception';
	        AEL_MISSING_COMPANY.ProhibitOverride= true;
	        return AEL_MISSING_COMPANY;
	    }
	}
	
	public static TaskType AEL_MISSING_GL_Account {
	    get{
	        AEL_MISSING_GL_Account = new TaskType();
	        AEL_MISSING_GL_Account.code = 'AEL-MGLA000001';
	        AEL_MISSING_GL_Account.label = 'Missing GL Account';
	        AEL_MISSING_GL_Account.description = 'The GL Account is missing or unavailable for this Accounting Entry Line';
	        AEL_MISSING_GL_Account.typeName = 'Exception';
	        AEL_MISSING_GL_Account.ProhibitOverride= true;
	        return AEL_MISSING_GL_Account;
	    }
	}
	
	public static TaskType AEL_MISSING_TRANSACTION_CURRENCY {
	    get{
	        AEL_MISSING_TRANSACTION_CURRENCY = new TaskType();
	        AEL_MISSING_TRANSACTION_CURRENCY.code = 'AEL-MTC000001';
	        AEL_MISSING_TRANSACTION_CURRENCY.label = 'Missing Transaction Currency';
	        AEL_MISSING_TRANSACTION_CURRENCY.description = 'The Transaction Currency is missing or unavailable for this Accounting Entry Line';
	        AEL_MISSING_TRANSACTION_CURRENCY.typeName = 'Exception';
	        AEL_MISSING_TRANSACTION_CURRENCY.ProhibitOverride= true;
	        return AEL_MISSING_TRANSACTION_CURRENCY;
	    }
	}
	
	public static TaskType AEL_MISSING_TRANSACTION_AMOUNT_CR {
	    get{
	        AEL_MISSING_TRANSACTION_AMOUNT_CR = new TaskType();
	        AEL_MISSING_TRANSACTION_AMOUNT_CR.code = 'AEL-MTACR000001';
	        AEL_MISSING_TRANSACTION_AMOUNT_CR.label = 'Missing Transaction Currency CR';
	        AEL_MISSING_TRANSACTION_AMOUNT_CR.description = 'The Transaction Amount - CR is missing or unavailable for this Accounting Entry Line';
	        AEL_MISSING_TRANSACTION_AMOUNT_CR.typeName = 'Exception';
	        AEL_MISSING_TRANSACTION_AMOUNT_CR.ProhibitOverride= true;
	        return AEL_MISSING_TRANSACTION_AMOUNT_CR;
	    }
	}
	
	public static TaskType AEL_MISSING_TRANSACTION_AMOUNT_DR {
	    get{
	        AEL_MISSING_TRANSACTION_AMOUNT_DR = new TaskType();
	        AEL_MISSING_TRANSACTION_AMOUNT_DR.code = 'AEL-MTADR000001';
	        AEL_MISSING_TRANSACTION_AMOUNT_DR.label = 'Missing Transaction Currency DR';
	        AEL_MISSING_TRANSACTION_AMOUNT_DR.description = 'The Transaction Amount - DR is missing or unavailable for this Accounting Entry Line';
	        AEL_MISSING_TRANSACTION_AMOUNT_DR.typeName = 'Exception';
	        AEL_MISSING_TRANSACTION_AMOUNT_DR.ProhibitOverride =true;
	        return AEL_MISSING_TRANSACTION_AMOUNT_DR;
	    }
	}
	
	public static TaskType AEL_MISSING_ACCOUNTING_RULE {
	    get{
	        AEL_MISSING_ACCOUNTING_RULE = new TaskType();
	        AEL_MISSING_ACCOUNTING_RULE.code = 'AEL-ATR00000001';
	        AEL_MISSING_ACCOUNTING_RULE.label = 'Missing Accounting Rule';
	        AEL_MISSING_ACCOUNTING_RULE.description = 'The Accounting Rule is missing for this Accounting Entry Line';
	        AEL_MISSING_ACCOUNTING_RULE.typeName = 'Exception';
	        AEL_MISSING_ACCOUNTING_RULE.ProhibitOverride =true;
	        return AEL_MISSING_ACCOUNTING_RULE;
	    }
	}
	
	public static TaskType AEL_MISSING_ITEM_COST {
	    get{
	        AEL_MISSING_ITEM_COST = new TaskType();
	        AEL_MISSING_ITEM_COST.code = 'AEL-MIC000001';
	        AEL_MISSING_ITEM_COST.label = 'Missing Item Cost';
	        AEL_MISSING_ITEM_COST.description = 'The item cost is missing for item on source document line for this Accounting Entry Line';
	        AEL_MISSING_ITEM_COST.typeName = 'Exception';
	        AEL_MISSING_ITEM_COST.ProhibitOverride = true;
	        return AEL_MISSING_ITEM_COST;
	    }
	}
	
	public static TaskType AEL_EXCHANGE_SERVICE_ERROR {
	    get{
	        AEL_EXCHANGE_SERVICE_ERROR = new TaskType();
	        AEL_EXCHANGE_SERVICE_ERROR.code = 'AEL-EXC000001';
	        AEL_EXCHANGE_SERVICE_ERROR.label = 'Exchange Service Error';
	        AEL_EXCHANGE_SERVICE_ERROR.description = 'Exchange Service Error for this Accounting Entry Line';
	        AEL_EXCHANGE_SERVICE_ERROR.typeName = 'Exception';
	        AEL_EXCHANGE_SERVICE_ERROR.ProhibitOverride = true;
	        return AEL_EXCHANGE_SERVICE_ERROR;
	    }
	}
	
	
	public static TaskType AEL_MISSING_FUNCTIONAL_CONVERSION_RATE {
		get{
	        AEL_MISSING_FUNCTIONAL_CONVERSION_RATE = new TaskType();
	        AEL_MISSING_FUNCTIONAL_CONVERSION_RATE.code = 'AEL-MFCR000001';
	        AEL_MISSING_FUNCTIONAL_CONVERSION_RATE.label = 'Missing Functional Conversion Rate';
	        AEL_MISSING_FUNCTIONAL_CONVERSION_RATE.description = 'The functional conversion rate is missing or for these currencies on the transaction date.';
	        AEL_MISSING_FUNCTIONAL_CONVERSION_RATE.typeName = 'Exception';
	        AEL_MISSING_FUNCTIONAL_CONVERSION_RATE.ProhibitOverride = true;
	        return AEL_MISSING_FUNCTIONAL_CONVERSION_RATE;
	    }
	}
	
	public static TaskType AE_SOURCE_DOC_EXCEPTION {
	    get{
	        AE_SOURCE_DOC_EXCEPTION = new TaskType();
	        AE_SOURCE_DOC_EXCEPTION.code = 'AE-SDEXC000001';
	        AE_SOURCE_DOC_EXCEPTION.label = 'Source Document Exception';
	        AE_SOURCE_DOC_EXCEPTION.description = 'The Source Document has an exception';
	        AE_SOURCE_DOC_EXCEPTION.typeName = 'Exception';
	        AE_SOURCE_DOC_EXCEPTION.ProhibitOverride = true;
	        return AE_SOURCE_DOC_EXCEPTION;
	    }
	}
	
	public static TaskType AE_MISSING_COMPANY {
	    get{
	        AE_MISSING_COMPANY = new TaskType();
	        AE_MISSING_COMPANY.code = 'AE-MCMPY000001';
	        AE_MISSING_COMPANY.label = 'Missing Company';
	        AE_MISSING_COMPANY.description = 'The Company is missing or unavailable for this Accounting Entry';
	        AE_MISSING_COMPANY.typeName = 'Exception';
	        AE_MISSING_COMPANY.ProhibitOverride = true;
	        return AE_MISSING_COMPANY;
	    }
	}
	
	//----------- KNDY-10121---------------   
	 
	public static TaskType AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED {
	    get{
	        AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED          		= new TaskType();
	        AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED.code    	    = 'AE-CDU000002';
	        AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED.label    		= 'Transactional Credit Debit Unmatched';
	        AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED.description 	= 'Total Transactional Debits and Credits are out of balance';
	        AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED.typeName 		= 'Exception';
	        AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED.ProhibitOverride= true;
	        return AE_TRANSACTIONAL_CREDIT_DEBIT_UNMATCHED;
	    }
	}
	public static TaskType AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED  {
	    get{
	        AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED          			= new TaskType();
	        AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED.code    	   	    = 'AE-CDU000003';
	        AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED.label    			= 'Functional Credit Debit Unmatched';
	        AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED.description 		= 'Total Functional Debits and Credits are out of balance';
	        AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED.typeName 			= 'Exception';
	        AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED.ProhibitOverride= true;
	        return AE_FUNCTIONAL_CREDIT_DEBIT_UNMATCHED ;
	    }
	}
	 
	
	public static TaskType AE_MISSING_TRANSACTION_TYPE {
	    get{
	        AE_MISSING_TRANSACTION_TYPE = new TaskType();
	        AE_MISSING_TRANSACTION_TYPE.code = 'AE-MTT000001';
	        AE_MISSING_TRANSACTION_TYPE.label = 'Missing Transaction Type';
	        AE_MISSING_TRANSACTION_TYPE.description = 'The Transaction Type is missing or unavailable for this Accounting Entry';
	        AE_MISSING_TRANSACTION_TYPE.typeName = 'Exception';
	        AE_MISSING_TRANSACTION_TYPE.ProhibitOverride= true;
	        return AE_MISSING_TRANSACTION_TYPE;
	    }
	}
	
	public static TaskType AE_MISSING_TRANSACTION_DATE {
	    get{
	        AE_MISSING_TRANSACTION_DATE = new TaskType();
	        AE_MISSING_TRANSACTION_DATE.code = 'AE-MTD000001';
	        AE_MISSING_TRANSACTION_DATE.label = 'Missing Transaction Date';
	        AE_MISSING_TRANSACTION_DATE.description = 'The Transaction Date is missing or unavailable for this Accounting Entry';
	        AE_MISSING_TRANSACTION_DATE.typeName = 'Exception';
	        AE_MISSING_TRANSACTION_DATE.ProhibitOverride= true;
	        return AE_MISSING_TRANSACTION_DATE;
	    }
	}
	
	public static TaskType AE_MISSING_TRANSACTION_CURRENCY {
	    get{
	        AE_MISSING_TRANSACTION_CURRENCY = new TaskType();
	        AE_MISSING_TRANSACTION_CURRENCY.code = 'AE-MTC000001';
	        AE_MISSING_TRANSACTION_CURRENCY.label = 'Missing Transaction Currency';
	        AE_MISSING_TRANSACTION_CURRENCY.description = 'The Transaction Currency is missing or unavailable for this Accounting Entry';
	        AE_MISSING_TRANSACTION_CURRENCY.typeName = 'Exception';
	        AE_MISSING_TRANSACTION_CURRENCY.ProhibitOverride= true;
	        return AE_MISSING_TRANSACTION_CURRENCY;
	    }
	}
	
	public static TaskType AE_MISSING_POSTING_DATE {
	    get{
	        AE_MISSING_POSTING_DATE = new TaskType();
	        AE_MISSING_POSTING_DATE.code = 'AE-MPD000001';
	        AE_MISSING_POSTING_DATE.label = 'Missing Posting Date';
	        AE_MISSING_POSTING_DATE.description = 'The Posting Date is missing or unavailable for this Accounting Entry';
	        AE_MISSING_POSTING_DATE.typeName = 'Exception';
	        return AE_MISSING_POSTING_DATE;
	    } 
	}
	
	public static TaskType AE_MISSING_GL_DATE_TIME {
	    get{
	        AE_MISSING_GL_DATE_TIME = new TaskType();
	        AE_MISSING_GL_DATE_TIME.code = 'AE-MGLDT000001';
	        AE_MISSING_GL_DATE_TIME.label = 'Missing GL Date Time';
	        AE_MISSING_GL_DATE_TIME.description = 'The GL Date Time is missing or unavailable for this Accounting Entry';
	        AE_MISSING_GL_DATE_TIME.typeName = 'Exception';
	        AE_MISSING_GL_DATE_TIME.ProhibitOverride = true;
	        return AE_MISSING_GL_DATE_TIME;
	    }
	}
	
	public static TaskType AE_MISSING_PERIOD {
	    get{
	        AE_MISSING_PERIOD = new TaskType();
	        AE_MISSING_PERIOD.code = 'AE-PRD000001';
	        AE_MISSING_PERIOD.label = 'Missing Period';
	        AE_MISSING_PERIOD.description = 'The Period is missing or unavailable for this Accounting Entry';
	        AE_MISSING_PERIOD.typeName = 'Exception';
	        AE_MISSING_PERIOD.ProhibitOverride = true;
	        return AE_MISSING_PERIOD;
	    }
	}
	
	public static TaskType AE_MISSING_SOURCEDOCUMENT {
	    get{
	    	AE_MISSING_SOURCEDOCUMENT = new TaskType();
	        AE_MISSING_SOURCEDOCUMENT.code = 'AE-MSD000001';
	        AE_MISSING_SOURCEDOCUMENT.label = 'Missing Source Document';
	        AE_MISSING_SOURCEDOCUMENT.description = 'The Source Document value is missing or unavailable for this Accounting Entry';
	        AE_MISSING_SOURCEDOCUMENT.typeName = 'Exception';
	        AE_MISSING_SOURCEDOCUMENT.ProhibitOverride = true;
	        return AE_MISSING_SOURCEDOCUMENT;
	    }
	}
	// Journal Entry Lines
	public static TaskType JEL_MISSING_COMPANY {
	    get{
	        JEL_MISSING_COMPANY = new TaskType();
	        JEL_MISSING_COMPANY.code = 'JEL-MCMPY000001';
	        JEL_MISSING_COMPANY.label = 'Missing Company';
	        JEL_MISSING_COMPANY.description = 'The Company is missing or unavailable for this Journal Entry Line';
	        JEL_MISSING_COMPANY.typeName = 'Exception';
	        return JEL_MISSING_COMPANY;
	    }
	}
	
	public static TaskType JEL_MISSING_GL_Account {
	    get{
	        JEL_MISSING_GL_Account = new TaskType();
	        JEL_MISSING_GL_Account.code = 'JEL-MGLA000001';
	        JEL_MISSING_GL_Account.label = 'Missing GL Account';
	        JEL_MISSING_GL_Account.description = 'The GL Account is missing or unavailable for this Journal Entry Line';
	        JEL_MISSING_GL_Account.typeName = 'Exception';
	        return JEL_MISSING_GL_Account;
	    }
	}
	
	public static TaskType JEL_MISSING_TRANSACTION_CURRENCY {
	    get{
	        JEL_MISSING_TRANSACTION_CURRENCY = new TaskType();
	        JEL_MISSING_TRANSACTION_CURRENCY.code = 'JEL-MTC000001';
	        JEL_MISSING_TRANSACTION_CURRENCY.label = 'Missing Transaction Currency';
	        JEL_MISSING_TRANSACTION_CURRENCY.description = 'The Transaction Currency is missing or unavailable for this Journal Entry Line';
	        JEL_MISSING_TRANSACTION_CURRENCY.typeName = 'Exception';
	        return JEL_MISSING_TRANSACTION_CURRENCY;
	    }
	}
	
	public static TaskType JEL_MISSING_TRANSACTION_AMOUNT_CR {
	    get{
	        JEL_MISSING_TRANSACTION_AMOUNT_CR = new TaskType();
	        JEL_MISSING_TRANSACTION_AMOUNT_CR.code = 'JEL-MTACR000001';
	        JEL_MISSING_TRANSACTION_AMOUNT_CR.label = 'Missing Transaction Currency CR';
	        JEL_MISSING_TRANSACTION_AMOUNT_CR.description = 'The Transaction Amount - CR is missing or unavailable for this Journal Entry Line';
	        JEL_MISSING_TRANSACTION_AMOUNT_CR.typeName = 'Exception';
	        return JEL_MISSING_TRANSACTION_AMOUNT_CR;
	    }
	}
	
	public static TaskType JEL_MISSING_TRANSACTION_AMOUNT_DR {
	    get{
	        JEL_MISSING_TRANSACTION_AMOUNT_DR = new TaskType();
	        JEL_MISSING_TRANSACTION_AMOUNT_DR.code = 'JEL-MTADR000001';
	        JEL_MISSING_TRANSACTION_AMOUNT_DR.label = 'Missing Transaction Currency DR';
	        JEL_MISSING_TRANSACTION_AMOUNT_DR.description = 'The Transaction Amount - DR is missing or unavailable for this Journal Entry Line';
	        JEL_MISSING_TRANSACTION_AMOUNT_DR.typeName = 'Exception';
	        return JEL_MISSING_TRANSACTION_AMOUNT_DR;
	    }
	}
	
	//Journal Entry
	public static TaskType JE_SOURCE_DOC_EXCEPTION {
	    get{
	        JE_SOURCE_DOC_EXCEPTION = new TaskType();
	        JE_SOURCE_DOC_EXCEPTION.code = 'JE-SDEXC000001';
	        JE_SOURCE_DOC_EXCEPTION.label = 'Source Document Exception';
	        JE_SOURCE_DOC_EXCEPTION.description = 'The Source Document has an exception';
	        JE_SOURCE_DOC_EXCEPTION.typeName = 'Exception';
	        return JE_SOURCE_DOC_EXCEPTION;
	    }
	}
	
	public static TaskType JE_MISSING_COMPANY {
	    get{
	        JE_MISSING_COMPANY = new TaskType();
	        JE_MISSING_COMPANY.code = 'JE-MCMPY000001';
	        JE_MISSING_COMPANY.label = 'Missing Company';
	        JE_MISSING_COMPANY.description = 'The Company is missing or unavailable for this Journal Entry';
	        JE_MISSING_COMPANY.typeName = 'Exception';
	        return JE_MISSING_COMPANY;
	    }
	}
	
	public static TaskType JE_CREDIT_DEBIT_UNMATCHED {
	    get{
	        JE_CREDIT_DEBIT_UNMATCHED = new TaskType();
	        JE_CREDIT_DEBIT_UNMATCHED.code = 'JE-CDU000001';
	        JE_CREDIT_DEBIT_UNMATCHED.label = 'Credit Debit Unmatched';
	        JE_CREDIT_DEBIT_UNMATCHED.description = 'The credit and debit does not match on this Journal Entry';
	        JE_CREDIT_DEBIT_UNMATCHED.typeName = 'Exception';
	        return JE_CREDIT_DEBIT_UNMATCHED;
	    }
	}

	public static TaskType JE_MISSING_TRANSACTION_DATE {
	    get{
	        JE_MISSING_TRANSACTION_DATE = new TaskType();
	        JE_MISSING_TRANSACTION_DATE.code = 'JE-MTD000001';
	        JE_MISSING_TRANSACTION_DATE.label = 'Missing Transaction Date';
	        JE_MISSING_TRANSACTION_DATE.description = 'The Transaction Date is missing or unavailable for this Journal Entry';
	        JE_MISSING_TRANSACTION_DATE.typeName = 'Exception';
	        return JE_MISSING_TRANSACTION_DATE;
	    }
	}
	
	public static TaskType JE_MISSING_TRANSACTION_CURRENCY {
	    get{
	        JE_MISSING_TRANSACTION_CURRENCY = new TaskType();
	        JE_MISSING_TRANSACTION_CURRENCY.code = 'JE-MTC000001';
	        JE_MISSING_TRANSACTION_CURRENCY.label = 'Missing Transaction Currency';
	        JE_MISSING_TRANSACTION_CURRENCY.description = 'The Transaction Currency is missing or unavailable for this Journal Entry';
	        JE_MISSING_TRANSACTION_CURRENCY.typeName = 'Exception';
	        return JE_MISSING_TRANSACTION_CURRENCY;
	    }
	}

	
	public static TaskType JE_MISSING_SOURCEDOCUMENT {
	    get{
	    	JE_MISSING_SOURCEDOCUMENT = new TaskType();
	        JE_MISSING_SOURCEDOCUMENT.code = 'JE-MSD000001';
	        JE_MISSING_SOURCEDOCUMENT.label = 'Missing Source Document';
	        JE_MISSING_SOURCEDOCUMENT.description = 'The Source Document value is missing or unavailable for this Journal Entry';
	        JE_MISSING_SOURCEDOCUMENT.typeName = 'Exception';
	        return JE_MISSING_SOURCEDOCUMENT;
	    }
	}
	
	public static TaskType SEGMENT_VALIDATION {
	    get{
	    	if(SEGMENT_VALIDATION == null) {
		        SEGMENT_VALIDATION = new TaskType();
		        SEGMENT_VALIDATION.code = 'SEG-VAL000001';
		        SEGMENT_VALIDATION.label = 'Segment Validation Error';
		        SEGMENT_VALIDATION.description = 'This is not a qualified combination of segments';
		        SEGMENT_VALIDATION.typeName = 'Exception';
		        SEGMENT_VALIDATION.ProhibitOverride= true;
	    	}
	        return SEGMENT_VALIDATION;
	    }
	}
	
	public static TaskType NO_MATCHING_TRANSIT_ROUTE_FOUND {
	    get{
	    	if(NO_MATCHING_TRANSIT_ROUTE_FOUND == null) {
		        NO_MATCHING_TRANSIT_ROUTE_FOUND = new TaskType();
		        NO_MATCHING_TRANSIT_ROUTE_FOUND.code = 'SO-TRAN000001';
		        NO_MATCHING_TRANSIT_ROUTE_FOUND.label = 'No matching transit route found. Please check the \'Transit Route\' configuration.';
		        NO_MATCHING_TRANSIT_ROUTE_FOUND.description = 'Could not find a transit route matching with the specified inputs (Facility address, Ship-to address, Means of Transport and Delivery method).';
		        NO_MATCHING_TRANSIT_ROUTE_FOUND.typeName = 'Exception';
	    	}
	        return NO_MATCHING_TRANSIT_ROUTE_FOUND;
	    }
	}
	
	public static TaskType CI_MISSING_BILLTO {
		 get{
	    	if(CI_MISSING_BILLTO == null) {
		        CI_MISSING_BILLTO = new TaskType();
		        CI_MISSING_BILLTO.code = 'CI-BILL000001';
		        CI_MISSING_BILLTO.label = 'Missing Bill To Customer';
		        CI_MISSING_BILLTO.description = 'Missing Bill To Customer';
		        CI_MISSING_BILLTO.typeName = 'Exception';
	    	}
	        return CI_MISSING_BILLTO;
	    }
	}
	
	public static TaskType CI_MISSING_COMPANY {
		 get{
	    	if(CI_MISSING_COMPANY == null) {
		        CI_MISSING_COMPANY = new TaskType();
		        CI_MISSING_COMPANY.code = 'CI-COMP000001';
		        CI_MISSING_COMPANY.label = 'Missing Company';
		        CI_MISSING_COMPANY.description = 'Missing Company';
		        CI_MISSING_COMPANY.typeName = 'Exception';
	    	}
	        return CI_MISSING_COMPANY;
	    }
	}
	
	public static TaskType CRL_DUPLICATE_EARNED_TERMS {
		 get{
	    	if(CRL_DUPLICATE_EARNED_TERMS == null) {
		        CRL_DUPLICATE_EARNED_TERMS = new TaskType();
		        CRL_DUPLICATE_EARNED_TERMS.code = 'CRL-EDT000001';
		        CRL_DUPLICATE_EARNED_TERMS.label = 'Duplicate Earned Term Discount';
		        CRL_DUPLICATE_EARNED_TERMS.description = 'Duplicate Earned Term Discount on ';
		        CRL_DUPLICATE_EARNED_TERMS.typeName = 'Exception';
		        CRL_DUPLICATE_EARNED_TERMS.ProhibitOverride = true;	
	    	}
	        return CRL_DUPLICATE_EARNED_TERMS;
	    }
	}
	
	public static TaskType NEGATIVE_ADDITIONAL_PAYMENTS {
		 get{
	    	if(NEGATIVE_ADDITIONAL_PAYMENTS == null) {
		        NEGATIVE_ADDITIONAL_PAYMENTS = new TaskType();
		        NEGATIVE_ADDITIONAL_PAYMENTS.code = 'CRL-NEGPYMT00001';
		        NEGATIVE_ADDITIONAL_PAYMENTS.label = 'Prepayment/Overpayment receipt lines cannot be negative';
		        NEGATIVE_ADDITIONAL_PAYMENTS.description = 'Prepayment/Overpayment receipt lines cannot be negative';
		        NEGATIVE_ADDITIONAL_PAYMENTS.typeName = 'Exception';
		        NEGATIVE_ADDITIONAL_PAYMENTS.ProhibitOverride = true;	
	    	}
	        return NEGATIVE_ADDITIONAL_PAYMENTS;
	    }
	}
	
	public static TaskType NEGATIVE_CLAIM_PAYMENTS {
		 get{
	    	if(NEGATIVE_CLAIM_PAYMENTS == null) {
		        NEGATIVE_CLAIM_PAYMENTS = new TaskType();
		        NEGATIVE_CLAIM_PAYMENTS.code = 'CRL-NEGCLAIMPYMT00001';
		        NEGATIVE_CLAIM_PAYMENTS.label = 'Claim payment receipt lines cannot be negative';
		        NEGATIVE_CLAIM_PAYMENTS.description = 'Claim payment receipt lines cannot be negative';
		        NEGATIVE_CLAIM_PAYMENTS.typeName = 'Exception';
		        NEGATIVE_CLAIM_PAYMENTS.ProhibitOverride = true;	
	    	}
	        return NEGATIVE_CLAIM_PAYMENTS;
	    }
	}
	
	public static TaskType CRL_ZERO_EMPTY_AMOUNT {
		 get{
	    	if(CRL_ZERO_EMPTY_AMOUNT == null) {
		        CRL_ZERO_EMPTY_AMOUNT = new TaskType();
		        CRL_ZERO_EMPTY_AMOUNT.code = 'CRL-AMT00001';
		        CRL_ZERO_EMPTY_AMOUNT.label = 'The amount field on the receipt line cannot be empty or zero.';
		        CRL_ZERO_EMPTY_AMOUNT.description = 'The amount field on the receipt line cannot be empty or zero.';
		        CRL_ZERO_EMPTY_AMOUNT.typeName = 'Exception';
		        CRL_ZERO_EMPTY_AMOUNT.ProhibitOverride = true;	
	    	}
	        return CRL_ZERO_EMPTY_AMOUNT;
	    }
	}
	
	public static TaskType CRL_PREPAYMENT_WITHOUT_SO {
		 get{
	    	if(CRL_PREPAYMENT_WITHOUT_SO == null) {
		        CRL_PREPAYMENT_WITHOUT_SO = new TaskType();
		        CRL_PREPAYMENT_WITHOUT_SO.code = 'CRL-PPT00001';
		        CRL_PREPAYMENT_WITHOUT_SO.label = 'Prepayment receipt lines must look up to a sales order';
		        CRL_PREPAYMENT_WITHOUT_SO.description = 'Prepayment receipt lines must look up to a sales order';
		        CRL_PREPAYMENT_WITHOUT_SO.typeName = 'Exception';
		        CRL_PREPAYMENT_WITHOUT_SO.ProhibitOverride = true;	
	    	}
	        return CRL_PREPAYMENT_WITHOUT_SO;
	    }
	}

	public static TaskType I_MISSING_TO_COMPANY{
		get{
			If(I_MISSING_TO_COMPANY == null){
				I_MISSING_TO_COMPANY = new TaskType();
				I_MISSING_TO_COMPANY.code = 'I-COMP00001';
				I_MISSING_TO_COMPANY.label = 'The to company is not specified!';
				I_MISSING_TO_COMPANY.description = 'The to company is not specified!';
				I_MISSING_TO_COMPANY.typeName = 'Exception';
		        I_MISSING_TO_COMPANY.ProhibitOverride = true;	
			}
			return I_MISSING_TO_COMPANY;
		}
	}

	public static TaskType I_MISSING_FROM_COMPANY{
		get{
			If(I_MISSING_FROM_COMPANY == null){
				I_MISSING_FROM_COMPANY = new TaskType();
				I_MISSING_FROM_COMPANY.code = 'I-COMP00002';
				I_MISSING_FROM_COMPANY.label = 'The from company is not specified!';
				I_MISSING_FROM_COMPANY.description = 'The from company is not specified!';
				I_MISSING_FROM_COMPANY.typeName = 'Exception';
		        I_MISSING_FROM_COMPANY.ProhibitOverride = true;	
			}
			return I_MISSING_FROM_COMPANY;
		}
	}

	public static TaskType IL_INVALID_AMOUNT{
		get{
			if(IL_INVALID_AMOUNT == null){
				IL_INVALID_AMOUNT = new TaskType();
				IL_INVALID_AMOUNT.code = 'IL-AMT000001';
				IL_INVALID_AMOUNT.label = 'Please enter a positive invoice amount!';
				IL_INVALID_AMOUNT.description = 'Please enter a positive invoice amount!';
				IL_INVALID_AMOUNT.typeName = 'Exception';
		        IL_INVALID_AMOUNT.ProhibitOverride = true;
			}
			return IL_INVALID_AMOUNT;
		}
	}

	public static TaskType IL_Accounting_Default_Required{
		get{
			if(IL_Accounting_Default_Required == null){
				IL_Accounting_Default_Required = new TaskType();
				IL_Accounting_Default_Required.code = 'IL-AD000001';
				IL_Accounting_Default_Required.label = 'Accounting Default is required for this invoice!';
				IL_Accounting_Default_Required.description = 'Accounting Default is required for this invoice!';
				IL_Accounting_Default_Required.typeName = 'Exception';
		        IL_Accounting_Default_Required.ProhibitOverride = true;
			}
			return IL_Accounting_Default_Required;
		}
	}

	public static TaskType IL_Accounting_Default_GLAccount_Required{
		get{
			if(IL_Accounting_Default_GLAccount_Required == null){
				IL_Accounting_Default_GLAccount_Required = new TaskType();
				IL_Accounting_Default_GLAccount_Required.code = 'IL-AD000002';
				IL_Accounting_Default_GLAccount_Required.label = 'GL Account on the Accounting Default is required for this invoice!';
				IL_Accounting_Default_GLAccount_Required.description = 'GL Account on the Accounting Default is required for this invoice!';
				IL_Accounting_Default_GLAccount_Required.typeName = 'Exception';
		        IL_Accounting_Default_GLAccount_Required.ProhibitOverride = true;
			}
			return IL_Accounting_Default_GLAccount_Required;
		}
	}

	public static TaskType IL_Accounting_Default_Company_Required{
		get{
			if(IL_Accounting_Default_Company_Required == null){
				IL_Accounting_Default_Company_Required = new TaskType();
				IL_Accounting_Default_Company_Required.code = 'IL-AD000003';
				IL_Accounting_Default_Company_Required.label = 'Company on the Accounting Default is required for this invoice!';
				IL_Accounting_Default_Company_Required.description = 'Company on the Accounting Default is required for this invoice!';
				IL_Accounting_Default_Company_Required.typeName = 'Exception';
		        IL_Accounting_Default_Company_Required.ProhibitOverride = true;
			}
			return IL_Accounting_Default_Company_Required;
		}
	}

	public static TaskType IL_Accounting_Default_Intercompany_Required{
		get{
			if(IL_Accounting_Default_Intercompany_Required == null){
				IL_Accounting_Default_Intercompany_Required = new TaskType();
				IL_Accounting_Default_Intercompany_Required.code = 'IL-AD000004';
				IL_Accounting_Default_Intercompany_Required.label = 'Intercompany on the Accounting Default is required for this invoice!';
				IL_Accounting_Default_Intercompany_Required.description = 'Intcerompany on the Accounting Default is required for this invoice!';
				IL_Accounting_Default_Intercompany_Required.typeName = 'Exception';
		        IL_Accounting_Default_Intercompany_Required.ProhibitOverride = true;
			}
			return IL_Accounting_Default_Intercompany_Required;
		}
	}

	public static TaskType PML_CHECK_COMPANIES {
		get{
	    	if(PML_CHECK_COMPANIES == null) {
		        PML_CHECK_COMPANIES = new TaskType();
		        PML_CHECK_COMPANIES.code = 'PML-COMP00001';
		        PML_CHECK_COMPANIES.label = 'You may not pay Invoices from Companies not included in this Payment';
		        PML_CHECK_COMPANIES.description = 'You may not pay Invoices from Companies not included in this Payment';
		        PML_CHECK_COMPANIES.typeName = 'Exception';
		        PML_CHECK_COMPANIES.ProhibitOverride = true;	
	    	}
	        return PML_CHECK_COMPANIES;
	    }
	}
	
    public static TaskType SOL_ITEM_SPEC_NOT_REPAIR {
         get {
            if (SOL_ITEM_SPEC_NOT_REPAIR == null) {
                SOL_ITEM_SPEC_NOT_REPAIR = new TaskType();
                SOL_ITEM_SPEC_NOT_REPAIR.code = 'SOL-PLAN00010';
                SOL_ITEM_SPEC_NOT_REPAIR.label = 'Item specification must be of type repair';
                SOL_ITEM_SPEC_NOT_REPAIR.description = 'Item specification must be of type repair';
                SOL_ITEM_SPEC_NOT_REPAIR.typeName = 'Exception';
                SOL_ITEM_SPEC_NOT_REPAIR.ProhibitOverride = false;  
            }
            return SOL_ITEM_SPEC_NOT_REPAIR;
        }
    }
	
	
	/*
	 * WORK ORDER TASKS
	 */
	public static TaskType WO_QTY_CHANGE_INC {
		get {
			if (WO_QTY_CHANGE_INC == null) {
				WO_QTY_CHANGE_INC = new TaskType();
				WO_QTY_CHANGE_INC.code = 'WO-QTY1';
				WO_QTY_CHANGE_INC.label = 'Order quantity increased';
				WO_QTY_CHANGE_INC.description = 'Order quantity increased';
				WO_QTY_CHANGE_INC.typeName = 'Info';
			}
			return WO_QTY_CHANGE_INC;
		}	
	}
	public static TaskType WO_QTY_CHANGE_DEC {
		get {
			if (WO_QTY_CHANGE_DEC == null) {
				WO_QTY_CHANGE_DEC = new TaskType();
				WO_QTY_CHANGE_DEC.code = 'WO-QTY2';
				WO_QTY_CHANGE_DEC.label = 'Order quantity decreased';
				WO_QTY_CHANGE_DEC.description = 'Order quantity decreased';
				WO_QTY_CHANGE_DEC.typeName = 'Info';
			}
			return WO_QTY_CHANGE_DEC;
		}	
	}
	public static TaskType WO_QTY_CHANGE_DEC_EX {
		get {
			if (WO_QTY_CHANGE_DEC_EX == null) {
				WO_QTY_CHANGE_DEC_EX = new TaskType();
				WO_QTY_CHANGE_DEC_EX.code = 'WO-QTY3';
				WO_QTY_CHANGE_DEC_EX.label = 'Unable to decrease order quantity';
				WO_QTY_CHANGE_DEC_EX.description = 'Unable to decrease order quantity';
				WO_QTY_CHANGE_DEC_EX.typeName = 'Info';
			}
			return WO_QTY_CHANGE_DEC_EX;
		}	
	}
	
	public static TaskType WO_COMPLETE_EXCEPTION {
		get {
			if (WO_COMPLETE_EXCEPTION == null) {
				WO_COMPLETE_EXCEPTION = new TaskType();
				WO_COMPLETE_EXCEPTION.code = 'WO-COMP1';
				WO_COMPLETE_EXCEPTION.label = 'Unable to complete work order';
				WO_COMPLETE_EXCEPTION.description = 'An error occcured while completing the work order. Please fix the error and try again:';
				WO_COMPLETE_EXCEPTION.typeName = 'Exception';
			}
			return WO_COMPLETE_EXCEPTION;
		}	
	}
	

    public static TaskType ORDER_RERELEASE_FAIL {
        get {
            if (ORDER_RERELEASE_FAIL == null) {
                ORDER_RERELEASE_FAIL = new TaskType();
                ORDER_RERELEASE_FAIL.code = 'RERELEASE1';
                ORDER_RERELEASE_FAIL.label = 'Unable to auto-rerelease order. Please rerelease manually.';
                ORDER_RERELEASE_FAIL.description = 'Unable to auto-rerelease order. Please rerelease manually.';
                ORDER_RERELEASE_FAIL.typeName = 'Exception';
            }
            return ORDER_RERELEASE_FAIL;
        }   
    }

    public static TaskType UNDO_SHIPMENT_FAIL {
        get {
            if (UNDO_SHIPMENT_FAIL == null) {
                UNDO_SHIPMENT_FAIL = new TaskType();
                UNDO_SHIPMENT_FAIL.code = 'SH-UNDO1';
                UNDO_SHIPMENT_FAIL.label = 'Unable to undo the shipment. Please contact your administrator.';
                UNDO_SHIPMENT_FAIL.description = 'Unable to undo the shipment. Please contact your administrator.';
                UNDO_SHIPMENT_FAIL.typeName = 'Exception';
            }
            return UNDO_SHIPMENT_FAIL;
        }   
    }
}