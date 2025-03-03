--To remove imported financials

DELETE ftd
FROM FinancialTransactionDetail ftd
WHERE ftd.ForeignKey = 'Main'

DELETE ft
FROM FinancialTransaction ft
WHERE ft.ForeignKey = 'Main'

DELETE fpd
FROM FinancialPaymentDetail fpd
WHERE fpd.ForeignKey = 'Main'

DELETE fb
FROM FinancialBatch fb
WHERE fb.ForeignKey = 'Main'