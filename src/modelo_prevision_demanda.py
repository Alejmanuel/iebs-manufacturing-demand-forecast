"""Modelo de previsión mensual de demanda por producto.

Lee la vista dbo.vw_DemandaMensualModelo desde SQL Server, prepara
variables temporales, entrena un Random Forest y genera los ficheros
de salida utilizados en Power BI.
"""

from pathlib import Path

import pandas as pd
import pyodbc
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error


CARPETA_SALIDA = Path(__file__).resolve().parent

CONEXION_SQL = (
    "Driver={ODBC Driver 18 for SQL Server};"
    "Server=localhost\\SQLEXPRESS;"
    "Database=IEBS_Manufacturing;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

CONSULTA = """
SELECT
    Periodo,
    CodigoProducto,
    CategoriaProducto,
    DemandaRealUnidades
FROM dbo.vw_DemandaMensualModelo;
"""


def cargar_datos() -> pd.DataFrame:
    """Obtiene la demanda mensual elegible para modelización."""
    with pyodbc.connect(CONEXION_SQL) as conexion:
        datos = pd.read_sql(CONSULTA, conexion)

    datos["Periodo"] = pd.to_datetime(datos["Periodo"])
    datos["DemandaRealUnidades"] = pd.to_numeric(
        datos["DemandaRealUnidades"], errors="coerce"
    ).fillna(0)
    return datos


def preparar_variables(datos: pd.DataFrame) -> tuple[pd.DataFrame, list[str]]:
    """Completa meses sin ventas y crea lags, media móvil y estacionalidad."""
    productos = datos[["CodigoProducto", "CategoriaProducto"]].drop_duplicates()
    meses = pd.DataFrame(
        {"Periodo": pd.date_range(datos["Periodo"].min(), datos["Periodo"].max(), freq="MS")}
    )

    productos["Clave"] = 1
    meses["Clave"] = 1
    calendario_producto = productos.merge(meses, on="Clave").drop(columns="Clave")

    datos = calendario_producto.merge(
        datos,
        on=["CodigoProducto", "CategoriaProducto", "Periodo"],
        how="left",
    )
    datos["DemandaRealUnidades"] = datos["DemandaRealUnidades"].fillna(0)
    datos = datos.sort_values(["CodigoProducto", "Periodo"]).reset_index(drop=True)

    grupo_producto = datos.groupby("CodigoProducto")["DemandaRealUnidades"]
    for retraso in (1, 3, 6, 12):
        datos[f"Lag_{retraso}"] = grupo_producto.shift(retraso).fillna(0)

    datos["MediaMovil3"] = grupo_producto.transform(
        lambda serie: serie.shift(1).rolling(window=3, min_periods=1).mean()
    ).fillna(0)
    datos["Mes"] = datos["Periodo"].dt.month

    categorias = pd.get_dummies(datos["CategoriaProducto"], prefix="CategoriaProducto")
    datos = pd.concat([datos, categorias], axis=1)

    variables = ["Lag_1", "Lag_3", "Lag_6", "Lag_12", "MediaMovil3", "Mes"]
    variables += categorias.columns.tolist()
    return datos, variables


def entrenar_y_evaluar(datos: pd.DataFrame, variables: list[str]) -> tuple[pd.DataFrame, float, float]:
    """Reserva los últimos seis meses y calcula MAE y WAPE."""
    limite_prueba = datos["Periodo"].max() - pd.DateOffset(months=5)
    entrenamiento = datos[datos["Periodo"] < limite_prueba].copy()
    prueba = datos[datos["Periodo"] >= limite_prueba].copy()

    modelo = RandomForestRegressor(
        n_estimators=50,
        max_depth=14,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1,
    )
    modelo.fit(entrenamiento[variables], entrenamiento["DemandaRealUnidades"])

    prueba["PrediccionUnidades"] = modelo.predict(prueba[variables]).clip(min=0)
    prueba["ErrorAbsoluto"] = (
        prueba["DemandaRealUnidades"] - prueba["PrediccionUnidades"]
    ).abs()

    mae = mean_absolute_error(
        prueba["DemandaRealUnidades"], prueba["PrediccionUnidades"]
    )
    wape = (
        prueba["ErrorAbsoluto"].sum()
        / prueba["DemandaRealUnidades"].abs().sum()
        * 100
    )
    return prueba, mae, wape


def guardar_resultados(prueba: pd.DataFrame, mae: float, wape: float) -> None:
    """Genera resultados completos, archivo compatible con Power BI y métricas."""
    prueba.to_csv(
        CARPETA_SALIDA / "predicciones_demanda.csv",
        index=False,
        encoding="utf-8-sig",
    )

    columnas_power_bi = [
        "Periodo",
        "CodigoProducto",
        "DemandaRealUnidades",
        "PrediccionUnidades",
        "ErrorAbsoluto",
    ]
    prueba[columnas_power_bi].to_csv(
        CARPETA_SALIDA / "predicciones_powerbi.csv",
        sep=";",
        decimal=",",
        index=False,
        encoding="utf-8-sig",
    )

    with open(CARPETA_SALIDA / "metricas_modelo.txt", "w", encoding="utf-8") as archivo:
        archivo.write(f"MAE: {mae:.2f}\\n")
        archivo.write(f"WAPE: {wape:.2f}%\\n")


def main() -> None:
    datos = cargar_datos()
    datos, variables = preparar_variables(datos)
    prueba, mae, wape = entrenar_y_evaluar(datos, variables)
    guardar_resultados(prueba, mae, wape)

    print(f"MAE: {mae:.2f}")
    print(f"WAPE: {wape:.2f}%")
    print("Archivos generados: predicciones_demanda.csv, predicciones_powerbi.csv y metricas_modelo.txt")


if __name__ == "__main__":
    main()
