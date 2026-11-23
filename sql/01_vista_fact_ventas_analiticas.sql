CREATE OR ALTER VIEW dbo.vw_FactVentasAnaliticas AS
WITH FacturaProducto AS (
    SELECT
        h.[No_] AS NumeroFactura,
        l.[Line No_] AS NumeroLinea,
        TRY_CONVERT(date, h.[Posting Date], 105) AS FechaVenta,
        h.[Sell-to Customer No_] AS CodigoCliente,
        l.[No_] AS CodigoProducto,
        i.[Description] AS DescripcionProducto,
        CASE
            WHEN l.[No_] LIKE 'EL%' THEN 'Elaborado'
            WHEN l.[No_] LIKE 'P%' THEN 'Plástico'
            WHEN l.[No_] LIKE 'DE%' THEN 'Dispositivo electrónico'
            WHEN l.[No_] LIKE 'SE%' THEN 'Semi elaborado'
            WHEN l.[No_] LIKE 'MP%' THEN 'Materia prima'
            ELSE 'Sin clasificar'
        END AS CategoriaProducto,
        l.[Quantity] AS UnidadesFacturadas,
        l.[Amount] AS ImporteFacturado,
        l.[Unit Cost (LCY)] AS CosteUnitario,
        l.[Amount] - l.[Quantity] * l.[Unit Cost (LCY)] AS MargenBrutoEstimado
    FROM dbo.Sales_Invoice_Line AS l
    INNER JOIN dbo.Sales_Invoice_Header AS h
        ON h.[No_] = l.[Document No_]
    INNER JOIN dbo.Item AS i
        ON i.[No_] = l.[No_]
)
SELECT
    NumeroFactura,
    NumeroLinea,
    FechaVenta,
    YEAR(FechaVenta) AS Anio,
    MONTH(FechaVenta) AS Mes,
    CodigoCliente,
    CodigoProducto,
    DescripcionProducto,
    CategoriaProducto,
    UnidadesFacturadas,
    ImporteFacturado,
    CosteUnitario,
    MargenBrutoEstimado
FROM FacturaProducto
WHERE FechaVenta IS NOT NULL;


SELECT TOP 100 *
FROM dbo.vw_FactVentasAnaliticas
ORDER BY FechaVenta DESC;