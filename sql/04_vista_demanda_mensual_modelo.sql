CREATE OR ALTER VIEW dbo.vw_DemandaMensualModelo AS
WITH ProductosElegibles AS (
    SELECT CodigoProducto
    FROM dbo.vw_DemandaMensual
    GROUP BY CodigoProducto
    HAVING COUNT(*) >= 36
)
SELECT
    d.Periodo,
    d.CodigoProducto,
    d.DescripcionProducto,
    d.CategoriaProducto,
    d.DemandaRealUnidades,
    d.ImporteFacturado,
    d.MargenBrutoEstimado
FROM dbo.vw_DemandaMensual AS d
INNER JOIN ProductosElegibles AS p
    ON p.CodigoProducto = d.CodigoProducto;

    SELECT
    COUNT(*) AS RegistrosMensuales,
    COUNT(DISTINCT CodigoProducto) AS ProductosElegibles,
    MIN(Periodo) AS PrimerPeriodo,
    MAX(Periodo) AS UltimoPeriodo
FROM dbo.vw_DemandaMensualModelo;