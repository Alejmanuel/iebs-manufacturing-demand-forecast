WITH HistorialProducto AS (
    SELECT
        CodigoProducto,
        COUNT(*) AS MesesConVentas
    FROM dbo.vw_DemandaMensual
    GROUP BY CodigoProducto
)
SELECT
    CASE
        WHEN MesesConVentas >= 36 THEN '36 meses o más'
        WHEN MesesConVentas >= 24 THEN 'De 24 a 35 meses'
        WHEN MesesConVentas >= 12 THEN 'De 12 a 23 meses'
        ELSE 'Menos de 12 meses'
    END AS TramoHistorial,
    COUNT(*) AS NumeroProductos,
    AVG(CAST(MesesConVentas AS decimal(10,2))) AS PromedioMesesConVentas
FROM HistorialProducto
GROUP BY
    CASE
        WHEN MesesConVentas >= 36 THEN '36 meses o más'
        WHEN MesesConVentas >= 24 THEN 'De 24 a 35 meses'
        WHEN MesesConVentas >= 12 THEN 'De 12 a 23 meses'
        ELSE 'Menos de 12 meses'
    END
ORDER BY
    MIN(MesesConVentas) DESC;