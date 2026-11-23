CREATE OR ALTER VIEW dbo.vw_DemandaMensual AS
SELECT
    DATEFROMPARTS(Anio, Mes, 1) AS Periodo,
    CodigoProducto,
    DescripcionProducto,
    CategoriaProducto,
    SUM(UnidadesFacturadas) AS DemandaRealUnidades,
    SUM(ImporteFacturado) AS ImporteFacturado,
    SUM(MargenBrutoEstimado) AS MargenBrutoEstimado
FROM dbo.vw_FactVentasAnaliticas
GROUP BY
    DATEFROMPARTS(Anio, Mes, 1),
    CodigoProducto,
    DescripcionProducto,
    CategoriaProducto;

SELECT TOP 100 *
FROM dbo.vw_DemandaMensual
ORDER BY Periodo DESC, DemandaRealUnidades DESC;