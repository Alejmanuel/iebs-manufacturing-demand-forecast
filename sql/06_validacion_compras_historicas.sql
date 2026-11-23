SELECT
    MIN(TRY_CONVERT(date, h.[Posting Date], 105)) AS PrimeraFecha,
    MAX(TRY_CONVERT(date, h.[Posting Date], 105)) AS UltimaFecha,
    COUNT(*) AS NumeroLineasCompra,
    SUM(l.[Quantity]) AS UnidadesCompradas,
    SUM(l.[Amount]) AS ImporteComprado,
    SUM(l.[Quantity] * l.[Unit Cost (LCY)]) AS CosteCompraEstimado
FROM dbo.Purch_Inv_Line AS l
INNER JOIN dbo.Purch_Inv_Header AS h
    ON h.[No_] = l.[Document No_];