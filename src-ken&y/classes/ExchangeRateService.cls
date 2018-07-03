public with sharing class ExchangeRateService {
	
	private static List<Exchange_Rate__c> exchangeRates;
	public static List<Exchange_Rate__c> returnExchangeRates(set<Id> fromCurrencies, set<Id> toCurrencies, DateTime fromDateTime, DateTime toDateTime){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Exchange_Rate__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','From_Currency__c','To_Currency__c','Multiplier_Exchange_Rate__c','Daily_Monthly__c','Rate_Start_Datetime__c',
			'Rate_End_Datetime__c'
		});
		soql.setWhereClause('From_Currency__c IN :fromCurrencies AND To_Currency__c IN :toCurrencies AND (Rate_End_DateTime__c >= :fromDateTime OR Rate_Start_DateTime__c <= :toDateTime)');
		soql.setOrderByClause('Rate_Start_DateTime__c');
		return Database.query(soql.getQuery());
	}

	public static void loadExchangeRates(set<Id>fromCurrencies, set<Id>toCurrencies, List<Datetime>dts ){
		loadExchangeRates(fromCurrencies, toCurrencies, dts, 'Daily');
	}
	
	public static void loadExchangeRates(set<Id>fromCurrencies, set<Id>toCurrencies, List<Datetime>dts,  string dailyMonthly){
		if(fromCurrencies.size() == 1 && toCurrencies.size() == 1 && fromCurrencies.containsAll(toCurrencies)){
			System.debug(LoggingLevel.ERROR, '#### Same no exchange.');
			exchangeRates = new list<Exchange_Rate__c>();
			return;
		}

		dts.sort();
		Datetime earliest = dts.get(0);
		DateTime latest = dts.get(dts.size()-1);

		SOQLUtil soql = new SOQLUtil('Exchange_Rate__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','From_Currency__c','To_Currency__c','Multiplier_Exchange_Rate__c','Daily_Monthly__c','Rate_Start_Datetime__c',
			'Rate_End_Datetime__c'
		});
		
		soql.setWhereClause('Daily_Monthly__c=\''+ dailyMonthly +'\' and ( Rate_Start_DateTime__c <=: latest and ( Rate_End_Datetime__c = null or Rate_End_Datetime__c >=:earliest ) )');
		soql.setOrderByClause('Rate_Start_DateTime__c desc');
		exchangeRates = Database.query(soql.getQuery());
	}
	public static Decimal convertAmount(Id fromCurrency, Id toCurrency, DateTime transactiondate, Decimal amount){
		System.debug(LoggingLevel.ERROR, 'Convert amount');
        System.debug(LoggingLevel.ERROR, 'From: ' + fromCurrency + '\tTo: ' + toCurrency + '\ttrans: ' + transactiondate + '\tEx Rates: ' + exchangeRates.size() + '\tAmount: ' + amount);
		if(fromCurrency != toCurrency && exchangeRates != null){
			system.debug(logginglevel.info,' exchangeRates is========='+exchangeRates);
			Exchange_Rate__c exr = getExchangeRate(fromCurrency, toCurrency, transactiondate);
			Decimal rate = exr != null ? exr.Multiplier_Exchange_Rate__c : null;
		
			system.debug(logginglevel.ERROR,'rate used for amount is========='+rate);
			if(rate != null){
				amount *= rate;
			}else{
				amount = null;
			}
		
		}
		system.debug(logginglevel.ERROR,'amount is========='+amount);
		return amount;
	}

	public static Decimal convertReverseAmount(Id functionalCurrency, Id transactionCurrency, DateTime transactiondate, Decimal amount){

		if(transactionCurrency != functionalCurrency && exchangeRates != null){
			Exchange_Rate__c exr = getExchangeRate(transactionCurrency, functionalCurrency, transactiondate);
			Decimal rate = exr != null ? exr.Multiplier_Exchange_Rate__c : null;
		
			if(rate != null){
				amount /= rate;
			}else{
				amount = null;
		}
	}

		return amount;
	}

	public static Exchange_Rate__c getExchangeRate(Id fromCurrency, Id toCurrency, DateTime transactiondate){
		System.debug(LoggingLevel.ERROR, '#### In getExchangeRate');
		Exchange_Rate__c exr = null;
			if(exchangeRates.size() > 0){
				for(Exchange_Rate__c er : exchangeRates){
					System.debug(LoggingLevel.ERROR, '#### Ex Rate From: ' + er.From_Currency__c + '\tto: ' + er.To_Currency__c);
					if(er != null){
                        SYstem.debug(LoggingLevel.ERROR, 'Comparing: ' + er.From_Currency__c + ' to: ' + fromCurrency + '\tand ' + er.To_Currency__c + ' to: ' + toCurrency);
						System.debug(LoggingLevel.ERROR, 'Before if loop========='+'Start date: ' + er.Rate_Start_Datetime__c + '\tEnd Date: ' + er.Rate_End_Datetime__c + '\ttrans: ' + transactiondate);

						if(er.From_Currency__c == fromCurrency && er.To_Currency__c == toCurrency ){
							System.debug(LoggingLevel.ERROR, '#### Trans date: ' + transactiondate + '\tEx start: ' + er.Rate_Start_Datetime__c + '\tEx End: ' + er.Rate_End_Datetime__c);
						}

						if(er.From_Currency__c == fromCurrency && er.To_Currency__c == toCurrency && 
							er.Rate_Start_Datetime__c <= transactiondate && (er.Rate_End_Datetime__c == null || er.Rate_End_Datetime__c >= transactiondate) ){
							System.debug(LoggingLevel.ERROR,'Inside if loop=========er.Name:'+er.Name+ '====Start date: ' + er.Rate_Start_Datetime__c + '\tEnd Date: ' + er.Rate_End_Datetime__c + '\ttrans: ' + transactiondate);
							exr = er;
							break;
						}
					}
				}
			}
			return exr;
	}
}