SELECT
    MIN(TRY_CONVERT(date, h.[Posting Date], 105)) AS PrimeraFecha,
    MAX(TRY_CONVERT(date, h.[Posting Date], 105)) AS UltimaFecha,
    COUNT(*) AS NumeroLineasFacturadas,
    SUM(l.[Quantity]) AS UnidadesFacturadas,
    SUM(l.[Amount]) AS ImporteFacturado,
    SUM(l.[Amount] - l.[Quantity] * l.[Unit Cost (LCY)]) AS MargenBrutoEstimado
FROM dbo.Sales_Invoice_Line AS l
INNER JOIN dbo.Sales_Invoice_Header AS h
    ON h.[No_] = l.[Document No_];